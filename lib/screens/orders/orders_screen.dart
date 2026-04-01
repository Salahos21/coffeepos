import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_helper.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import 'package:intl/intl.dart';

import 'summary_cards.dart';
import 'analytics_dashboard.dart';
import 'order_list_tile.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // --- PAGINATION VARIABLES ---
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 50;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;

  List<PosOrder> _orders = [];
  List<PosOrder> _filteredOrders = [];
  bool _isLoading = true;
  bool _isClosingShift = false;

  // --- RANGE STATE ---
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _endDate = DateTime.now();
  int _activeRangeDays = 0; // 0: Today, 30: 30 Days, 365: 1 Year, -1: Custom

  double _todayRevenue = 0;
  double _rangeRevenue = 0;

  List<dynamic> _chartData = [];
  List<MapEntry<String, int>> _topSellers = [];
  List<String> _recentDays = [];
  Map<String, double> _revenueByBarista = {};

  late RealtimeChannel _orderSubscription;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
    _fetchInitialData();
    _setupOrderRealtime();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchMoreOrders();
      }
    });
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
        _fetchAnalytics();
        _fetchInitialData();
      },
    )
        .subscribe();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Supabase.instance.client.removeChannel(_orderSubscription);
    super.dispose();
  }

  Future<void> _fetchAnalytics() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    final cafeId = auth.cafeId;
    if (cafeId == null) return;

    final data = await SupabaseHelper.instance.getDashboardAnalytics(
      cafeId: cafeId,
      start: _startDate,
      end: _endDate,
      cashierName: currentUser?.role == 'Manager' ? null : currentUser?.name,
    );

    final dailyMap = Map<String, dynamic>.from(data['dailyRevenue']);
    final topSellersMap = Map<String, dynamic>.from(data['topSellers']);
    final baristaMap = Map<String, dynamic>.from(data['baristaRevenue']);

    String todayKey = DateTime.now().toIso8601String().substring(0, 10);
    double calculatedTodayRevenue = (dailyMap[todayKey] ?? 0).toDouble();

    List<dynamic> newChartData = [];
    List<String> newRecentDays = [];
    int index = 0;

    DateTime currentDate = _startDate;
    DateTime endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    // Determine label interval to prevent "black ink bar" overlap
    int totalDays = endOfDay.difference(_startDate).inDays + 1;
    int labelInterval = 1;
    if (totalDays > 300) labelInterval = 45;
    else if (totalDays > 31) labelInterval = 7;
    else if (totalDays > 7) labelInterval = 2;

    while (currentDate.isBefore(endOfDay)) {
      String dateKey = currentDate.toIso8601String().substring(0, 10);

      if (index % labelInterval == 0) {
        newRecentDays.add(DateFormat('dd/MM').format(currentDate));
      } else {
        newRecentDays.add("");
      }

      num rawDaily = dailyMap[dateKey] ?? 0;
      newChartData.add({'x': index, 'y': rawDaily.toDouble()});

      currentDate = currentDate.add(const Duration(days: 1));
      index++;
    }

    if (mounted) {
      setState(() {
        _todayRevenue = calculatedTodayRevenue;
        _rangeRevenue = (data['rangeRevenue'] as num).toDouble();
        _topSellers = topSellersMap.entries.map((e) => MapEntry(e.key, (e.value as num).toInt())).toList();
        _revenueByBarista = baristaMap.map((k, v) => MapEntry(k, (v as num).toDouble()));
        _chartData = newChartData;
        _recentDays = newRecentDays;
      });
    }
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _hasMoreData = true; });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    final cafeId = auth.cafeId;

    if (cafeId == null) { setState(() => _isLoading = false); return; }

    List<PosOrder> orders = await SupabaseHelper.instance.getOrdersPaginated(
        cafeId, _startDate, _endDate, _pageSize, 0);

    if (currentUser?.role != 'Manager') {
      orders = orders.where((o) => o.cashierName == currentUser?.name).toList();
    }

    if (mounted) {
      setState(() {
        _orders = orders;
        _filteredOrders = orders;
        _hasMoreData = orders.length == _pageSize;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMoreOrders() async {
    if (_isFetchingMore || !_hasMoreData) return;
    setState(() => _isFetchingMore = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    final cafeId = auth.cafeId;

    List<PosOrder> nextOrders = await SupabaseHelper.instance.getOrdersPaginated(
        cafeId!, _startDate, _endDate, _pageSize, _orders.length);

    if (currentUser?.role != 'Manager') {
      nextOrders = nextOrders.where((o) => o.cashierName == currentUser?.name).toList();
    }

    if (mounted) {
      setState(() {
        _orders.addAll(nextOrders);
        _filteredOrders = _orders;
        _hasMoreData = nextOrders.length == _pageSize;
        _isFetchingMore = false;
      });
    }
  }

  void _handleCloseShift() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.hasActiveShift) return;
    setState(() => _isClosingShift = true);

    try {
      DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      List<PosOrder> allTodayOrders = await SupabaseHelper.instance.getOrdersByRange(auth.cafeId!, today, DateTime.now());
      List<PosOrder> shiftOrders = allTodayOrders.where((o) => o.cashierName == auth.currentUser?.name).toList();
      final double shiftSales = shiftOrders.where((o) => !o.isVoid).fold(0, (sum, o) => sum + o.finalTotal);

      await auth.endShift(shiftSales);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shift Closed"), backgroundColor: Colors.green));
        auth.logout();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isClosingShift = false);
    }
  }

  void _filterOrders(String query) {
    setState(() {
      _filteredOrders = _orders.where((order) =>
      order.itemsSummary.toLowerCase().contains(query.toLowerCase()) ||
          order.id.toString().contains(query)
      ).toList();
    });
  }

  void _setQuickRange(int days) {
    setState(() {
      _activeRangeDays = days;
      _endDate = DateTime.now();
      final start = _endDate.subtract(Duration(days: days));
      _startDate = DateTime(start.year, start.month, start.day);
    });
    _fetchAnalytics();
    _fetchInitialData();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate)
    );
    if (picked != null) {
      setState(() {
        _activeRangeDays = -1;
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchAnalytics();
      _fetchInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)));

    final isManager = Provider.of<AuthProvider>(context).currentUser?.role == 'Manager';
    final lang = Provider.of<LanguageProvider>(context);
    final double padding = MediaQuery.of(context).size.width < 600 ? 16.0 : 32.0;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          floating: true, pinned: true, expandedHeight: 60,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent,
          title: Text(isManager ? lang.t('order_history') ?? 'Order History' : lang.t('orders') ?? 'Orders', style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
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
                  label: Text(lang.t('close_shift') ?? 'Close Shift', style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                ),
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isManager) ...[
                  FilterChip(
                    label: const Text("Today"),
                    selected: _activeRangeDays == 0,
                    showCheckmark: false,
                    selectedColor: const Color(0xFF006E3B).withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: _activeRangeDays == 0 ? const Color(0xFF006E3B) : Colors.black,
                      fontWeight: _activeRangeDays == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => _setQuickRange(0),
                  ),
                  FilterChip(
                    label: const Text("30 Days"),
                    selected: _activeRangeDays == 30,
                    showCheckmark: false,
                    selectedColor: const Color(0xFF006E3B).withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: _activeRangeDays == 30 ? const Color(0xFF006E3B) : Colors.black,
                      fontWeight: _activeRangeDays == 30 ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => _setQuickRange(30),
                  ),
                  FilterChip(
                    label: const Text("1 Year"),
                    selected: _activeRangeDays == 365,
                    showCheckmark: false,
                    selectedColor: const Color(0xFF006E3B).withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: _activeRangeDays == 365 ? const Color(0xFF006E3B) : Colors.black,
                      fontWeight: _activeRangeDays == 365 ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => _setQuickRange(365),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(Icons.calendar_month, size: 18, color: Color(0xFF006E3B)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _activeRangeDays == -1 ? const Color(0xFF006E3B) : Colors.grey.shade300),
                    ),
                    label: Text(
                      "${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}",
                      style: TextStyle(color: _activeRangeDays == -1 ? const Color(0xFF006E3B) : Colors.black, fontWeight: _activeRangeDays == -1 ? FontWeight.bold : FontWeight.normal),
                    ),
                  ),
                  IconButton(onPressed: () => Share.share("Report: Total DH ${_rangeRevenue}"), icon: const Icon(Icons.share, color: Color(0xFF006E3B))),
                ],
              ],
            ),
          ),
        ),

        if (isManager) SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                SummaryCardsRow(todayRevenue: _todayRevenue, rangeRevenue: _rangeRevenue, orderCount: _orders.length, lang: lang),
                const SizedBox(height: 32),
                AnalyticsDashboard(chartData: _chartData, recentDays: _recentDays, topSellers: _topSellers, revenueByBarista: _revenueByBarista),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          sliver: SliverToBoxAdapter(
            child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16, runSpacing: 16,
                children: [
                  Text(lang.t('order_history') ?? 'Order History', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Container(
                      constraints: const BoxConstraints(maxWidth: 300), height: 45,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: const Color(0xFFEEDDDD))),
                      child: TextField(
                          onChanged: _filterOrders,
                          decoration: InputDecoration(hintText: lang.t('search_hint') ?? 'Search...', prefixIcon: const Icon(Icons.search, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 10))
                      )
                  ),
                ]
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        _filteredOrders.isEmpty
            ? const SliverFillRemaining(child: Center(child: Text('No orders found')))
            : SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                    (context, index) => OrderListTile(order: _filteredOrders[index], isManager: isManager, onRefreshRequested: _fetchInitialData),
                childCount: _filteredOrders.length
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 80),
            child: Center(
              child: _isFetchingMore
                  ? const CircularProgressIndicator(color: Color(0xFF006E3B))
                  : !_hasMoreData && _orders.isNotEmpty ? const Text("End of history", style: TextStyle(color: Colors.grey)) : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}