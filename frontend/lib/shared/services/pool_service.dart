import 'dart:convert';
import 'package:http/http.dart' as http;

class PoolService {
  static const String _baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://software2-backend-hxe7f4b9dug6dqat.eastus2-01.azurewebsites.net');

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

  Future<Map<String, dynamic>> updatePool(String poolId, Map<String, dynamic> data, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/piscinas/$poolId'),
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
          'message': responseData['detail'] ?? 'Error al actualizar la piscina',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  Future<Map<String, dynamic>> getPools(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pools'),  // ✅ Nuevo endpoint simplificado
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

  /// ✅ NUEVO: Obtener una piscina específica por ID
  Future<Map<String, dynamic>> getPoolById(String poolId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pools/$poolId'),  // ✅ Nuevo endpoint GET /pools/{pool_id}
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Piscina no encontrada o no tienes acceso',
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Error al obtener la piscina',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  Future<Map<String, dynamic>> calcularYRegistrarTratamiento(String poolId, double ph, double cloro, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/piscinas/$poolId/tratamiento'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ph': ph,
          'cloro': cloro,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Error al calcular la receta',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Houve um erro no cálculo. Compruebe la conexión.'};
    }
  }
}
