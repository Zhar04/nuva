import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/booking.dart';
import '../models/user_profile.dart';
import '../screens/auth_screen.dart';
import '../screens/booking_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/community_compose_screen.dart';
import '../screens/community_post_screen.dart';
import '../screens/instant_screen.dart';
import '../screens/intake_screen.dart';
import '../screens/legal_screens.dart';
import '../screens/main_shell.dart';
import '../screens/mbti_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/onboarding_specialist_screen.dart';
import '../screens/onboarding_user_screen.dart';
import '../screens/password_reset_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/payment_success_screen.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/profile_subscreens.dart';
import '../screens/progress_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/psy_cabinet_edit_screen.dart';
import '../screens/psy_client_screen.dart';
import '../screens/role_select_screen.dart';
import '../screens/specialists_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/video_call_screen.dart';
import '../services/backend_auth.dart';

/// Routes a guest may reach without a signed-in account. Everything else
/// (home, specialists, booking, payment, chats, journal, psy/*, …) is gated.
/// Prefix-matched, so e.g. `/onboarding/user` and `/legal/privacy` are covered.
const _publicPrefixes = <String>[
  '/splash',
  '/',
  '/auth',
  '/onboarding',
  '/role',
  '/legal',
  '/quiz',
  '/reset-password',
];

/// Whether [location] is reachable without a signed-in account. Exposed for
/// tests; the redirect uses it to decide who gets bounced to /auth.
bool isPublicRoute(String location) {
  // Strip query string before matching.
  final path = location.split('?').first;
  if (path == '/') return true;
  for (final p in _publicPrefixes) {
    if (p == '/') continue;
    if (path == p || path.startsWith('$p/')) return true;
  }
  return false;
}

/// Bridges the Riverpod auth [StateNotifier] to a [Listenable] so go_router's
/// (non-reactive) redirect re-runs on every login / logout / restore.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(ProviderContainer container) {
    _sub = container.listen<AuthState>(
      backendAuthProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

Future<GoRouter> buildRouter(ProviderContainer container) async {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(container),
    redirect: (context, state) {
      final auth = container.read(backendAuthProvider);
      final location = state.matchedLocation;

      // Still restoring a saved session → hold on /splash (no form flash).
      if (auth.restoring) {
        return location == '/splash' ? null : '/splash';
      }

      // Offline guest (saved token, backend unreachable): let them roam so the
      // sample-catalog demo works. Only redirect away from /splash so the app
      // doesn't get stuck on the loader once restore finished.
      if (auth.offline && !auth.isSignedIn) {
        return location == '/splash' ? '/home' : null;
      }

      final signedIn = auth.isSignedIn;
      final public = isPublicRoute(location);

      if (!signedIn) {
        if (public) return null;
        // Stash the intended route so we can return after sign-in.
        return Uri(path: '/auth', queryParameters: {'next': location})
            .toString();
      }

      // Signed in but sitting on /auth → into the app, honoring a stashed
      // ?next= intended route. (The register flow navigates itself to
      // /onboarding right after sign-up — see auth_screen._submit — and the
      // /onboarding rule below leaves a not-yet-onboarded user there.)
      if (location == '/auth') {
        final next = state.uri.queryParameters['next'];
        return (next != null && next.isNotEmpty && !isPublicRoute(next))
            ? next
            : '/home';
      }
      if (location == '/splash' || location == '/') {
        return '/home';
      }
      // Spec: a signed-in user on /onboarding → /home — but ONLY once they've
      // finished onboarding. The register flow (role → register → onboarding)
      // signs the account in BEFORE onboarding runs (the avatar upload and the
      // specialists/me PUT both need a JWT), so a mid-registration user
      // (onboarded == false) must be allowed to complete it. A returning,
      // already-onboarded user can't get stranded re-doing it.
      if (location.startsWith('/onboarding')) {
        final onboarded = container.read(userProfileProvider).onboarded;
        if (onboarded) return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: '/auth',
        builder: (_, st) => AuthScreen(
            initialRegister: st.uri.queryParameters['mode'] == 'register'),
      ),
      // Password reset: request (from the login screen) + confirm (from the
      // email link, carrying uid+token).
      GoRoute(
        path: '/auth/forgot',
        builder: (_, __) => const PasswordResetRequestScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, st) => PasswordResetConfirmScreen(
          uid: st.uri.queryParameters['uid'] ?? '',
          token: st.uri.queryParameters['token'] ?? '',
        ),
      ),

      // Registration + onboarding pipelines (Epic 3)
      GoRoute(path: '/role', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(
          path: '/onboarding/user',
          builder: (_, __) => const OnboardingUserScreen()),
      GoRoute(
          path: '/onboarding/specialist',
          builder: (_, __) => const OnboardingSpecialistScreen()),

      // Profile sub-screens + progress (Epic 3)
      GoRoute(
          path: '/profile/edit',
          builder: (_, __) => const ProfileEditScreen()),
      GoRoute(path: '/sessions', builder: (_, __) => const SessionsScreen()),
      GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
      GoRoute(
          path: '/favorites', builder: (_, __) => const FavoritesScreen()),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
      GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
      GoRoute(path: '/mbti', builder: (_, __) => const MbtiScreen()),

      // Psychologist cabinet sub-screens.
      GoRoute(
        path: '/psy/cabinet',
        builder: (_, __) => const PsyCabinetEditScreen(),
      ),
      GoRoute(
        path: '/psy/client/:id',
        builder: (_, st) => ClientDetailScreen(
            clientId: int.tryParse(st.pathParameters['id'] ?? '') ?? 0),
      ),

      // Shell tabs (IndexedStack inside).
      GoRoute(path: '/home', builder: (_, __) => const MainShell(initialTab: 0)),
      GoRoute(path: '/specialists', builder: (_, __) => const MainShell(initialTab: 1)),
      GoRoute(path: '/community', builder: (_, __) => const MainShell(initialTab: 2)),
      GoRoute(path: '/calm', builder: (_, __) => const MainShell(initialTab: 3)),
      GoRoute(path: '/profile', builder: (_, __) => const MainShell(initialTab: 4)),

      // Entry quiz (public — reachable by a guest before auth).
      GoRoute(path: '/quiz', builder: (_, __) => const QuizScreen()),

      // "Поговорить сейчас" funnel (auth-gated — creates a booking).
      GoRoute(
        path: '/instant',
        builder: (_, st) =>
            InstantScreen(concern: st.uri.queryParameters['concern'] ?? ''),
      ),

      // Detail screens (pushed on top).
      GoRoute(path: '/intake', builder: (_, __) => const IntakeScreen()),

      GoRoute(
        path: '/specialists/:id',
        builder: (_, st) => SpecialistDetailScreen(id: st.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (_, st) =>
            BookingScreen(specialistId: st.pathParameters['id']!),
      ),
      GoRoute(
        path: '/payment/:id',
        builder: (_, st) => PaymentScreen(booking: st.extra as AppBooking),
      ),
      GoRoute(
        path: '/payment-success',
        builder: (_, st) => PaymentSuccessScreen(
          draft: st.extra as BookingDraft,
          requested: st.uri.queryParameters['requested'] == '1',
        ),
      ),

      GoRoute(
        path: '/community/compose',
        builder: (_, __) => const CommunityComposeScreen(),
      ),
      GoRoute(
        path: '/community/:id',
        builder: (_, st) =>
            CommunityPostScreen(postId: st.pathParameters['id']!),
      ),

      GoRoute(path: '/chats', builder: (_, __) => const ChatListScreen()),
      GoRoute(
        path: '/chats/:id',
        builder: (_, st) => ChatScreen(chatId: st.pathParameters['id']!),
      ),
      GoRoute(
        path: '/call/:room',
        builder: (_, st) =>
            VideoCallScreen(roomSeed: st.pathParameters['room']!),
      ),

      GoRoute(
        path: '/legal/privacy',
        builder: (_, __) => const LegalScreen(doc: LegalDoc.privacy),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (_, __) => const LegalScreen(doc: LegalDoc.terms),
      ),
      GoRoute(
        path: '/legal/about',
        builder: (_, __) => const LegalScreen(doc: LegalDoc.about),
      ),
    ],
  );
}
