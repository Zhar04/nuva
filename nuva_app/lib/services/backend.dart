import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Backend bootstrap. Reads SUPABASE_URL / SUPABASE_ANON_KEY from .env.
/// If they are missing — the app still runs against local mocks (Phase 0).
/// When user fills .env — auth, chat, bookings, posts all switch to Supabase.
class Backend {
  static bool _enabled = false;
  static bool get enabled => _enabled;

  static SupabaseClient? get client =>
      _enabled ? Supabase.instance.client : null;

  static Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      _enabled = false;
      return;
    }
    await Supabase.initialize(
      url: url,
      anonKey: key,
      debug: false,
    );
    _enabled = true;
  }
}
