import 'dart:convert';
import 'package:http/http.dart' as http;

class PoolService {
  static const String _baseUrl = 'http://localhost:8000';

  Future<Map<String, dynamic>> createPool(Map<String, dynamic> data, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/piscinas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Error al registrar la piscina',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  Future<Map<String, dynamic>> getPools(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/piscinas'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Error al obtener piscinas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }
}
