import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../database_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart'; // Added
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

  // Settings State
  final TextEditingController _taxRateController = TextEditingController();
  bool _isBlindDropEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final dbCategories = await DatabaseHelper.instance.getAllCategories();
    final dbProducts = await DatabaseHelper.instance.getAllProducts();
    final dbUsers = await DatabaseHelper.instance.getAllUsers();
    final taxRate = await DatabaseHelper.instance.getTaxRate();
    final blindDrop = await DatabaseHelper.instance.getBlindDropSetting();

    if (!mounted) return;

    setState(() {
      categories = dbCategories;
      products = dbProducts;
      users = dbUsers;
      _taxRateController.text = taxRate.toString();
      _isBlindDropEnabled = blindDrop;
      isLoading = false;
    });
  }

  // --- LOGIC (REMAINING AS IS) ---
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!mounted) return;
      setState(() => _selectedImagePath = image.path);
    }
  }

  Future<void> _addProduct() async {
    final name = _prodNameController.text.trim();
    final desc = _prodDescController.text.trim();
    final priceText = _prodPriceController.text.trim();
    if (name.isEmpty || priceText.isEmpty || _selectedCategory == null || _selectedImagePath == null) return;

    final price = double.tryParse(priceText) ?? 0.0;
    final newProduct = Product(
      name: name, description: desc, price: price,
      image: _selectedImagePath!, category: _selectedCategory!,
    );

    await DatabaseHelper.instance.insertProduct(newProduct);
    if (!mounted) return;
    _prodNameController.clear(); _prodDescController.clear(); _prodPriceController.clear();
    setState(() { _selectedCategory = null; _selectedImagePath = null; });
    _loadAllData();
  }

  Future<void> _deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    if (!mounted) return;
    _loadAllData();
  }

  Future<void> _addUser() async {
    final name = _userNameController.text.trim();
    final pin = _userPinController.text.trim();
    if (name.isEmpty || pin.length != 4) return;

    final newUser = PosUser(name: name, role: _selectedRole, pin: pin);
    try {
      await DatabaseHelper.instance.insertUser(newUser);
      if (!mounted) return;
      _userNameController.clear(); _userPinController.clear();
      setState(() => _selectedRole = 'Barista');
      _loadAllData();
    } catch (e) { /* Error handling */ }
  }

  Future<void> _deleteUser(PosUser userToDelete) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (userToDelete.id == currentUser?.id || userToDelete.role == 'Manager') return;
    await DatabaseHelper.instance.deleteUser(userToDelete.id!);
    if (!mounted) return;
    _loadAllData();
  }

  Future<void> _saveTaxRate() async {
    final rate = double.tryParse(_taxRateController.text.trim());
    if (rate == null) return;
    await DatabaseHelper.instance.saveTaxRate(rate);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved!')));
  }

  Future<void> _toggleBlindDrop(bool value) async {
    setState(() => _isBlindDropEnabled = value);
    await DatabaseHelper.instance.saveBlindDropSetting(value);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)));

    final lang = Provider.of<LanguageProvider>(context);

    return DefaultTabController(
      length: 5,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.t('config'), style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                isScrollable: true,
                indicatorColor: const Color(0xFF006E3B),
                labelColor: const Color(0xFF006E3B),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(icon: const Icon(Icons.folder_outlined), text: lang.t('categories_tab')),
                  Tab(icon: const Icon(Icons.coffee_outlined), text: lang.t('products')),
                  Tab(icon: const Icon(Icons.people_outline), text: lang.t('staff_tab')),
                  Tab(icon: const Icon(Icons.settings_outlined), text: lang.t('settings')),
                  Tab(icon: const Icon(Icons.palette_outlined), text: lang.t('theme_tab')),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: TabBarView(
                children: [
                  _buildCategoryTab(lang),
                  _buildProductTab(lang),
                  _buildStaffTab(lang),
                  _buildSettingsTab(lang),
                  _buildThemeTab(lang),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(LanguageProvider lang) {
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
                  decoration: InputDecoration(labelText: lang.t('new_cat_label'), border: const OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(lang.t('add'), style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(120, 56)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: categories.isEmpty
              ? const Center(child: Text('No categories'))
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

  Widget _buildProductTab(LanguageProvider lang) {
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
                  Expanded(child: TextField(controller: _prodNameController, decoration: InputDecoration(labelText: lang.t('prod_name_label'), border: const OutlineInputBorder()))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _prodPriceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '${lang.t('price')} (\$)', border: const OutlineInputBorder()))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: lang.t('categories_tab'), border: const OutlineInputBorder()),
                      value: _selectedCategory,
                      items: categories.map((cat) => DropdownMenuItem(value: cat.name, child: Text(cat.name))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: _prodDescController, decoration: InputDecoration(labelText: lang.t('description'), border: const OutlineInputBorder())),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16, runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(lang.t('pick_image')),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(150, 48)),
                  ),
                  if (_selectedImagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_selectedImagePath!), width: 50, height: 50, fit: BoxFit.cover),
                    ),
                  ElevatedButton.icon(
                    onPressed: _addProduct,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: Text(lang.t('save_product'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('No products'))
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

  Widget _buildStaffTab(LanguageProvider lang) {
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
                  Expanded(child: TextField(controller: _userNameController, decoration: InputDecoration(labelText: lang.t('name'), border: const OutlineInputBorder()))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _userPinController, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'PIN', border: OutlineInputBorder(), counterText: ""))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: lang.t('role'), border: const OutlineInputBorder()),
                      value: _selectedRole,
                      items: [
                        DropdownMenuItem(value: 'Manager', child: Text(lang.t('manager_role'))),
                        DropdownMenuItem(value: 'Barista', child: Text(lang.t('barista_role'))),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addUser,
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: Text(lang.t('add_staff'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: users.isEmpty
              ? const Center(child: Text('No staff'))
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
                  subtitle: Text(user.role == 'Manager' ? lang.t('manager_role') : lang.t('barista_role')),
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

  Widget _buildSettingsTab(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.t('tax_config_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(lang.t('tax_config_sub'), style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _taxRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: '${lang.t('tax')} (%)', border: const OutlineInputBorder(), suffixText: '%'),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _saveTaxRate,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(lang.t('save_settings'), style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(minimumSize: const Size(150, 56)),
              ),
            ],
          ),
          const SizedBox(height: 48),
          const Divider(),
          const SizedBox(height: 24),
          Text(lang.t('security_settings'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: Text(lang.t('blind_drop_title')),
            subtitle: Text(lang.t('blind_drop_sub')),
            value: _isBlindDropEnabled,
            onChanged: _toggleBlindDrop,
            activeThumbColor: const Color(0xFF006E3B),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTab(LanguageProvider lang) {
    final themeProvider = context.watch<ThemeProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.t('theme_selection'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildThemeOption(context, AppThemeColor.green, lang.t('theme_green'), const Color(0xFF006E3B), themeProvider.currentTheme == AppThemeColor.green),
            _buildThemeOption(context, AppThemeColor.blue, lang.t('theme_blue'), const Color(0xFF0056D2), themeProvider.currentTheme == AppThemeColor.blue),
            _buildThemeOption(context, AppThemeColor.dark, lang.t('theme_dark'), const Color(0xFF00E676), themeProvider.currentTheme == AppThemeColor.dark),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(BuildContext context, AppThemeColor theme, String label, Color color, bool isSelected) {
    return InkWell(
      onTap: () => context.read<ThemeProvider>().setTheme(theme),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
            ),
            const SizedBox(height: 16),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.black87)),
          ],
        ),
      ),
    );
  }
}