import 'package:flutter/material.dart';
// REMOVED: shared_preferences import as we no longer store local passwords
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_helper.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final TextEditingController _taxRateController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // DELETED: _passwordController

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    // DELETED: _passwordController.dispose()
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.cafeId == null) return;

    try {
      final settings = await SupabaseHelper.instance.getCafeSettings(auth.cafeId!);
      final taxRate = await SupabaseHelper.instance.getTaxRate(auth.cafeId!);

      // DELETED: SharedPreferences logic for local passwords

      if (mounted) {
        setState(() {
          _taxRateController.text = taxRate.toString();
          _businessNameController.text = settings?['business_name'] ?? '';
          _emailController.text = settings?['reporting_email'] ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.cafeId == null) return;

    try {
      // 1. Save Tax Rate
      final rate = double.tryParse(_taxRateController.text) ?? 0.0;
      await SupabaseHelper.instance.updateTaxRate(rate, auth.cafeId!);

      // 2. Save Business Info to Cloud
      await SupabaseHelper.instance.updateCafeSettings(
        cafeId: auth.cafeId!,
        businessName: _businessNameController.text.trim(),
        reportingEmail: _emailController.text.trim(),
      );

      // DELETED: Local password saving logic

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All Settings saved successfully!'), backgroundColor: Color(0xFF006E3B)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // _buildLanguageButton remains the same...
  Widget _buildLanguageButton(BuildContext context, String label, String code) {
    final langProvider = Provider.of<LanguageProvider>(context);
    bool isSelected = langProvider.currentLocale.languageCode == code;

    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF006E3B) : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        onPressed: () => langProvider.setLanguage(code),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF006E3B)));

    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // --- LANGUAGE SECTION ---
        Text(lang.currentLocale.languageCode == 'ar' ? 'لغة التطبيق' : 'App Language',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006E3B))),
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
        const SizedBox(height: 32),
        const Divider(),

        // --- BUSINESS & REPORTING SECTION ---
        const SizedBox(height: 24),
        Text(lang.t('business_reporting') ?? 'Business & Reporting',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006E3B))),
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
          controller: _taxRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: "Tax Rate (%)",
              prefixIcon: Icon(Icons.request_quote),
              border: OutlineInputBorder()
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
              labelText: lang.t('email') ?? 'Reporting Email', // Updated label
              prefixIcon: const Icon(Icons.email),
              border: const OutlineInputBorder()
          ),
        ),

        // DELETED: The entire Password TextField and its helperText

        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF006E3B)),
          child: Text(lang.t('save_settings') ?? 'Save Settings', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),

        const SizedBox(height: 32),
        const Divider(),

        // --- DEVICE & CLOUD INFO ---
        const SizedBox(height: 24),
        const Text('Cloud Sync Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF006E3B))),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Active Café ID", style: TextStyle(fontSize: 14, color: Colors.grey)),
          subtitle: Text(auth.cafeId ?? "Not Linked", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          trailing: OutlinedButton.icon(
            icon: const Icon(Icons.link_off, color: Colors.redAccent, size: 18),
            label: const Text("Unlink Device", style: TextStyle(color: Colors.redAccent)),
            onPressed: () => auth.unlinkDevice(),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}