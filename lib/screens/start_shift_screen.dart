import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../main.dart'; // To navigate to POSMainLayout

class StartShiftScreen extends StatelessWidget {
  const StartShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              auth.logout();
              Navigator.pop(context); // Go back to login
            },
            tooltip: lang.t('logout') ?? 'Logout',
          )
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_filled, size: 80, color: Color(0xFF006E3B)),
              const SizedBox(height: 24),
              Text(
                "Welcome, ${user?.name ?? 'User'}!",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "You do not have an active shift.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 1. Record the exact start time in the AuthProvider
                    await auth.startShift();

                    // 2. Navigate to the main POS layout
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const POSMainLayout()),
                      );
                    }
                  },
                  icon: const Icon(Icons.play_circle_fill, size: 28),
                  label: const Text(
                    "START SHIFT",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006E3B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}