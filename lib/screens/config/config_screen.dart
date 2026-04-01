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