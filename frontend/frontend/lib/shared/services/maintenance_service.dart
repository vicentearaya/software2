import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';
import '../../models/maintenance.dart';

class MaintenanceService {
  /// Obtiene el historial de mantenciones del usuario.
  /// Sigue el patrón de retorno de otros servicios del proyecto.
  Future<Map<String, dynamic>> getMaintenanceHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mantenciones/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> list = responseData;
        final mantenciones = list
            .map((json) => Maintenance.fromJson(json))
            .toList();
        return {'success': true, 'data': mantenciones};
      } else {
        String defaultMessage = 'Error al obtener el historial de mantenimiento';
        dynamic responseData;
        try {
          responseData = jsonDecode(response.body);
        } catch (_) {
          responseData = null;
        }
        return {
          'success': false,
          'message': responseData is Map<String, dynamic>
              ? (responseData['detail'] ?? defaultMessage)
              : '$defaultMessage (HTTP ${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: No se pudo obtener el historial.',
      };
    }
  }
}
