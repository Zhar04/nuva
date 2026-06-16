import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/booking.dart';
import '../services/backend_auth.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';
import '../widgets/user_avatar.dart';

/// Psychologist "Сегодня": greeting + the sessions clients booked with them.
class PsyTodayScreen extends ConsumerWidget {
  const PsyTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final user = ref.watch(backendAuthProvider).user;
    final name = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : 'специалист';
    final async = ref.watch(incomingBookingsProvider);

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Здравствуйте,',
                        style: TextStyle(color: t.textSec, fontSize: 14)),
                    Text(name,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Text('ВАШИ СЕССИИ',
                    style: TextStyle(
                      color: t.textTer,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    )),
              ),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _empty(t),
                  data: (sessions) {
                    final upcoming = sessions
                        .where((b) =>
                            b.status != 'cancelled' && b.status != 'completed')
                        .toList()
                      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
                    if (upcoming.isEmpty) return _empty(t);
                    return RefreshIndicator(
                      color: t.blue,
                      backgroundColor: t.surface,
                      onRefresh: () async {
                        ref.invalidate(incomingBookingsProvider);
                        await ref.read(incomingBookingsProvider.future);
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
                        itemCount: upcoming.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _SessionCard(booking: upcoming[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(NuvaTokens t) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available_rounded, size: 54, color: t.textTer),
              const SizedBox(height: 14),
              Text('Пока нет записей',
                  style: TextStyle(
                      color: t.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                'Как только клиент запишется к вам — сессия появится здесь.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textSec, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      );
}

class _SessionCard extends StatelessWidget {
  final AppBooking booking;
  const _SessionCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final when = DateFormat('d MMMM · HH:mm', 'ru').format(booking.startsAt);
    final convId = booking.conversationId;
    return GlassCard(
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientAvatar(
                initials: booking.clientName.isNotEmpty
                    ? booking.clientName[0].toUpperCase()
                    : 'К',
                gradient: const [Color(0xFF7E8BD9), Color(0xFFB39DDB)],
                size: 44,
                radius: 14,
                fontSize: 17,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.clientName,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600)),
                    Text('$when · ${booking.formatLabel}',
                        style: TextStyle(color: t.textSec, fontSize: 12.5)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: t.glassBgUp,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(booking.statusLabel,
                    style: TextStyle(
                        color: t.textSec,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: convId == null
                      ? null
                      : () => context.push('/chats/$convId'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Чат'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.blue,
                    side: BorderSide(color: t.glassBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (convId == null || !booking.joinable)
                      ? null
                      : () => context.push('/call/conv$convId'),
                  icon: const Icon(Icons.videocam_rounded, size: 16),
                  label: Text(booking.joinable ? 'Войти' : 'По времени'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: booking.joinable ? t.teal : t.textTer,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Psychologist profile: avatar, their public listing summary, settings.
class PsyProfileScreen extends ConsumerWidget {
  const PsyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final user = ref.watch(backendAuthProvider).user;
    final me = ref.watch(specialistMeProvider).valueOrNull;
    final name = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : 'Специалист';

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
            children: [
              GestureDetector(
                onTap: () => context.push('/profile/edit'),
                child: Row(
                  children: [
                    UserAvatar(
                      avatar: user?.avatar ?? '',
                      initials:
                          name.isNotEmpty ? name[0].toUpperCase() : 'П',
                      gradient: const [Color(0xFF7E8BD9), Color(0xFFB39DDB)],
                      size: 64,
                      radius: 20,
                      fontSize: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: t.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('Психолог',
                                style: TextStyle(
                                    color: t.blue,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_outlined, color: t.textTer, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('ВАШ ПРОФИЛЬ В КАТАЛОГЕ',
                  style: TextStyle(
                      color: t.textTer,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1)),
              const SizedBox(height: 10),
              GlassCard(
                elevated: true,
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: me == null
                    ? Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: t.textSec, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Профиль ещё не заполнен — клиенты вас не видят. '
                              'Заполните в онбординге специалиста.',
                              style: TextStyle(
                                  color: t.textSec, fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(me.title,
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            'Сессия от ${me.sessionPriceKzt} ₸ · ${me.yearsExperience} лет опыта',
                            style: TextStyle(color: t.textSec, fontSize: 12.5),
                          ),
                          if (me.worksWith.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: me.worksWith
                                  .map((w) => Tag(label: w))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 22),
              Text('НАСТРОЙКИ',
                  style: TextStyle(
                      color: t.textTer,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1)),
              const SizedBox(height: 10),
              _row(t, Icons.edit_outlined, 'Редактировать профиль',
                  () => context.push('/profile/edit')),
              _row(
                t,
                ref.watch(themeModeProvider) == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : (ref.watch(themeModeProvider) == ThemeMode.light
                        ? Icons.light_mode_rounded
                        : Icons.brightness_auto_rounded),
                'Тема',
                () {
                  final next = switch (ref.read(themeModeProvider)) {
                    ThemeMode.system => ThemeMode.light,
                    ThemeMode.light => ThemeMode.dark,
                    ThemeMode.dark => ThemeMode.system,
                  };
                  ref.read(themeModeProvider.notifier).set(next);
                },
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await ref.read(backendAuthProvider.notifier).logout();
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                  child: Text('Выйти',
                      style: TextStyle(color: t.danger, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(NuvaTokens t, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: t.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: t.text, fontSize: 14.5)),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: t.textTer),
          ],
        ),
      ),
    );
  }
}
