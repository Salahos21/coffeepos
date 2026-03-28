import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart'; // To access cartState and CartItem
import '../database_helper.dart';
import '../providers/auth_provider.dart';

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
    setState(() {
      cartState.currentTaxRate = rate;
    });
  }

  // --- NEW: CHECKOUT CONFIRMATION DIALOG ---
  void _showCheckoutConfirmation(BuildContext context, String cashierName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), // Paper look
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('CONFIRM ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.5)),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              
              // Receipt Items
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006E3B),
              minimumSize: const Size(200, 56),
            ),
            onPressed: () async {
              // 1. Create Summary
              final summary = cartState.items.map((item) => '${item.quantity}x ${item.product.name}').join(', ');

              // 2. Save Order
              final newOrder = PosOrder(
                date: DateTime.now().toString().substring(0, 16),
                subtotal: cartState.subtotal,
                taxAmount: cartState.taxAmount,
                finalTotal: cartState.finalTotal,
                itemsSummary: summary,
                cashierName: cashierName,
              );

              await DatabaseHelper.instance.insertOrder(newOrder);
              
              // 3. Reset
              cartState.clearCart();
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
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
                        const Text(
                          'Active Order',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        Text(
                          'Cashier: ${currentUser?.name ?? "Guest"}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '#4921',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 2. Dynamic Order Items List
                Expanded(
                  child: cartState.items.isEmpty
                      ? Center(
                    child: Text(
                      'Cart is empty.\nTap a product to start.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                      : ListView.builder(
                    itemCount: cartState.items.length,
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildCartItem(item),
                      );
                    },
                  ),
                ),

                // 3. Dynamic Totals & Checkout
                Column(
                  children: [
                    _buildSummaryRow('Subtotal', '\$${cartState.subtotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Tax (${cartState.currentTaxRate}%)', '\$${cartState.taxAmount.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Due', style: TextStyle(fontSize: 16)),
                        Text(
                            '\$${cartState.finalTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: _buildSecondaryButton(Icons.note_add_outlined, 'Note')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSecondaryButton(Icons.local_offer_outlined, 'Discount')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- THE CHECKOUT BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: cartState.items.isEmpty ? null : () => _showCheckoutConfirmation(context, currentUser?.name ?? 'Guest Cashier'),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006E3B),
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(item.modifiers, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildQtyButton(Icons.remove, () => cartState.updateQuantity(item, -1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    _buildQtyButton(Icons.add, () => cartState.updateQuantity(item, 1)),
                  ],
                ),
              ],
            ),
          ),
          Text(
              '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white10 
              : const Color(0xFFFDECE9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        Text(value, style: TextStyle(color: Colors.grey[800], fontSize: 14)),
      ],
    );
  }

  Widget _buildSecondaryButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white10 
            : const Color(0xFFF3D8D3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
