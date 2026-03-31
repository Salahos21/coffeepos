import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this package
import '../models/app_models.dart';
import '../services/supabase_helper.dart'; // We will create this next

class AuthProvider extends ChangeNotifier {
  PosUser? _currentUser;
  String? _cafeId;
  bool _isLoading = true;

  PosUser? get currentUser => _currentUser;
  String? get cafeId => _cafeId;
  bool get isLoading => _isLoading;

  // 1. Initialize: Check if this tablet is already linked to a Café
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _cafeId = prefs.getString('linked_cafe_id');

    _isLoading = false;
    notifyListeners();
  }

  // 2. Link Device: The one-time setup to bind this tablet to a specific Café
  Future<void> linkToCafe(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('linked_cafe_id', id);
    _cafeId = id;
    notifyListeners();
  }

  // 3. Login: Verify staff PIN against Supabase for THIS Café
  Future<bool> login(String pin) async {
    if (_cafeId == null) return false;

    // This calls our new cloud-based helper
    final user = await SupabaseHelper.instance.verifyStaffPin(pin, _cafeId!);

    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Optional: To reset a tablet for a different café
  Future<void> unlinkDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('linked_cafe_id');
    _cafeId = null;
    _currentUser = null;
    notifyListeners();
  }
}