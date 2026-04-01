import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../services/supabase_helper.dart';

class AuthProvider extends ChangeNotifier {
  PosUser? _currentUser;
  String? _cafeId;
  dynamic _currentShiftId; // Tracks the active shift ID
  bool _isLoading = true;

  PosUser? get currentUser => _currentUser;
  String? get cafeId => _cafeId;
  dynamic get currentShiftId => _currentShiftId;
  bool get hasActiveShift => _currentShiftId != null;
  bool get isLoading => _isLoading;

  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _cafeId = prefs.getString('linked_cafe_id');
    _isLoading = false;
    notifyListeners();
  }

  Future<void> linkToCafe(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('linked_cafe_id', id);
    _cafeId = id;
    notifyListeners();
  }

  Future<bool> login(String pin) async {
    if (_cafeId == null) return false;

    final user = await SupabaseHelper.instance.verifyStaffPin(pin, _cafeId!);

    if (user != null) {
      _currentUser = user;
      _currentShiftId = await SupabaseHelper.instance.getActiveShift(_cafeId!, user.name);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> startShift() async {
    if (_cafeId == null || _currentUser == null) return;
    _currentShiftId = await SupabaseHelper.instance.startShift(_cafeId!, _currentUser!.name);
    notifyListeners();
  }

  Future<void> endShift(double totalSales) async {
    if (_currentShiftId != null) {
      try {
        // Update database first
        await SupabaseHelper.instance.closeShift(_currentShiftId, totalSales);

        // Only clear state if DB call succeeded
        _currentShiftId = null;
        notifyListeners();
      } catch (e) {
        print("Database Update Failed: $e");
        rethrow;
      }
    }
  }

  void logout() {
    _currentUser = null;
    _currentShiftId = null;
    notifyListeners();
  }

  Future<void> unlinkDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('linked_cafe_id');
    _cafeId = null;
    _currentUser = null;
    _currentShiftId = null;
    notifyListeners();
  }
}