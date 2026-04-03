import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../services/supabase_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTaxRate());
  }

  Future<void> _loadTaxRate() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.cafeId != null) {
      final rate = await SupabaseHelper.instance.getTaxRate(auth.cafeId!);
      if (mounted) {
        cartState.currentTaxRate = rate;
      }
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
      child: const POSCenterArea(),
      builder: (context, centerAreaChild) {
        return LayoutBuilder(
          builder: (context, constraints) {
            bool isTablet = constraints.maxWidth >= 600;

            if (isTablet) {
              return Row(
                children: [
                  Expanded(child: centerAreaChild!),

                  if (cartState.items.isNotEmpty) ...[
                    // UPGRADED: Removed hard divider, sidebar handles its own shadow now
                    _buildCartPanel(context, isMobile: false),
                  ],
                ],
              );
            } else {
              final currency = _getCurrency(lang);
              return Scaffold(
                body: centerAreaChild!,
                floatingActionButton: cartState.items.isEmpty
                    ? const SizedBox.shrink()
                    : FloatingActionButton.extended(
                  onPressed: () => _showMobileCart(context),
                  backgroundColor: const Color(0xFF006E3B),
                  elevation: 4, // Softer shadow
                  label: Text(
                    '${lang.t('view_cart') ?? 'View Cart'} (${cartState.items.length}) - $currency ${cartState.finalTotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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

  Widget _buildCartPanel(BuildContext context, {bool isMobile = false}) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final lang = Provider.of<LanguageProvider>(context);
    final currency = _getCurrency(lang);

    return Container(
      width: isMobile ? double.infinity : 380,
      decoration: BoxDecoration(
          color: Colors.white,
          // UPGRADED: Soft shadow on the left side for tablet view
          boxShadow: isMobile ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(-4, 0))
          ]
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.t('active_order') ?? 'Active Order', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('${lang.t('cashier') ?? 'Cashier'}: ${currentUser?.name ?? "Guest"}', style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFDECE9),
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Text(
                      '#${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF006E3B))
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              physics: const BouncingScrollPhysics(),
              itemCount: cartState.items.length,
              itemBuilder: (context, index) => _buildCartItem(cartState.items[index], currency),
            ),
          ),

          // UPGRADED: Checkout Bottom Section with floating shadow
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -10))
              ],
            ),
            child: Column(
              children: [
                _buildSummaryRow(lang.t('subtotal') ?? 'Subtotal', '$currency ${cartState.subtotal.toStringAsFixed(2)}'),
                _buildSummaryRow('${lang.t('tax') ?? 'Tax'} (${cartState.currentTaxRate}%)', '$currency ${cartState.taxAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.t('total_due') ?? 'Total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('$currency ${cartState.finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60, // Slightly taller, premium button
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006E3B),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _showCheckoutConfirmation(context, currentUser?.name ?? 'Guest'),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
                    label: Text(lang.t('checkout') ?? 'Checkout', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UPGRADED: Soft UI Cart Item
  Widget _buildCartItem(CartItem item, String currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQtyButton(Icons.add, () => cartState.addItem(item.product)),
                    Container(
                      constraints: const BoxConstraints(minWidth: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    _buildQtyButton(Icons.remove, () => cartState.updateQuantity(item, -1)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$currency ${(item.product.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF006E3B)),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }

  bool _isProcessingCheckout = false;

  void _showCheckoutConfirmation(BuildContext context, String cashierName) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currency = _getCurrency(lang);

    showDialog(
      context: context,
      barrierDismissible: !_isProcessingCheckout,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(lang.t('confirm_order') ?? 'Confirm Order', style: const TextStyle(fontWeight: FontWeight.w800)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...cartState.items.map((item) => _buildReceiptRow(
                        '${item.quantity}x ${item.product.name}',
                        '$currency ${(item.product.price * item.quantity).toStringAsFixed(2)}')),
                    const Divider(height: 24),
                    _buildReceiptRow(lang.t('total') ?? 'Total', '$currency ${cartState.finalTotal.toStringAsFixed(2)}', isBold: true),
                    if (_isProcessingCheckout)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: CircularProgressIndicator(color: Color(0xFF006E3B)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: _isProcessingCheckout ? null : () => Navigator.pop(context),
                    child: Text(lang.t('cancel') ?? 'Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006E3B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isProcessingCheckout ? null : () async {
                    setDialogState(() => _isProcessingCheckout = true);

                    try {
                      final newOrder = PosOrder(
                        date: DateTime.now().toIso8601String(),
                        subtotal: cartState.subtotal,
                        taxAmount: cartState.taxAmount,
                        finalTotal: cartState.finalTotal,
                        itemsSummary: cartState.items.map((i) => '${i.quantity}x ${i.product.name}').join(', '),
                        cashierName: cashierName,
                      );

                      await SupabaseHelper.instance.insertOrder(newOrder, auth.cafeId!);
                      cartState.clearCart();
                      if (context.mounted) Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Order Successful"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                      );
                    } finally {
                      setDialogState(() => _isProcessingCheckout = false);
                    }
                  },
                  child: Text(lang.t('confirm_payment') ?? 'Confirm', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          }
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w800 : FontWeight.w500, color: isBold ? Colors.black : Colors.black87))),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600))
        ],
      ),
    );
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => ListenableBuilder(
          listenable: cartState,
          builder: (context, child) {
            return FractionallySizedBox(
              heightFactor: 0.9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), // Smoother radius
                child: _buildCartPanel(context, isMobile: true),
              ),
            );
          }
      ),
    );
  }
}