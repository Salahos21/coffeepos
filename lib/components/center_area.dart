import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../database_helper.dart';
import 'dart:io';

class POSCenterArea extends StatefulWidget {
  const POSCenterArea({super.key});

  @override
  State<POSCenterArea> createState() => _POSCenterAreaState();
}
class _POSCenterAreaState extends State<POSCenterArea> {
  String selectedCategory = 'All';
  String searchQuery = '';

  // 1. The memory for our database products
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true; // Tells the UI to show a loading spinner
  // NEW: A dynamic list that always starts with 'All'
  List<String> dynamicCategories = ['All'];
  @override
  void initState() {
    super.initState();
    _loadMenuFromDatabase(); // 2. Fetch data as soon as the screen loads
  }

  Future<void> _loadMenuFromDatabase() async {
    // 1. Fetch the products
    final dbProducts = await DatabaseHelper.instance.getAllProducts();

    // 2. NEW: Fetch the categories!
    final dbCategories = await DatabaseHelper.instance.getAllCategories();

    // 3. Combine 'All' with the names of the custom categories
    final categoryNames = ['All'] + dbCategories.map((c) => c.name).toList();

    setState(() {
      products = dbProducts;
      dynamicCategories = categoryNames; // Save our new list!

      // Safety check: if they deleted the category we were currently looking at, reset to 'All'
      if (!dynamicCategories.contains(selectedCategory)) {
        selectedCategory = 'All';
      }

      _filterProducts();
      isLoading = false;
    });
  }
  // This method filters the menu based on the search bar and selected category chip!
  void _filterProducts() {
    setState(() {
      filteredProducts = products.where((product) {
        // 1. Check if the product matches the selected category (or if "All" is selected)
        final matchesCategory = selectedCategory == 'All' || product.category == selectedCategory;

        // 2. Check if the product matches whatever is typed in the search bar
        final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());

        // Only keep the product if it matches BOTH conditions
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFCF8F8),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tactile POS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  Text('Main Counter • Shift: Morning Crew', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
                      _filterProducts(); // Make sure this is here so it filters as you type!
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search menu...',
                    hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.black54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              ),
              Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.black87)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.black87)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.sync, color: Colors.black87)),

                  // NEW: Cart button that only shows on narrow screens
                  if (MediaQuery.of(context).size.width < 950)
                    IconButton(
                      onPressed: () {
                        // This opens the slide-out drawer we just added!
                        Scaffold.of(context).openEndDrawer();
                      },
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

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ChoiceChip(
                    label: Text(category, style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    )),
                    selected: isSelected,
                    selectedColor: const Color(0xFF006E3B),
                    backgroundColor: Colors.white,
                    showCheckmark: false, // Keeps it looking clean like a button
                    side: BorderSide(color: isSelected ? const Color(0xFF006E3B) : Colors.grey.shade300),
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                        _filterProducts(); // This filters your GridView!
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // 4. The Product Grid (Now with a Loading Spinner!)
          // The Product Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)))
                : GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                // 1. Max width per card. Flutter will auto-add columns if the screen is wide enough!
                maxCrossAxisExtent: 280,
                // 2. Lock the height! This prevents the card from ever stretching vertically.
                mainAxisExtent: 290,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(context, filteredProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                  // SMART IMAGE LOGIC: If it starts with http, it's from the web. Otherwise, it's a local file!
                  child: product.image.startsWith('http')
                      ? Image.network(
                    product.image,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(height: 120, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                  )
                      : Image.file(
                    File(product.image),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(height: 120, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                  ),
                ),
                if (product.tag != null)
                  Positioned(
                    top: 8, right: 8,
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
                Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF006E3B), shape: BoxShape.circle),
                  child: IconButton(
                    iconSize: 20, padding: const EdgeInsets.all(8), constraints: const BoxConstraints(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      cartState.addItem(product);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added to order!'), duration: const Duration(milliseconds: 800), behavior: SnackBarBehavior.floating));
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