import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart'; // ADDED GOOGLE FONTS

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
          background: const Color(0xFFF4F7FC), // Softer background
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
          background: const Color(0xFFF9FAFB), // Modern neutral grey-white
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
    final textColor = isDark ? Colors.white : const Color(0xFF111827); // Darker, richer text

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
        titleTextStyle: GoogleFonts.inter( // UPGRADED FONT
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0, // Flat design
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Softer, rounder buttons
          ),
          textStyle: GoogleFonts.inter( // UPGRADED FONT
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // INJECT GOOGLE FONTS ACROSS THE ENTIRE APP
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: -1.0,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.5,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: isDark ? Colors.white70 : const Color(0xFF374151),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}