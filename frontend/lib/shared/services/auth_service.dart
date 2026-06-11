import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';

  final ApiClient _api;

  AuthService({ApiClient? apiClient, http.Client? client})
      : _api = apiClient ?? ApiClient(httpClient: client);

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
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
    await _saveLoginPreferences(email, rememberMe);
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

  /// Indica si la app debe abrir directamente el dashboard al iniciar.
  Future<bool> shouldAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.containsKey(_tokenKey);
    if (!hasToken) return false;

    final rememberMe = prefs.getBool(_rememberMeKey);
    // Sesiones previas sin preferencia explícita: mantener acceso automático.
    if (rememberMe == null) return true;
    if (!rememberMe) {
      await _clearSession(prefs);
      return false;
    }
    return true;
  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? true;
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedEmailKey);
  }

  Future<void> _saveLoginPreferences(String email, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);
    if (rememberMe) {
      await prefs.setString(_savedEmailKey, email);
    } else {
      await prefs.remove(_savedEmailKey);
    }
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final savedEmail = prefs.getString(_savedEmailKey);

    await prefs.clear();

    // Conserva solo el correo si el usuario quiere ser recordado.
    if (rememberMe) {
      await prefs.setBool(_rememberMeKey, true);
      if (savedEmail != null && savedEmail.isNotEmpty) {
        await prefs.setString(_savedEmailKey, savedEmail);
      }
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null) return null;
    try {
      return jsonDecode(userStr) as Map<String, dynamic>;
    } catch (_) {
      await prefs.remove(_userKey);
      return null;
    }
  }
}
