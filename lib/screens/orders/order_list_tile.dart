import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/supabase_helper.dart';

class OrderListTile extends StatelessWidget {
  final PosOrder order;
  final bool isManager;
  final VoidCallback onRefreshRequested;

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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(lang.t('void_order') ?? 'Void Order', style: const TextStyle(fontWeight: FontWeight.w800)),
            content: Text('${lang.t('void_order') ?? 'Void Order'} #${order.id}?', style: const TextStyle(fontSize: 16)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(lang.t('cancel') ?? 'Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(lang.t('void_order') ?? 'Void Order', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)))
            ]
        )
    );

    if (confirmed == true && auth.cafeId != null) {
      await SupabaseHelper.instance.voidOrder(order.id!, auth.cafeId!);
      onRefreshRequested();
    }
  }

  void _showReceiptModal(BuildContext context) {
    // Safety check for date formatting to prevent crashes if date string is short
    final displayDate = order.date.length >= 16 ? order.date.substring(0, 16) : order.date;

    showDialog(
        context: context,
        builder: (context) {
          // Responsive check inside the dialog
          final isMobile = MediaQuery.of(context).size.width < 600;

          return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // UPGRADED: Softer modal corners
              contentPadding: EdgeInsets.all(isMobile ? 24 : 32), // UPGRADED: More breathing room
              content: SizedBox(
                  width: isMobile ? double.maxFinite : 360,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TACTILE POS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 8),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order #${order.id}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              Text(displayDate, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600))
                            ]
                        ),
                        const SizedBox(height: 8),
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 8),
                        ...order.itemsSummary.split(', ').map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(item, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))
                            )
                        )),
                        const SizedBox(height: 8),
                        Divider(thickness: 2, color: Colors.grey.shade200),
                        const SizedBox(height: 8),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                              Text('DH ${order.finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))
                            ]
                        )
                      ]
                  )
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CLOSE', style: TextStyle(color: Color(0xFF006E3B), fontWeight: FontWeight.w700, letterSpacing: 0.5))
                )
              ]
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          // UPGRADED: Elegant voided state, standard white for normal orders
            color: order.isVoid ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: order.isVoid ? Colors.red.shade100 : Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
            ]
        ),
        child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // UPGRADED: Better touch targets
            onTap: () => _showReceiptModal(context),
            leading: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: order.isVoid ? Colors.white : const Color(0xFFFDECE9),
                    borderRadius: BorderRadius.circular(12) // UPGRADED: Modern Squircle instead of Circle
                ),
                child: Text('#${order.id}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: order.isVoid ? Colors.red : const Color(0xFF006E3B)))
            ),
            title: Text(
                order.itemsSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    decoration: order.isVoid ? TextDecoration.lineThrough : null,
                    color: order.isVoid ? Colors.grey.shade500 : Colors.black87
                )
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text("${order.date.split('T').first} • ${order.cashierName}", style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ),
            trailing: (!order.isVoid && isManager)
                ? IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _confirmVoid(context))
                : const Icon(Icons.chevron_right, color: Colors.black26)
        )
    );
  }
}