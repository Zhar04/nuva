import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Thin HTTP client for the Nuva Django backend (`/api/v1/...`).
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = (baseUrl ??
                dotenv.env['API_BASE_URL'] ??
                'http://localhost:8000')
            .replaceAll(RegExp(r'/+$'), ''),
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  Uri _u(String path) => Uri.parse('$baseUrl/api/v1/$path');

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body,
          {String? token}) =>
      _send(() => _http.post(_u(path),
          headers: _headers(token), body: jsonEncode(body)));

  Future<Map<String, dynamic>> get(String path, {String? token}) =>
      _send(() => _http.get(_u(path), headers: _headers(token)));

  /// Run an HTTP call and decode it. A transport failure (the request never got
  /// an HTTP response — DNS, TLS, CORS, offline) is wrapped as a
  /// [NetworkException] so callers can tell "no connection" apart from a real
  /// HTTP error like 400. An [ApiException] (a non-2xx response) passes through.
  Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() call) async {
    final http.Response res;
    try {
      res = await call();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException(e);
    }
    return _decode(res);
  }

  /// GET that returns a JSON list (or the `results` of a paginated response).
  Future<List<dynamic>> getList(String path, {String? token}) async {
    final res = await _http.get(_u(path), headers: _headers(token));
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    final decoded =
        res.body.isEmpty ? const [] : jsonDecode(utf8.decode(res.bodyBytes));
    if (!ok) {
      throw ApiException(
          res.statusCode, decoded is Map<String, dynamic> ? decoded : {});
    }
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['results'] is List) {
      return decoded['results'] as List;
    }
    return const [];
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body,
          {String? token}) =>
      _send(() => _http.patch(_u(path),
          headers: _headers(token), body: jsonEncode(body)));

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body,
          {String? token}) =>
      _send(() => _http.put(_u(path),
          headers: _headers(token), body: jsonEncode(body)));

  Future<void> delete(String path, {String? token}) async {
    final res = await _http.delete(_u(path), headers: _headers(token));
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, const {});
    }
  }

  Map<String, String> _headers(String? token) => {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decode(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    Map<String, dynamic> body;
    try {
      body = res.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      body = {'detail': res.body};
    }
    if (!ok) throw ApiException(res.statusCode, body);
    return body;
  }
}

/// Carries a DRF error so the UI can show a friendly message.
class ApiException implements Exception {
  ApiException(this.status, this.body);
  final int status;
  final Map<String, dynamic> body;

  String get message {
    final detail = body['detail'];
    if (detail is String) return detail;
    for (final v in body.values) {
      if (v is List && v.isNotEmpty) return v.first.toString();
      if (v is String) return v;
    }
    return 'Ошибка $status';
  }

  @override
  String toString() => 'ApiException($status): $message';
}

/// The request never reached an HTTP response (offline, DNS/TLS, or a CORS
/// block on web). Distinct from [ApiException], which carries a real status.
class NetworkException implements Exception {
  NetworkException(this.cause);
  final Object cause;

  @override
  String toString() => 'NetworkException: $cause';
}
