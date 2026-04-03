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

  Widget _buildCard(String title, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24), // Slightly more breathing room
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          // UPGRADED: Soft floating shadow instead of a hard grey border
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 8))
          ]
      ),
      child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5), overflow: TextOverflow.ellipsis)
                  ]
              ),
            )
          ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avgSale = orderCount == 0 ? 0.0 : (rangeRevenue / orderCount);

    return LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final cardWidth = isMobile ? double.infinity : (constraints.maxWidth - 40) / 3;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildCard(lang.t('today_revenue') ?? 'Today Rev', 'DH ${todayRevenue.toStringAsFixed(2)}', Icons.today, const Color(0xFF006E3B), cardWidth),
              _buildCard(lang.t('range_total') ?? 'Range Total', 'DH ${rangeRevenue.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.blueGrey, cardWidth),
              _buildCard(lang.t('avg_sale') ?? 'Avg Sale', 'DH ${avgSale.toStringAsFixed(2)}', Icons.trending_up, Colors.indigo, cardWidth),
            ],
          );
        }
    );
  }
}