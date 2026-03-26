import 'package:flutter/material.dart';
import '../models/app_models.dart'; // To access cartState and CartItem
import '../database_helper.dart';

class POSActiveOrderSidebar extends StatelessWidget {
  const POSActiveOrderSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Wrap the entire sidebar in a ListenableBuilder
    return ListenableBuilder(
        listenable: cartState,
        builder: (context, child) {
          return Container(
            width: 380,
            color: const Color(0xFFFDECE9),
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
                  // Show this if the cart is empty
                      ? Center(
                    child: Text(
                      'Cart is empty.\nTap a product to start.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                  // Show the list of items if we have them
                      : ListView.builder(
                    itemCount: cartState.items.length,
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildCartItem(item), // Pass the whole CartItem object
                      );
                    },
                  ),
                ),

                // 3. Dynamic Totals & Checkout
                Column(
                  children: [
                    _buildSummaryRow('Subtotal', '\$${cartState.subtotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Tax (8%)', '\$${cartState.tax.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Due', style: TextStyle(fontSize: 16)),
                        Text(
                            '\$${cartState.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Note & Discount Buttons
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
                        // Disable the button if the cart is empty!
                        onPressed: cartState.items.isEmpty ? null : () async {

                          // 1. Create a quick text summary of what they bought (e.g., "2x Latte, 1x Muffin")
                          final summary = cartState.items.map((item) => '${item.quantity}x ${item.product.name}').join(', ');

                          // 2. Build the Receipt object
                          final newOrder = PosOrder(
                            date: DateTime.now().toString().substring(0, 16), // Gives us "YYYY-MM-DD HH:MM"
                            total: cartState.total,
                            itemsSummary: summary,
                            cashierName: currentUser?.name ?? 'Guest Cashier', // Use actual logged in user!
                          );

                          // 3. Save it to the SQLite hard drive!
                          await DatabaseHelper.instance.insertOrder(newOrder);

                          // 4. Ring them up!
                          cartState.clearCart();

                          // 5. Tell the barista it worked
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order saved successfully!'),
                                backgroundColor: Color(0xFF006E3B),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
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

  // Helper updated to take a CartItem and calculate dynamic line totals
  Widget _buildCartItem(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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

                // Quantity Controls (- 1 +) wired to the cartState
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

  // Added onTap parameter so the buttons actually work
  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECE9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: Colors.black87),
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
        color: const Color(0xFFF3D8D3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
