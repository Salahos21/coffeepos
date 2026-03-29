import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../providers/language_provider.dart';

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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _businessNameController.text = prefs.getString('businessName') ?? 'My Coffee Shop';
      _emailController.text = prefs.getString('reportingEmail') ?? '';
      _passwordController.text = prefs.getString('appPassword') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('businessName', _businessNameController.text.trim());
    await prefs.setString('reportingEmail', _emailController.text.trim());
    await prefs.setString('appPassword', _passwordController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Color(0xFF006E3B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportDatabase() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'pos_database.db');
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        await Share.shareXFiles(
          [XFile(dbPath)],
          subject: 'Tactile POS Database Backup',
        );
      } else {
        throw Exception("Database file not found.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importDatabase() async {
    try {
      await DatabaseHelper.instance.close();
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        File pickedFile = File(result.files.single.path!);
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbPath = p.join(dbFolder.path, 'pos_database.db');

        bool confirm = await _showConfirmDialog();
        if (!confirm) return;

        await pickedFile.copy(dbPath);
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Import Successful'),
            content: const Text('Database restored. Restart required.'),
            actions: [
              ElevatedButton(onPressed: () => exit(0), child: const Text('RESTART NOW')),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Overwrite Database?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('IMPORT')),
        ],
      ),
    ) ?? false;
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

            // Business Name
            TextField(
              controller: _businessNameController,
              decoration: InputDecoration(
                  labelText: lang.currentLocale.languageCode == 'ar' ? 'اسم العمل' : 'Business Name',
                  prefixIcon: const Icon(Icons.store),
                  border: const OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 16),

            // Email Field (Restored)
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

            // Password Field (Restored)
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

            // --- DATA & BACKUPS ---
            const SizedBox(height: 24),
            const Text('Data & Backups', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportDatabase,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('EXPORT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importDatabase,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('IMPORT'),
                  ),
                ),
              ],
            ),

            // --- DEBUG SECTION ---
            const SizedBox(height: 60),
            const Divider(color: Colors.redAccent),
            const Text('Developer Tools', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await DatabaseHelper.instance.seedHistoricalData();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('90 Days Data Injected!'), backgroundColor: Colors.redAccent),
                );
              },
              icon: const Icon(Icons.bug_report, color: Colors.white),
              label: const Text('INJECT FAKE DATA', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}