import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:8000';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Login - MOCK temporal, reemplazar cuando el backend esté corriendo
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return {'success': true, 'data': {}};

    // TODO: descomentar cuando el backend esté corriendo
    // try {
    //   final response = await http.post(
    //     Uri.parse('$_baseUrl/auth/login'),
    //     headers: {'Content-Type': 'application/json'},
    //     body: jsonEncode({'username': email, 'password': password}),
    //   );
    //   final data = jsonDecode(response.body);
    //   if (response.statusCode == 200) {
    //     await _saveSession(data['access_token'], {});
    //     return {'success': true, 'data': data};
    //   } else {
    //     return {'success': false, 'message': data['detail'] ?? 'Error al iniciar sesión'};
    //   }
    // } catch (e) {
    //   return {'success': false, 'message': 'No se pudo conectar al servidor'};
    // }
  }

  // Registro
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await _saveSession(data['token'], data['user']);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Error al crear cuenta',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  // Guardar sesión
  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // Verificar si hay sesión activa
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Obtener token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Obtener usuario guardado
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }
}
