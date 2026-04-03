import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboard extends StatelessWidget {
  final List<dynamic> chartData;
  final List<String> recentDays;
  final List<MapEntry<String, int>> topSellers;
  final Map<String, double> revenueByBarista;

  const AnalyticsDashboard({
    super.key,
    required this.chartData,
    required this.recentDays,
    required this.topSellers,
    required this.revenueByBarista,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 800;

        if (isTablet) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildBarChart()),
              const SizedBox(width: 20),
              Expanded(
                  child: Column(
                      children: [
                        _buildTopSellersCard(),
                        const SizedBox(height: 20),
                        _buildTeamCard()
                      ]
                  )
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBarChart(),
              const SizedBox(height: 20),
              _buildTopSellersCard(),
              const SizedBox(height: 20),
              _buildTeamCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildBarChart() {
    // FIX: Adjust bar width based on amount of data to prevent "giant bar" effect
    double barWidth = 16.0;
    if (chartData.length < 5) barWidth = 30.0;
    if (chartData.length == 1) barWidth = 60.0;

    List<BarChartGroupData> flChartGroups = chartData.map((data) {
      return BarChartGroupData(
          x: data['x'] as int,
          barRods: [
            BarChartRodData(
                toY: data['y'] as double,
                color: const Color(0xFF006E3B),
                width: barWidth,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)) // Slightly rounded tops look nicer
            )
          ]
      );
    }).toList();

    return Container(
        height: 350,
        padding: const EdgeInsets.all(20), // Reduced slightly for mobile
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Range Performance', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Expanded(
                  child: flChartGroups.isEmpty
                      ? const Center(child: Text("No data for this range", style: TextStyle(color: Colors.grey)))
                      : BarChart(
                      BarChartData(
                          barGroups: flChartGroups,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 100, // Show horizontal grid lines for better readability
                            getDrawingHorizontalLine: (value) {
                              return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
                            },
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, m) {
                                      if (v.toInt() >= 0 && v.toInt() < recentDays.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(recentDays[v.toInt()], style: const TextStyle(fontSize: 10)),
                                        );
                                      }
                                      return const Text('');
                                    }
                                )
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          )
                      )
                  )
              ),
            ]
        )
    );
  }

  Widget _buildTopSellersCard() {
    return Container(
      // Dynamic height based on content
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Top Sellers', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (topSellers.isEmpty) const Text("No sales data yet.", style: TextStyle(color: Colors.grey)),
              ...topSellers.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis)),
                      Text('${e.value} sold', style: const TextStyle(color: Color(0xFF006E3B), fontWeight: FontWeight.bold))
                    ]
                ),
              )),
            ]
        )
    );
  }

  Widget _buildTeamCard() {
    return Container(
        constraints: const BoxConstraints(minHeight: 120, maxHeight: 200), // Max height to allow scrolling if many baristas
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Team Performance', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (revenueByBarista.isEmpty) const Text("No shift data yet.", style: TextStyle(color: Colors.grey)),
              Expanded(
                  child: ListView(
                      children: revenueByBarista.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key),
                              Text('DH ${e.value.toStringAsFixed(2)}')
                            ]
                        ),
                      )).toList()
                  )
              ),
            ]
        )
    );
  }
}