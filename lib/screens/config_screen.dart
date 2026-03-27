import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../database_helper.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  // Data Lists
  List<ProductCategory> categories = [];
  List<Product> products = [];
  List<PosUser> users = [];
  bool isLoading = true;

  // Controllers for Category
  final TextEditingController _categoryController = TextEditingController();

  // Controllers for Product Form
  final TextEditingController _prodNameController = TextEditingController();
  final TextEditingController _prodDescController = TextEditingController();
  final TextEditingController _prodPriceController = TextEditingController();

  String? _selectedCategory;
  String? _selectedImagePath;

  // Controllers for Staff Form
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPinController = TextEditingController();
  String _selectedRole = 'Barista';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Read: Fetch Categories, Products, and Users from SQLite
  Future<void> _loadAllData() async {
    final dbCategories = await DatabaseHelper.instance.getAllCategories();
    final dbProducts = await DatabaseHelper.instance.getAllProducts();
    final dbUsers = await DatabaseHelper.instance.getAllUsers();

    if (!mounted) return;

    setState(() {
      categories = dbCategories;
      products = dbProducts;
      users = dbUsers;
      isLoading = false;
    });
  }

  // --- CATEGORY LOGIC ---
  Future<void> _addCategory() async {
    final text = _categoryController.text.trim();
    if (text.isEmpty) return;
    await DatabaseHelper.instance.insertCategory(ProductCategory(name: text));
    if (!mounted) return;
    _categoryController.clear();
    _loadAllData();
  }

  Future<void> _deleteCategory(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    if (!mounted) return;
    _loadAllData();
  }

  // --- PRODUCT LOGIC ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (!mounted) return;
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  Future<void> _addProduct() async {
    final name = _prodNameController.text.trim();
    final desc = _prodDescController.text.trim();
    final priceText = _prodPriceController.text.trim();

    if (name.isEmpty || priceText.isEmpty || _selectedCategory == null || _selectedImagePath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select an image!')),
      );
      return;
    }

    final price = double.tryParse(priceText) ?? 0.0;

    final newProduct = Product(
      name: name,
      description: desc,
      price: price,
      image: _selectedImagePath!,
      category: _selectedCategory!,
    );

    await DatabaseHelper.instance.insertProduct(newProduct);

    if (!mounted) return;

    _prodNameController.clear();
    _prodDescController.clear();
    _prodPriceController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedImagePath = null;
    });

    _loadAllData();
  }

  Future<void> _deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    if (!mounted) return;
    _loadAllData();
  }

  // --- STAFF LOGIC ---
  Future<void> _addUser() async {
    final name = _userNameController.text.trim();
    final pin = _userPinController.text.trim();

    if (name.isEmpty || pin.length != 4) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and a 4-digit PIN!')),
      );
      return;
    }

    final newUser = PosUser(name: name, role: _selectedRole, pin: pin);
    
    try {
      await DatabaseHelper.instance.insertUser(newUser);
      if (!mounted) return;
      _userNameController.clear();
      _userPinController.clear();
      setState(() {
        _selectedRole = 'Barista';
      });
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding user. PIN might already be in use.')),
      );
    }
  }

  Future<void> _deleteUser(PosUser userToDelete) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    // Prevent deleting your own account or any Manager (Admin) to avoid lockout
    if (userToDelete.id == currentUser?.id || userToDelete.role == 'Manager') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Managers and your own account cannot be deleted for safety.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await DatabaseHelper.instance.deleteUser(userToDelete.id!);
    if (!mounted) return;
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)));
    }

    return DefaultTabController(
      length: 4, // Increased to 4 tabs
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Store Configuration', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TabBar(
                indicatorColor: Color(0xFF006E3B),
                labelColor: Color(0xFF006E3B),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(icon: Icon(Icons.folder_outlined), text: 'Categories'),
                  Tab(icon: Icon(Icons.coffee_outlined), text: 'Products'),
                  Tab(icon: Icon(Icons.people_outline), text: 'Staff'),
                  Tab(icon: Icon(Icons.palette_outlined), text: 'Theme'), // Added Theme tab
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: TabBarView(
                children: [
                  _buildCategoryTab(),
                  _buildProductTab(),
                  _buildStaffTab(),
                  _buildThemeTab(), // Added Theme tab view
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'New Category Name', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(120, 56),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: categories.isEmpty
              ? const Center(child: Text('No categories found.'))
              : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return Card(
                      child: ListTile(
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteCategory(cat.id!),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: _prodNameController, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _prodPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (\$)', border: OutlineInputBorder()))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      initialValue: _selectedCategory,
                      items: categories.map((cat) => DropdownMenuItem(value: cat.name, child: Text(cat.name))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: _prodDescController, decoration: const InputDecoration(labelText: 'Short Description', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pick Image'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(150, 48)),
                  ),
                  if (_selectedImagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_selectedImagePath!), width: 50, height: 50, fit: BoxFit.cover),
                    ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _addProduct,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Save Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(180, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('No products found.'))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return Card(
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: p.image.startsWith('http')
                              ? Image.network(p.image, width: 50, height: 50, fit: BoxFit.cover)
                              : Image.file(File(p.image), width: 50, height: 50, fit: BoxFit.cover),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.category} • \$${p.price.toStringAsFixed(2)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteProduct(p.id!),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStaffTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userNameController,
                      decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _userPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(labelText: '4-Digit PIN', border: OutlineInputBorder(), counterText: ""),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                      initialValue: _selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                        DropdownMenuItem(value: 'Barista', child: Text('Barista')),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _addUser,
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text('Add Staff Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: users.isEmpty
              ? const Center(child: Text('No staff members found.'))
              : ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF0F7F4),
                    child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF006E3B), fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user.role),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteUser(user),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTab() {
    final themeProvider = context.watch<ThemeProvider>();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select App Appearance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildThemeOption(
                context, 
                AppThemeColor.green, 
                'Classic Green', 
                const Color(0xFF006E3B),
                themeProvider.currentTheme == AppThemeColor.green,
              ),
              _buildThemeOption(
                context, 
                AppThemeColor.blue, 
                'Ocean Blue', 
                const Color(0xFF0056D2),
                themeProvider.currentTheme == AppThemeColor.blue,
              ),
              _buildThemeOption(
                context, 
                AppThemeColor.dark, 
                'Midnight Dark', 
                const Color(0xFF00E676),
                themeProvider.currentTheme == AppThemeColor.dark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, AppThemeColor theme, String label, Color color, bool isSelected) {
    return InkWell(
      onTap: () => context.read<ThemeProvider>().setTheme(theme),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
            ),
            const SizedBox(height: 16),
            Text(label, style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.black87,
            )),
          ],
        ),
      ),
    );
  }
}
