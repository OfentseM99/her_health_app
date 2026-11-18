import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// An error from the backend, carrying the HTTP status code so callers can
/// react to specific cases (e.g. an unverified account at login).
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, {this.statusCode});

  bool get isUnverified =>
      statusCode == 403 && message.toLowerCase().contains('verify');

  @override
  String toString() => message;
}

/// Handles HTTP calls to the FastAPI backend for the patient app.
class AuthService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String? accessToken;

  static bool get isLoggedIn => accessToken != null;

  static String? firstName;

  static const _tokenKey = 'patient_access_token';
  static const _biometricEnabledKey = 'patient_biometric_enabled';

  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static Future<bool> isBiometricUnlockEnabled() async {
    return await _secureStorage.read(key: _biometricEnabledKey) == 'true';
  }

  static Future<bool> enableBiometricUnlock() async {
    final token = accessToken;

    if (token == null || token.isEmpty) {
      throw AuthException('Please log in before enabling device unlock.');
    }

    final localAuth = LocalAuthentication();
    final biometrics = await localAuth.getAvailableBiometrics();

    if (biometrics.isEmpty) return false;

    final authenticated = await localAuth.authenticate(
      localizedReason:
          'Verify your identity to enable Her Health device unlock.',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );

    if (!authenticated) return false;

    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _biometricEnabledKey, value: 'true');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);

    return true;
  }

  static Future<bool> authenticateBiometricSession() async {
    if (!await isBiometricUnlockEnabled()) return false;

    final localAuth = LocalAuthentication();
    final authenticated = await localAuth.authenticate(
      localizedReason: 'Authenticate to access your Her Health account.',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );

    if (!authenticated) return false;

    final token = await _secureStorage.read(key: _tokenKey);

    if (token == null || token.isEmpty) {
      await _secureStorage.delete(key: _biometricEnabledKey);
      return false;
    }

    accessToken = token;

    try {
      final me = await getMe();
      final profile = me['profile'];
      firstName = (profile is Map) ? profile['first_name'] as String? : null;
      return true;
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        accessToken = null;
        firstName = null;
        await _secureStorage.delete(key: _tokenKey);
        await _secureStorage.delete(key: _biometricEnabledKey);
        return false;
      }
      rethrow;
    }
  }

  // ===========================================================
  // Session
  // ===========================================================

  static Future<void> logout() async {
    accessToken = null;
    firstName = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {}

    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
    } catch (_) {}
  }

  static Future<bool> restoreSession() async {
    if (await isBiometricUnlockEnabled()) return false;

    String? saved;

    try {
      final prefs = await SharedPreferences.getInstance();
      saved = prefs.getString(_tokenKey);
    } catch (_) {
      saved = null;
    }

    if (saved == null || saved.isEmpty) return false;

    accessToken = saved;

    try {
      final me = await getMe();
      final profile = me['profile'];
      firstName = (profile is Map) ? profile['first_name'] as String? : null;
      return true;
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await logout();
        return false;
      }
      return true;
    }
  }

  static Future<void> _saveAccessToken(String token) async {
    accessToken = token;

    try {
      if (await isBiometricUnlockEnabled()) {
        await _secureStorage.write(key: _tokenKey, value: token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
      }
    } catch (_) {}

    try {
      final me = await getMe();
      final profile = me['profile'];
      firstName = (profile is Map) ? profile['first_name'] as String? : null;
    } catch (_) {
      firstName = null;
    }
  }

  // ===========================================================
  // Registration
  // ===========================================================

  static Future<Map<String, dynamic>> register({
    required String email,
    required String phone,
    required String password,
    String? fullName,
    DateTime? dateOfBirth,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? address,
    String? province,
    String? city,
    String? bloodType,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? currentMedications,
    bool acceptedPrivacy = false,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'phone': phone,
      'password': password,
      'accepted_privacy': acceptedPrivacy,
    };

    if (fullName != null && fullName.trim().isNotEmpty) {
      body['full_name'] = fullName.trim();
    }

    if (dateOfBirth != null) {
      final mm = dateOfBirth.month.toString().padLeft(2, '0');
      final dd = dateOfBirth.day.toString().padLeft(2, '0');

      body['date_of_birth'] = '${dateOfBirth.year}-$mm-$dd';
    }

    if (emergencyContactName != null &&
        emergencyContactName.trim().isNotEmpty) {
      body['emergency_contact_name'] = emergencyContactName.trim();
    }

    if (emergencyContactPhone != null &&
        emergencyContactPhone.trim().isNotEmpty) {
      body['emergency_contact_phone'] = emergencyContactPhone.trim();
    }

    if (address != null && address.trim().isNotEmpty) {
      body['address'] = address.trim();
    }

    if (province != null && province.trim().isNotEmpty) {
      body['province'] = province.trim();
    }

    if (city != null && city.trim().isNotEmpty) {
      body['city'] = city.trim();
    }

    if (bloodType != null && bloodType.trim().isNotEmpty) {
      body['blood_type'] = bloodType.trim();
    }

    if (allergies != null && allergies.isNotEmpty) {
      body['allergies'] = allergies;
    }

    if (medicalConditions != null && medicalConditions.isNotEmpty) {
      body['medical_conditions'] = medicalConditions;
    }

    if (currentMedications != null && currentMedications.isNotEmpty) {
      body['current_medications'] = currentMedications;
    }

    return await _post('/auth/register', body);
  }

  static Future<void> verify({
    required String email,
    required String method,
    required String code,
  }) async {
    await _post('/auth/verify', {
      'email': email,
      'method': method,
      'code': code,
    });
  }

  static Future<Map<String, dynamic>> resendCodes({
    required String email,
  }) async {
    return await _post(
      '/auth/resend-codes',
      {'email': email},
    );
  }

  // ===========================================================
  // Password login
  // ===========================================================

  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '/auth/login',
      {
        'email': email,
        'password': password,
      },
    );

    final token = response['access_token'] as String;

    await _saveAccessToken(token);

    return token;
  }

  // ===========================================================
  // Passkeys / device unlock
  // ===========================================================

  /// Starts registration of Face ID, Touch ID, fingerprint or device PIN.
  ///
  /// The patient must already be logged in normally.
  static Future<Map<String, dynamic>> beginPasskeyRegistration({
    String portal = 'patient',
  }) async {
    final data = await _authorizedPostRaw(
      '/auth/passkeys/register/options',
      {
        'portal': portal,
      },
    );

    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Completes registration after the browser/device returns its credential.
  static Future<Map<String, dynamic>> finishPasskeyRegistration({
    required Map<String, dynamic> credential,
    String? deviceName,
    String portal = 'patient',
  }) async {
    final data = await _authorizedPostRaw(
      '/auth/passkeys/register/verify',
      {
        'portal': portal,
        'credential': credential,
        if (deviceName != null && deviceName.trim().isNotEmpty)
          'device_name': deviceName.trim(),
      },
    );

    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Requests the WebAuthn challenge/options needed to log in using
  /// the device's Face ID, Touch ID, fingerprint or PIN.
  static Future<Map<String, dynamic>> beginPasskeyLogin({
    required String email,
    String portal = 'patient',
  }) async {
    return await _post(
      '/auth/passkeys/login/options',
      {
        'email': email,
        'portal': portal,
      },
    );
  }

  /// Verifies the device credential and stores the returned JWT just like
  /// normal password login.
  static Future<String> finishPasskeyLogin({
    required String email,
    required Map<String, dynamic> credential,
    String portal = 'patient',
  }) async {
    final response = await _post(
      '/auth/passkeys/login/verify',
      {
        'email': email,
        'portal': portal,
        'credential': credential,
      },
    );

    final token = response['access_token'] as String;

    await _saveAccessToken(token);

    return token;
  }

  // ===========================================================
  // Health journey
  // ===========================================================

  static Future<void> saveHealthJourney({
    required String journeyType,
    required Map<String, dynamic> answers,
  }) async {
    await _authorizedPost(
      '/health-journey/setup',
      {
        'journey_type': journeyType,
        'answers': answers,
      },
    );
  }

  static Future<Map<String, dynamic>?> getHealthJourney() async {
    try {
      final data = await _authorizedGetRaw('/health-journey/me');

      return data is Map<String, dynamic> ? data : null;
    } on AuthException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getExistingHealthJourney() async {
    try {
      final data = await _authorizedGetRaw('/health-journey/me');

      return data is Map<String, dynamic> ? data : null;
    } on AuthException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }

  static Future<List<dynamic>> getHealthJourneyHistory() async {
    final data = await _authorizedGetRaw('/health-journey/history');

    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> activateHealthJourney(
    int journeyId,
  ) async {
    final data = await _authorizedPostRaw(
      '/health-journey/$journeyId/activate',
      {},
    );

    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  // ===========================================================
  // Health tracking
  // ===========================================================

  static Future<List<dynamic>> getHealthTrackingEntries({
    int? journeyId,
  }) async {
    final path = journeyId == null
        ? '/health-journey/entries'
        : '/health-journey/entries?journey_id=$journeyId';

    final data = await _authorizedGetRaw(path);

    return data is List ? data : [];
  }

  static Future<void> saveHealthTrackingEntry({
    required String entryDate,
    String? painLevel,
    String? mood,
    required Map<String, dynamic> data,
  }) async {
    await _authorizedPostRaw(
      '/health-journey/entries',
      {
        'entry_date': entryDate,
        'pain_level': painLevel,
        'mood': mood,
        'data': data,
      },
    );
  }
  // ===========================================================
  // Appointments
  // ===========================================================

  static Future<List<dynamic>> getMyAppointments() async {
    final data = await _authorizedGetRaw('/appointments');

    return data is List ? data : [];
  }

  static Future<void> requestAppointment({
    required String date,
    required String time,
    String? reason,
  }) async {
    await _authorizedPostRaw(
      '/appointments/request',
      {
        'requested_date': date,
        'requested_time': time,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  // ===========================================================
  // Forgot password
  // ===========================================================

  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
    required String method,
  }) async {
    return await _post(
      '/auth/request-password-reset',
      {
        'email': email,
        'method': method,
      },
    );
  }

  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _post(
      '/auth/reset-password',
      {
        'email': email,
        'code': code,
        'new_password': newPassword,
      },
    );
  }

  // ===========================================================
  // Chat / Nia
  // ===========================================================

  static Future<List<dynamic>> getNiaTopics() async {
    final data = await _authorizedGetRaw('/chat/topics');
    return data is List ? data : [];
  }

  static Future<List<dynamic>> sendChatMessage(
    String message,
  ) async {
    final data = await _authorizedPostRaw(
      '/chat/message',
      {'message': message},
    );

    return data is List ? data : [];
  }

  static Future<List<dynamic>> getChatHistory() async {
    final data = await _authorizedGetRaw(
      '/chat/messages',
    );

    return data is List ? data : [];
  }

  // ===========================================================
  // Messages / Contact Doctor
  // ===========================================================

  static Future<void> sendDoctorMessage(
    String message,
  ) async {
    await _authorizedPostRaw(
      '/messages/send',
      {'message': message},
    );
  }

  static Future<List<dynamic>> getMyMessageThread() async {
    final data = await _authorizedGetRaw(
      '/messages/mine',
    );

    return data is List ? data : [];
  }

  // ===========================================================
  // Patient profile
  // ===========================================================

  static Future<Map<String, dynamic>> getMe() async {
    final data = await _authorizedGetRaw('/auth/me');

    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  static Future<void> updateProfile(
    Map<String, dynamic> fields,
  ) async {
    await _authorizedPutRaw(
      '/auth/me/profile',
      fields,
    );

    if (fields['first_name'] is String) {
      firstName = fields['first_name'] as String;
    }
  }

  // ===========================================================
  // Reminders
  // ===========================================================

  static Future<List<dynamic>> getReminders() async {
    final data = await _authorizedGetRaw('/reminders');

    return data is List ? data : [];
  }

  static Future<void> addReminder({
    required String title,
    String? notes,
    required DateTime remindAt,
  }) async {
    await _authorizedPostRaw(
      '/reminders',
      {
        'title': title,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'remind_at': remindAt.toIso8601String(),
      },
    );
  }

  static Future<void> setReminderDone(
    int id,
    bool isDone,
  ) async {
    await _authorizedPutRaw(
      '/reminders/$id/done',
      {
        'is_done': isDone,
      },
    );
  }

  static Future<void> deleteReminder(
    int id,
  ) async {
    await _authorizedDeleteRaw(
      '/reminders/$id',
    );
  }

  // ===========================================================
  // Billing
  // ===========================================================

  static Future<List<dynamic>> getMyBills() async {
    final data = await _authorizedGetRaw('/billing/me');

    return data is List ? data : [];
  }

  // ===========================================================
  // Articles
  // ===========================================================

  static Future<List<dynamic>> getArticles() async {
    final data = await _authorizedGetRaw('/articles');

    return data is List ? data : [];
  }

  // ===========================================================
  // POPIA / patient data rights
  // ===========================================================

  static Future<Map<String, dynamic>> exportMyData() async {
    final data = await _authorizedGetRaw(
      '/auth/me/export',
    );

    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  static Future<void> deleteMyAccount(
    String password,
  ) async {
    await _authorizedPostRaw(
      '/auth/me/delete',
      {
        'password': password,
      },
    );
  }

  // ===========================================================
  // HTTP helpers
  // ===========================================================

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    late http.Response response;

    try {
      response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    } catch (_) {
      throw AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _authorizedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final data = await _authorizedPostRaw(
      path,
      body,
    );

    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  static Future<dynamic> _authorizedPostRaw(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = accessToken;

    if (token == null) {
      throw AuthException(
        'You need to be logged in to do that.',
      );
    }

    late http.Response response;

    try {
      response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
    } catch (_) {
      throw AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    return _handleResponseRaw(response);
  }

  static Future<dynamic> _authorizedGetRaw(
    String path,
  ) async {
    final token = accessToken;

    if (token == null) {
      throw AuthException(
        'You need to be logged in to do that.',
      );
    }

    late http.Response response;

    try {
      response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {
      throw AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    return _handleResponseRaw(response);
  }

  static Future<dynamic> _authorizedPutRaw(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = accessToken;

    if (token == null) {
      throw AuthException(
        'You need to be logged in to do that.',
      );
    }

    late http.Response response;

    try {
      response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
    } catch (_) {
      throw AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    return _handleResponseRaw(response);
  }

  static Future<dynamic> _authorizedDeleteRaw(
    String path,
  ) async {
    final token = accessToken;

    if (token == null) {
      throw AuthException(
        'You need to be logged in to do that.',
      );
    }

    late http.Response response;

    try {
      response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {
      throw AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    return _handleResponseRaw(response);
  }

  static Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    final data = _handleResponseRaw(response);

    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  static dynamic _handleResponseRaw(
    http.Response response,
  ) {
    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map ? data['detail'] : null;

      throw AuthException(
        detail is String ? detail : 'Something went wrong. Please try again.',
        statusCode: response.statusCode,
      );
    }

    return data;
  }
}
