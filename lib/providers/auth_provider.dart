import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthState {
  unauthenticated,
  needsAuthentication,
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthState _authState = AuthState.unauthenticated;
  bool _needsAuthentication = false;
  bool _isAppInBackground = false;

  AuthState get authState => _authState;
  bool get needsAuthentication => _needsAuthentication;
  bool get isAppInBackground => _isAppInBackground;

  void setAuthState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  void setNeedsAuthentication(bool needsAuth) {
    _needsAuthentication = needsAuth;
    notifyListeners();
  }

  void setAppInBackground(bool inBackground) {
    _isAppInBackground = inBackground;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    
    if (isLoggedIn) {
      _authState = AuthState.needsAuthentication;
    } else {
      _authState = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  void markAsAuthenticated() {
    _authState = AuthState.authenticated;
    _needsAuthentication = false;
    notifyListeners();
  }

  void logout() {
    _authState = AuthState.unauthenticated;
    _needsAuthentication = false;
    notifyListeners();
  }
}