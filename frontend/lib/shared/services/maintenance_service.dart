import 'package:http/http.dart' as http;

import '../../core/network/api_client.dart';
import '../../models/maintenance.dart';

class MaintenanceService {
  final ApiClient _api;

  MaintenanceService({ApiClient? apiClient, http.Client? client})
      : _api = apiClient ?? ApiClient(httpClient: client);

  Future<Map<String, dynamic>> getMaintenanceHistory(String token) async {
    final response = await _api.get('/mantenciones/', token: token);
    if (response['success'] != true) {
      return response;
    }
    final raw = response['data'];
    if (raw is! List) {
      return {
        'success': false,
        'message': 'Respuesta inválida del servidor al obtener el historial.',
      };
    }
    final mantenciones = raw
        .map((json) => Maintenance.fromJson(json as Map<String, dynamic>))
        .toList();
    return {'success': true, 'data': mantenciones};
  }
}
