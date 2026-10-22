import 'dart:js_interop';

@JS('herHealthPasskeys.isAvailable')
external JSPromise<JSBoolean> _isAvailable();

@JS('herHealthPasskeys.register')
external JSPromise<JSString> _register(JSString optionsJson);

@JS('herHealthPasskeys.authenticate')
external JSPromise<JSString> _authenticate(JSString optionsJson);

class PasskeyService {
  static Future<bool> isAvailable() async {
    final result = await _isAvailable().toDart;
    return result.toDart;
  }

  static Future<String> register(String optionsJson) async {
    final result = await _register(optionsJson.toJS).toDart;
    return result.toDart;
  }

  static Future<String> authenticate(String optionsJson) async {
    final result = await _authenticate(optionsJson.toJS).toDart;
    return result.toDart;
  }
}
