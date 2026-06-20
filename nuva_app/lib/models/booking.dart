import 'package:flutter/material.dart';

import '../utils/format.dart';

/// A booking as returned by the backend `/api/v1/bookings/` (specialist nested).
///
/// Lifecycle: `requested` → (psychologist accepts) → `scheduled` (free intro)
/// or `pending_payment` (paid) → (client pays) → `paid` → `completed`. A
/// declined request carries a reason and an optional proposed new time.
class AppBooking {
  final int id;
  final String? specialistId;
  final String specialistName;
  final String specialistInitials;
  final List<Color> gradient;
  final DateTime startsAt;
  final String format; // video | audio | chat
  final String status; // requested | pending_payment | scheduled | paid | completed | declined | cancelled | refunded
  final int priceKzt;
  final int serviceFeeKzt;
  final String clientName; // for the psychologist's incoming view
  final int? clientId; // the client's user id (for the client card)
  final int? conversationId; // thread with this client (to open chat/call)
  // ── Request metadata ──
  final String intent; // intro | package
  final bool isIntro;
  final bool isPromo; // free instant/promo session — excluded from commission
  final String source; // manual | instant | quiz
  final String concern; // "что беспокоит"
  final String clientMessage;
  final int matchScore; // % совпадения
  final String declineReason;
  final DateTime? proposedStartsAt;

  const AppBooking({
    required this.id,
    this.specialistId,
    required this.specialistName,
    required this.specialistInitials,
    required this.gradient,
    required this.startsAt,
    required this.format,
    required this.status,
    required this.priceKzt,
    this.serviceFeeKzt = 1000,
    this.clientName = 'Клиент',
    this.clientId,
    this.conversationId,
    this.intent = 'intro',
    this.isIntro = false,
    this.isPromo = false,
    this.source = 'manual',
    this.concern = '',
    this.clientMessage = '',
    this.matchScore = 0,
    this.declineReason = '',
    this.proposedStartsAt,
  });

  /// A call can be joined from ~5 min before the start until 90 min after.
  bool get joinable {
    final now = DateTime.now();
    return now.isAfter(startsAt.subtract(const Duration(minutes: 5))) &&
        now.isBefore(startsAt.add(const Duration(minutes: 90)));
  }

  /// Waiting for the psychologist to accept or decline.
  bool get isRequest => status == 'requested';

  /// Accepted paid session — the client still has to pay.
  bool get isAwaitingPayment => status == 'pending_payment';

  /// Confirmed and locked into the calendar (free intro or paid session).
  bool get isConfirmed =>
      status == 'scheduled' || status == 'paid' || status == 'completed';

  bool get isDeclined => status == 'declined';

  /// Shown in the calendar/schedule: confirmed and not yet finished.
  bool get isUpcoming =>
      startsAt.isAfter(DateTime.now()) &&
      (status == 'scheduled' || status == 'paid' || status == 'pending_payment');

  String get formatLabel => switch (format) {
        'audio' => 'Аудио',
        'chat' => 'Чат',
        _ => 'Видео',
      };

  String get intentLabel => switch (intent) {
        'package' => 'Хочет приобрести пакет сессий',
        _ => 'Хочет ознакомительную сессию',
      };

  String get statusLabel => switch (status) {
        'requested' => 'Новый запрос',
        'pending_payment' => 'Ждёт оплаты',
        'scheduled' => 'В расписании',
        'paid' => 'Оплачено',
        'completed' => 'Завершена',
        'declined' => 'Отклонён',
        'cancelled' => 'Отменена',
        'refunded' => 'Возврат',
        _ => 'Запрос',
      };

  factory AppBooking.fromJson(Map<String, dynamic> m) {
    final sp = (m['specialist'] ?? const {}) as Map<String, dynamic>;
    final fn = (sp['first_name'] ?? '') as String;
    final ln = (sp['last_name'] ?? '') as String;
    final grad = ((sp['avatar_gradient'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    return AppBooking(
      id: (m['id'] as num).toInt(),
      specialistId: sp['id'] == null ? null : '${sp['id']}',
      specialistName: '$fn $ln'.trim(),
      specialistInitials:
          (fn.isNotEmpty ? fn[0] : '') + (ln.isNotEmpty ? ln[0] : ''),
      gradient: grad.length >= 2
          ? grad.map(hexToColor).toList()
          : const [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
      startsAt: DateTime.tryParse('${m['starts_at']}')?.toLocal() ??
          DateTime.now(),
      format: (m['format'] ?? 'video') as String,
      status: (m['status'] ?? 'requested') as String,
      priceKzt: (m['price_kzt'] as num?)?.toInt() ?? 0,
      serviceFeeKzt: (m['service_fee_kzt'] as num?)?.toInt() ?? 1000,
      clientName: (m['client_name'] ?? 'Клиент') as String,
      clientId: (m['client_id'] as num?)?.toInt(),
      conversationId: (m['conversation_id'] as num?)?.toInt(),
      intent: (m['intent'] ?? 'intro') as String,
      isIntro: (m['is_intro'] as bool?) ?? false,
      isPromo: (m['is_promo'] as bool?) ?? false,
      source: (m['source'] ?? 'manual') as String,
      concern: (m['concern'] ?? '') as String,
      clientMessage: (m['client_message'] ?? '') as String,
      matchScore: (m['match_score'] as num?)?.toInt() ?? 0,
      declineReason: (m['decline_reason'] ?? '') as String,
      proposedStartsAt: DateTime.tryParse('${m['proposed_starts_at']}')?.toLocal(),
    );
  }
}

/// One session in a client's history (for the psychologist's client card).
class ClientSession {
  final int id;
  final DateTime startsAt;
  final String format;
  final String status;
  final int priceKzt;
  final bool isIntro;
  final String concern;

  const ClientSession({
    required this.id,
    required this.startsAt,
    required this.format,
    required this.status,
    required this.priceKzt,
    required this.isIntro,
    required this.concern,
  });

  bool get isDone => status == 'completed' ||
      startsAt.add(const Duration(minutes: 50)).isBefore(DateTime.now());

  factory ClientSession.fromJson(Map<String, dynamic> m) => ClientSession(
        id: (m['id'] as num).toInt(),
        startsAt:
            DateTime.tryParse('${m['starts_at']}')?.toLocal() ?? DateTime.now(),
        format: (m['format'] ?? 'video') as String,
        status: (m['status'] ?? '') as String,
        priceKzt: (m['price_kzt'] as num?)?.toInt() ?? 0,
        isIntro: (m['is_intro'] as bool?) ?? false,
        concern: (m['concern'] ?? '') as String,
      );
}

/// The psychologist's private view of one client (`/bookings/clients/{id}`).
class ClientCard {
  final int clientId;
  final String name;
  final String concern;
  final String note;
  final List<int> moodTrend; // 1..5, oldest → newest
  final List<ClientSession> sessions;

  const ClientCard({
    required this.clientId,
    required this.name,
    required this.concern,
    required this.note,
    required this.moodTrend,
    required this.sessions,
  });

  factory ClientCard.fromJson(Map<String, dynamic> m) => ClientCard(
        clientId: (m['client_id'] as num?)?.toInt() ?? 0,
        name: (m['name'] ?? 'Клиент') as String,
        concern: (m['concern'] ?? '') as String,
        note: (m['note'] ?? '') as String,
        moodTrend: ((m['mood_trend'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        sessions: ((m['sessions'] as List?) ?? const [])
            .map((e) => ClientSession.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
