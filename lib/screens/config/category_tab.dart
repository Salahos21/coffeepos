import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../services/supabase_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';

class CategoryTab extends StatefulWidget {
  const CategoryTab({super.key});

  @override
  State<CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<CategoryTab> {
  final TextEditingController _categoryController = TextEditingController();
  List<ProductCategory> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.cafeId == null) return;

    try {
      final dbCategories = await SupabaseHelper.instance.getCategories(auth.cafeId!);
      if (mounted) {
        setState(() {
          categories = dbCategories;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
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
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(hintText: "Category Name", border: OutlineInputBorder())
                  )
              ),
              const SizedBox(width: 12),
              SizedBox(
                  height: 56,
                  width: 120,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006E3B), foregroundColor: Colors.white),
                    onPressed: () async {
                      if (_categoryController.text.isEmpty || auth.cafeId == null) return;
                      await SupabaseHelper.instance.insertCategory(ProductCategory(name: _categoryController.text.trim()), auth.cafeId!);
                      _categoryController.clear();
                      _loadCategories();
                    },
                    child: Text(lang.t('add')),
                  )
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final category = categories[i];
                  return Card(
                    child: ListTile(
                      title: Text(category.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          bool inUse = await SupabaseHelper.instance.isCategoryInUse(category.id, auth.cafeId!);
                          if (inUse) {
                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Cannot Delete"),
                                content: Text("The category '${category.name}' still contains products. Please delete or move those products first."),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                              ),
                            );
                          } else {
                            _confirmDelete(
                                "Delete Category?",
                                "Are you sure you want to remove '${category.name}'?",
                                    () async {
                                  await SupabaseHelper.instance.deleteCategory(category.id, auth.cafeId!);
                                  _loadCategories();
                                }
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              )
          )
        ],
      ),
    );
  }
}