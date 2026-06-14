import 'backend.dart';

/// Thin DB layer. CRUD that the app needs in Phase 1.
/// Each method returns local mocks when Backend.disabled.
class DbService {
  Future<List<Map<String, dynamic>>> fetchSpecialists() async {
    final c = Backend.client;
    if (c == null) return const [];
    final rows = await c.from('specialists').select().eq('is_active', true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> fetchSpecialist(String id) async {
    final c = Backend.client;
    if (c == null) return null;
    final row = await c
        .from('specialists')
        .select('*, reviews(*), education(*)')
        .eq('id', id)
        .single();
    return row;
  }

  Future<void> createBooking({
    required String specialistId,
    required DateTime startsAt,
    required String format,
    required int priceKzt,
  }) async {
    final c = Backend.client;
    if (c == null) return;
    final userId = c.auth.currentUser?.id;
    await c.from('bookings').insert({
      'user_id': userId,
      'specialist_id': specialistId,
      'starts_at': startsAt.toIso8601String(),
      'format': format,
      'price_kzt': priceKzt,
      'status': 'pending_payment',
    });
  }

  Stream<List<Map<String, dynamic>>> watchChat(String chatId) {
    final c = Backend.client;
    if (c == null) return const Stream.empty();
    return c
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('sent_at');
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final c = Backend.client;
    if (c == null) return;
    await c.from('messages').insert({
      'chat_id': chatId,
      'sender_id': c.auth.currentUser?.id,
      'text': text,
    });
  }

  Future<List<Map<String, dynamic>>> fetchCommunityFeed({String? tag}) async {
    final c = Backend.client;
    if (c == null) return const [];
    var q = c.from('community_posts').select('*, replies:community_replies(count)');
    if (tag != null && tag != 'Все') {
      q = q.contains('tags', [tag]);
    }
    return List<Map<String, dynamic>>.from(
      await q.order('created_at', ascending: false).limit(50),
    );
  }

  Future<void> publishPost({
    required String text,
    required List<String> tags,
  }) async {
    final c = Backend.client;
    if (c == null) return;
    await c.from('community_posts').insert({
      'author_id': c.auth.currentUser?.id,
      'text': text,
      'tags': tags,
    });
  }
}
