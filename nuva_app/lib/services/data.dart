import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/chat.dart';
import '../models/community.dart';
import '../models/gamification.dart';
import '../models/specialist.dart';
import 'api_client.dart';
import 'backend_auth.dart' show apiClientProvider, backendAuthProvider;

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

/// Optimistic like state, keyed by `"post:<id>"` / `"reply:<id>"`. Lives in one
/// provider (not in list widgets) so it survives scroll/rebuilds, and is
/// reconciled with the server response. Fixes the recycled-widget like bug.
class LikeState {
  final bool liked;
  final int count;
  const LikeState(this.liked, this.count);
}

class LikeNotifier extends Notifier<Map<String, LikeState>> {
  @override
  Map<String, LikeState> build() => const {};

  Future<void> toggle(
      String key, String path, bool curLiked, int curCount) async {
    final nextLiked = !curLiked;
    final optimistic =
        LikeState(nextLiked, (curCount + (nextLiked ? 1 : -1)).clamp(0, 1 << 31));
    state = {...state, key: optimistic};
    try {
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      final res = await ref
          .read(apiClientProvider)
          .post(path, const <String, dynamic>{}, token: token);
      state = {
        ...state,
        key: LikeState(
          (res['liked'] as bool?) ?? optimistic.liked,
          (res['likes_count'] as num?)?.toInt() ?? optimistic.count,
        ),
      };
    } catch (_) {
      state = {...state, key: LikeState(curLiked, curCount)}; // revert
    }
  }
}

final likeProvider =
    NotifierProvider<LikeNotifier, Map<String, LikeState>>(LikeNotifier.new);

/// Community feed for a tag — from the Django backend (`/community/posts/`),
/// falling back to mock posts when unreachable. Re-runs on auth changes.
final communityFeedProvider =
    FutureProvider.family<List<CommunityPost>, String>((ref, tag) async {
  ref.watch(backendAuthProvider);
  final token = ref.read(backendAuthProvider.notifier).accessToken;
  final api = ref.watch(apiClientProvider);
  List<CommunityPost> mock() => tag == 'Все'
      ? communityFeed
      : communityFeed.where((p) => p.tags.contains(tag)).toList();
  if (token == null) return mock();
  try {
    final path = tag == 'Все'
        ? 'community/posts/'
        : 'community/posts/?tag=${Uri.encodeQueryComponent(tag)}';
    final rows = await api.getList(path, token: token);
    return rows
        .map((m) => CommunityPost.fromMap(m as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return mock();
  }
});

/// A single community post (with up-to-date like state) from the backend.
final communityPostProvider =
    FutureProvider.family<CommunityPost?, int>((ref, id) async {
  ref.watch(backendAuthProvider);
  final token = ref.read(backendAuthProvider.notifier).accessToken;
  if (token == null) return null;
  final api = ref.watch(apiClientProvider);
  try {
    final m = await api.get('community/posts/$id/', token: token);
    return CommunityPost.fromMap(m);
  } catch (_) {
    return null;
  }
});

/// Replies to a community post.
final communityRepliesProvider =
    FutureProvider.family<List<CommunityReply>, int>((ref, postId) async {
  ref.watch(backendAuthProvider);
  final token = ref.read(backendAuthProvider.notifier).accessToken;
  if (token == null) return const [];
  final api = ref.watch(apiClientProvider);
  try {
    final rows =
        await api.getList('community/posts/$postId/replies/', token: token);
    return rows
        .map((m) => CommunityReply.fromMap(m as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
});

/// The current user's chat threads (`/api/v1/chat/conversations/`).
final conversationsProvider = FutureProvider<List<ApiConversation>>((ref) async {
  ref.watch(backendAuthProvider);
  final token = ref.read(backendAuthProvider.notifier).accessToken;
  if (token == null) return const [];
  final api = ref.watch(apiClientProvider);
  try {
    final rows = await api.getList('chat/conversations/', token: token);
    return rows
        .map((m) => ApiConversation.fromJson(m as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
});

/// Messages in one conversation. Opening also marks specialist msgs as read
/// (server side), so we invalidate [conversationsProvider] after reading.
final messagesProvider =
    FutureProvider.family<List<ApiMessage>, int>((ref, convoId) async {
  ref.watch(backendAuthProvider);
  final token = ref.read(backendAuthProvider.notifier).accessToken;
  if (token == null) return const [];
  final api = ref.watch(apiClientProvider);
  final rows =
      await api.getList('chat/conversations/$convoId/messages/', token: token);
  return rows
      .map((m) => ApiMessage.fromJson(m as Map<String, dynamic>))
      .toList();
});

/// Gamification stats (points / level / streak / achievements) computed by the
/// backend from real activity (`/api/v1/journal/stats/`).
final gamificationProvider = FutureProvider<GamificationState>((ref) async {
  ref.watch(backendAuthProvider);
  final token = ref.read(backendAuthProvider.notifier).accessToken;
  if (token == null) return gamificationFallback;
  final api = ref.watch(apiClientProvider);
  try {
    final m = await api.get('journal/stats/', token: token);
    return GamificationState.fromJson(m);
  } catch (_) {
    return gamificationFallback;
  }
});

/// The current user's mood history (`/api/v1/journal/moods/`).
final moodHistoryProvider = FutureProvider<List<MoodEntry>>((ref) async {
  ref.watch(backendAuthProvider);
  final token = ref.read(backendAuthProvider.notifier).accessToken;
  if (token == null) return const [];
  final api = ref.watch(apiClientProvider);
  try {
    final rows = await api.getList('journal/moods/', token: token);
    return rows
        .map((m) => MoodEntry.fromJson(m as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
});

/// The signed-in psychologist's own catalog profile (`/specialists/me`).
/// Returns the parsed Specialist, or null if they haven't created one yet.
final specialistMeProvider = FutureProvider<Specialist?>((ref) async {
  ref.watch(backendAuthProvider);
  final token = ref.read(backendAuthProvider.notifier).accessToken;
  if (token == null) return null;
  final api = ref.watch(apiClientProvider);
  try {
    final m = await api.get('specialists/me', token: token);
    if (m['exists'] != true) return null;
    return Specialist.fromMap(m);
  } catch (_) {
    return null;
  }
});

/// Sessions booked WITH the signed-in psychologist (`/bookings/incoming`).
final incomingBookingsProvider =
    FutureProvider<List<AppBooking>>((ref) async {
  ref.watch(backendAuthProvider);
  final token = ref.read(backendAuthProvider.notifier).accessToken;
  if (token == null) return const [];
  final api = ref.watch(apiClientProvider);
  try {
    final rows = await api.getList('bookings/incoming', token: token);
    return rows
        .map((m) => AppBooking.fromJson(m as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
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

/// The psychologist's private card for one client (`/bookings/clients/{id}`):
/// concern, session history, a private note and a coarse mood trend.
final clientCardProvider =
    FutureProvider.family<ClientCard?, int>((ref, clientId) async {
  ref.watch(backendAuthProvider);
  final token = ref.read(backendAuthProvider.notifier).accessToken;
  if (token == null) return null;
  final api = ref.watch(apiClientProvider);
  try {
    final m = await api.get('bookings/clients/$clientId', token: token);
    return ClientCard.fromJson(m);
  } catch (_) {
    return null;
  }
});

/// Psychologist-side write actions on bookings (accept / decline / save note)
/// and the client-side pay action. Centralised so screens don't repeat the
/// token+endpoint plumbing.
class PsyActions {
  final Ref ref;
  PsyActions(this.ref);

  String? get _token => ref.read(backendAuthProvider.notifier).accessToken;
  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> accept(int bookingId) async {
    await _api.post('bookings/$bookingId/accept', const {}, token: _token);
    ref.invalidate(incomingBookingsProvider);
  }

  Future<void> decline(int bookingId,
      {String reason = '', DateTime? proposed}) async {
    await _api.post(
      'bookings/$bookingId/decline',
      {
        'reason': reason,
        if (proposed != null)
          'proposed_starts_at': proposed.toUtc().toIso8601String(),
      },
      token: _token,
    );
    ref.invalidate(incomingBookingsProvider);
  }

  Future<void> pay(int bookingId) async {
    await _api.post('bookings/$bookingId/pay', const {'provider': 'mock'},
        token: _token);
    ref.invalidate(bookingsProvider);
  }

  Future<void> saveClientNote(int clientId, String text) async {
    await _api.put('bookings/clients/$clientId', {'text': text}, token: _token);
    ref.invalidate(clientCardProvider(clientId));
  }
}

final psyActionsProvider = Provider<PsyActions>((ref) => PsyActions(ref));
