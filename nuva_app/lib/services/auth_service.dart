import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend.dart';

/// Phone-based auth via Supabase + an SMS provider (Mobizon / Twilio, configured
/// in the Supabase dashboard). Also supports anonymous sign-in, which gives a
/// real `auth.uid()` (so RLS-protected writes work) without needing SMS — a good
/// fit for Nuva's anonymity-first design and the quickest way to test locally.
///
/// When the backend is not configured we fall back to a local anonymous handle
/// so the app still runs entirely on mocks.
class AuthService {
  static const _localAlias = 'local-anon';

  SupabaseClient? get _c => Backend.client;

  Session? get session => _c?.auth.currentSession;
  User? get currentUser => _c?.auth.currentUser;

  String? get currentUserId =>
      Backend.enabled ? currentUser?.id : _localAlias;

  bool get isSignedIn => Backend.enabled ? currentUser != null : true;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// Stream of auth changes, or null when the backend is off.
  Stream<AuthState>? get authStateChanges => _c?.auth.onAuthStateChange;

  /// Best-effort: ensure there is *some* session so RLS writes work. Tries
  /// anonymous sign-in; silently no-ops if anonymous sign-ins are disabled in
  /// the project (Authentication → Providers → Anonymous).
  Future<void> ensureSession() async {
    final c = _c;
    if (c == null || c.auth.currentSession != null) return;
    try {
      await c.auth.signInAnonymously();
    } catch (_) {
      // Anonymous sign-ins not enabled — continue session-less (writes will fail
      // gracefully until the user signs in with phone OTP).
    }
  }

  Future<void> signInAnonymously() async {
    final c = _c;
    if (c == null) return;
    await c.auth.signInAnonymously();
  }

  Future<void> sendOtp(String phoneE164) async {
    final c = _c;
    if (c == null) return;
    await c.auth.signInWithOtp(phone: phoneE164);
  }

  Future<bool> verifyOtp({
    required String phoneE164,
    required String code,
  }) async {
    final c = _c;
    if (c == null) return false; // fail closed when backend is off
    final res = await c.auth.verifyOTP(
      type: OtpType.sms,
      phone: phoneE164,
      token: code,
    );
    return res.session != null;
  }

  Future<void> signOut() async {
    if (Backend.enabled) {
      await _c?.auth.signOut();
    }
  }
}
