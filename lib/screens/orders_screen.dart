import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database_helper.dart';
import '../models/app_models.dart';
import 'dart:math' as math;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<PosOrder> _orders = [];
  bool _isLoading = true;

  // Analytics Data
  double _todayRevenue = 0;
  double _allTimeRevenue = 0;
  List<BarChartGroupData> _chartData = [];
  List<MapEntry<String, int>> _topSellers = [];
  List<String> _recentDays = [];

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateData();
  }

  Future<void> _fetchAndCalculateData() async {
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

    for (var order in orders) {
      allTimeTotal += order.total;
      final orderDate = order.date.substring(0, 10);
      
      if (orderDate == todayStr) {
        todayTotal += order.total;
      }

      // Group for Chart (Daily)
      dailyRevenue[orderDate] = (dailyRevenue[orderDate] ?? 0) + order.total;

      // Parse Items Summary
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

    // 4. Get Top 3 Sellers
    final sortedSellers = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _orders = orders;
      _todayRevenue = todayTotal;
      _allTimeRevenue = allTimeTotal;
      _chartData = barGroups;
      _recentDays = days;
      _topSellers = sortedSellers.take(3).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)));
    }

    final isManager = currentUser?.role == 'Manager';
    final String dashboardTitle = isManager 
        ? 'Store Analytics' 
        : 'My Daily Performance';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dashboardTitle,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 24),

          // 1. Revenue Cards
          Row(
            children: [
              _buildSummaryCard('Today\'s Revenue', '\$${_todayRevenue.toStringAsFixed(2)}', Icons.today, const Color(0xFF006E3B)),
              const SizedBox(width: 20),
              // Only show All-Time Revenue for Managers
              if (isManager)
                _buildSummaryCard('All-Time Revenue', '\$${_allTimeRevenue.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.blueGrey)
              else
                // For Baristas, show their total sales for the selected period (all their orders)
                _buildSummaryCard('My Total Sales', '\$${_allTimeRevenue.toStringAsFixed(2)}', Icons.person_outline, Colors.blueGrey),
            ],
          ),
          const SizedBox(height: 32),

          // 2. Chart & Top Sellers Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue Chart
              Expanded(
                flex: 2,
                child: Container(
                  height: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEDDDD)),
                  ),
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
                                    return Text(_recentDays[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
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
              // Top Sellers
              Expanded(
                child: Container(
                  height: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEDDDD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top Sellers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      if (_topSellers.isEmpty)
                        const Expanded(child: Center(child: Text('No data')))
                      else
                        ..._topSellers.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFF0F7F4), borderRadius: BorderRadius.circular(20)),
                                child: Text('${e.value} sold', style: const TextStyle(color: Color(0xFF006E3B), fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),
          const Text('Order History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // 3. The Order List
          if (_orders.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('No orders yet'),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFEEDDDD)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF0F7F4),
                      child: Text('#${order.id}', style: const TextStyle(fontSize: 10, color: Color(0xFF006E3B), fontWeight: FontWeight.bold)),
                    ),
                    title: Text(order.itemsSummary, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(order.date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    trailing: Text('\$${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF006E3B))),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEDDDD)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
