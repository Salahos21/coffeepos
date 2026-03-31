import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_helper.dart'; // Added for Cafe ID display

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // lib/screens/settings_screen.dart

  Future<void> _loadSettings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.cafeId == null) return;

    // 1. Load from Cloud via Supabase
    final settings = await SupabaseHelper.instance.getCafeSettings(auth.cafeId!);

    if (settings != null) {
      setState(() {
        _businessNameController.text = settings['business_name'] ?? '';
        _emailController.text = settings['reporting_email'] ?? '';
      });
    }

    // 2. Load the Password locally (Keep passwords off the cloud for now)
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _passwordController.text = prefs.getString('appPassword') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cafeId = auth.cafeId;

    if (cafeId == null) return;

    try {
      // 1. Save Business Info to Supabase
      await SupabaseHelper.instance.updateCafeSettings(
        cafeId: cafeId,
        businessName: _businessNameController.text.trim(),
        reportingEmail: _emailController.text.trim(),
      );

      // 2. Save Password locally (for Edge Function secrets, use Dashboard)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appPassword', _passwordController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings synced to Cloud!'),
          backgroundColor: Color(0xFF006E3B),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error syncing: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildLanguageButton(BuildContext context, String label, String code) {
    final langProvider = Provider.of<LanguageProvider>(context);
    bool isSelected = langProvider.currentLocale.languageCode == code;

    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF006E3B) : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => langProvider.setLanguage(code),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context); // Access Auth for Café ID

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('settings'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- LANGUAGE SECTION ---
            Text(lang.currentLocale.languageCode == 'ar' ? 'لغة التطبيق' : 'App Language',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF006E3B))),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLanguageButton(context, 'English', 'en'),
                const SizedBox(width: 8),
                _buildLanguageButton(context, 'Français', 'fr'),
                const SizedBox(width: 8),
                _buildLanguageButton(context, 'العربية', 'ar'),
              ],
            ),
            const SizedBox(height: 40),
            const Divider(),

            // --- BUSINESS & REPORTING SECTION ---
            const SizedBox(height: 24),
            Text(lang.t('business_reporting'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF006E3B))),
            const SizedBox(height: 16),

            TextField(
              controller: _businessNameController,
              decoration: InputDecoration(
                  labelText: lang.currentLocale.languageCode == 'ar' ? 'اسم العمل' : 'Business Name',
                  prefixIcon: const Icon(Icons.store),
                  border: const OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  labelText: lang.t('email'),
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: lang.t('password'),
                  helperText: lang.currentLocale.languageCode == 'ar'
                      ? 'رمز مكون من 16 حرفًا من إعدادات جوجل.'
                      : '16-character code from Google settings.',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder()
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF006E3B)),
              child: Text(lang.t('save_settings'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 40),
            const Divider(),

            // --- DEVICE & CLOUD INFO ---
            const SizedBox(height: 24),
            const Text('Cloud Sync Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Active Café ID", style: TextStyle(fontSize: 14, color: Colors.grey)),
              subtitle: Text(auth.cafeId ?? "Not Linked", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              trailing: IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                onPressed: () => auth.unlinkDevice(), // Button to reset the tablet
              ),
            ),
            const Text(
              "This tablet is linked to your cloud account. To switch cafés, use the logout icon above.",
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}