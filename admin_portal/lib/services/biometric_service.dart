import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Checks whether this device has usable enrolled biometrics.
  static Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;

      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;

      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Requests fingerprint or face authentication.
  /// Device PIN/password fallback is deliberately disabled.
  static Future<bool> authenticate({
    String reason = 'Authenticate to unlock Her Health.',
  }) async {
    return _auth.authenticate(
      localizedReason: reason,
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
  }
}