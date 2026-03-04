import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on device
  static Future<bool> isAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate using biometric or device credentials
  static Future<BiometricAuthResult> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = true,
  }) async {
    try {
      // Check if biometric is available
      final bool isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        return BiometricAuthResult(
          success: false,
          message: 'Biometric authentication not available on this device',
          errorCode: 'NOT_AVAILABLE',
        );
      }

      // Attempt authentication
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly, // Only allow biometric authentication
        ),
      );

      if (authenticated) {
        return BiometricAuthResult(
          success: true,
          message: 'Authentication successful',
        );
      } else {
        return BiometricAuthResult(
          success: false,
          message: 'Authentication failed',
          errorCode: 'AUTH_FAILED',
        );
      }
    } on PlatformException catch (e) {
      // Handle specific error cases
      String message;
      String errorCode = e.code;

      switch (e.code) {
        case auth_error.notAvailable:
          message = 'Biometric authentication not available';
          break;
        case auth_error.notEnrolled:
          message = 'No biometric credentials enrolled. Please set up biometric authentication in device settings.';
          break;
        case auth_error.lockedOut:
          message = 'Too many failed attempts. Please try again later.';
          break;
        case auth_error.permanentlyLockedOut:
          message = 'Biometric authentication is permanently locked. Please use device PIN.';
          break;
        case 'PasscodeNotSet':
          message = 'Please set up a passcode on your device';
          break;
        default:
          message = e.message ?? 'Authentication error occurred';
      }

      return BiometricAuthResult(
        success: false,
        message: message,
        errorCode: errorCode,
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
        errorCode: 'UNKNOWN',
      );
    }
  }

  /// Stop authentication (if in progress)
  static Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      // Ignore errors when stopping
    }
  }
}

/// Result of biometric authentication
class BiometricAuthResult {
  final bool success;
  final String message;
  final String? errorCode;

  BiometricAuthResult({
    required this.success,
    required this.message,
    this.errorCode,
  });

  bool get isNotAvailable => errorCode == 'NOT_AVAILABLE' || errorCode == auth_error.notAvailable;
  bool get isNotEnrolled => errorCode == auth_error.notEnrolled;
  bool get isLockedOut => errorCode == auth_error.lockedOut || errorCode == auth_error.permanentlyLockedOut;
}
