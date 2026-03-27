import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../main.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _enteredPin = '';

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
    final user = await DatabaseHelper.instance.getUserByPin(_enteredPin);

    if (user != null) {
      if (mounted) {
        // Correct way to set the user using Provider
        context.read<AuthProvider>().login(user);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const POSMainLayout()),
        );
      }
    } else {
      setState(() {
        _enteredPin = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid PIN'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F8),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Color(0xFF006E3B)),
                const SizedBox(height: 16),
                const Text(
                  'Enter your PIN',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                // PIN Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    bool isFilled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? const Color(0xFF006E3B) : Colors.grey[300],
                        border: Border.all(
                          color: isFilled ? const Color(0xFF006E3B) : Colors.grey[400]!,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Keypad
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label) {
    return InkWell(
      onTap: () => _handleKeyPress(label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFDECE9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return InkWell(
      onTap: _handleDelete,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.backspace_outlined, size: 24),
      ),
    );
  }
}
