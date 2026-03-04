import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen_new.dart';
import '../screens/user_dashboard_new.dart';
import '../screens/verifier_use_case_screen.dart';
import '../widgets/lock_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialAuthState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App went to background - require authentication on resume
      context.read<AuthProvider>().setNeedsAuthentication(true);
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground - check if authentication is needed
      final authProvider = context.read<AuthProvider>();
      if (authProvider.needsAuthentication) {
        authProvider.setAuthState(AuthState.needsAuthentication);
      }
    }
  }

  Future<void> _checkInitialAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(keyIsLoggedIn) ?? false;
    
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    
    if (isLoggedIn) {
      // User is logged in, but we need to authenticate
      authProvider.setAuthState(AuthState.needsAuthentication);
    } else {
      // User is not logged in
      authProvider.setAuthState(AuthState.unauthenticated);
    }
  }

  void _handleAuthenticationSuccess() {
    final authProvider = context.read<AuthProvider>();
    authProvider.setAuthState(AuthState.authenticated);
    authProvider.setNeedsAuthentication(false);
  }

  void _handleLogout() {
    final authProvider = context.read<AuthProvider>();
    authProvider.setAuthState(AuthState.unauthenticated);
    authProvider.setNeedsAuthentication(false);
    
    SharedPreferences.getInstance().then((prefs) => prefs.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.authState) {
          case AuthState.unauthenticated:
            return const LoginScreenNew();
          
          case AuthState.needsAuthentication:
            return LockScreen(
              onAuthenticationSuccess: _handleAuthenticationSuccess,
            );
          
          case AuthState.authenticated:
            return _buildAuthenticatedContent();
        }
      },
    );
  }

  Widget _buildAuthenticatedContent() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final prefs = snapshot.data!;
        final role = prefs.getString(keyRole);
        final userId = prefs.getString(keyUserId);
        final name = prefs.getString(keyName);

        if (role == 'user' && userId != null && name != null) {
          return UserDashboardNew(userId: userId, name: name);
        } else if (role == 'verifier' && userId != null && name != null) {
          return VerifierUseCaseScreen(verifierId: userId, name: name);
        } else {
          // Invalid state, logout
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleLogout();
          });
          return const LoginScreenNew();
        }
      },
    );
  }
}