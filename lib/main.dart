import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports for our clean components and screens
import 'components/side_nav.dart';
import 'components/active_order_sidebar.dart';
import 'screens/config_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'models/app_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final themeProvider = ThemeProvider();
  themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: cartState), // Providing existing global cartState
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
    return Scaffold(
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

          // 2. CONTENT AREA
          Expanded(
            child: _selectedIndex == 0
                ? const POSActiveOrderSidebar() // Handles Register + Cart responsively
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
        ],
      ),
    );
  }
}
