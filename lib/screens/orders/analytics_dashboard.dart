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
    // LayoutBuilder checks the available width on the device
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint: 800px (Standard dividing line between phone and tablet)
        final isTablet = constraints.maxWidth > 800;

        if (isTablet) {
          // --- TABLET VIEW (Your original side-by-side layout) ---
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
          // --- PHONE VIEW (Stacked layout) ---
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
    // Convert dynamic map data back to FL Chart format
    List<BarChartGroupData> flChartGroups = chartData.map((data) {
      return BarChartGroupData(
          x: data['x'] as int,
          barRods: [BarChartRodData(toY: data['y'] as double, color: const Color(0xFF006E3B), width: 16)]
      );
    }).toList();

    return Container(
        height: 350,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Range Performance', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Expanded(
                  child: BarChart(
                      BarChartData(
                          barGroups: flChartGroups,
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, m) => Text(recentDays[v.toInt()], style: const TextStyle(fontSize: 10))
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
        height: 165,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Top Sellers', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...topSellers.map((e) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key),
                    Text('${e.value} sold', style: const TextStyle(color: Color(0xFF006E3B), fontWeight: FontWeight.bold))
                  ]
              )),
            ]
        )
    );
  }

  Widget _buildTeamCard() {
    return Container(
        height: 165,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEDDDD))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Team Performance', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                  child: ListView(
                      children: revenueByBarista.entries.map((e) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key),
                            Text('DH ${e.value.toStringAsFixed(2)}')
                          ]
                      )).toList()
                  )
              ),
            ]
        )
    );
  }
}