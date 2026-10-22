class PasskeyService {
  static Future<bool> isAvailable() async => false;

  static Future<String> register(String optionsJson) {
    throw UnsupportedError('Device unlock is only available on web for now.');
  }

  static Future<String> authenticate(String optionsJson) {
    throw UnsupportedError('Device unlock is only available on web for now.');
  }
}
