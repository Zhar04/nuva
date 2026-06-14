import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/auth_screen.dart';
import '../screens/booking_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/community_compose_screen.dart';
import '../screens/community_post_screen.dart';
import '../screens/intake_screen.dart';
import '../screens/legal_screens.dart';
import '../screens/main_shell.dart';
import '../screens/onboarding_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/payment_success_screen.dart';
import '../screens/specialists_screen.dart';
import '../screens/video_call_screen.dart';

Future<GoRouter> buildRouter() async {
  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool('onboarded') ?? false;

  return GoRouter(
    initialLocation: onboarded ? '/home' : '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),

      // Shell tabs (IndexedStack inside).
      GoRoute(path: '/home', builder: (_, __) => const MainShell(initialTab: 0)),
      GoRoute(path: '/specialists', builder: (_, __) => const MainShell(initialTab: 1)),
      GoRoute(path: '/community', builder: (_, __) => const MainShell(initialTab: 2)),
      GoRoute(path: '/calm', builder: (_, __) => const MainShell(initialTab: 3)),
      GoRoute(path: '/profile', builder: (_, __) => const MainShell(initialTab: 4)),

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
        builder: (_, st) => PaymentScreen(draft: st.extra as BookingDraft),
      ),
      GoRoute(
        path: '/payment-success',
        builder: (_, st) =>
            PaymentSuccessScreen(draft: st.extra as BookingDraft),
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
        path: '/call/:specialistId',
        builder: (_, st) =>
            VideoCallScreen(specialistId: st.pathParameters['specialistId']!),
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
