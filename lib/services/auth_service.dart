import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// An error from the backend, carrying the HTTP status code so callers can
/// react to specific cases (e.g. an unverified account at login).
///
/// toString() returns just the message, so existing code that shows
/// e.toString() to the user keeps working unchanged.
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, {this.statusCode});

  /// True when login was refused because the account isn't verified yet.
  /// Matches the 403 the backend sends for that case (a 403 is also used
  /// for inactive accounts, so the message is checked as well).
  bool get isUnverified =>
      statusCode == 403 && message.toLowerCase().contains('verify');

  @override
  String toString() => message;
}

/// Handles HTTP calls to the FastAPI backend for the patient app.
///
/// Base URL notes:
/// - iOS simulator / macOS desktop / Chrome (web): http://127.0.0.1:8000
///   works as-is.
/// - Android emulator: use http://10.0.2.2:8000 instead -- localhost
///   there refers to the emulator itself, not your Mac.
/// - Physical device: use your Mac's LAN IP (e.g. http://192.168.x.x:8000),
///   with the phone on the same Wi-Fi network.
class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// The login token. Kept in memory while the app runs, and also saved
  /// to device storage (see restoreSession) so a refresh keeps the
  /// patient logged in.
  static String? accessToken;

  static bool get isLoggedIn => accessToken != null;

  /// The logged-in patient's first name, fetched right after login, for
  /// greetings like "Welcome, Ada". Null if unknown.
  static String? firstName;

  // The login token is saved on the device so a browser refresh or app
  // restart doesn't log the patient out. On web, shared_preferences
  // writes straight to the browser's Local Storage.
  static const _tokenKey = 'patient_access_token';

  static Future<void> logout() async {
    accessToken = null;
    firstName = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      // ignore: avoid_print
      print('AUTH STORAGE: could not clear saved login: $e');
    }
  }

  /// Called once at startup. Restores a saved login if the server still
  /// accepts the token. Returns true if the patient is logged in.
  static Future<bool> restoreSession() async {
    String? saved;
    try {
      final prefs = await SharedPreferences.getInstance();
      saved = prefs.getString(_tokenKey);
    } catch (e) {
      // ignore: avoid_print
      print('AUTH STORAGE: could not read saved login: $e');
      saved = null;
    }
    if (saved == null || saved.isEmpty) {
      return false;
    }

    accessToken = saved;
    try {
      final me = await getMe();
      final profile = me['profile'];
      firstName = (profile is Map) ? profile['first_name'] as String? : null;
      return true;
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        // Expired or invalid token: clear it and send them to log in.
        await logout();
        return false;
      }
      // Server unreachable or similar: keep the saved login rather than
      // forcing a logout because of a network blip.
      return true;
    }
  }

  /// Registers a new account. On success, returns a map containing
  /// email_code and phone_code -- these are SIMULATED verification codes
  /// (no real email/SMS provider is connected yet), meant to be shown
  /// on-screen during development. The user only needs to verify ONE of
  /// the two, their choice. Throws a String error message on failure.
  static Future<Map<String, dynamic>> register({
    required String email,
    required String phone,
    required String password,
    String? fullName,
    DateTime? dateOfBirth,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? address,
    String? city,
    String? bloodType,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? currentMedications,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'phone': phone,
      'password': password,
    };

    // Optional profile details -- only sent when filled in. When a name is
    // sent, the backend creates the patient profile together with the
    // account.
    if (fullName != null && fullName.trim().isNotEmpty) {
      body['full_name'] = fullName.trim();
    }
    if (dateOfBirth != null) {
      final mm = dateOfBirth.month.toString().padLeft(2, '0');
      final dd = dateOfBirth.day.toString().padLeft(2, '0');
      body['date_of_birth'] = '${dateOfBirth.year}-$mm-$dd';
    }
    if (emergencyContactName != null && emergencyContactName.trim().isNotEmpty) {
      body['emergency_contact_name'] = emergencyContactName.trim();
    }
    if (emergencyContactPhone != null &&
        emergencyContactPhone.trim().isNotEmpty) {
      body['emergency_contact_phone'] = emergencyContactPhone.trim();
    }
    if (address != null && address.trim().isNotEmpty) {
      body['address'] = address.trim();
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

  /// Verifies the account using ONE method -- 'email' or 'phone' -- with
  /// its corresponding code. Throws a String error message
  /// (e.g. "Incorrect verification code.") on failure.
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

  /// Requests new codes. Returns the new SIMULATED codes the same way
  /// register() does.
  static Future<Map<String, dynamic>> resendCodes({
    required String email,
  }) async {
    return await _post('/auth/resend-codes', {'email': email});
  }

  /// Logs in, returning the access token on success.
  /// Saves (creates or updates) the caller's health journey. Requires the
  /// user to be logged in -- accessToken must be set.
  static Future<void> saveHealthJourney({
    required String journeyType,
    required Map<String, dynamic> answers,
  }) async {
    await _authorizedPost('/health-journey/setup', {
      'journey_type': journeyType,
      'answers': answers,
    });
  }

  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    final token = response['access_token'] as String;
    accessToken = token;

    // Best-effort: fetch the first name for greetings. A failure here
    // must never block a successful login.
    try {
      final me = await getMe();
      final profile = me['profile'];
      firstName = (profile is Map) ? profile['first_name'] as String? : null;
    } catch (_) {
      firstName = null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      // If saving fails, the patient stays logged in for this session;
      // they just won't survive a refresh. Printed so it's never silent.
      // ignore: avoid_print
      print('AUTH STORAGE: could not save login: $e');
    }

    return token;
  }

  /// Same as _post, but attaches the logged-in user's token. Throws an
  /// AuthException immediately if no one is logged in, rather than sending
  /// a request that the backend would just reject as unauthenticated.
  static Future<Map<String, dynamic>> _authorizedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = accessToken;
    if (token == null) {
      throw AuthException('You need to be logged in to do that.');
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
    } catch (e) {
      throw AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    late http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      throw AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    return _handleResponse(response);
  }

  /// Shared response parsing, for endpoints that return a single JSON
  /// object (a Map). Delegates to _handleResponseRaw, which also backs
  /// the *Raw variants below for endpoints that return a JSON array
  /// instead (appointments, chat messages).
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = _handleResponseRaw(response);
    return (data is Map<String, dynamic>) ? data : {};
  }

  /// Same error handling as _handleResponse, but returns whatever JSON
  /// shape the backend actually sent -- a Map or a List -- instead of
  /// forcing a Map cast that would throw on a list response.
  static dynamic _handleResponseRaw(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = (data is Map) ? data['detail'] : null;
      throw AuthException(
        detail is String ? detail : 'Something went wrong. Please try again.',
        statusCode: response.statusCode,
      );
    }

    return data;
  }

  /// Same as _authorizedPost, but for endpoints that return a JSON array
  /// (e.g. /appointments, /chat/message) rather than a single object.
  static Future<dynamic> _authorizedGetRaw(String path) async {
    final token = accessToken;
    if (token == null) {
      throw AuthException('You need to be logged in to do that.');
    }

    late http.Response response;
    try {
      response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      throw AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    return _handleResponseRaw(response);
  }

  /// List-returning counterpart to _authorizedPost.
  static Future<dynamic> _authorizedPostRaw(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = accessToken;
    if (token == null) {
      throw AuthException('You need to be logged in to do that.');
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
    } catch (e) {
      throw AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    return _handleResponseRaw(response);
  }

  // ===========================================================
  // Appointments
  // ===========================================================

  /// The logged-in patient's own appointments, most recent first (the
  /// backend already sorts them that way).
  static Future<List<dynamic>> getMyAppointments() async {
    final data = await _authorizedGetRaw('/appointments');
    return (data is List) ? data : [];
  }

  /// Requests a new appointment. date is 'YYYY-MM-DD', time is 'HH:MM:SS'.
  static Future<void> requestAppointment({
    required String date,
    required String time,
    String? reason,
  }) async {
    await _authorizedPostRaw('/appointments/request', {
      'requested_date': date,
      'requested_time': time,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }

  // ===========================================================
  // Health journey
  // ===========================================================

  /// The patient's existing health journey (journey_type + answers), or
  /// null if they haven't set one up yet. A 404 here is the normal case
  /// for a brand-new patient, not an error -- everything else still
  /// throws.
  static Future<Map<String, dynamic>?> getExistingHealthJourney() async {
    try {
      final data = await _authorizedGetRaw('/health-journey/me');
      return (data is Map<String, dynamic>) ? data : null;
    } on AuthException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  // ===========================================================
  // Forgot password
  // ===========================================================
  //
  // Neither of these calls is authorized -- there's no token yet at
  // this point, since the whole reason we're here is the user can't
  // log in.

  /// Requests a reset code sent to 'email' or 'phone'. Returns a map
  /// with the SIMULATED code (see note on register() above -- no real
  /// email/SMS provider is connected yet) and, for the phone method,
  /// the phone number to display it against.
  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
    required String method,
  }) async {
    return await _post('/auth/request-password-reset', {
      'email': email,
      'method': method,
    });
  }

  /// Verifies the reset code and sets the new password. Throws an
  /// AuthException (e.g. "Incorrect reset code.") on failure.
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _post('/auth/reset-password', {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }

  // ===========================================================
  // Chat (Nia)
  // ===========================================================

  /// Sends a message and returns both the saved user message and the
  /// saved reply, as a 2-item list, in that order.
  static Future<List<dynamic>> sendChatMessage(String message) async {
    final data = await _authorizedPostRaw('/chat/message', {
      'message': message,
    });
    return (data is List) ? data : [];
  }

  /// Full conversation history, oldest first.
  static Future<List<dynamic>> getChatHistory() async {
    final data = await _authorizedGetRaw('/chat/messages');
    return (data is List) ? data : [];
  }

  // ===========================================================
  // Messages (Contact Doctor)
  // ===========================================================
  //
  // A real messaging thread with the practice's staff, separate from
  // Nia. Staff-side (viewing/replying across patients) isn't wired into
  // the admin portal yet -- these two methods cover the patient side
  // only.

  /// Sends a message into the patient's own thread with the practice.
  static Future<void> sendDoctorMessage(String message) async {
    await _authorizedPostRaw('/messages/send', {'message': message});
  }

  /// The patient's full message thread with the practice, oldest first.
  static Future<List<dynamic>> getMyMessageThread() async {
    final data = await _authorizedGetRaw('/messages/mine');
    return (data is List) ? data : [];
  }

  // ===========================================================
  // Own profile (Health Profile screen)
  // ===========================================================

  /// Account details plus the patient profile ('profile' is null for
  /// accounts without one).
  static Future<Map<String, dynamic>> getMe() async {
    final data = await _authorizedGetRaw('/auth/me');
    return (data is Map<String, dynamic>) ? data : {};
  }

  /// Saves edited profile fields. Only the keys included are changed.
  static Future<void> updateProfile(Map<String, dynamic> fields) async {
    await _authorizedPutRaw('/auth/me/profile', fields);
    if (fields['first_name'] is String) {
      firstName = fields['first_name'] as String;
    }
  }

  static Future<dynamic> _authorizedPutRaw(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = accessToken;
    if (token == null) {
      throw AuthException('You need to be logged in to do that.');
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
    } catch (e) {
      throw AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    return _handleResponseRaw(response);
  }

  // ===========================================================
  // Reminders
  // ===========================================================

  static Future<List<dynamic>> getReminders() async {
    final data = await _authorizedGetRaw('/reminders');
    return (data is List) ? data : [];
  }

  static Future<void> addReminder({
    required String title,
    String? notes,
    required DateTime remindAt,
  }) async {
    await _authorizedPostRaw('/reminders', {
      'title': title,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'remind_at': remindAt.toIso8601String(),
    });
  }

  static Future<void> setReminderDone(int id, bool isDone) async {
    await _authorizedPutRaw('/reminders/$id/done', {'is_done': isDone});
  }

  static Future<void> deleteReminder(int id) async {
    await _authorizedDeleteRaw('/reminders/$id');
  }

  // ===========================================================
  // Health articles (written by staff in the admin portal)
  // ===========================================================

  static Future<List<dynamic>> getArticles() async {
    final data = await _authorizedGetRaw('/articles');
    return (data is List) ? data : [];
  }

  static Future<dynamic> _authorizedDeleteRaw(String path) async {
    final token = accessToken;
    if (token == null) {
      throw AuthException('You need to be logged in to do that.');
    }

    late http.Response response;
    try {
      response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      throw AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    return _handleResponseRaw(response);
  }
}
