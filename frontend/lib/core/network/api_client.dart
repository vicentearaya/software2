import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';

/// Respuesta de error homogénea (mensajes en español para la UI).
class ApiClientException implements Exception {
  ApiClientException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Cliente HTTP común: base URL, cabeceras JSON y manejo de `detail` del backend.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  String get baseUrl => ApiConfig.baseUrl;

  Map<String, String> jsonHeaders({String? token}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  dynamic _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String messageFromResponse(dynamic decoded, String fallback) {
    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      final d = decoded['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty) {
        final first = d.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
      }
    }
    return fallback;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('$baseUrl${_normalizePath(path)}');
    final headers = {...jsonHeaders(token: token), ...?extraHeaders};
    try {
      final res = await _http.get(uri, headers: headers);
      final decoded = _decode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': decoded};
      }
      return {
        'success': false,
        'message': messageFromResponse(
          decoded,
          'No se pudo completar la solicitud (HTTP ${res.statusCode}).',
        ),
      };
    } catch (_) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('$baseUrl${_normalizePath(path)}');
    final headers = {...jsonHeaders(token: token), ...?extraHeaders};
    try {
      final res = await _http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      final decoded = _decode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': decoded};
      }
      return {
        'success': false,
        'message': messageFromResponse(
          decoded,
          'No se pudo completar la solicitud (HTTP ${res.statusCode}).',
        ),
      };
    } catch (_) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('$baseUrl${_normalizePath(path)}');
    final headers = {...jsonHeaders(token: token), ...?extraHeaders};
    try {
      final res = await _http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      final decoded = _decode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': decoded};
      }
      return {
        'success': false,
        'message': messageFromResponse(
          decoded,
          'No se pudo completar la solicitud (HTTP ${res.statusCode}).',
        ),
      };
    } catch (_) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('$baseUrl${_normalizePath(path)}');
    final headers = {...jsonHeaders(token: token), ...?extraHeaders};
    try {
      final res = await _http.delete(uri, headers: headers);
      final decoded = _decode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': decoded};
      }
      return {
        'success': false,
        'message': messageFromResponse(
          decoded,
          'No se pudo completar la solicitud (HTTP ${res.statusCode}).',
        ),
      };
    } catch (_) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }

  String _normalizePath(String path) {
    if (path.startsWith('/')) return path;
    return '/$path';
  }
}
