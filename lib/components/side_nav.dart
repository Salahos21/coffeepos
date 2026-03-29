import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../screens/login_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/settings_screen.dart';

class POSSideNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const POSSideNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isManager = currentUser?.role == 'Manager';
    final lang = Provider.of<LanguageProvider>(context);

    return Container(
      width: 100, // Increased slightly for longer localized words
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF006E3B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.coffee, color: Colors.white),
          ),
          const SizedBox(height: 48),

          // Nav Items
          _buildNavItem(Icons.point_of_sale, lang.t('register'), 0, isSelected: selectedIndex == 0),
          _buildNavItem(Icons.receipt_long, lang.t('orders'), 1, isSelected: selectedIndex == 1),

          if (isManager)
            _buildNavItem(Icons.inventory_2_outlined, lang.t('config'), 2, isSelected: selectedIndex == 2),

          const Spacer(),

          // User Profile Section
          Column(
            children: [
              if (isManager)
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.grey, size: 24),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  tooltip: lang.t('settings'), // Translated Tooltip
                ),
              const SizedBox(height: 12),
              CircleAvatar(
                backgroundColor: const Color(0xFF006E3B).withValues(alpha: 0.1),
                child: Text(
                  (currentUser?.name ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Color(0xFF006E3B), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentUser?.name ?? '',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              // Translated Role (Manager/Barista)
              Text(
                currentUser?.role == 'Manager' ? lang.t('manager_role') : lang.t('barista_role'),
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
                onPressed: () {
                  authProvider.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                },
                tooltip: lang.t('logout'), // Translated Tooltip
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {required bool isSelected}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: InkWell(
        onTap: () => onItemSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72, // Wider hit area
          height: 64,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF006E3B) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black45,
                size: 24,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black45,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis, // Safety for long words
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}