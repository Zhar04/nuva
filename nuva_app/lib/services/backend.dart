import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Backend bootstrap. Reads SUPABASE_URL / SUPABASE_ANON_KEY from .env.
/// If they are missing — the app still runs against local mocks (Phase 0).
/// When user fills .env — auth, chat, bookings, posts all switch to Supabase.
class Backend {
  static bool _enabled = false;
  static bool get enabled => _enabled;

  static SupabaseClient? get client {
    // `Supabase.instance` throws (null-check on its internal singleton) if it
    // was never initialized. Guard on _enabled AND catch defensively so a
    // misconfigured/legacy backend can never white-screen the app on startup.
    if (!_enabled) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<void> init() async {
    // Legacy Supabase bootstrap. The app's real backend is the Django API
    // (api_client/backend_auth); this stays only for the not-yet-removed
    // db_service/auth_service paths and must NEVER throw on startup — without
    // SUPABASE_* the app runs fully on the Django backend + mock fallback.
    try {
      final url = dotenv.env['SUPABASE_URL'];
      final key = dotenv.env['SUPABASE_ANON_KEY'];
      if (url == null || url.isEmpty || key == null || key.isEmpty) {
        _enabled = false;
        return;
      }
      await Supabase.initialize(url: url, anonKey: key, debug: false);
      _enabled = true;
    } catch (_) {
      _enabled = false;
    }
  }
}
