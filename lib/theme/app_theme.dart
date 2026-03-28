import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeColor { green, blue, dark }

class ThemeProvider extends ChangeNotifier {
  AppThemeColor _currentTheme = AppThemeColor.green;

  AppThemeColor get currentTheme => _currentTheme;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('app_theme');
    if (themeName != null) {
      _currentTheme = AppThemeColor.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => AppThemeColor.green,
      );
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeColor theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme.name);
    notifyListeners();
  }

  ThemeData get themeData {
    switch (_currentTheme) {
      case AppThemeColor.blue:
        return _buildTheme(
          primary: const Color(0xFF0056D2),
          background: const Color(0xFFF0F4FF),
          surface: Colors.white,
          isDark: false,
        );
      case AppThemeColor.dark:
        return _buildTheme(
          primary: const Color(0xFF00E676),
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
          isDark: true,
        );
      case AppThemeColor.green:
          return _buildTheme(
          primary: const Color(0xFF006E3B),
          background: const Color(0xFFFCF8F8),
          surface: Colors.white,
          isDark: false,
        );
    }
  }

  ThemeData _buildTheme({
    required Color primary,
    required Color background,
    required Color surface,
    required bool isDark,
  }) {
    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textColor = isDark ? Colors.white : Colors.black;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
    );
  }
}
