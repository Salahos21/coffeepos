import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/supabase_helper.dart';

class POSCenterArea extends StatefulWidget {
  const POSCenterArea({super.key});

  @override
  State<POSCenterArea> createState() => _POSCenterAreaState();
}

class _POSCenterAreaState extends State<POSCenterArea> {
  String selectedCategory = 'All';
  String searchQuery = '';

  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;
  List<String> dynamicCategories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadMenuFromCloud();
  }

  Future<void> _loadMenuFromCloud() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final String? cafeId = auth.cafeId;

    if (cafeId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final dbProducts = await SupabaseHelper.instance.getProducts(cafeId);
      final dbCategories = await SupabaseHelper.instance.getCategories(cafeId);

      final categoryNames = ['All'] + dbCategories.map((c) => c.name).toList();

      if (mounted) {
        setState(() {
          products = dbProducts;
          dynamicCategories = categoryNames;
          if (!dynamicCategories.contains(selectedCategory)) {
            selectedCategory = 'All';
          }
          _filterProducts();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("SaaS Load Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterProducts() {
    setState(() {
      filteredProducts = products.where((product) {
        final matchesCategory = selectedCategory == 'All' || product.categoryName == selectedCategory;
        final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Container(
      color: const Color(0xFFFCF8F8),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tactile POS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  Text(lang.currentLocale.languageCode == 'ar'
                      ? 'المنصة الرئيسية • الوردية: الصباحية'
                      : 'Main Counter • Shift: Morning Crew',
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              Flexible(
                child: Container(
                  width: 300,
                  height: 48,
                  decoration: BoxDecoration(color: const Color(0xFFFDECE9), borderRadius: BorderRadius.circular(24)),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        _filterProducts();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: lang.t('search_hint'),
                      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.black87)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.black87)),
                  IconButton(
                      onPressed: () => _loadMenuFromCloud(),
                      icon: const Icon(Icons.sync, color: Colors.black87)
                  ),
                  if (MediaQuery.of(context).size.width < 950)
                    IconButton(
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                      icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF006E3B), size: 28),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dynamicCategories.length,
              itemBuilder: (context, index) {
                final category = dynamicCategories[index];
                final isSelected = selectedCategory == category;
                final displayLabel = lang.t(category.toLowerCase());

                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12.0),
                  child: ChoiceChip(
                    label: Text(displayLabel, style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    )),
                    selected: isSelected,
                    selectedColor: const Color(0xFF006E3B),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                    side: BorderSide(color: isSelected ? const Color(0xFF006E3B) : Colors.grey.shade300),
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                        _filterProducts();
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)))
                : filteredProducts.isEmpty
                ? const Center(child: Text("No products found for this café"))
                : GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisExtent: 290,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(context, filteredProducts[index], lang);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, LanguageProvider lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product.image.startsWith('http')
                      ? Image.network(
                    product.image,
                    height: 120, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(height: 120, color: Colors.grey[200], child: const Icon(Icons.fastfood, color: Colors.grey)),
                  )
                      : Image.file(
                    File(product.image),
                    height: 120, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(height: 120, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                  ),
                ),
                if (product.tag != null)
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: product.tagColor, borderRadius: BorderRadius.circular(8)),
                      child: Text(product.tag!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(product.description, style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('DH ${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF006E3B), shape: BoxShape.circle),
                  child: IconButton(
                    iconSize: 20, padding: const EdgeInsets.all(8), constraints: const BoxConstraints(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      context.read<CartState>().addItem(product);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}