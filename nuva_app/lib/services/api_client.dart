import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Thin HTTP client for the Nuva Django backend (`/api/v1/...`).
class ApiClient {
  ApiClient({String? baseUrl})
      : baseUrl = (baseUrl ??
                dotenv.env['API_BASE_URL'] ??
                'http://localhost:8000')
            .replaceAll(RegExp(r'/+$'), '');

  final String baseUrl;

  Uri _u(String path) => Uri.parse('$baseUrl/api/v1/$path');

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body,
          {String? token}) async =>
      _decode(await http.post(_u(path),
          headers: _headers(token), body: jsonEncode(body)));

  Future<Map<String, dynamic>> get(String path, {String? token}) async =>
      _decode(await http.get(_u(path), headers: _headers(token)));

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body,
          {String? token}) async =>
      _decode(await http.patch(_u(path),
          headers: _headers(token), body: jsonEncode(body)));

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
