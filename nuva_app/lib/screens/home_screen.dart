import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/booking.dart';
import '../models/specialist.dart';
import '../services/backend_auth.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    final specialists =
        ref.watch(specialistsProvider).valueOrNull ?? specialistCatalog;

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(specialistsProvider);
              ref.invalidate(bookingsProvider);
              await ref.read(specialistsProvider.future);
            },
            color: t.blue,
            backgroundColor: t.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.homeHello,
                              style: TextStyle(
                                color: t.textSec,
                                fontSize: 14,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            s.homeQuestion,
                            style: TextStyle(
                              color: t.text,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ThemeSwitch(),
                    const SizedBox(width: 8),
                    _LangSwitch(),
                  ],
                ),
                const SizedBox(height: 20),
                _MoodRow(),
                const SizedBox(height: 20),
                _MyBookings(),
                const SizedBox(height: 18),
                SectionLabel(label: 'Быстрые действия'),
                _PrimaryAction(
                  icon: Icons.auto_awesome_rounded,
                  title: s.aiHelp,
                  sub: s.findSpecialist,
                  onTap: () => context.push('/intake'),
                ),
                const SizedBox(height: 12),
                _PrimaryAction(
                  icon: Icons.psychology_rounded,
                  title: s.specialists,
                  sub: '${specialists.length} проверенных психологов',
                  onTap: () => context.go('/specialists'),
                ),
                const SizedBox(height: 18),
                SectionLabel(label: 'Рекомендуем'),
                ...specialists.take(2).map((sp) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SpecialistMini(
                        sp: sp,
                        onTap: () => context.push('/specialists/${sp.id}'),
                      ),
                    )),
                const SizedBox(height: 8),
                _EmergencyCard(label: s.needHelpNow),
              ],
            ),
          )),
        ),
      ),
    );
  }
}

class _LangSwitch extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final lang = ref.watch(langProvider);
    return GlassCard(
      onTap: () {
        final next = AppLang.values[(lang.index + 1) % AppLang.values.length];
        ref.read(langProvider.notifier).state = next;
      },
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevated: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language_rounded, size: 14, color: t.blue),
          const SizedBox(width: 5),
          Text(
            lang.code,
            style: TextStyle(
              color: t.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSwitch extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final mode = ref.watch(themeModeProvider);
    final icon = switch (mode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      _ => Icons.brightness_auto_rounded,
    };
    return GlassCard(
      onTap: () {
        final next = switch (mode) {
          ThemeMode.system => ThemeMode.light,
          ThemeMode.light => ThemeMode.dark,
          ThemeMode.dark => ThemeMode.system,
        };
        ref.read(themeModeProvider.notifier).set(next);
      },
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevated: true,
      child: Icon(icon, size: 16, color: t.blue),
    );
  }
}

class _MoodRow extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MoodRow> createState() => _MoodRowState();
}

class _MoodRowState extends ConsumerState<_MoodRow> {
  int? _picked;

  Future<void> _save(int mood) async {
    try {
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      await ref.read(apiClientProvider).post(
        'journal/moods/',
        {'mood': mood},
        token: token,
      );
      ref.invalidate(gamificationProvider);
      ref.invalidate(moodHistoryProvider);
    } catch (_) {
      // Not signed in / backend off — the pick still shows locally.
    }
  }

  // Mood orbs: gradient circle + white line-face icon along a gentle spectrum.
  static const _moods = <(IconData, String, List<Color>)>[
    (Icons.sentiment_very_dissatisfied_rounded, 'Грустно',
        [Color(0xFF8E9BE6), Color(0xFFB3BCF0)]),
    (Icons.sentiment_dissatisfied_rounded, 'Тревожно',
        [Color(0xFFF2A65A), Color(0xFFF7C48B)]),
    (Icons.sentiment_neutral_rounded, 'Так себе',
        [Color(0xFF93A0B5), Color(0xFFB7C0CE)]),
    (Icons.sentiment_satisfied_rounded, 'Норм',
        [Color(0xFF49C6C0), Color(0xFF86DED6)]),
    (Icons.sentiment_very_satisfied_rounded, 'Хорошо',
        [Color(0xFF5DC98A), Color(0xFF8FE0AC)]),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_moods.length, (i) {
          final m = _moods[i];
          final picked = _picked == i;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _picked = i);
              _save(i + 1);
            },
            child: AnimatedScale(
              scale: picked ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: m.$3,
                      ),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: picked ? 0.55 : 0.18),
                        width: picked ? 1.5 : 1,
                      ),
                      boxShadow: picked
                          ? [
                              BoxShadow(
                                color: m.$3.last.withValues(alpha: 0.55),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(m.$1, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    m.$2,
                    style: TextStyle(
                      color: picked ? t.text : t.textSec,
                      fontSize: 10.5,
                      fontWeight: picked ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Real booking statuses for the client: a confirmed request awaiting payment,
/// a declined request (with the psychologist's reason / proposed time), and
/// upcoming confirmed sessions. Falls back to a soft placeholder when empty.
class _MyBookings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(bookingsProvider).valueOrNull ?? const <AppBooking>[];
    final now = DateTime.now();
    final awaiting = all.where((b) => b.isAwaitingPayment).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final declined = all.where((b) => b.isDeclined).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    final upcoming = all
        .where((b) => b.isConfirmed && b.startsAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    if (awaiting.isEmpty && declined.isEmpty && upcoming.isEmpty) {
      return _UpcomingSession();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(label: 'Мои записи'),
        for (final b in awaiting) ...[
          _AwaitingPaymentCard(booking: b),
          const SizedBox(height: 10),
        ],
        for (final b in declined.take(2)) ...[
          _DeclinedCard(booking: b),
          const SizedBox(height: 10),
        ],
        for (final b in upcoming.take(3)) ...[
          _ConfirmedCard(booking: b),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AwaitingPaymentCard extends StatelessWidget {
  final AppBooking booking;
  const _AwaitingPaymentCard({required this.booking});

  static const _amber = Color(0xFFE8A33D);

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final when = DateFormat('d MMMM · HH:mm', 'ru').format(booking.startsAt);
    final total = NumberFormat.currency(
            locale: 'ru_KZ', symbol: '₸', decimalDigits: 0)
        .format(booking.priceKzt + booking.serviceFeeKzt);
    return GlassCard(
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_rounded, color: _amber, size: 12),
                    SizedBox(width: 5),
                    Text('ЗАПРОС ПОДТВЕРЖДЁН',
                        style: TextStyle(
                          color: _amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        )),
                  ],
                ),
              ),
              const Spacer(),
              Text(when,
                  style: TextStyle(
                      color: t.text, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GradientAvatar(
                initials: booking.specialistInitials.isNotEmpty
                    ? booking.specialistInitials
                    : 'П',
                gradient: booking.gradient,
                size: 42,
                radius: 13,
                fontSize: 15,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.specialistName,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    Text('${booking.formatLabel} · ждёт оплаты',
                        style: TextStyle(color: t.textSec, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => context.push('/payment/${booking.id}',
                  extra: booking),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text('Оплатить · $total',
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeclinedCard extends StatelessWidget {
  final AppBooking booking;
  const _DeclinedCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final proposed = booking.proposedStartsAt;
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: t.textSec, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Запрос к ${booking.specialistName} не подтверждён',
                    style: TextStyle(
                        color: t.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (booking.declineReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Причина: ${booking.declineReason}',
                style: TextStyle(color: t.textSec, fontSize: 12.5, height: 1.4)),
          ],
          if (proposed != null) ...[
            const SizedBox(height: 6),
            Text(
                'Психолог предложил: '
                '${DateFormat('d MMMM · HH:mm', 'ru').format(proposed)}',
                style: TextStyle(color: t.teal, fontSize: 12.5)),
          ],
          if (booking.specialistId != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () =>
                    context.push('/booking/${booking.specialistId}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.blue,
                  side: BorderSide(color: t.glassBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
                child: const Text('Выбрать другое время'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmedCard extends StatelessWidget {
  final AppBooking booking;
  const _ConfirmedCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final when = DateFormat('d MMMM · HH:mm', 'ru').format(booking.startsAt);
    final convId = booking.conversationId;
    return GlassCard(
      onTap: convId == null ? null : () => context.push('/chats/$convId'),
      elevated: true,
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          GradientAvatar(
            initials: booking.specialistInitials.isNotEmpty
                ? booking.specialistInitials
                : 'П',
            gradient: booking.gradient,
            size: 42,
            radius: 13,
            fontSize: 15,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(booking.specialistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: t.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    if (booking.isIntro)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Бесплатно',
                            style: TextStyle(
                                color: t.teal,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$when · ${booking.formatLabel}',
                    style: TextStyle(color: t.textSec, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chat_bubble_outline_rounded, color: t.blue, size: 20),
        ],
      ),
    );
  }
}

class _UpcomingSession extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final sp =
        (ref.watch(specialistsProvider).valueOrNull ?? specialistCatalog).first;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dateLabel = DateFormat('d MMM · EEEE', 'ru').format(tomorrow);

    return GlassCard(
      onTap: () => context.push('/chats'),
      elevated: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: t.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: t.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('ЗАВТРА',
                        style: TextStyle(
                          color: t.teal,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        )),
                  ],
                ),
              ),
              const Spacer(),
              Text('$dateLabel · 14:00',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GradientAvatar(
                initials: sp.initials,
                gradient: sp.avatarGradient,
                size: 44,
                radius: 14,
                fontSize: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sp.fullName,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    Text('${sp.title} · Видео',
                        style: TextStyle(color: t.textSec, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: t.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chat_bubble_rounded,
                        color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('Чат',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _PrimaryAction({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.blue, t.blueDeep],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: t.blue.withValues(alpha: t.dark ? 0.34 : 0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12.5)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Colors.white.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}

class _SpecialistMini extends StatelessWidget {
  final Specialist sp;
  final VoidCallback onTap;
  const _SpecialistMini({required this.sp, required this.onTap});

  static final _fmt = NumberFormat.currency(
      locale: 'ru_KZ', symbol: '₸', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      onTap: onTap,
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          GradientAvatar(
            initials: sp.initials,
            gradient: sp.avatarGradient,
            size: 44,
            radius: 14,
            fontSize: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(sp.fullName,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, color: t.blue, size: 12),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: t.teal, size: 12),
                    const SizedBox(width: 2),
                    Text('${sp.rating}',
                        style: TextStyle(
                          color: t.text,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 8),
                    Text(sp.title,
                        style:
                            TextStyle(color: t.textSec, fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
          Text(_fmt.format(sp.sessionPriceKzt),
              style: TextStyle(
                color: t.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final String label;
  const _EmergencyCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      onTap: () {},
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.danger.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.favorite_rounded, color: t.danger, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: t.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                Text('Кризисная линия Казахстан · 150',
                    style: TextStyle(
                      color: t.danger.withValues(alpha: 0.75),
                      fontSize: 11.5,
                    )),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: t.danger.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
