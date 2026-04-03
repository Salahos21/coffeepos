import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
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

  final LinearGradient _primaryGradient = const LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF006E3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.cafeId == null && !auth.isLoading) {
        auth.initializeAuth();
      }
    });
  }

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
        final user = auth.currentUser;

        if (user?.role == 'Manager') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const POSMainLayout()),
          );
        } else if (auth.hasActiveShift) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const POSMainLayout()),
          );
        } else {
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

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: auth.cafeId == null
              ? _buildCafeLinkView(lang, auth)
              : _buildPinPadView(lang),
        ),
      ),
    );
  }

  Widget _buildCafeLinkView(LanguageProvider lang, AuthProvider auth) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(40),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // THE FIX: Removed ShaderMask here as well.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.storefront_outlined, size: 48, color: Color(0xFF059669)),
          ),
          const SizedBox(height: 24),
          const Text("Activate Tablet", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text("Enter your unique Café ID to begin", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          const SizedBox(height: 32),

          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.grey.shade200)
            ),
            child: TextField(
              controller: _cafeIdController,
              decoration: InputDecoration(
                hintText: "Café ID",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colors.black45),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),

          const SizedBox(height: 32),

          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
                gradient: _primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
                ]
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
              onPressed: () async {
                if (_cafeIdController.text.isNotEmpty) {
                  await auth.linkToCafe(_cafeIdController.text.trim());
                }
              },
              child: const Text("Link Device", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinPadView(LanguageProvider lang) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // THE FIX: Removed ShaderMask here too.
          const Icon(Icons.lock_outline, size: 48, color: Color(0xFF059669)),
          const SizedBox(height: 16),
          Text(lang.t('enter_pin') ?? 'Enter PIN', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 32),
          _buildPinIndicators(),
          const SizedBox(height: 40),
          if (_isVerifying)
            const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                for (var i = 1; i <= 9; i++) _buildKey('$i'),
                const SizedBox.shrink(),
                _buildKey('0'),
                _buildDeleteKey(),
              ],
            ),
          const SizedBox(height: 32),
          // THE FIX: Completely hide the Unlink button while loading so it cannot
          // teleport into your finger during the layout shift!
          if (!_isVerifying)
            TextButton(
              onPressed: () => context.read<AuthProvider>().unlinkDevice(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade500),
              child: const Text("Switch Café / Change ID", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            )
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.grey.shade100),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 24,
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16, height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? null : Colors.grey.shade200,
            gradient: isFilled ? _primaryGradient : null,
            boxShadow: isFilled
                ? [BoxShadow(color: const Color(0xFF059669).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
        );
      }),
    );
  }

  Widget _buildKey(String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _handleKeyPress(label),
        child: Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Text(label, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _handleDelete,
        child: Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(Icons.backspace_outlined, size: 26, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}