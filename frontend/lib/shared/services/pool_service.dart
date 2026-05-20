import 'package:http/http.dart' as http;

import '../../core/network/api_client.dart';

class PoolService {
  final ApiClient _api;

  PoolService({ApiClient? apiClient, http.Client? client})
      : _api = apiClient ?? ApiClient(httpClient: client);

  Future<Map<String, dynamic>> createPool(
    Map<String, dynamic> data,
    String token,
  ) async {
    return _api.post('/piscinas', body: data, token: token);
  }

  Future<Map<String, dynamic>> updatePool(
    String poolId,
    Map<String, dynamic> data,
    String token,
  ) async {
    return _api.put('/piscinas/$poolId', body: data, token: token);
  }

  Future<Map<String, dynamic>> getPools(String token) async {
    return _api.get('/piscinas', token: token);
  }

  Future<Map<String, dynamic>> calcularYRegistrarTratamiento(
    String poolId,
    double ph,
    double cloro,
    String token,
  ) async {
    return _api.post(
      '/piscinas/$poolId/tratamiento',
      body: {'ph': ph, 'cloro': cloro},
      token: token,
    );
  }

  Future<Map<String, dynamic>> deletePool(String poolId, String token) async {
    return _api.delete('/piscinas/$poolId', token: token);
  }

  /// Estado del agua (vía unificada autenticada).
  Future<Map<String, dynamic>> getPoolStatus(
    String poolId, {
    String? token,
  }) async {
    return _api.get('/piscinas/$poolId/status', token: token);
  }

  Future<Map<String, dynamic>> bindDeviceToPool({
    required String deviceId,
    required String poolId,
    required String token,
  }) async {
    return _api.post(
      '/api/v1/device/bind',
      body: {'device_id': deviceId, 'pool_id': poolId},
      token: token,
    );
  }

  Future<Map<String, dynamic>> unbindDeviceFromPool({
    required String deviceId,
    required String poolId,
    required String token,
  }) async {
    return _api.post(
      '/api/v1/device/unbind',
      body: {'device_id': deviceId, 'pool_id': poolId},
      token: token,
    );
  }

  Future<Map<String, dynamic>> getDeviceBinding({
    required String deviceId,
    required String token,
  }) async {
    return _api.get('/api/v1/device/$deviceId/binding', token: token);
  }

  Future<Map<String, dynamic>> getDeviceStatus({
    required String deviceId,
    required String token,
  }) async {
    return _api.get('/api/v1/device/$deviceId/status', token: token);
  }
}
