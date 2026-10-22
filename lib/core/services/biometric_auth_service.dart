import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  BiometricAuthService._();

  static const String biometricEnabledKey = 'biometric_enabled';

  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      final supported = await isDeviceSupported();
      if (!supported) return false;
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(biometricEnabledKey) ?? false;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(biometricEnabledKey, enabled);
  }

  static Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('sessionToken');
    final userData = prefs.getString('userData');
    return token != null &&
        token.isNotEmpty &&
        userData != null &&
        userData.isNotEmpty;
  }

  static Future<bool> authenticate({
    required String reason,
    bool biometricOnly = true,
  }) async {
    if (kIsWeb) return true;

    try {
      final canUse = await canCheckBiometrics();
      if (!canUse) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
      );
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.systemCanceled ||
          e.code == LocalAuthExceptionCode.timeout ||
          e.code == LocalAuthExceptionCode.temporaryLockout ||
          e.code == LocalAuthExceptionCode.biometricLockout ||
          e.code == LocalAuthExceptionCode.noBiometricsEnrolled ||
          e.code == LocalAuthExceptionCode.noCredentialsSet ||
          e.code == LocalAuthExceptionCode.noBiometricHardware) {
        return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Prompts biometric only when the user has enabled it in settings.
  static Future<bool> authenticateIfEnabled({
    required String reason,
  }) async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return true;
    return authenticate(reason: reason);
  }

  static Future<bool> enableBiometric() async {
    final canUse = await canCheckBiometrics();
    if (!canUse) return false;

    final authenticated = await authenticate(
      reason: 'Verify your identity to enable biometric login',
    );
    if (!authenticated) return false;

    await setBiometricEnabled(true);
    return true;
  }

  static Future<bool> disableBiometric() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return true;

    final authenticated = await authenticate(
      reason: 'Verify your identity to disable biometric login',
    );
    if (!authenticated) return false;

    await setBiometricEnabled(false);
    return true;
  }

  /// Clears session data while preserving remember-me and biometric preferences.
  static Future<void> clearSessionPreservingPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final biometricEnabled = prefs.getBool(biometricEnabledKey) ?? false;

    await prefs.clear();

    if (rememberMe) {
      await prefs.setString('saved_email', savedEmail ?? '');
      await prefs.setString('saved_password', savedPassword ?? '');
      await prefs.setBool('remember_me', true);
    }
    if (biometricEnabled) {
      await prefs.setBool(biometricEnabledKey, true);
    }
  }
}
