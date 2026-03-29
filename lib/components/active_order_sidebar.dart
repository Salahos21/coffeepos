import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../database_helper.dart';
import '../providers/auth_provider.dart';
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

  void _showCheckoutConfirmation(BuildContext context, String cashierName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('CONFIRM ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.5)),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cartState.items.length,
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity}x ${item.product.name}'),
                          Text('\$${(item.product.price * item.quantity).toStringAsFixed(2)}'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 2),
              _buildReceiptRow('Subtotal', '\$${cartState.subtotal.toStringAsFixed(2)}'),
              _buildReceiptRow('Tax (${cartState.currentTaxRate}%)', '\$${cartState.taxAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _buildReceiptRow('TOTAL', '\$${cartState.finalTotal.toStringAsFixed(2)}', isBold: true, size: 22),
              const SizedBox(height: 30),
              const Text('Please confirm payment from customer', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006E3B)),
            onPressed: () async {
              final summary = cartState.items.map((item) => '${item.quantity}x ${item.product.name}').join(', ');
              final newOrder = PosOrder(
                date: DateTime.now().toString().substring(0, 16),
                subtotal: cartState.subtotal,
                taxAmount: cartState.taxAmount,
                finalTotal: cartState.finalTotal,
                itemsSummary: summary,
                cashierName: cashierName,
              );
              await DatabaseHelper.instance.insertOrder(newOrder);
              cartState.clearCart();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment Successful!'), backgroundColor: Color(0xFF006E3B)),
                );
              }
            },
            child: const Text('CONFIRM PAYMENT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, double size = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: size)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: size)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          return Scaffold(
            body: const POSCenterArea(),
            floatingActionButton: ListenableBuilder(
              listenable: cartState,
              builder: (context, child) {
                if (cartState.items.isEmpty) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  onPressed: () => _showMobileCart(context),
                  backgroundColor: const Color(0xFF006E3B),
                  label: Text(
                    'View Cart (${cartState.items.length}) - \$${cartState.finalTotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                );
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildCartPanel(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return ListenableBuilder(
      listenable: cartState,
      builder: (context, child) {
        return Container(
          width: 380,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Theme.of(context).cardColor 
              : const Color(0xFFFDECE9),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active Order', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Cashier: ${currentUser?.name ?? "Guest"}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                    child: const Text('#4921', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Items
              Expanded(
                child: cartState.items.isEmpty
                    ? const Center(child: Text('Cart is empty.'))
                    : ListView.builder(
                        itemCount: cartState.items.length,
                        itemBuilder: (context, index) => _buildCartItem(cartState.items[index]),
                      ),
              ),
              // Footer
              Column(
                children: [
                  _buildSummaryRow('Subtotal', '\$${cartState.subtotal.toStringAsFixed(2)}'),
                  _buildSummaryRow('Tax (${cartState.currentTaxRate}%)', '\$${cartState.taxAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Due', style: TextStyle(fontSize: 16)),
                      Text('\$${cartState.finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: cartState.items.isEmpty ? null : () => _showCheckoutConfirmation(context, currentUser?.name ?? 'Guest Cashier'),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Expanded(child: _buildCartPanel(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _buildQtyButton(Icons.remove, () => cartState.updateQuantity(item, -1)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('${item.quantity}')),
                    _buildQtyButton(Icons.add, () => cartState.updateQuantity(item, 1)),
                  ],
                ),
              ],
            ),
          ),
          Text('\$${(item.product.price * item.quantity).toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value)],
    );
  }
}
