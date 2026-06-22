// Pure model-parsing tests for the fields added by the quiz / instant-funnel
// work: AppBooking.is_promo/source and Specialist.instant_available. No plugins,
// no network — just the fromJson/fromMap mapping, including defensive defaults.
import 'package:flutter_test/flutter_test.dart';
import 'package:nuva/models/booking.dart';
import 'package:nuva/models/specialist.dart';

void main() {
  group('AppBooking.fromJson', () {
    test('parses is_promo and source for an instant promo booking', () {
      final b = AppBooking.fromJson({
        'id': 1,
        'specialist': {
          'id': 7,
          'first_name': 'Аяна',
          'last_name': 'С.',
          'avatar_gradient': ['#7FB7E8', '#A3D8F4'],
        },
        'starts_at': '2026-06-22T10:00:00Z',
        'format': 'chat',
        'status': 'scheduled',
        'price_kzt': 0,
        'service_fee_kzt': 0,
        'is_intro': true,
        'is_promo': true,
        'source': 'instant',
        'conversation_id': 42,
      });
      expect(b.isPromo, isTrue);
      expect(b.source, 'instant');
      expect(b.priceKzt, 0);
      expect(b.serviceFeeKzt, 0);
      expect(b.conversationId, 42);
      expect(b.format, 'chat');
    });

    test('defaults is_promo=false and source=manual when absent', () {
      final b = AppBooking.fromJson({
        'id': 2,
        'specialist': {'id': 1, 'first_name': 'A', 'last_name': 'B'},
        'starts_at': '2026-06-22T10:00:00Z',
        'status': 'requested',
      });
      expect(b.isPromo, isFalse);
      expect(b.source, 'manual');
    });
  });

  group('Specialist.fromMap', () {
    test('parses instant_available when present', () {
      final s = Specialist.fromMap({
        'id': 1,
        'first_name': 'Аяна',
        'last_name': 'С.',
        'title': 'Психолог',
        'rating': 4.8,
        'instant_available': true,
      });
      expect(s.instantAvailable, isTrue);
    });

    test('defaults instant_available=false when absent', () {
      final s = Specialist.fromMap({
        'id': 1,
        'first_name': 'A',
        'last_name': 'B',
        'title': 'T',
        'rating': '4.5', // DRF can serialize a Decimal as a string
      });
      expect(s.instantAvailable, isFalse);
      expect(s.rating, 4.5); // defensive numeric parse still works
    });
  });
}
