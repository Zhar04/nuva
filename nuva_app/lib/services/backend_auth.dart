import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

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
  const AuthState({this.user, this.restoring = false});
  bool get isSignedIn => user != null;
}

/// Holds JWT tokens (shared_preferences) + the signed-in user, and talks to the
/// backend auth endpoints. Restores the session on startup.
class BackendAuth extends StateNotifier<AuthState> {
  BackendAuth(this._api) : super(const AuthState(restoring: true)) {
    _restore();
  }

  final ApiClient _api;
  static const _kAccess = 'nuva_access';
  static const _kRefresh = 'nuva_refresh';
  String? _access;
  String? _refresh;

  String? get accessToken => _access;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    _access = prefs.getString(_kAccess);
    _refresh = prefs.getString(_kRefresh);
    if (_access != null) {
      if (await _loadMe()) return;
      if (await _tryRefresh() && await _loadMe()) return;
      await _clear();
    }
    state = const AuthState();
  }

  Future<bool> _loadMe() async {
    try {
      final me = await _api.get('auth/me', token: _access);
      state = AuthState(user: BackendUser.fromJson(me));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _tryRefresh() async {
    if (_refresh == null) return false;
    try {
      final r = await _api.post('auth/refresh', {'refresh': _refresh});
      _access = r['access'] as String;
      await _persist();
      return true;
    } catch (_) {
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
    final prefs = await SharedPreferences.getInstance();
    if (_access != null) await prefs.setString(_kAccess, _access!);
    if (_refresh != null) await prefs.setString(_kRefresh, _refresh!);
  }

  Future<void> _clear() async {
    _access = null;
    _refresh = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
  }
}

final apiClientProvider = Provider<ApiClient>((_) => ApiClient());
final backendAuthProvider =
    StateNotifierProvider<BackendAuth, AuthState>(
        (ref) => BackendAuth(ref.watch(apiClientProvider)));
