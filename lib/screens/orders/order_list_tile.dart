import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/supabase_helper.dart';

class OrderListTile extends StatelessWidget {
  final PosOrder order;
  final bool isManager;
  final VoidCallback onRefreshRequested; // Tells the parent screen to refresh if an order is voided

  const OrderListTile({
    super.key,
    required this.order,
    required this.isManager,
    required this.onRefreshRequested,
  });

  Future<void> _confirmVoid(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
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

    if (confirmed == true && auth.cafeId != null) {
      await SupabaseHelper.instance.voidOrder(order.id!, auth.cafeId!);
      onRefreshRequested(); // Call the callback to refresh the main screen
    }
  }

  void _showReceiptModal(BuildContext context) {
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
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Order #${order.id}'), Text(order.date.substring(0,16))]),
                      const Divider(),
                      ...order.itemsSummary.split(', ').map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Align(alignment: Alignment.centerLeft, child: Text(item)))),
                      const Divider(thickness: 2),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text('DH ${order.finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))])
                    ]
                )
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))]
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        color: order.isVoid ? Colors.red.shade50 : null,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEEDDDD))
        ),
        child: ListTile(
            onTap: () => _showReceiptModal(context),
            leading: CircleAvatar(child: Text('#${order.id}', style: const TextStyle(fontSize: 10))),
            title: Text(
                order.itemsSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(decoration: order.isVoid ? TextDecoration.lineThrough : null)
            ),
            subtitle: Text("${order.date} • ${order.cashierName}"),
            trailing: (!order.isVoid && isManager)
                ? IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _confirmVoid(context))
                : const Icon(Icons.chevron_right)
        )
    );
  }
}