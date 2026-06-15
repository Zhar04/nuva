import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../models/community.dart';
import '../models/specialist.dart';
import 'auth_service.dart';
import 'backend_auth.dart' show apiClientProvider, backendAuthProvider;
import 'db_service.dart';

/// Shared service singletons.
final dbProvider = Provider<DbService>((_) => DbService());
final authServiceProvider = Provider<AuthService>((_) => AuthService());

/// Emits whenever the Supabase auth session changes (sign-in / sign-out /
/// anonymous). Null when the backend is not configured.
final authStateProvider = StreamProvider<AuthState?>((ref) {
  final stream = ref.watch(authServiceProvider).authStateChanges;
  return stream ?? Stream<AuthState?>.value(null);
});

/// Specialists — from the Django backend (`/api/v1/specialists`), falling back
/// to the bundled mock catalog when the backend is unreachable. Non-empty list.
final specialistsProvider = FutureProvider<List<Specialist>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final rows = await api.getList('specialists/');
    if (rows.isEmpty) return specialistCatalog;
    return rows
        .map((m) => Specialist.fromMap(m as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return specialistCatalog;
  }
});

/// Full specialist (with education + reviews) from the backend detail endpoint;
/// falls back to the list item / mock.
final specialistDetailProvider =
    FutureProvider.family<Specialist, String>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  try {
    final m = await api.get('specialists/$id');
    return Specialist.fromMap(m);
  } catch (_) {
    final list = await ref.watch(specialistsProvider.future);
    final hit = list.where((s) => s.id == id).toList();
    if (hit.isNotEmpty) return hit.first;
    try {
      return specialistCatalog.byId(id);
    } catch (_) {
      return list.isNotEmpty ? list.first : specialistCatalog.first;
    }
  }
});

/// Community feed for a tag — from Supabase, falling back to mock posts.
/// Re-runs on auth changes so a freshly published post shows up.
final communityFeedProvider =
    FutureProvider.family<List<CommunityPost>, String>((ref, tag) async {
  ref.watch(authStateProvider);
  final db = ref.watch(dbProvider);
  List<CommunityPost> mock() => tag == 'Все'
      ? communityFeed
      : communityFeed.where((p) => p.tags.contains(tag)).toList();
  try {
    final rows = await db.fetchCommunityFeed(tag: tag);
    if (rows.isEmpty) return mock();
    return rows.map(CommunityPost.fromMap).toList();
  } catch (_) {
    return mock();
  }
});

/// The current user's bookings from the backend (`/api/v1/bookings/`).
final bookingsProvider = FutureProvider<List<AppBooking>>((ref) async {
  ref.watch(backendAuthProvider); // refresh on sign-in / sign-out
  final token = ref.read(backendAuthProvider.notifier).accessToken;
  if (token == null) return const [];
  final api = ref.watch(apiClientProvider);
  try {
    final rows = await api.getList('bookings/', token: token);
    return rows
        .map((m) => AppBooking.fromJson(m as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
});
