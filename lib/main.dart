import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Imports for our clean components and screens
import 'components/side_nav.dart';
import 'components/active_order_sidebar.dart';
import 'screens/config_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'models/app_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // Load Theme and Language immediately on startup
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: cartState),
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
    // We use Consumer here so the entire app rebuilds (and flips RTL)
    // the moment setLanguage() is called in Settings.
    return Consumer<LanguageProvider>(
      builder: (context, lang, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tactile POS',
          theme: context.watch<ThemeProvider>().themeData,

          // Localization Settings
          locale: lang.currentLocale,
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Entry point is Login
          home: const LoginScreen(),
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

  @override
  Widget build(BuildContext context) {
    // In Arabic mode, the Row children [SideNav, Divider, Expanded]
    // will reverse order automatically.
    return Scaffold(
      body: Row(
        children: [
          // 1. NAVIGATION PANEL (Will be Right-aligned in Arabic)
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
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                POSActiveOrderSidebar(), // Register + Cart
                OrdersScreen(),          // Analytics/History
                ConfigScreen(),          // Manager Settings
              ],
            ),
          ),
        ],
      ),
    );
  }
}