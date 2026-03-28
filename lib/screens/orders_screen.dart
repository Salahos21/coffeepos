import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<PosOrder> _orders = [];
  List<PosOrder> _filteredOrders = [];
  bool _isLoading = true;

  // Search & Filter State
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  // Analytics Data
  double _todayRevenue = 0;
  double _allTimeRevenue = 0;
  List<BarChartGroupData> _chartData = [];
  List<MapEntry<String, int>> _topSellers = [];
  List<String> _recentDays = [];
  Map<String, double> _revenueByBarista = {};

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateData();
  }

  Future<void> _fetchAndCalculateData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    // 1. Fetch orders based on role
    final isManager = currentUser?.role == 'Manager';
    List<PosOrder> orders;
    if (isManager) {
      orders = await DatabaseHelper.instance.getAllOrders();
    } else {
      orders = await DatabaseHelper.instance.getOrdersByCashier(currentUser?.name ?? '');
    }

    final now = DateTime.now();
    final todayStr = now.toString().substring(0, 10);

    // 2. Analytics Math
    double todayTotal = 0;
    double allTimeTotal = 0;
    Map<String, double> dailyRevenue = {};
    Map<String, int> itemCounts = {};
    Map<String, double> baristaRevenue = {};

    for (var order in orders) {
      allTimeTotal += order.finalTotal;
      final orderDate = order.date.substring(0, 10);
      
      if (orderDate == todayStr) {
        todayTotal += order.finalTotal;
      }

      dailyRevenue[orderDate] = (dailyRevenue[orderDate] ?? 0) + order.finalTotal;
      baristaRevenue[order.cashierName] = (baristaRevenue[order.cashierName] ?? 0) + order.finalTotal;

      final items = order.itemsSummary.split(', ');
      for (var itemStr in items) {
        final parts = itemStr.split('x ');
        if (parts.length == 2) {
          final qty = int.tryParse(parts[0]) ?? 0;
          final name = parts[1];
          itemCounts[name] = (itemCounts[name] ?? 0) + qty;
        }
      }
    }

    final sortedBaristas = Map.fromEntries(
        baristaRevenue.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );

    // 3. Prepare Chart Data (Last 7 Days)
    List<BarChartGroupData> barGroups = [];
    List<String> days = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr = day.toString().substring(0, 10);
      final revenue = dailyRevenue[dayStr] ?? 0;
      
      days.add(dayStr.substring(5)); // Show MM-DD
      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: revenue,
              color: const Color(0xFF006E3B),
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            )
          ],
        ),
      );
    }

    final sortedSellers = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _orders = orders;
      _filteredOrders = orders;
      _todayRevenue = todayTotal;
      _allTimeRevenue = allTimeTotal;
      _chartData = barGroups;
      _recentDays = days;
      _topSellers = sortedSellers.take(3).toList();
      _revenueByBarista = sortedBaristas;
      _isLoading = false;
    });
  }

  void _filterOrders() {
    setState(() {
      _filteredOrders = _orders.where((order) {
        final matchesSearch = order.itemsSummary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            order.cashierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            order.id.toString().contains(_searchQuery);
        
        bool matchesDate = true;
        if (_dateRange != null) {
          final orderDate = DateTime.parse(order.date);
          matchesDate = orderDate.isAfter(_dateRange!.start.subtract(const Duration(seconds: 1))) && 
                        orderDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        }

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF006E3B),
              primary: const Color(0xFF006E3B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _filterOrders();
    }
  }

// --- CLOSE SHIFT DIALOG ---
  void _showCloseShiftDialog(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser!;
    final isBlindDrop = await DatabaseHelper.instance.getBlindDropSetting();

    final now = DateTime.now();
    final todayStr = now.toString().substring(0, 10);
    double todaySales = _orders
        .where((o) => o.date.startsWith(todayStr))
        .fold(0, (sum, o) => sum + o.finalTotal);

    final TextEditingController startingCashController = TextEditingController(text: "100.00");
    final TextEditingController actualCashController = TextEditingController();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            double startingCash = double.tryParse(startingCashController.text) ?? 0;
            double actualCash = double.tryParse(actualCashController.text) ?? 0;
            double expectedCash = startingCash + todaySales;
            double variance = actualCash - expectedCash;

            bool hideMath = (user.role == 'Barista' && isBlindDrop);

            return AlertDialog(
              title: const Text('Close Shift Report'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: startingCashController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Starting Cash (\$)', border: OutlineInputBorder()),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: actualCashController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Actual Cash Counted (\$)', border: OutlineInputBorder()),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // SAFE SYNTAX: Replaced the spread operator with a standard ternary check
                    hideMath
                        ? const SizedBox.shrink() // <-- Invisible, zero-pixel widget
                        : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Divider(),
                        _buildSummaryRow('Today\'s Sales', '\$${todaySales.toStringAsFixed(2)}'),
                        _buildSummaryRow('Expected in Drawer', '\$${expectedCash.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Variance', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '\$${variance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: variance >= 0 ? Colors.green : Colors.red,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006E3B)),
                  onPressed: () async {
                    final report = ShiftReport(
                      date: DateTime.now().toString().substring(0, 16),
                      employeeName: user.name,
                      startingCash: startingCash,
                      totalSales: todaySales,
                      expectedCash: expectedCash,
                      actualCash: actualCash,
                      variance: variance,
                    );
                    await DatabaseHelper.instance.insertShiftReport(report);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shift Closed & Report Saved!'), backgroundColor: Color(0xFF006E3B)),
                      );
                    }
                  },
                  child: const Text('SUBMIT REPORT', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
      ),
    );
  }

  void _showReceiptModal(BuildContext context, PosOrder order) {
    final List<String> itemLines = order.itemsSummary.split(', ');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TACTILE POS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 2)),
              const Text('123 Coffee Lane, Tech City', style: TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 20),
              Divider(thickness: 1, color: Colors.grey[300]),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(order.date, style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Cashier: ${order.cashierName}', style: const TextStyle(fontSize: 12)),
              ),
              Divider(thickness: 1, color: Colors.grey[300]),
              const SizedBox(height: 10),
              ...itemLines.map((line) {
                final parts = line.split('x ');
                final qty = parts[0];
                final name = parts.length > 1 ? parts[1] : line;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Text('$qty x', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              Divider(thickness: 2, color: Colors.black87),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text('\$${order.finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              const SizedBox(height: 30),
              const Text('THANK YOU!', style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: 4)),
              const SizedBox(height: 10),
              Container(height: 30, width: double.infinity, color: Colors.grey[200]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE', style: TextStyle(color: Colors.black54))),
          ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.print, size: 18), label: const Text('PRINT'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006E3B), foregroundColor: Colors.white, minimumSize: const Size(100, 40))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)));
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isManager = currentUser?.role == 'Manager';
    final String dashboardTitle = isManager ? 'Store Analytics' : 'My Daily Performance';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dashboardTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              ElevatedButton.icon(
                onPressed: () => _showCloseShiftDialog(context),
                icon: const Icon(Icons.lock_clock),
                label: const Text('Close Shift'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Revenue Cards
          Row(
            children: [
              _buildSummaryCard('Today\'s Revenue', '\$${_todayRevenue.toStringAsFixed(2)}', Icons.today, const Color(0xFF006E3B)),
              const SizedBox(width: 20),
              if (isManager)
                _buildSummaryCard('All-Time Revenue', '\$${_allTimeRevenue.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.blueGrey)
              else
                _buildSummaryCard('My Total Sales', '\$${_allTimeRevenue.toStringAsFixed(2)}', Icons.person_outline, Colors.blueGrey),
            ],
          ),
          const SizedBox(height: 32),

          // 2. Chart & Performance Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last 7 Days Revenue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 24),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            barGroups: _chartData,
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() < _recentDays.length) {
                                      return Text(_recentDays[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: isManager ? 165 : 350,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Top Sellers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          if (_topSellers.isEmpty) const Expanded(child: Center(child: Text('No data')))
                          else ..._topSellers.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)), Text('${e.value} sold', style: const TextStyle(color: Color(0xFF006E3B), fontWeight: FontWeight.bold, fontSize: 11))]))),
                        ],
                      ),
                    ),
                    if (isManager) ...[
                      const SizedBox(height: 20),
                      Container(
                        height: 165,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Team Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            Expanded(child: ListView(children: _revenueByBarista.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)), Text('\$${e.value.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF006E3B), fontWeight: FontWeight.bold, fontSize: 11))]))).toList())),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Container(
                    width: 250,
                    height: 40,
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEEDDDD))),
                    child: TextField(
                      onChanged: (val) { _searchQuery = val; _filterOrders(); },
                      decoration: const InputDecoration(hintText: 'Search order ID or item...', hintStyle: TextStyle(fontSize: 12), prefixIcon: Icon(Icons.search, size: 18), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ActionChip(avatar: const Icon(Icons.date_range, size: 16), label: Text(_dateRange == null ? 'All Dates' : 'Filtered'), onPressed: () => _selectDateRange(context)),
                  if (_dateRange != null) IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.red), onPressed: () { setState(() => _dateRange = null); _filterOrders(); }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_filteredOrders.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('No orders found matching your filters')))
          else ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _filteredOrders.length, itemBuilder: (context, index) {
            final order = _filteredOrders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFEEDDDD))),
              child: ListTile(
                onTap: () => _showReceiptModal(context, order),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(backgroundColor: const Color(0xFFF0F7F4), child: Text('#${order.id}', style: const TextStyle(fontSize: 10, color: Color(0xFF006E3B), fontWeight: FontWeight.bold))),
                title: Text(order.itemsSummary, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.date, style: TextStyle(color: Colors.grey[500], fontSize: 12)), if (isManager) Text('Cashier: ${order.cashierName}', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic))]),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))]),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
