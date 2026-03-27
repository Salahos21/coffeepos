import 'package:flutter/material.dart';
import '../models/app_models.dart';

class AuthProvider extends ChangeNotifier {
  PosUser? _currentUser;

  PosUser? get currentUser => _currentUser;

  void login(PosUser user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
