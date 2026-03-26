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
        expect(request.url.path, '/auth/login');
        return http.Response(
            jsonEncode({'access_token': 'dummy_valid_jwt_token_123'}), 200);
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
