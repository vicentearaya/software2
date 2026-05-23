import 'package:http/http.dart' as http;

import '../../core/network/api_client.dart';

/// Inventario remoto (`GET/POST/DELETE /inventario`, ajustes `.../agregar`, `.../usar`).
/// Respuestas siguen el contrato de [ApiClient]: `success`, `data`, `message`.
class InventoryService {
  final ApiClient _api;

  InventoryService({ApiClient? apiClient, http.Client? client})
      : _api = apiClient ?? ApiClient(httpClient: client);

  Future<Map<String, dynamic>> getItems(String token) async {
    return _api.get('/inventario', token: token);
  }

  /// Catálogo de productos (mismos que la calculadora de tratamiento).
  Future<Map<String, dynamic>> getCatalog(String token) async {
    return _api.get('/productos/catalogo', token: token);
  }

  Future<Map<String, dynamic>> createItem({
    required Map<String, dynamic> body,
    required String token,
  }) async {
    return _api.post('/inventario', body: body, token: token);
  }

  Future<Map<String, dynamic>> addStock({
    required String itemId,
    required double cantidad,
    required String token,
  }) async {
    return _api.post(
      '/inventario/$itemId/agregar',
      body: {'cantidad': cantidad},
      token: token,
    );
  }

  Future<Map<String, dynamic>> useStock({
    required String itemId,
    required double cantidad,
    required String token,
  }) async {
    return _api.post(
      '/inventario/$itemId/usar',
      body: {'cantidad': cantidad},
      token: token,
    );
  }

  Future<Map<String, dynamic>> deleteItem({
    required String itemId,
    required String token,
  }) async {
    return _api.delete('/inventario/$itemId', token: token);
  }
}
