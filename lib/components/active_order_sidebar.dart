import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../database_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'center_area.dart';

class POSActiveOrderSidebar extends StatefulWidget {
  const POSActiveOrderSidebar({super.key});

  @override
  State<POSActiveOrderSidebar> createState() => _POSActiveOrderSidebarState();
}

class _POSActiveOrderSidebarState extends State<POSActiveOrderSidebar> {
  @override
  void initState() {
    super.initState();
    _loadTaxRate();
  }

  Future<void> _loadTaxRate() async {
    final rate = await DatabaseHelper.instance.getTaxRate();
    if (mounted) {
      setState(() {
        cartState.currentTaxRate = rate;
      });
    }
  }

  String _getCurrency(LanguageProvider lang) {
    return lang.currentLocale.languageCode == 'ar' ? 'د.م.' : 'DH';
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return ListenableBuilder(
      listenable: cartState,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            bool isTablet = constraints.maxWidth >= 800;

            if (isTablet) {
              return Row(
                children: [
                  const Expanded(child: POSCenterArea()),
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEEDDDD)),
                  _buildCartPanel(context),
                ],
              );
            } else {
              final currency = _getCurrency(lang);
              return Scaffold(
                body: const POSCenterArea(),
                floatingActionButton: cartState.items.isEmpty
                    ? const SizedBox.shrink()
                    : FloatingActionButton.extended(
                  onPressed: () => _showMobileCart(context),
                  backgroundColor: const Color(0xFF006E3B),
                  label: Text(
                    '${lang.t('view_cart')} (${cartState.items.length}) - $currency ${cartState.finalTotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildCartPanel(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final lang = Provider.of<LanguageProvider>(context);
    final currency = _getCurrency(lang);

    return Container(
      width: 380,
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).cardColor
          : const Color(0xFFFDECE9),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.t('active_order'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('${lang.t('cashier')}: ${currentUser?.name ?? "Guest"}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(128), borderRadius: BorderRadius.circular(12)),
                  child: const Text('#4921', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                ),
              ],
            ),
          ),

          Expanded(
            child: cartState.items.isEmpty
                ? Center(child: Text(lang.t('cart_empty')))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: cartState.items.length,
              itemBuilder: (context, index) => _buildCartItem(cartState.items[index], currency),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              border: const Border(top: BorderSide(color: Color(0xFFEEDDDD))),
            ),
            child: Column(
              children: [
                _buildSummaryRow(lang.t('subtotal'), '$currency ${cartState.subtotal.toStringAsFixed(2)}'),
                _buildSummaryRow('${lang.t('tax')} (${cartState.currentTaxRate}%)', '$currency ${cartState.taxAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.t('total_due'), style: const TextStyle(fontSize: 16)),
                    Text('$currency ${cartState.finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: cartState.items.isEmpty ? null : () => _showCheckoutConfirmation(context, currentUser?.name ?? 'Guest'),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: Text(lang.t('checkout'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, String currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEDDDD).withAlpha(128)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                // FIX: Swap order so [+] is first (Left for EN/FR) and [-] is last (Right for EN/FR)
                Row(
                  children: [
                    _buildQtyButton(Icons.add, () => cartState.addItem(item.product)),
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildQtyButton(Icons.remove, () => cartState.updateQuantity(item, -1)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '$currency ${(item.product.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006E3B)),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }

  void _showCheckoutConfirmation(BuildContext context, String cashierName) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final currency = _getCurrency(lang);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('confirm_order')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...cartState.items.map((item) => _buildReceiptRow(
                '${item.quantity}x ${item.product.name}',
                '$currency ${(item.product.price * item.quantity).toStringAsFixed(2)}')),
            const Divider(),
            _buildReceiptRow(lang.t('total'), '$currency ${cartState.finalTotal.toStringAsFixed(2)}', isBold: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t('cancel'))),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                cartState.clearCart();
              },
              child: Text(lang.t('confirm_payment'))
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value)],
    );
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(heightFactor: 0.9, child: _buildCartPanel(context)),
    );
  }
}