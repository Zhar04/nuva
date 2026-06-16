import 'package:go_router/go_router.dart';

import '../screens/auth_screen.dart';
import '../screens/booking_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/community_compose_screen.dart';
import '../screens/community_post_screen.dart';
import '../screens/intake_screen.dart';
import '../screens/legal_screens.dart';
import '../screens/main_shell.dart';
import '../screens/mbti_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/onboarding_specialist_screen.dart';
import '../screens/onboarding_user_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/payment_success_screen.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/profile_subscreens.dart';
import '../screens/progress_screen.dart';
import '../screens/role_select_screen.dart';
import '../screens/specialists_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/video_call_screen.dart';

Future<GoRouter> buildRouter() async {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: '/auth',
        builder: (_, st) => AuthScreen(
            initialRegister: st.uri.queryParameters['mode'] == 'register'),
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
