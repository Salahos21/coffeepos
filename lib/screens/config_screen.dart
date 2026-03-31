import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../services/supabase_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  List<ProductCategory> categories = [];
  List<Product> products = [];
  List<PosUser> users = [];
  bool isLoading = true;
  bool isSavingProduct = false;

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _prodNameController = TextEditingController();
  final TextEditingController _prodPriceController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPinController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController();

  dynamic _selectedCategoryId;
  String? _selectedImagePath;
  String _selectedRole = 'Barista';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.cafeId == null) return;
    try {
      final dbCategories = await SupabaseHelper.instance.getCategories(auth.cafeId!);
      final dbProducts = await SupabaseHelper.instance.getProducts(auth.cafeId!);
      final dbUsers = await SupabaseHelper.instance.getAllStaff(auth.cafeId!);
      final taxRate = await SupabaseHelper.instance.getTaxRate(auth.cafeId!);
      if (!mounted) return;
      setState(() {
        categories = dbCategories;
        products = dbProducts;
        users = dbUsers;
        _taxRateController.text = taxRate.toString();
        if (_selectedCategoryId != null) {
          bool stillExists = categories.any((c) => c.id == _selectedCategoryId);
          if (!stillExists) _selectedCategoryId = null;
        }
        isLoading = false;
      });
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
      _loadAllData();
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
    final lang = Provider.of<LanguageProvider>(context);

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            elevation: 1,
            child: TabBar(
              isScrollable: true,
              labelColor: const Color(0xFF006E3B),
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: lang.t('categories_tab')),
                Tab(text: lang.t('products')),
                Tab(text: lang.t('staff_tab')),
                Tab(text: lang.t('settings')),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildCategoryTab(lang), _buildProductTab(lang), _buildStaffTab(lang), _buildSettingsTab(lang)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(LanguageProvider lang) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: TextField(controller: _categoryController, decoration: const InputDecoration(hintText: "Category Name", border: OutlineInputBorder()))),
              const SizedBox(width: 12),
              SizedBox(height: 56, width: 120, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006E3B), foregroundColor: Colors.white),
                onPressed: () async {
                  if (_categoryController.text.isEmpty) return;
                  await SupabaseHelper.instance.insertCategory(ProductCategory(name: _categoryController.text), auth.cafeId!);
                  _categoryController.clear();
                  _loadAllData();
                },
                child: Text(lang.t('add')),
              )),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final category = categories[i];
              return Card(
                child: ListTile(
                  title: Text(category.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      // FIXED Logic: Diagnostic Check
                      bool inUse = await SupabaseHelper.instance.isCategoryInUse(category.id, auth.cafeId!);

                      if (inUse) {
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Cannot Delete"),
                            content: Text("The category '${category.name}' still contains products. Please delete or move those products first to keep your data clean."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
                            ],
                          ),
                        );
                      } else {
                        _confirmDelete(
                            "Delete Category?",
                            "Are you sure you want to remove '${category.name}'?",
                                () async {
                              await SupabaseHelper.instance.deleteCategory(category.id, auth.cafeId!);
                              _loadAllData();
                            }
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ))
        ],
      ),
    );
  }

  Widget _buildProductTab(LanguageProvider lang) {
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
                      _loadAllData();
                    }
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildStaffTab(LanguageProvider lang) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
            controller: _userNameController,
            decoration: const InputDecoration(labelText: "Staff Name", border: OutlineInputBorder())
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _userPinController,
          decoration: const InputDecoration(labelText: "4-Digit PIN", border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          maxLength: 4, // Prevents entering long PINs
        ),
        const SizedBox(height: 16),
        // ADDED: Role Selection so the database doesn't get empty roles
        DropdownButtonFormField<String>(
          value: _selectedRole,
          items: ['Barista', 'Manager'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
          onChanged: (v) => setState(() => _selectedRole = v!),
          decoration: const InputDecoration(labelText: "Select Role", border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        SizedBox(height: 54, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006E3B), foregroundColor: Colors.white),
          onPressed: () async {
            // Validation: Name must not be empty and PIN must be exactly 4 digits
            if (_userNameController.text.isEmpty || _userPinController.text.length != 4) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a name and a 4-digit PIN"), backgroundColor: Colors.orange)
              );
              return;
            }

            try {
              await SupabaseHelper.instance.insertStaff(
                  PosUser(
                      name: _userNameController.text.trim(),
                      role: _selectedRole,
                      pin: _userPinController.text.trim()
                  ),
                  auth.cafeId!
              );

              _userNameController.clear();
              _userPinController.clear();
              _loadAllData(); // Refresh the list

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Staff added successfully!"), backgroundColor: Colors.green)
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to add staff: $e"), backgroundColor: Colors.red)
                );
              }
            }
          },
          child: const Text("Add Staff"),
        )),
        const Divider(height: 40),
        // List of existing staff
        ...users.map((u) => ListTile(
          leading: CircleAvatar(backgroundColor: u.role == 'Manager' ? Colors.orange : Colors.blue, child: Icon(u.role == 'Manager' ? Icons.verified_user : Icons.person, color: Colors.white)),
          title: Text(u.name),
          subtitle: Text(u.role),
          trailing: Text("PIN: ${u.pin}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        )),
      ],
    );
  }

  Widget _buildSettingsTab(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(controller: _taxRateController, decoration: const InputDecoration(labelText: "Tax Rate (%)", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006E3B), foregroundColor: Colors.white),
              onPressed: () async {
                await SupabaseHelper.instance.updateTaxRate(double.tryParse(_taxRateController.text) ?? 0.0, Provider.of<AuthProvider>(context, listen: false).cafeId!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings Updated")));
              },
              child: const Text("Update Tax")
          ),
        ],
      ),
    );
  }
}