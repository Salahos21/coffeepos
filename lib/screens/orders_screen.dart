import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database_helper.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<PosOrder> _orders = [];
  List<PosOrder> _filteredOrders = [];
  bool _isLoading = true;

  String _searchQuery = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _endDate = DateTime.now();

  double _todayRevenue = 0;
  double _rangeRevenue = 0;
  List<BarChartGroupData> _chartData = [];
  List<MapEntry<String, int>> _topSellers = [];
  List<String> _recentDays = [];
  Map<String, double> _revenueByBarista = {};

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateData();
  }

  // CORRECTION: Refresh data whenever the tab is selected/re-focused
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAndCalculateData();
  }

  Future<void> _fetchAndCalculateData() async {
    // Safety check to ensure widget is still active
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isManager = currentUser?.role == 'Manager';

    List<PosOrder> orders;
    if (isManager) {
      orders = await DatabaseHelper.instance.getOrdersByRange(_startDate, _endDate);
    } else {
      orders = await DatabaseHelper.instance.getOrdersByCashier(currentUser?.name ?? '');
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    double todayTotal = 0;
    double rangeTotal = 0;
    Map<String, double> dailyRevenue = {};
    Map<String, int> itemCounts = {};
    Map<String, double> baristaRevenue = {};

    for (var order in orders) {
      if (!order.isVoid) {
        rangeTotal += order.finalTotal;
        final orderDate = order.date.substring(0, 10);
        if (orderDate == todayStr) todayTotal += order.finalTotal;

        dailyRevenue[orderDate] = (dailyRevenue[orderDate] ?? 0) + order.finalTotal;
        baristaRevenue[order.cashierName] = (baristaRevenue[order.cashierName] ?? 0) + order.finalTotal;

        final items = order.itemsSummary.split(', ');
        for (var itemStr in items) {
          final parts = itemStr.split('x ');
          if (parts.length == 2) {
            itemCounts[parts[1]] = (itemCounts[parts[1]] ?? 0) + (int.tryParse(parts[0]) ?? 0);
          }
        }
      }
    }

    List<BarChartGroupData> barGroups = [];
    List<String> days = [];
    for (int i = 6; i >= 0; i--) {
      final day = _endDate.subtract(Duration(days: i));
      final dayStr = DateFormat('yyyy-MM-dd').format(day);
      days.add(dayStr.substring(5));
      barGroups.add(BarChartGroupData(x: 6 - i, barRods: [
        BarChartRodData(toY: dailyRevenue[dayStr] ?? 0, color: const Color(0xFF006E3B), width: 16)
      ]));
    }

    if (mounted) {
      setState(() {
        _orders = orders;
        _filteredOrders = orders;
        _todayRevenue = todayTotal;
        _rangeRevenue = rangeTotal;
        _chartData = barGroups;
        _recentDays = days;
        _topSellers = (itemCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(3).toList();
        _revenueByBarista = Map.fromEntries(baristaRevenue.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
        _isLoading = false;
      });
    }
  }

  void _filterOrders(String query) {
    setState(() {
      _searchQuery = query;
      _filteredOrders = _orders.where((order) {
        return order.itemsSummary.toLowerCase().contains(query.toLowerCase()) ||
            order.id.toString().contains(query);
      }).toList();
    });
  }

  void _setQuickRange(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = DateTime.now().subtract(Duration(days: days));
      _isLoading = true;
    });
    _fetchAndCalculateData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)));

    final isManager = Provider.of<AuthProvider>(context).currentUser?.role == 'Manager';
    final lang = Provider.of<LanguageProvider>(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          expandedHeight: 60,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          title: Text(
            isManager ? lang.t('order_history') : lang.t('orders'),
            style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: ElevatedButton.icon(
                  onPressed: () => _showCloseShiftDialog(context),
                  icon: const Icon(Icons.lock_clock, size: 16),
                  label: Text(
                    lang.t('close_shift'),
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (isManager) ...[
                    _buildFilterChip("Today", 0),
                    const SizedBox(width: 8),
                    _buildFilterChip("30 Days", 30),
                    const SizedBox(width: 8),
                    _buildFilterChip("1 Year", 365),
                    const SizedBox(width: 16),
                    const VerticalDivider(),
                    OutlinedButton.icon(
                      onPressed: () => _selectDateRange(context),
                      icon: const Icon(Icons.calendar_month, size: 18, color: Color(0xFF006E3B)),
                      label: Text(
                        "${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}",
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                    ),
                  ],
                  if (isManager)
                    IconButton(
                      onPressed: _shareReport,
                      icon: const Icon(Icons.share, color: Color(0xFF006E3B)),
                    ),
                ],
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isManager) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    _buildSummaryCard(lang.t('today_revenue'), '\$${_todayRevenue.toStringAsFixed(2)}', Icons.today, const Color(0xFF006E3B)),
                    const SizedBox(width: 20),
                    _buildSummaryCard(lang.t('range_total'), '\$${_rangeRevenue.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.blueGrey),
                    const SizedBox(width: 20),
                    _buildSummaryCard(lang.t('avg_sale'), '\$${(_orders.isEmpty ? 0 : _rangeRevenue / _orders.length).toStringAsFixed(2)}', Icons.trending_up, Colors.indigo),
                  ]),
                  const SizedBox(height: 32),
                  _buildChartsRow(),
                ],
                const SizedBox(height: 48),
                _buildHistoryHeader(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        _filteredOrders.isEmpty
            ? const SliverFillRemaining(child: Center(child: Text('No orders found')))
            : SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildOrderTile(_filteredOrders[index], isManager),
              childCount: _filteredOrders.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildFilterChip(String label, int days) {
    final bool isSelected = DateTime.now().difference(_startDate).inDays == days;
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? const Color(0xFF006E3B) : Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      onPressed: () => _setQuickRange(days),
    );
  }

  Widget _buildChartsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildBarChart()),
        const SizedBox(width: 20),
        Expanded(child: Column(children: [_buildTopSellersCard(), const SizedBox(height: 20), _buildTeamCard()])),
      ],
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 350, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Range Performance', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Expanded(child: BarChart(BarChartData(
          barGroups: _chartData, borderData: FlBorderData(show: false), gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text(_recentDays[v.toInt()], style: const TextStyle(fontSize: 10)))),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ))),
      ]),
    );
  }

  Widget _buildHistoryHeader() {
    final lang = Provider.of<LanguageProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          lang.t('order_history'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Container(
          width: 300,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFEEDDDD)),
          ),
          child: TextField(
            onChanged: (value) => _filterOrders(value),
            decoration: InputDecoration(
              hintText: lang.t('search_hint'),
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _filterOrders('');
                  _fetchAndCalculateData();
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTile(PosOrder order, bool isManager) {
    return Card(
      color: order.isVoid ? Colors.red.shade50 : null,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFEEDDDD))),
      child: ListTile(
        onTap: () => _showReceiptModal(context, order),
        leading: CircleAvatar(child: Text('#${order.id}', style: const TextStyle(fontSize: 10))),
        title: Text(order.itemsSummary, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(decoration: order.isVoid ? TextDecoration.lineThrough : null)),
        subtitle: Text("${order.date} • ${order.cashierName}"),
        trailing: (!order.isVoid && isManager)
            ? IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _confirmVoid(context, order))
            : const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
      child: Row(children: [Icon(icon, color: color, size: 32), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])]),
    ));
  }

  Widget _buildTopSellersCard() {
    return Container(height: 165, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Top Sellers', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._topSellers.map((e) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key), Text('${e.value} sold', style: const TextStyle(color: Color(0xFF006E3B), fontWeight: FontWeight.bold))])),
      ]),
    );
  }

  Widget _buildTeamCard() {
    return Container(height: 165, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Team Performance', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(child: ListView(children: _revenueByBarista.entries.map((e) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key), Text('\$${e.value.toStringAsFixed(2)}')])).toList())),
      ]),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006E3B),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isLoading = true;
      });
      _fetchAndCalculateData();
    }
  }

  Future<void> _shareReport() async {
    await Share.share("Store Report: Range ${_startDate.toString().substring(0,10)} to ${_endDate.toString().substring(0,10)}\nTotal: \$${_rangeRevenue.toStringAsFixed(2)}");
  }

  Future<void> _confirmVoid(BuildContext context, PosOrder order) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
            title: Text(lang.t('void_order')),
            content: Text('${lang.t('void_order')} #${order.id}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(lang.t('cancel'))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(lang.t('void_order'), style: const TextStyle(color: Colors.red)))
            ]
        )
    );
    if (confirmed == true) { await DatabaseHelper.instance.voidOrder(order.id!); _fetchAndCalculateData(); }
  }

  void _showCloseShiftDialog(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser!;
    final isBlindDrop = await DatabaseHelper.instance.getBlindDropSetting();
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    double todaySales = _orders
        .where((o) => o.date.startsWith(todayStr) && !o.isVoid)
        .fold(0, (sum, o) => sum + o.finalTotal);

    final TextEditingController startingCashController = TextEditingController(text: "100.00");
    final TextEditingController actualCashController = TextEditingController();

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
              title: Text(lang.t('close_shift')),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: startingCashController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Starting Cash (\$)', border: OutlineInputBorder()), onChanged: (_) => setDialogState(() {})),
                    const SizedBox(height: 16),
                    TextField(controller: actualCashController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual Cash Counted (\$)', border: OutlineInputBorder()), onChanged: (_) => setDialogState(() {})),
                    const SizedBox(height: 24),
                    if (!hideMath) ...[
                      const Divider(),
                      _buildRow(lang.t('today_revenue'), '\$${todaySales.toStringAsFixed(2)}'),
                      _buildRow('Expected', '\$${expectedCash.toStringAsFixed(2)}'),
                      _buildRow('Variance', '\$${variance.toStringAsFixed(2)}', isBold: true, color: variance >= 0 ? Colors.green : Colors.red),
                    ] else const Text('Blind Drop Enabled: Math is hidden until submission.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t('cancel'))),
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
                    _sendShiftEmailReport(report);
                    Navigator.pop(context);
                  },
                  child: Text(lang.t('confirm_payment'), style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
      ),
    );
  }

  void _showReceiptModal(BuildContext context, PosOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TACTILE POS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Order #${order.id}'), Text(order.date)]),
              const Divider(),
              ...order.itemsSummary.split(', ').map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Align(alignment: Alignment.centerLeft, child: Text(item)))),
              const Divider(thickness: 2),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text('\$${order.finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
              const SizedBox(height: 20),
              const Text('THANK YOU!'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
          ElevatedButton(onPressed: () {}, child: const Text('PRINT')),
        ],
      ),
    );
  }

  Future<void> _sendShiftEmailReport(ShiftReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final String username = prefs.getString('reportingEmail') ?? '';
    final String password = prefs.getString('appPassword') ?? '';
    if (username.isEmpty || password.isEmpty) return;
    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Tactile POS')
      ..recipients.add(username)
      ..subject = 'Daily Shift Report: ${report.date}'
      ..text = 'Employee: ${report.employeeName}\nSales: \$${report.totalSales}\nVariance: \$${report.variance}';
    try { await send(message, smtpServer); } catch (e) { debugPrint('Email failed: $e'); }
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
      ]),
    );
  }
}