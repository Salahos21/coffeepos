import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../services/supabase_helper.dart';
import '../../providers/auth_provider.dart';

class ProductTab extends StatefulWidget {
  const ProductTab({super.key});

  @override
  State<ProductTab> createState() => _ProductTabState();
}

class _ProductTabState extends State<ProductTab> {
  final TextEditingController _prodNameController = TextEditingController();
  final TextEditingController _prodPriceController = TextEditingController();

  List<Product> products = [];
  List<ProductCategory> categories = [];

  bool isLoading = true;
  bool isSavingProduct = false;

  dynamic _selectedCategoryId;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _prodNameController.dispose();
    _prodPriceController.dispose();
    super.dispose();
  }

  // Uses Future.wait for faster parallel loading!
  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.cafeId == null) return;

    try {
      final results = await Future.wait([
        SupabaseHelper.instance.getProducts(auth.cafeId!),
        SupabaseHelper.instance.getCategories(auth.cafeId!),
      ]);

      if (mounted) {
        setState(() {
          products = results[0] as List<Product>;
          categories = results[1] as List<ProductCategory>;

          // Ensure the selected category still exists, otherwise reset it
          if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _selectedImagePath = image.path);
    }
  }

  Future<void> _addProduct() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (_prodNameController.text.isEmpty || _selectedCategoryId == null || auth.cafeId == null) return;

    setState(() => isSavingProduct = true);
    try {
      final newProduct = Product(
        name: _prodNameController.text.trim(),
        description: '',
        price: double.tryParse(_prodPriceController.text) ?? 0.0,
        image: _selectedImagePath ?? '',
        categoryId: _selectedCategoryId,
      );

      await SupabaseHelper.instance.addProduct(newProduct, auth.cafeId!);

      _prodNameController.clear();
      _prodPriceController.clear();
      setState(() {
        _selectedCategoryId = null;
        _selectedImagePath = null;
        isSavingProduct = false;
      });
      _loadData();
    } catch (e) {
      if (mounted) {
        setState(() => isSavingProduct = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _confirmDelete(String title, String content, Function() onConfirm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)));
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(controller: _prodNameController, decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _prodPriceController, decoration: const InputDecoration(labelText: "Price", border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        DropdownButtonFormField<dynamic>(
          value: _selectedCategoryId,
          items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
          decoration: const InputDecoration(labelText: "Select Category", border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(_selectedImagePath == null ? "Pick Product Image" : "Image Selected ✅"),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            if (_selectedImagePath != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_selectedImagePath!), width: 56, height: 56, fit: BoxFit.cover),
              ),
            ]
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(height: 54, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006E3B), foregroundColor: Colors.white),
          onPressed: isSavingProduct ? null : _addProduct,
          child: isSavingProduct ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Product", style: TextStyle(fontWeight: FontWeight.bold)),
        )),
        const Divider(height: 40),
        ...products.map((p) => ListTile(
          leading: p.image.startsWith('http')
              ? Image.network(p.image, width: 40, height: 40, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey))
              : const Icon(Icons.fastfood),
          title: Text(p.name),
          subtitle: Text(p.categoryName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("DH ${p.price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(
                    "Delete Product?",
                    "Are you sure you want to delete '${p.name}'?",
                        () async {
                      await SupabaseHelper.instance.deleteProduct(p.id, auth.cafeId!);
                      _loadData();
                    }
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}