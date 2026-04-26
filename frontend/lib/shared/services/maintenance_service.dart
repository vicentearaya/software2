import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/maintenance.dart';

class MaintenanceService {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue:
        'https://software2-backend-hxe7f4b9dug6dqat.eastus2-01.azurewebsites.net',
  );

  /// Obtiene el historial de mantenciones del usuario.
  /// Sigue el patrón de retorno de otros servicios del proyecto.
  Future<Map<String, dynamic>> getMaintenanceHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mantenciones'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> list = responseData;
        final mantenciones = list
            .map((json) => Maintenance.fromJson(json))
            .toList();
        return {'success': true, 'data': mantenciones};
      } else {
        return {
          'success': false,
          'message':
              responseData['detail'] ??
              'Error al obtener el historial de mantenimiento',
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
