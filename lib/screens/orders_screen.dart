import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_helper.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
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
  bool _isClosingShift = false;

  String _searchQuery = '';
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _endDate = DateTime.now();

  double _todayRevenue = 0;
  double _rangeRevenue = 0;
  List<BarChartGroupData> _chartData = [];
  List<MapEntry<String, int>> _topSellers = [];
  List<String> _recentDays = [];
  Map<String, double> _revenueByBarista = {};

  late RealtimeChannel _orderSubscription;

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateData();
    _setupOrderRealtime();
  }

  void _setupOrderRealtime() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.cafeId == null) return;

    _orderSubscription = Supabase.instance.client
        .channel('public:orders')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'cafe_id',
        value: auth.cafeId,
      ),
      callback: (payload) {
        _fetchAndCalculateData();
      },
    )
        .subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_orderSubscription);
    super.dispose();
  }

  Future<void> _fetchAndCalculateData() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    final cafeId = auth.cafeId;

    if (cafeId == null) {
      setState(() => _isLoading = false);
      return;
    }

    List<PosOrder> orders = await SupabaseHelper.instance.getOrdersByRange(cafeId, _startDate, _endDate);

    if (currentUser?.role != 'Manager') {
      orders = orders.where((o) => o.cashierName == currentUser?.name).toList();
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
        if (order.date.startsWith(todayStr)) todayTotal += order.finalTotal;
        final orderDatePart = order.date.substring(0, 10);
        dailyRevenue[orderDatePart] = (dailyRevenue[orderDatePart] ?? 0) + order.finalTotal;
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
      final day = DateTime.now().subtract(Duration(days: i));
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

  /// Automated "One-Tap" Shift Closure
  void _handleCloseShift() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser!;
    final cafeId = auth.cafeId!;
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    setState(() => _isClosingShift = true);

    try {
      // 1. Calculate revenue from today's non-voided orders
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      double todaySales = _orders
          .where((o) => o.date.startsWith(todayStr) && !o.isVoid)
          .fold(0, (sum, o) => sum + o.finalTotal);

      // 2. Create and insert simplified report
      final report = ShiftReport(
        date: now.toIso8601String(),
        employeeName: user.name,
        totalSales: todaySales,
      );

      await SupabaseHelper.instance.insertShiftReport(report, cafeId);

      // 3. Fetch cloud settings for target email and business name
      final settings = await SupabaseHelper.instance.getCafeSettings(cafeId);
      final String businessName = settings?['business_name'] ?? 'Tactile POS';
      final String reportingEmail = settings?['reporting_email'] ?? '';

      // 4. Trigger professional email via Edge Function
      if (reportingEmail.isNotEmpty) {
        await SupabaseHelper.instance.sendEmailReportViaEdge(
          email: reportingEmail,
          businessName: businessName,
          report: report,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Shift Closed & Report Sent Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isClosingShift = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)));
    final auth = Provider.of<AuthProvider>(context);
    final isManager = auth.currentUser?.role == 'Manager';
    final lang = Provider.of<LanguageProvider>(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true, pinned: true, expandedHeight: 60,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent,
          title: Text(isManager ? lang.t('order_history') : lang.t('orders'), style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: ElevatedButton.icon(
                  onPressed: _isClosingShift ? null : _handleCloseShift,
                  icon: _isClosingShift
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.lock_clock, size: 16),
                  label: Text(lang.t('close_shift'), style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
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
                    OutlinedButton.icon(
                      onPressed: () => _selectDateRange(context),
                      icon: const Icon(Icons.calendar_month, size: 18, color: Color(0xFF006E3B)),
                      label: Text("${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}"),
                    ),
                    IconButton(onPressed: _shareReport, icon: const Icon(Icons.share, color: Color(0xFF006E3B))),
                  ],
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
                    _buildSummaryCard(lang.t('today_revenue'), 'DH ${_todayRevenue.toStringAsFixed(2)}', Icons.today, const Color(0xFF006E3B)),
                    const SizedBox(width: 20),
                    _buildSummaryCard(lang.t('range_total'), 'DH ${_rangeRevenue.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.blueGrey),
                    const SizedBox(width: 20),
                    _buildSummaryCard(lang.t('avg_sale'), 'DH ${(_orders.isEmpty ? 0 : _rangeRevenue / _orders.length).toStringAsFixed(2)}', Icons.trending_up, Colors.indigo),
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
            delegate: SliverChildBuilderDelegate((context, index) => _buildOrderTile(_filteredOrders[index], isManager), childCount: _filteredOrders.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildFilterChip(String label, int days) {
    final targetStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).subtract(Duration(days: days));
    final bool isSelected = _startDate.year == targetStart.year && _startDate.month == targetStart.month && _startDate.day == targetStart.day;
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? const Color(0xFF006E3B) : Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      onPressed: () => _setQuickRange(days),
    );
  }

  void _setQuickRange(int days) {
    final now = DateTime.now();
    setState(() {
      _endDate = now;
      final start = now.subtract(Duration(days: days));
      _startDate = DateTime(start.year, start.month, start.day);
      _isLoading = true;
    });
    _fetchAndCalculateData();
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
          child: Row(children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])
          ]),
        )
    );
  }

  Widget _buildChartsRow() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: 2, child: _buildBarChart()),
    const SizedBox(width: 20),
    Expanded(child: Column(children: [_buildTopSellersCard(), const SizedBox(height: 20), _buildTeamCard()])),
  ]);

  Widget _buildBarChart() => Container(height: 350, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Range Performance', style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 24),
    Expanded(child: BarChart(BarChartData(barGroups: _chartData, borderData: FlBorderData(show: false), gridData: const FlGridData(show: false), titlesData: FlTitlesData(
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text(_recentDays[v.toInt()], style: const TextStyle(fontSize: 10)))),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    )))),
  ]));

  Widget _buildTopSellersCard() => Container(height: 165, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Top Sellers', style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    ..._topSellers.map((e) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key), Text('${e.value} sold', style: const TextStyle(color: Color(0xFF006E3B), fontWeight: FontWeight.bold))])),
  ]));

  Widget _buildTeamCard() => Container(height: 165, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Team Performance', style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    Expanded(child: ListView(children: _revenueByBarista.entries.map((e) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key), Text('DH ${e.value.toStringAsFixed(2)}')])).toList())),
  ]));

  Widget _buildHistoryHeader() {
    final lang = Provider.of<LanguageProvider>(context);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(lang.t('order_history'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Container(width: 300, height: 45, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: const Color(0xFFEEDDDD))), child: TextField(onChanged: (value) => _filterOrders(value), decoration: InputDecoration(hintText: lang.t('search_hint'), prefixIcon: const Icon(Icons.search, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 10)))),
    ]);
  }

  void _filterOrders(String query) {
    setState(() {
      _searchQuery = query;
      _filteredOrders = _orders.where((order) => order.itemsSummary.toLowerCase().contains(query.toLowerCase()) || order.id.toString().contains(query)).toList();
    });
  }

  Widget _buildOrderTile(PosOrder order, bool isManager) => Card(color: order.isVoid ? Colors.red.shade50 : null, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFEEDDDD))), child: ListTile(onTap: () => _showReceiptModal(context, order), leading: CircleAvatar(child: Text('#${order.id}', style: const TextStyle(fontSize: 10))), title: Text(order.itemsSummary, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(decoration: order.isVoid ? TextDecoration.lineThrough : null)), subtitle: Text("${order.date} • ${order.cashierName}"), trailing: (!order.isVoid && isManager) ? IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _confirmVoid(context, order)) : const Icon(Icons.chevron_right)));

  Future<void> _confirmVoid(BuildContext context, PosOrder order) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text(lang.t('void_order')), content: Text('${lang.t('void_order')} #${order.id}?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(lang.t('cancel'))), TextButton(onPressed: () => Navigator.pop(context, true), child: Text(lang.t('void_order'), style: const TextStyle(color: Colors.red)))]));
    if (confirmed == true && auth.cafeId != null) {
      await SupabaseHelper.instance.voidOrder(order.id!, auth.cafeId!);
      _fetchAndCalculateData();
    }
  }

  void _showReceiptModal(BuildContext context, PosOrder order) => showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), content: SizedBox(width: 350, child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('TACTILE POS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Order #${order.id}'), Text(order.date.substring(0,16))]), const Divider(), ...order.itemsSummary.split(', ').map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Align(alignment: Alignment.centerLeft, child: Text(item)))), const Divider(thickness: 2), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text('DH ${order.finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))])])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))]));

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: DateTimeRange(start: _startDate, end: _endDate));
    if (picked != null) { setState(() { _startDate = picked.start; _endDate = picked.end; _isLoading = true; }); _fetchAndCalculateData(); }
  }

  Future<void> _shareReport() async => await Share.share("Cafe Report: ${_startDate.toString().substring(0,10)} to ${_endDate.toString().substring(0,10)}\nTotal: DH ${_rangeRevenue.toStringAsFixed(2)}");
}