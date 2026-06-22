import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// JWT session storage backed by the OS secure store (Keychain / Keystore;
/// WebCrypto-wrapped on web) instead of plaintext shared_preferences. The
/// tokens are special-category-adjacent credentials, so they must not sit in
/// the clear (privacy-policy gap H2/H3 in TECHNICAL_LETTER.md).
///
/// One-time migration: older builds persisted the tokens in shared_preferences;
/// on first read we lift any legacy values into secure storage and wipe the
/// plaintext copy, so existing sessions survive the upgrade without a re-login.
class _TokenStore {
  static const _kAccess = 'nuva_access';
  static const _kRefresh = 'nuva_refresh';

  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<(String?, String?)> read() async {
    var access = await _secure.read(key: _kAccess);
    var refresh = await _secure.read(key: _kRefresh);
    if (access == null && refresh == null) {
      // Migrate a legacy plaintext session, if any, then scrub it.
      final prefs = await SharedPreferences.getInstance();
      final legacyA = prefs.getString(_kAccess);
      final legacyR = prefs.getString(_kRefresh);
      if (legacyA != null || legacyR != null) {
        access = legacyA;
        refresh = legacyR;
        await write(access, refresh);
        await prefs.remove(_kAccess);
        await prefs.remove(_kRefresh);
      }
    }
    return (access, refresh);
  }

  /// Persist the tokens. Best-effort: a secure-store write can throw on web
  /// (e.g. a broken service worker / WebCrypto hiccup), but the live session
  /// already holds the tokens in memory — failing to *remember* them across
  /// restarts must NEVER fail the sign-in that just succeeded. Swallow + report.
  Future<void> write(String? access, String? refresh) async {
    try {
      if (access != null) await _secure.write(key: _kAccess, value: access);
      if (refresh != null) await _secure.write(key: _kRefresh, value: refresh);
    } catch (_) {
      // Session stays valid for this run; it just won't be restored next launch.
    }
  }

  Future<void> clear() async {
    try {
      await _secure.delete(key: _kAccess);
      await _secure.delete(key: _kRefresh);
      // Belt-and-braces: also clear any lingering legacy plaintext copy.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAccess);
      await prefs.remove(_kRefresh);
    } catch (_) {
      // Logout already cleared in-memory tokens; storage cleanup is best-effort.
    }
  }
}

/// User as returned by the backend `/auth/me`.
class BackendUser {
  final int id;
  final String email;
  final String name;
  final String role; // seeker | psychologist | admin
  final String? mbti;
  final String bio;
  final String avatar; // base64 data URL, or '' if none
  const BackendUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.mbti,
    this.bio = '',
    this.avatar = '',
  });

  bool get isPsychologist => role == 'psychologist';

  factory BackendUser.fromJson(Map<String, dynamic> m) => BackendUser(
        id: (m['id'] as num).toInt(),
        email: (m['email'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        role: (m['role'] ?? 'seeker') as String,
        mbti: m['mbti'] as String?,
        bio: (m['bio'] ?? '') as String,
        avatar: (m['avatar'] ?? '') as String,
      );
}

class AuthState {
  final BackendUser? user;
  final bool restoring;

  /// True when a saved session token exists but the backend was unreachable
  /// at restore time, so we couldn't confirm the user. We keep the token and
  /// let the app run as a guest (sample catalogs) instead of forcing /auth —
  /// this is what keeps the offline demo alive.
  final bool offline;

  const AuthState({this.user, this.restoring = false, this.offline = false});
  bool get isSignedIn => user != null;
}

/// Holds JWT tokens (in the OS secure store) + the signed-in user, and talks to
/// the backend auth endpoints. Restores the session on startup.
class BackendAuth extends StateNotifier<AuthState> {
  BackendAuth(this._api) : super(const AuthState(restoring: true)) {
    _restore();
  }

  final ApiClient _api;
  final _tokens = _TokenStore();
  String? _access;
  String? _refresh;

  String? get accessToken => _access;

  Future<void> _restore() async {
    // A secure-store read can throw (web PWA with a missing/corrupt entry, or
    // Android Keystore corruption). The token read must never escape _restore —
    // otherwise AuthState stays at restoring:true and the app hangs on /splash
    // (the white-screen-on-launch class). Fall through to a clean signed-out
    // state on any failure.
    try {
      final (access, refresh) = await _tokens.read();
      _access = access;
      _refresh = refresh;
    } catch (_) {
      _access = null;
      _refresh = null;
    }
    if (_access != null) {
      if (await _loadMe()) return;
      // /auth/me failed. If it was the backend rejecting us (401 etc.), the
      // token is stale — try a refresh, then give up to a clean logout. If it
      // was a network failure, _backendReachable is false: keep the saved
      // token and run as an offline guest so the sample-catalog demo lives on.
      if (_backendReachable) {
        if (await _tryRefresh() && await _loadMe()) return;
        await _clear();
        state = const AuthState();
      } else {
        // Token preserved (not cleared) so a later online launch can confirm it.
        state = const AuthState(offline: true);
      }
      return;
    }
    state = const AuthState();
  }

  /// Tracks whether the last auth call actually reached the backend (vs a
  /// transport failure). Drives the offline-guest path in [_restore].
  bool _backendReachable = true;

  Future<bool> _loadMe() async {
    try {
      final me = await _api.get('auth/me', token: _access);
      _backendReachable = true;
      state = AuthState(user: BackendUser.fromJson(me));
      return true;
    } on ApiException {
      _backendReachable = true; // backend answered, just not 2xx
      return false;
    } catch (_) {
      _backendReachable = false; // network/transport failure
      return false;
    }
  }

  Future<bool> _tryRefresh() async {
    if (_refresh == null) return false;
    try {
      final r = await _api.post('auth/refresh', {'refresh': _refresh});
      _access = r['access'] as String;
      await _persist();
      _backendReachable = true;
      return true;
    } on ApiException {
      _backendReachable = true;
      return false;
    } catch (_) {
      _backendReachable = false;
      return false;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? name,
    String role = 'seeker',
  }) async {
    final r = await _api.post('auth/register', {
      'email': email,
      'password': password,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      'role': role,
    });
    _access = r['access'] as String;
    _refresh = r['refresh'] as String;
    await _persist();
    state = AuthState(
        user: BackendUser.fromJson(r['user'] as Map<String, dynamic>));
  }

  Future<void> login({required String email, required String password}) async {
    final r = await _api.post('auth/login', {
      'email': email,
      'password': password,
    });
    _access = r['access'] as String;
    _refresh = r['refresh'] as String;
    await _persist();
    await _loadMe();
  }

  /// Update profile fields (name / avatar / bio / mbti) then refresh the user.
  Future<void> updateProfile(
      {String? name, String? avatar, String? bio, String? mbti}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatar != null) body['avatar'] = avatar;
    if (bio != null) body['bio'] = bio;
    if (mbti != null) body['mbti'] = mbti;
    if (body.isEmpty) return;
    await _api.patch('auth/me', body, token: _access);
    await _loadMe();
  }

  /// Re-fetch the signed-in user (e.g. after the backend changed their role
  /// when a specialist profile was created). No-op if not signed in.
  Future<void> reloadUser() async {
    if (_access != null) await _loadMe();
  }

  Future<void> logout() async {
    await _clear();
    state = const AuthState();
  }

  Future<void> _persist() async {
    await _tokens.write(_access, _refresh);
  }

  Future<void> _clear() async {
    _access = null;
    _refresh = null;
    await _tokens.clear();
  }
}

final apiClientProvider = Provider<ApiClient>((_) => ApiClient());
final backendAuthProvider =
    StateNotifierProvider<BackendAuth, AuthState>(
        (ref) => BackendAuth(ref.watch(apiClientProvider)));
