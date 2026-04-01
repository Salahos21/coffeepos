import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// FIX: Pointing back to the components folder!
import 'screens/pos/active_order_sidebar.dart';
import 'screens/config/config_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'models/app_models.dart';
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: cartState),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const TactilePOSApp(),
    ),
  );
}

class TactilePOSApp extends StatelessWidget {
  const TactilePOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lang, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tactile POS',
          theme: context.watch<ThemeProvider>().themeData,
          locale: lang.currentLocale,
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
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

  final List<Widget> _screens = const [
    POSActiveOrderSidebar(),
    OrdersScreen(),
    ConfigScreen(),
  ];

  void _handleLogout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isManager = currentUser?.role == 'Manager';

    return Scaffold(
      backgroundColor: Colors.white,

      // TOP BAR: Profile, Role, and Logout
      appBar: AppBar(
        backgroundColor: const Color(0xFF006E3B),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.coffee, size: 20),
            const SizedBox(width: 8),
            Text(currentUser?.name ?? 'User', style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                currentUser?.role == 'Manager' ? (lang.t('manager_role') ?? 'Manager') : (lang.t('barista_role') ?? 'Barista'),
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: lang.t('logout'),
          ),
        ],
      ),

      // MAIN CONTENT
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // BOTTOM NAV
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF006E3B).withValues(alpha: 0.15),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.point_of_sale_outlined),
            selectedIcon: const Icon(Icons.point_of_sale, color: Color(0xFF006E3B)),
            label: lang.t('register') ?? 'Register',
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long, color: Color(0xFF006E3B)),
            label: lang.t('orders') ?? 'Orders',
          ),
          if (isManager)
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2, color: Color(0xFF006E3B)),
              label: lang.t('config') ?? 'Config',
            ),
        ],
      ),
    );
  }
}