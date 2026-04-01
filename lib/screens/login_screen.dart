import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

// IMPORTANT: Make sure you created this file from our previous steps!
import 'start_shift_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _enteredPin = '';
  final TextEditingController _cafeIdController = TextEditingController();
  bool _isVerifying = false;

  void _handleKeyPress(String key) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += key;
      });
    }

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _handleDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final auth = context.read<AuthProvider>();

    final success = await auth.login(_enteredPin);

    if (success) {
      if (mounted) {
        // --- THE TRAFFIC COP LOGIC ---
        if (auth.hasActiveShift) {
          print("DEBUG: Active shift found. Routing to POS.");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const POSMainLayout()),
          );
        } else {
          print("DEBUG: No active shift. Routing to Start Screen.");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StartShiftScreen()),
          );
        }
      }
    } else {
      setState(() {
        _enteredPin = '';
        _isVerifying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.t('invalid_pin') ?? 'Invalid PIN'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F8),
      body: Center(
        child: SingleChildScrollView(
          child: auth.cafeId == null
              ? _buildCafeLinkView(lang, auth)
              : _buildPinPadView(lang),
        ),
      ),
    );
  }

  // --- VIEW 1: LINK DEVICE TO CAFE ---
  Widget _buildCafeLinkView(LanguageProvider lang, AuthProvider auth) {
    return Container(
      // CHANGED: Use constraints instead of fixed width for responsiveness
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 24), // Added margin for phones
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.storefront_outlined, size: 64, color: Color(0xFF006E3B)),
          const SizedBox(height: 16),
          const Text("Activate Tablet", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Enter your unique Café ID to begin", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(
            controller: _cafeIdController,
            decoration: const InputDecoration(
              labelText: "Café ID",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006E3B)),
              onPressed: () async {
                if (_cafeIdController.text.isNotEmpty) {
                  await auth.linkToCafe(_cafeIdController.text.trim());
                }
              },
              child: const Text("Link Device", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // --- VIEW 2: STANDARD PIN PAD ---
  Widget _buildPinPadView(LanguageProvider lang) {
    return Container(
      // CHANGED: Use constraints instead of fixed width for responsiveness
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 24), // Added margin for phones
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Color(0xFF006E3B)),
          const SizedBox(height: 16),
          Text(lang.t('enter_pin') ?? 'Enter PIN', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildPinIndicators(),
          const SizedBox(height: 32),
          if (_isVerifying)
            const CircularProgressIndicator(color: Color(0xFF006E3B))
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                for (var i = 1; i <= 9; i++) _buildKey('$i'),
                const SizedBox.shrink(),
                _buildKey('0'),
                _buildDeleteKey(),
              ],
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.read<AuthProvider>().unlinkDevice(),
            child: const Text("Switch Café / Change ID", style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildPinIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isFilled = index < _enteredPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16, height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xFF006E3B) : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildKey(String label) {
    return InkWell(
      onTap: () => _handleKeyPress(label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFFDECE9), borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return InkWell(
      onTap: _handleDelete,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.backspace_outlined, size: 24),
      ),
    );
  }
}