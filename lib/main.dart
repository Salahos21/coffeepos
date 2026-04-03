import 'package:flutter/material.dart';
import 'package:pos_prototype_0/screens/start_shift_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: cartState),
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

  void _handleLogout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Clear the data
    authProvider.logout();

    // 2. THE FIX: Instant Snap routing instead of a slow slide animation
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    // THE FIX: The Null Guard.
    // If we are actively logging out, freeze the UI as a clean white screen
    // so it doesn't accidentally draw the StartShiftScreen.
    if (currentUser == null) {
      return const Scaffold(backgroundColor: Colors.white);
    }

    final isManager = currentUser.role == 'Manager';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF006E3B),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.coffee, size: 20),
            const SizedBox(width: 8),
            Text(currentUser.name, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                isManager ? (lang.t('manager_role') ?? 'Manager') : (lang.t('barista_role') ?? 'Barista'),
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

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          (isManager || authProvider.hasActiveShift)
              ? const POSActiveOrderSidebar()
              : const StartShiftScreen(),

          const OrdersScreen(),
          const ConfigScreen(),
        ],
      ),

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