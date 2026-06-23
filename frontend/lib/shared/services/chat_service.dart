import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';

class ChatStreamResult {
  ChatStreamResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

/// Cliente de chat con respuestas en streaming desde el backend.
class ChatService {
  ChatService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  String get _baseUrl => ApiConfig.baseUrl;

  Future<ChatStreamResult> askStreaming({
    required String message,
    required String token,
    required void Function(String chunk) onChunk,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/ask');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'text/plain'
      ..body = jsonEncode({'message': message.trim()});

    try {
      final streamed = await _http.send(request).timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw TimeoutException('El asistente tardó demasiado.'),
      );

      if (streamed.statusCode == 401) {
        return ChatStreamResult(
          success: false,
          errorMessage: 'Tu sesión expiró. Vuelve a iniciar sesión.',
        );
      }

      if (streamed.statusCode == 429) {
        final body = await streamed.stream.bytesToString();
        final decoded = _tryDecodeJson(body);
        return ChatStreamResult(
          success: false,
          errorMessage: _detailFromBody(decoded) ??
              'Demasiadas preguntas. Espera un momento e intenta de nuevo.',
        );
      }

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        final body = await streamed.stream.bytesToString();
        final decoded = _tryDecodeJson(body);
        return ChatStreamResult(
          success: false,
          errorMessage: _detailFromBody(decoded) ??
              'No se pudo obtener respuesta del asistente.',
        );
      }

      await for (final chunk in streamed.stream.transform(const Utf8Decoder())) {
        if (chunk.isNotEmpty) {
          onChunk(chunk);
        }
      }

      return ChatStreamResult(success: true);
    } on TimeoutException {
      return ChatStreamResult(
        success: false,
        errorMessage: 'El asistente tardó demasiado en responder.',
      );
    } catch (_) {
      return ChatStreamResult(
        success: false,
        errorMessage: 'No se pudo conectar con el asistente.',
      );
    }
  }

  dynamic _tryDecodeJson(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String? _detailFromBody(dynamic decoded) {
    if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
      return decoded['detail'] as String;
    }
    return null;
  }
}
