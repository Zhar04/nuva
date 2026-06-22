// Tests that the ApiClient distinguishes a real HTTP error (ApiException, e.g.
// 400 "email taken") from a transport failure (NetworkException) — so the UI
// can stop showing "no connection" when the server actually answered.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nuva/services/api_client.dart';

void main() {
  test('ApiException.message reads a DRF field error (email taken)', () {
    final e = ApiException(400, {
      'email': ['user с таким email уже существует.'],
    });
    expect(e.message, 'user с таким email уже существует.');
    expect(e.status, 400);
  });

  test('ApiException.message reads a detail string', () {
    final e = ApiException(401, {'detail': 'No active account found'});
    expect(e.message, 'No active account found');
  });

  test('_decode throws ApiException (not NetworkException) on a 400 response',
      () async {
    // A 400 with a JSON body is a real server answer → ApiException.
    final client = _StubClient((req) async => http.Response(
          jsonEncode({
            'email': ['user с таким email уже существует.'],
          }),
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ));
    final api = ApiClient(baseUrl: 'https://test', httpClient: client);
    expect(
      () => api.post('auth/register', {'email': 'x'}),
      throwsA(isA<ApiException>()
          .having((e) => e.status, 'status', 400)
          .having((e) => e.message, 'message',
              'user с таким email уже существует.')),
    );
  });

  test('a transport failure surfaces as NetworkException, not ApiException',
      () async {
    final client = _StubClient((req) async {
      throw http.ClientException('Failed to fetch');
    });
    final api = ApiClient(baseUrl: 'https://test', httpClient: client);
    expect(
      () => api.post('auth/register', {'email': 'x'}),
      throwsA(isA<NetworkException>()),
    );
  });
}

/// Minimal http.Client stub that runs a handler for every request.
class _StubClient extends http.BaseClient {
  _StubClient(this.handler);
  final Future<http.Response> Function(http.BaseRequest) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final res = await handler(request);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
    );
  }
}
