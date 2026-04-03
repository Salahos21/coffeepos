import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../services/supabase_helper.dart';

class AuthProvider extends ChangeNotifier {
  PosUser? _currentUser;
  String? _cafeId;
  dynamic _currentShiftId;
  bool _isLoading = true;

  AuthProvider() {
    print("🛑 TELEMETRY: [1] AuthProvider Constructor Booting up!");
    initializeAuth();
  }

  PosUser? get currentUser => _currentUser;

  // TELEMETRY ALARM on the getter
  String? get cafeId {
    print("🛑 TELEMETRY: [READ] UI asked for cafeId. Current value: $_cafeId");
    return _cafeId;
  }

  dynamic get currentShiftId => _currentShiftId;
  bool get hasActiveShift => _currentShiftId != null;
  bool get isLoading => _isLoading;

  Future<void> initializeAuth() async {
    print("🛑 TELEMETRY: [2] initializeAuth() started. Checking hard drive...");
    _isLoading = true;

    final prefs = await SharedPreferences.getInstance();
    _cafeId = prefs.getString('linked_cafe_id');

    print("🛑 TELEMETRY: [3] Hard drive check complete. Found cafeId: $_cafeId");

    _isLoading = false;
    notifyListeners();
  }

  Future<void> linkToCafe(String id) async {
    print("🛑 TELEMETRY: [WRITE] Linking to new Cafe: $id");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('linked_cafe_id', id);
    _cafeId = id;
    notifyListeners();
  }

  Future<bool> login(String pin) async {
    final currentCafeId = _cafeId;
    if (currentCafeId == null) return false;

    final user = await SupabaseHelper.instance.verifyStaffPin(pin, currentCafeId);

    if (user != null) {
      _currentUser = user;
      _currentShiftId = await SupabaseHelper.instance.getActiveShift(currentCafeId, user.name);
      print("🛑 TELEMETRY: [LOGIN] User ${user.name} logged in.");
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> startShift() async {
    final currentCafeId = _cafeId;
    final user = _currentUser;

    if (currentCafeId == null || user == null) return;

    _currentShiftId = await SupabaseHelper.instance.startShift(currentCafeId, user.name);
    print("🛑 TELEMETRY: [SHIFT] Started shift for ${user.name}.");
    notifyListeners();
  }

  Future<void> endShift(double totalSales) async {
    final shiftId = _currentShiftId;

    if (shiftId != null) {
      try {
        await SupabaseHelper.instance.closeShift(shiftId, totalSales);
        _currentShiftId = null;
        notifyListeners();
      } catch (e) {
        print("Database Update Failed: $e");
        rethrow;
      }
    }
  }

  void logout() {
    print("🛑 TELEMETRY: [LOGOUT] Logout called! Wiping user data, BUT keeping cafeId: $_cafeId");
    _currentUser = null;
    _currentShiftId = null;
    notifyListeners();
  }

  Future<void> unlinkDevice() async {
    print("🛑 ALARM ALARM ALARM: [UNLINK] unlinkDevice() was triggered!!!");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('linked_cafe_id');
    _cafeId = null;
    _currentUser = null;
    _currentShiftId = null;
    notifyListeners();
  }
}