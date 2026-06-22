import 'package:flutter_test/flutter_test.dart';
import 'package:nuva/router/app_router.dart';

/// Unit tests for the auth-guard route classification used by the centralized
/// go_router redirect (lib/router/app_router.dart). The redirect bounces any
/// non-public route to /auth for a signed-out user, so this table is the spec
/// for "what a guest may reach".
void main() {
  group('isPublicRoute', () {
    test('entry + auth + onboarding + legal are public', () {
      for (final r in [
        '/',
        '/splash',
        '/auth',
        '/auth?mode=register',
        '/onboarding',
        '/onboarding/user',
        '/onboarding/specialist',
        '/role',
        '/legal/privacy',
        '/legal/terms',
        '/legal/about',
        // The entry quiz is reachable by a guest before sign-up.
        '/quiz',
      ]) {
        expect(isPublicRoute(r), isTrue, reason: '$r should be public');
      }
    });

    test('app surfaces are gated', () {
      for (final r in [
        '/home',
        '/specialists',
        '/specialists/42',
        '/booking/42',
        '/payment/42',
        '/chats',
        '/chats/7',
        '/journal',
        '/community',
        '/psy/cabinet',
        '/psy/client/3',
        '/profile',
        // "Поговорить сейчас" creates a booking — must require sign-in.
        '/instant',
      ]) {
        expect(isPublicRoute(r), isFalse, reason: '$r should be gated');
      }
    });

    test('query string is ignored when classifying', () {
      expect(isPublicRoute('/auth?next=/home'), isTrue);
      expect(isPublicRoute('/booking/1?ref=x'), isFalse);
    });

    test('a prefix does not leak to a sibling that merely shares a stem', () {
      // '/role' is public, but '/roles-admin' (hypothetical) must not be.
      expect(isPublicRoute('/roleplay'), isFalse);
      // '/legal' guards only '/legal' and '/legal/...'.
      expect(isPublicRoute('/legalese'), isFalse);
    });
  });
}
