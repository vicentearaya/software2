import 'package:cleanpool_app/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('ApiClient maps FastAPI detail string to message', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (req) async => http.Response(
          '{"detail":"No autorizado"}',
          401,
        ),
      ),
    );
    final r = await client.get('/cualquier', token: 'x');
    expect(r['success'], false);
    expect(r['message'], 'No autorizado');
  });

  test('ApiClient success wraps decoded JSON as data', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (req) async => http.Response('{"ok":true,"estado":"APTA"}', 200),
      ),
    );
    final r = await client.get('/piscinas/x/status', token: 't');
    expect(r['success'], true);
    expect((r['data'] as Map)['estado'], 'APTA');
  });
}
