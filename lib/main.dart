import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports for our clean components and screens
import 'components/side_nav.dart';
import 'components/center_area.dart';
import 'components/active_order_sidebar.dart';
import 'screens/config_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';

void main() async {
  // Ensure Flutter framework is ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-load the theme settings from SharedPreferences
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const TactilePOSApp(),
    ),
  );
}

class TactilePOSApp extends StatelessWidget {
  const TactilePOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tactile POS',
      theme: context.watch<ThemeProvider>().themeData,
      home: const LoginScreen(),
    );
  }
}

class POSMainLayout extends StatefulWidget {
  const POSMainLayout({super.key});

  @override
  State<POSMainLayout> createState() => _POSMainLayoutState();
}

class _POSMainLayoutState extends State<POSMainLayout> {
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
          // 1. LEFT NAVIGATION PANEL
          POSSideNav(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),

          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEEDDDD)),

          // 2. CENTER CONTENT AREA
          Expanded(
            child: _selectedIndex == 0
                ? const POSCenterArea()
                : _selectedIndex == 1
                ? const OrdersScreen()
                : _selectedIndex == 2
                ? const ConfigScreen()
                : const Center(
              child: Text(
                'Unknown Screen',
                style: TextStyle(fontSize: 24, color: Colors.grey),
              ),
            ),
          ),

          // 3. RIGHT ACTIVE ORDER SIDEBAR
          if (!isPortrait && _selectedIndex == 0)
            const POSActiveOrderSidebar(),
        ],
      ),
    );
  }
}