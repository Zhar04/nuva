import 'package:flutter/material.dart';

import '../utils/format.dart';

/// A booking as returned by the backend `/api/v1/bookings/` (specialist nested).
class AppBooking {
  final int id;
  final String specialistName;
  final String specialistInitials;
  final List<Color> gradient;
  final DateTime startsAt;
  final String format; // video | audio | chat
  final String status; // pending_payment | paid | completed | cancelled | refunded
  final int priceKzt;
  final String clientName; // for the psychologist's incoming view
  final int? conversationId; // thread with this client (to open chat/call)

  const AppBooking({
    required this.id,
    required this.specialistName,
    required this.specialistInitials,
    required this.gradient,
    required this.startsAt,
    required this.format,
    required this.status,
    required this.priceKzt,
    this.clientName = 'Клиент',
    this.conversationId,
  });

  /// A call can be joined from ~5 min before the start until 90 min after.
  bool get joinable {
    final now = DateTime.now();
    return now.isAfter(startsAt.subtract(const Duration(minutes: 5))) &&
        now.isBefore(startsAt.add(const Duration(minutes: 90)));
  }

  bool get isUpcoming =>
      startsAt.isAfter(DateTime.now()) &&
      status != 'cancelled' &&
      status != 'completed';

  String get formatLabel => switch (format) {
        'audio' => 'Аудио',
        'chat' => 'Чат',
        _ => 'Видео',
      };

  String get statusLabel => switch (status) {
        'paid' => 'Оплачено',
        'completed' => 'Завершена',
        'cancelled' => 'Отменена',
        'refunded' => 'Возврат',
        _ => 'Ожидает оплаты',
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
      specialistName: '$fn $ln'.trim(),
      specialistInitials:
          (fn.isNotEmpty ? fn[0] : '') + (ln.isNotEmpty ? ln[0] : ''),
      gradient: grad.length >= 2
          ? grad.map(hexToColor).toList()
          : const [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
      startsAt: DateTime.tryParse('${m['starts_at']}')?.toLocal() ??
          DateTime.now(),
      format: (m['format'] ?? 'video') as String,
      status: (m['status'] ?? 'pending_payment') as String,
      priceKzt: (m['price_kzt'] as num?)?.toInt() ?? 0,
      clientName: (m['client_name'] ?? 'Клиент') as String,
      conversationId: (m['conversation_id'] as num?)?.toInt(),
    );
  }
}
