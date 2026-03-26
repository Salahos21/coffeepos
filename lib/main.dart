import 'package:flutter/material.dart';

// 1. Import our clean components and screens
import 'components/side_nav.dart';
import 'components/center_area.dart';
import 'components/active_order_sidebar.dart';
import 'screens/config_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/login_screen.dart'; // Add this line

void main() {
  runApp(const TactilePOSApp());
}

class TactilePOSApp extends StatelessWidget {
  const TactilePOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tactile POS',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFCF8F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006E3B),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // Changed from POSMainLayout to LoginScreen
    );
  }
}

class POSMainLayout extends StatefulWidget {
  const POSMainLayout({super.key});

  @override
  State<POSMainLayout> createState() => _POSMainLayoutState();
}

class _POSMainLayoutState extends State<POSMainLayout> {
  // NEW: State variable to track the active screen (0 = Register, 2 = Config)
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait = screenWidth < 950;

    return Scaffold(
      endDrawer: isPortrait ? const Drawer(
        child: POSActiveOrderSidebar(),
      ) : null,
      body: Row(
        children: [
          // 1. LEFT NAVIGATION PANEL (Now dynamic!)
          POSSideNav(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),

          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEEDDDD)),

          // 2. CENTER CONTENT AREA (Swaps based on the selected index)
          Expanded(
            child: _selectedIndex == 0
                ? const POSCenterArea()     // The Register
                : _selectedIndex == 1
                ? const OrdersScreen()   // The Order History
                : _selectedIndex == 2
                ? const ConfigScreen() // The Configuration
                : const Center(
              child: Text(
                'Unknown Screen',
                style: TextStyle(fontSize: 24, color: Colors.grey),
              ),
            ),
          ),

          // 3. RIGHT ACTIVE ORDER SIDEBAR
          // (Only show the cart if we are on wide screen AND on the Register page!)
          if (!isPortrait && _selectedIndex == 0)
            const POSActiveOrderSidebar(),
        ],
      ),
    );
  }
}