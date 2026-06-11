import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cleanpool_app/shared/services/auth_service.dart';

void main() {
  setUp(() {
    // Mock SharedPreferences para evitar errores de plataforma en tests unitarios
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Login Tests', () {
    test('login success returns token and saves to SharedPreferences', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({'access_token': 'dummy_valid_jwt_token_123'}),
            200,
          );
        }
        if (request.url.path.endsWith('/auth/me')) {
          return http.Response(
            jsonEncode({
              'username': 'tester',
              'email': 'test@test.com',
              'name': 'Tester',
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final authService = AuthService(client: mockClient);
      final result = await authService.login('test@test.com', 'password123');

      expect(result['success'], true);
      expect(result['data']['access_token'], 'dummy_valid_jwt_token_123');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      expect(token, 'dummy_valid_jwt_token_123');
    });

    test('login failure returns error message on 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
            jsonEncode({'detail': 'Credenciales incorrectas.'}), 401);
      });

      final authService = AuthService(client: mockClient);
      final result = await authService.login('test@test.com', 'wrongpassword');

      expect(result['success'], false);
      expect(result['message'], 'Credenciales incorrectas.');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('auth_token'), false);
    });

    test('login with rememberMe saves email and preference', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({'access_token': 'token_remember'}),
            200,
          );
        }
        if (request.url.path.endsWith('/auth/me')) {
          return http.Response(jsonEncode({'username': 'tester'}), 200);
        }
        return http.Response('{}', 404);
      });

      final authService = AuthService(client: mockClient);
      await authService.login('user@test.com', 'password123', rememberMe: true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('remember_me'), true);
      expect(prefs.getString('saved_email'), 'user@test.com');
      expect(await authService.shouldAutoLogin(), true);
    });

    test('login without rememberMe clears session on next startup', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({'access_token': 'token_temp'}),
            200,
          );
        }
        if (request.url.path.endsWith('/auth/me')) {
          return http.Response(jsonEncode({'username': 'tester'}), 200);
        }
        return http.Response('{}', 404);
      });

      final authService = AuthService(client: mockClient);
      await authService.login('user@test.com', 'password123', rememberMe: false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('remember_me'), false);
      expect(prefs.containsKey('saved_email'), false);

      expect(await authService.shouldAutoLogin(), false);
      expect(prefs.containsKey('auth_token'), false);
    });

    test('logout keeps saved email when rememberMe is active', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'token',
        'user_data': '{}',
        'remember_me': true,
        'saved_email': 'user@test.com',
      });

      final authService = AuthService();
      await authService.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('auth_token'), false);
      expect(prefs.getBool('remember_me'), true);
      expect(prefs.getString('saved_email'), 'user@test.com');
    });

    test('login network error handles exception correctly', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Network error');
      });

      final authService = AuthService(client: mockClient);
      final result = await authService.login('test@test.com', 'password123');

      expect(result['success'], false);
      expect(result['message'], 'No se pudo conectar al servidor');
    });
  });
}
