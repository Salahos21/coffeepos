import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // This tells Flutter to wait until the green screen with the spinner
    // is fully painted BEFORE it starts the heavy background tasks.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // 1. Initialize Supabase (Network task)
    await Supabase.initialize(
      url: 'https://pkarwrxrrocusianlhnc.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBrYXJ3cnhycm9jdXNpYW5saG5jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4MTk5NDksImV4cCI6MjA5MDM5NTk0OX0.vcFh8Qk3jmIQBnDONh6AiC4KqunPBVht7Zgf-BaMdio',
    );

    // 2. Initialize Auth (Local storage task)
    if (mounted) {
      await Provider.of<AuthProvider>(context, listen: false).initializeAuth();
    }

    // 3. Add a tiny delay so the splash screen doesn't just flash instantly (optional)
    await Future.delayed(const Duration(milliseconds: 500));

    // 4. Navigate to Login Screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF006E3B), // Your brand green
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee, size: 80, color: Colors.white), // Replace with your Image.asset logo later
            SizedBox(height: 24),
            Text(
              'Tactile POS',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}