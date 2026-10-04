import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'admin_access_token';
  static const _roleKey = 'admin_role_id';


  static const List<int> staffRoleIds = [2, 3, 4];

  static Future<String?> login(String email, String password) async {
    final Uri url = Uri.parse('$baseUrl/auth/login');

    late http.Response response;
    try {
      response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
    } catch (e) {
      return 'Could not reach the server. Check your connection and try again.';
    }

    if (response.statusCode != 200) {
      final body = _tryDecode(response.body);
      final detail = body?['detail'];
      return detail is String ? detail : 'Login failed. Please try again.';
    }

    final data = _tryDecode(response.body);
    final token = data?['access_token'];
    if (token is! String) {
      return 'Unexpected response from server.';
    }

    final roleId = _decodeRoleFromToken(token);
    if (roleId == null || !staffRoleIds.contains(roleId)) {
      return 'This account does not have staff access to the admin portal.';
    }

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: roleId.toString());
    return null;
  }

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<int?> getRoleId() async {
    final stored = await _storage.read(key: _roleKey);
    return stored == null ? null : int.tryParse(stored);
  }

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
  }

  /// Authenticated GET request. Automatically attaches the stored token.
  static Future<http.Response> authorizedGet(String path) async {
    final token = await getToken();
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  /// Authenticated PUT request with a JSON body.
  static Future<http.Response> authorizedPut(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  /// Authenticated POST request with a JSON body.
  static Future<http.Response> authorizedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  /// Authenticated DELETE request.
  static Future<http.Response> authorizedDelete(String path) async {
    final token = await getToken();
    return http.delete(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }


  static int? _decodeRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      payload = payload.padRight(
        payload.length + (4 - payload.length % 4) % 4,
        '=',
      );

      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final roleId = map['role_id'];
      return roleId is int ? roleId : null;
    } catch (_) {
      return null;
    }
  }
}
