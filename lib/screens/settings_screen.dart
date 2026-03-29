import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../database_helper.dart'; // Verified path for lib/database_helper.dart

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
          text: 'Here is the database backup for ${_businessNameController.text}.',
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
      // 1. Close connection BEFORE picking file to release the lock
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
            content: const Text('Database restored. The app must restart to load the new data.'),
            actions: [
              ElevatedButton(
                onPressed: () => exit(0),
                child: const Text('RESTART NOW'),
              ),
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
        content: const Text('This will replace all current data with the backup file. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('IMPORT')),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Business & Reporting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF006E3B))),
            const SizedBox(height: 16),
            TextField(
              controller: _businessNameController,
              decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.store), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Reporting Gmail Address', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Gmail App Password',
                prefixIcon: Icon(Icons.lock),
                helperText: '16-character code from Google Account settings.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF006E3B)),
              child: const Text('SAVE SETTINGS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
            const Divider(),
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
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importDatabase,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('IMPORT'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Text(
                'Tip: Export your database weekly and save it to your Google Drive for safety.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
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
                  const SnackBar(content: Text('90 Days of Fake Data Injected!'), backgroundColor: Colors.redAccent),
                );
              },
              icon: const Icon(Icons.bug_report, color: Colors.white),
              label: const Text('INJECT 3 MONTHS OF FAKE ORDERS', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}