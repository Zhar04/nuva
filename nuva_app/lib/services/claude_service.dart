import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Anthropic Messages wrapper.
///
/// Two modes:
///   • CLAUDE_PROXY_URL set → call our backend proxy (recommended for prod;
///     the key never lives in the client).
///   • Else if ANTHROPIC_API_KEY set → call Anthropic directly (dev only).
///   • Else → throws — UI shows a friendly error.
class ClaudeService {
  static const _anthropicEndpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-6';
  static const _version = '2023-06-01';

  String get _proxyUrl => dotenv.env['CLAUDE_PROXY_URL'] ?? '';
  String get _apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  bool get isConfigured => _proxyUrl.isNotEmpty || _apiKey.isNotEmpty;

  Future<String> reply({
    required List<ChatTurn> history,
    required String userLanguage,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'Configure CLAUDE_PROXY_URL (prod) or ANTHROPIC_API_KEY (dev) in .env',
      );
    }
    return _proxyUrl.isNotEmpty
        ? _viaProxy(history: history, userLanguage: userLanguage)
        : _direct(history: history, userLanguage: userLanguage);
  }

  Future<String> _viaProxy({
    required List<ChatTurn> history,
    required String userLanguage,
  }) async {
    final res = await http.post(
      Uri.parse(_proxyUrl),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'language': userLanguage,
        'messages': history.map((t) => t.toJson()).toList(),
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Proxy ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (body['reply'] as String).trim();
  }

  Future<String> _direct({
    required List<ChatTurn> history,
    required String userLanguage,
  }) async {
    final res = await http.post(
      Uri.parse(_anthropicEndpoint),
      headers: {
        'content-type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': _version,
        // Required for direct calls from a browser (Flutter web). Dev-only:
        // the key is exposed to the client — use the Cloudflare proxy for prod.
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 600,
        'system': _systemPrompt(userLanguage),
        'messages': history.map((t) => t.toJson()).toList(),
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Claude ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final content = (body['content'] as List).cast<Map<String, dynamic>>();
    return content
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join('\n')
        .trim();
  }

  String _systemPrompt(String lang) {
    final language = switch (lang) {
      'kk' => 'Kazakh (қазақша)',
      'en' => 'English',
      _ => 'Russian (русский)',
    };
    return '''
You are Nuva, an empathetic intake assistant for a Kazakhstan mental-health app.
Always respond in $language.

Goal: in 4 short steps, understand the user well enough to suggest 1–3 psychologists from our catalog. Steps:
1. What's troubling them right now (open question, listen).
2. What outcome they want (relief, clarity, change, support).
3. Format preference (online video, chat, in person), language, budget if comfortable.
4. Practical check (urgency, prior therapy experience, any safety concerns).

Tone: warm, short, validating. One question at a time. 2–3 sentences max per reply. Never diagnose. If user signals crisis or self-harm, gently surface the local helpline (Казахстан: 150) and suggest contacting emergency services.

After step 4 reply with a brief summary and ask if they want to see matched specialists.
''';
  }
}

class ChatTurn {
  final String role; // 'user' | 'assistant'
  final String content;
  const ChatTurn(this.role, this.content);
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
