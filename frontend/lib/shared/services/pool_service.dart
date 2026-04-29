import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';

class PoolService {
  Future<Map<String, dynamic>> createPool(
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/piscinas'),
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

  Future<Map<String, dynamic>> updatePool(
    String poolId,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/piscinas/$poolId'),
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
        Uri.parse('${ApiConfig.baseUrl}/piscinas'),
        headers: {'Authorization': 'Bearer $token'},
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

  Future<Map<String, dynamic>> calcularYRegistrarTratamiento(
    String poolId,
    double ph,
    double cloro,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/piscinas/$poolId/tratamiento'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'ph': ph, 'cloro': cloro}),
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
      return {
        'success': false,
        'message': 'Houve um erro no cálculo. Compruebe la conexión.',
      };
    }
  }

  Future<Map<String, dynamic>> deletePool(String poolId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/piscinas/$poolId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Error al eliminar la piscina',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  Future<Map<String, dynamic>> getPoolStatus(
    String poolId, {
    String? token,
  }) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/pools/$poolId/status'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message':
              responseData['detail'] ??
              'Error al obtener el estado de la piscina',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  Future<Map<String, dynamic>> bindDeviceToPool({
    required String deviceId,
    required String poolId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/device/bind'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'device_id': deviceId, 'pool_id': poolId}),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      }
      return {
        'success': false,
        'message':
            responseData['detail'] ?? 'No se pudo vincular el dispositivo',
      };
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  Future<Map<String, dynamic>> unbindDeviceFromPool({
    required String deviceId,
    required String poolId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/device/unbind'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'device_id': deviceId, 'pool_id': poolId}),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      }
      return {
        'success': false,
        'message':
            responseData['detail'] ?? 'No se pudo desvincular el dispositivo',
      };
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  Future<Map<String, dynamic>> getDeviceBinding({
    required String deviceId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/device/$deviceId/binding'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      }
      return {
        'success': false,
        'message':
            responseData['detail'] ??
            'No se pudo consultar el estado del dispositivo',
      };
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  Future<Map<String, dynamic>> getDeviceStatus({
    required String deviceId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/device/$deviceId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      }
      return {
        'success': false,
        'message':
            responseData['detail'] ??
            'No se pudo consultar el estado del dispositivo',
      };
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }
}
