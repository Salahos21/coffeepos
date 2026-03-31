import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'components/side_nav.dart';
import 'components/active_order_sidebar.dart';
import 'screens/config_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'models/app_models.dart';
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://pkarwrxrrocusianlhnc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBrYXJ3cnhycm9jdXNpYW5saG5jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4MTk5NDksImV4cCI6MjA5MDM5NTk0OX0.vcFh8Qk3jmIQBnDONh6AiC4KqunPBVht7Zgf-BaMdio',
  );

  final authProvider = AuthProvider();
  await authProvider.initializeAuth();

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

  // Define screens in a list to ensure they are treated as distinct Expanded children
  final List<Widget> _screens = const [
    POSActiveOrderSidebar(),
    OrdersScreen(),
    ConfigScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar with fixed width
          POSSideNav(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),

          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEEDDDD)),

          // Main content area
          Expanded(
            child: Container(
              color: Colors.white,
              // SizedBox.expand ensures the child fills the Expanded area
              child: SizedBox.expand(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}