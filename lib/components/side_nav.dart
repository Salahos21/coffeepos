import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../screens/login_screen.dart';

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
    final isManager = currentUser?.role == 'Manager';

    return Container(
      width: 90,
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
          _buildNavItem(Icons.point_of_sale, 'Register', 0),
          _buildNavItem(Icons.receipt_long, 'Orders', 1),
          
          if (isManager)
            _buildNavItem(Icons.inventory_2_outlined, 'Config', 2),

          const Spacer(),

          // User Profile Section
          Column(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF006E3B).withOpacity(0.1),
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
              Text(
                currentUser?.role ?? '',
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
                onPressed: () {
                  currentUser = null;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                tooltip: 'Log off / Switch User',
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: InkWell(
        onTap: () => onItemSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
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
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black45,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
