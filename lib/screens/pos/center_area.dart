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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile, lang),

          SizedBox(height: isMobile ? 16 : 32),

          // UPGRADED: Custom Animated Category Pills
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: dynamicCategories.length,
              itemBuilder: (context, index) {
                final category = dynamicCategories[index];
                final isSelected = selectedCategory == category;
                final displayLabel = lang.t(category.toLowerCase()) ?? category;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                      _filterProducts();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsetsDirectional.only(end: 12.0),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF006E3B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                      boxShadow: isSelected
                          ? [BoxShadow(color: const Color(0xFF006E3B).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Text(
                        displayLabel,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        )
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: isMobile ? 16 : 24),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)))
                : filteredProducts.isEmpty
                ? Center(child: Text("No products found for this café", style: TextStyle(color: Colors.grey.shade500)))
                : GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: isMobile ? 200 : 280,
                mainAxisExtent: isMobile ? 260 : 300,
                crossAxisSpacing: isMobile ? 16 : 24,
                mainAxisSpacing: isMobile ? 16 : 24,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(context, filteredProducts[index], isMobile);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile, LanguageProvider lang) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tactile POS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1.0)),
              Row(
                children: [
                  IconButton(onPressed: () => _loadMenuFromCloud(), icon: const Icon(Icons.sync, color: Colors.black87)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(lang, double.infinity),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tactile POS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1.0)),
              Text(lang.currentLocale.languageCode == 'ar'
                  ? 'المنصة الرئيسية • الوردية: الصباحية'
                  : 'Main Counter • Shift: Morning Crew',
                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
          Flexible(
            child: _buildSearchBar(lang, 340),
          ),
          Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.black87)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.black87)),
              Container(
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: IconButton(onPressed: () => _loadMenuFromCloud(), icon: const Icon(Icons.sync, color: Colors.black87))
              ),
            ],
          ),
        ],
      );
    }
  }

  // UPGRADED: Soft-UI Search Bar
  Widget _buildSearchBar(LanguageProvider lang, double width) {
    return Container(
      width: width,
      height: 52,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade100)
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            _filterProducts();
          });
        },
        decoration: InputDecoration(
          hintText: lang.t('search_hint') ?? 'Search menu...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.search, color: Colors.black45),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // UPGRADED: Edge-to-Edge Premium Product Card
  Widget _buildProductCard(BuildContext context, Product product, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8)),
          ],
          border: Border.all(color: Colors.grey.shade100)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: Image hugs the corners of the card now (No padding)
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: product.image.startsWith('http')
                    ? Image.network(
                  product.image,
                  height: isMobile ? 120 : 150,
                  width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(height: isMobile ? 120 : 150, color: Colors.grey[100], child: const Icon(Icons.fastfood, color: Colors.grey)),
                )
                    : Image.file(
                  File(product.image),
                  height: isMobile ? 120 : 150, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(height: isMobile ? 120 : 150, color: Colors.grey[100], child: const Icon(Icons.broken_image)),
                ),
              ),
              if (product.tag != null)
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: product.tagColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                    child: Text(product.tag!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ),
                ),
            ],
          ),

          // Wrapped text area in padding
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile ? 15 : 17, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(product.description, style: TextStyle(color: Colors.grey[500], fontSize: isMobile ? 12 : 13, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DH ${product.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: isMobile ? 15 : 18, color: const Color(0xFF006E3B))),
                      Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFF006E3B),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: const Color(0xFF006E3B).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                        ),
                        child: IconButton(
                          iconSize: isMobile ? 20 : 22,
                          padding: EdgeInsets.all(isMobile ? 6 : 8),
                          constraints: const BoxConstraints(),
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
          ),
        ],
      ),
    );
  }
}