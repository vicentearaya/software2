import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  final ApiClient _api;

  AuthService({ApiClient? apiClient, http.Client? client})
      : _api = apiClient ?? ApiClient(httpClient: client);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post(
      '/auth/login',
      body: {'username': email, 'password': password},
    );
    if (response['success'] != true) {
      return response;
    }
    final data = response['data'] as Map<String, dynamic>;
    final token = data['access_token'] as String;

    Map<String, dynamic> userData = {};
    final me = await _api.get('/auth/me', token: token);
    if (me['success'] == true && me['data'] is Map<String, dynamic>) {
      userData = me['data'] as Map<String, dynamic>;
    }

    await _saveSession(token, userData);
    return {'success': true, 'data': data};
  }

  Future<Map<String, dynamic>> register(
    String name,
    String username,
    String email,
    String password,
  ) async {
    final response = await _api.post(
      '/auth/register',
      body: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      },
    );
    if (response['success'] != true) {
      return response;
    }
    final data = response['data'] as Map<String, dynamic>;
    await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>);
    return {'success': true, 'data': data};
  }

  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null) return null;
    return jsonDecode(userStr) as Map<String, dynamic>;
  }
}
