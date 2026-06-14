import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend.dart';

/// Phone-based auth via Supabase + Mobizon / Twilio (configured in Supabase
/// dashboard). Phase 0 — anonymous "local user" fallback when Backend.disabled.
class AuthService {
  /// Anonymous handle used while backend is not connected.
  static const _localAlias = 'local-anon';

  String? get currentUserId =>
      Backend.enabled ? Backend.client?.auth.currentUser?.id : _localAlias;

  bool get isSignedIn => currentUserId != null;

  Future<void> sendOtp(String phoneE164) async {
    final c = Backend.client;
    if (c == null) return;
    await c.auth.signInWithOtp(phone: phoneE164);
  }

  Future<bool> verifyOtp({
    required String phoneE164,
    required String code,
  }) async {
    final c = Backend.client;
    if (c == null) return true; // Phase 0 — accept anything in mock mode.
    final res = await c.auth.verifyOTP(
      type: OtpType.sms,
      phone: phoneE164,
      token: code,
    );
    return res.session != null;
  }

  Future<void> signOut() async {
    if (Backend.enabled) {
      await Backend.client?.auth.signOut();
    }
  }
}
