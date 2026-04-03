import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

// Import the new independent tab widgets
import 'category_tab.dart';
import 'product_tab.dart';
import 'staff_tab.dart';
import 'settings_tab.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // UPGRADED: Sleek, border-bottom tab bar instead of heavy elevation
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)
              ),
            ),
            child: TabBar(
              isScrollable: true,
              labelColor: const Color(0xFF059669), // Upgraded to the new Emerald
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: const Color(0xFF059669),
              indicatorWeight: 3,
              dividerColor: Colors.transparent, // Removes the ugly default grey line in Material 3
              labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3),
              unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3),
              tabs: [
                Tab(text: lang.t('categories_tab') ?? 'Categories'),
                Tab(text: lang.t('products') ?? 'Products'),
                Tab(text: lang.t('staff_tab') ?? 'Staff'),
                Tab(text: lang.t('settings') ?? 'Settings'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                CategoryTab(),
                ProductTab(),
                StaffTab(),
                SettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}