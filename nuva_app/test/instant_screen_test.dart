// Widget tests for the "поговорить сейчас" funnel FSM. A fake ApiClient drives
// the three startup outcomes (matched / fallback / offline) without any network.
// Navigation isn't exercised here (those taps push routes); we assert the phase
// the screen settles into by the visible copy.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuva/l10n/strings.dart';
import 'package:nuva/screens/instant_screen.dart';
import 'package:nuva/services/api_client.dart';
import 'package:nuva/services/backend_auth.dart';
import 'package:nuva/theme/theme.dart';

/// A fake that returns canned responses (or throws) for the instant endpoints.
class _FakeApi extends ApiClient {
  _FakeApi(this._onPost) : super(baseUrl: 'http://test');
  final Future<Map<String, dynamic>> Function(String path) _onPost;

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body,
          {String? token}) =>
      _onPost(path);
}

Future<void> _pumpInstant(WidgetTester tester, _FakeApi api) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api)],
      child: MaterialApp(
        theme: NuvaTheme.light(),
        home: const InstantScreen(concern: 'Тревога'),
      ),
    ),
  );
  // initState fires _match() on the first post-frame callback; let it resolve.
  await tester.pump(); // build
  await tester.pump(const Duration(milliseconds: 50)); // future completes
}

void main() {
  const ru = S(AppLang.ru);

  testWidgets('match available → shows the matched phase + channel choice',
      (tester) async {
    final api = _FakeApi((path) async => {
          'available': true,
          'booking': {
            'id': 1,
            'specialist': {
              'id': 7,
              'first_name': 'Аяна',
              'last_name': 'С.',
              'avatar_gradient': ['#7FB7E8', '#A3D8F4'],
            },
            'starts_at': '2026-06-22T10:00:00Z',
            'format': 'video',
            'status': 'scheduled',
            'price_kzt': 0,
            'service_fee_kzt': 0,
            'is_intro': true,
            'is_promo': true,
            'source': 'instant',
            'conversation_id': 42,
          },
        });
    await _pumpInstant(tester, api);

    expect(find.text(ru.instantMatched), findsOneWidget);
    expect(find.text(ru.instantVideo), findsOneWidget);
    expect(find.text(ru.instantChat), findsOneWidget);
    expect(find.text('Аяна С.'), findsOneWidget);
  });

  testWidgets('no one available → shows the fallback with the request CTA',
      (tester) async {
    final api = _FakeApi((path) async => {
          'available': false,
          'respond_within_min': 15,
        });
    await _pumpInstant(tester, api);

    expect(find.text(ru.instantNoneTitle), findsOneWidget);
    expect(find.text(ru.instantLeaveRequest), findsOneWidget);
    expect(find.text(ru.instantTalkToBot), findsOneWidget);
  });

  testWidgets('backend unreachable → degrades to the offline view',
      (tester) async {
    final api = _FakeApi((path) async => throw Exception('network down'));
    await _pumpInstant(tester, api);

    expect(find.text(ru.instantOfflineTitle), findsOneWidget);
    // Offline view offers the catalog + a localized retry (review fix).
    expect(find.text(ru.instantRetry), findsOneWidget);
  });
}
