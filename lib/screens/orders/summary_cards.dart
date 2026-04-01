import 'package:flutter/material.dart';
import '../../providers/language_provider.dart';

class SummaryCardsRow extends StatelessWidget {
  final double todayRevenue;
  final double rangeRevenue;
  final int orderCount;
  final LanguageProvider lang;

  const SummaryCardsRow({
    super.key,
    required this.todayRevenue,
    required this.rangeRevenue,
    required this.orderCount,
    required this.lang,
  });

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Expanded(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEDDDD))
          ),
          child: Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 16),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.grey)),
                      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                    ]
                )
              ]
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final avgSale = orderCount == 0 ? 0.0 : (rangeRevenue / orderCount);

    return Row(
      children: [
        _buildCard(lang.t('today_revenue'), 'DH ${todayRevenue.toStringAsFixed(2)}', Icons.today, const Color(0xFF006E3B)),
        const SizedBox(width: 20),
        _buildCard(lang.t('range_total'), 'DH ${rangeRevenue.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.blueGrey),
        const SizedBox(width: 20),
        _buildCard(lang.t('avg_sale'), 'DH ${avgSale.toStringAsFixed(2)}', Icons.trending_up, Colors.indigo),
      ],
    );
  }
}