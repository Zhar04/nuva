import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/booking.dart';
import '../models/chat.dart';
import '../models/specialist.dart';
import '../services/api_client.dart';
import '../services/backend_auth.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../widgets/auto_refresh.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';
import '../widgets/user_avatar.dart';

const _amber = Color(0xFFE8A33D);

/// Format a KZT amount with thin spaces: 15000 → "15 000 ₸".
String _kzt(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b ₸';
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Доброе утро,';
  if (h < 18) return 'Добрый день,';
  return 'Добрый вечер,';
}

bool _isPaid(AppBooking b) => b.status == 'paid' || b.status == 'completed';
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Compact theme cycler (System → Light → Dark) for the cabinet header.
class _PsyThemeSwitch extends ConsumerWidget {
  const _PsyThemeSwitch();

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

/// Compact language cycler (RU → KZ → EN) for the cabinet header.
class _PsyLangSwitch extends ConsumerWidget {
  const _PsyLangSwitch();

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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      elevated: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language_rounded, size: 14, color: t.blue),
          const SizedBox(width: 5),
          Text(lang.code,
              style: TextStyle(
                  color: t.text, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Shared psychologist screen header (title + optional subtitle + trailing).
class _SpecHeader extends StatelessWidget {
  final String title;
  final String? sub;
  final Widget? trailing;
  const _SpecHeader({required this.title, this.sub, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    )),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub!,
                      style: TextStyle(color: t.textSec, fontSize: 12.5)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Small section label with a leading icon (matches the prototype's section
/// captions).
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  const _SectionLabel({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: t.textSec),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                color: t.textSec,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              )),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

/// Banner shown across the cabinet while the profile awaits verification.
class _VerifyBanner extends StatelessWidget {
  const _VerifyBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.12),
        border: Border.all(color: _amber.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: _amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Профиль на проверке',
                    style: TextStyle(
                        color: t.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Мы проверяем ваши документы. Пока вы не видны клиентам '
                  'в каталоге и не принимаете записи.',
                  style:
                      TextStyle(color: t.textSec, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 1 · Сегодня (dashboard)
// ════════════════════════════════════════════════════════════
class PsyTodayScreen extends ConsumerWidget {
  const PsyTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final user = ref.watch(backendAuthProvider).user;
    final name = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : 'специалист';
    final me = ref.watch(specialistMeProvider).valueOrNull;
    final bookings =
        ref.watch(incomingBookingsProvider).valueOrNull ?? const <AppBooking>[];

    final now = DateTime.now();
    final upcoming = bookings.where((b) => b.isUpcoming).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final next = upcoming.isNotEmpty ? upcoming.first : null;
    final today = bookings
        .where((b) =>
            _sameDay(b.startsAt, now) &&
            b.status != 'cancelled' &&
            b.status != 'refunded')
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final monthEarn = bookings
        .where((b) =>
            _isPaid(b) &&
            b.startsAt.year == now.year &&
            b.startsAt.month == now.month)
        .fold<int>(0, (s, b) => s + b.priceKzt);

    return AutoRefresh(
      interval: const Duration(seconds: 8),
      onTick: (ref) {
        ref.invalidate(incomingBookingsProvider);
        ref.invalidate(conversationsProvider);
        ref.invalidate(specialistMeProvider);
      },
      child: Scaffold(
        body: GlassBackdrop(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 130),
              children: [
                // greeting row
                Row(
                  children: [
                    UserAvatar(
                      avatar: user?.avatar ?? '',
                      initials: name.characters.first.toUpperCase(),
                      gradient: const [Color(0xFF7E8BD9), Color(0xFFB39DDB)],
                      size: 46,
                      radius: 999,
                      fontSize: 19,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(),
                              style:
                                  TextStyle(color: t.textSec, fontSize: 13)),
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: t.text,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              )),
                        ],
                      ),
                    ),
                    const _PsyThemeSwitch(),
                    const SizedBox(width: 6),
                    const _PsyLangSwitch(),
                    IconButton(
                      onPressed: () => context.push('/chats'),
                      icon: Icon(Icons.chat_bubble_outline_rounded,
                          color: t.text, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // role badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, size: 14, color: t.blue),
                        const SizedBox(width: 6),
                        Text('Режим специалиста',
                            style: TextStyle(
                                color: t.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (me != null && !me.isVerified) ...[
                  const _VerifyBanner(),
                  const SizedBox(height: 14),
                ],
                // next session hero
                _NextSessionHero(next: next),
                const SizedBox(height: 18),
                // stats
                Row(
                  children: [
                    _StatCard(
                      value: me != null && me.rating > 0
                          ? me.rating.toStringAsFixed(1)
                          : '—',
                      label: 'Рейтинг',
                      icon: Icons.star_rounded,
                      accent: _amber,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: '${today.length}',
                      label: 'Сегодня сессий',
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: monthEarn > 0
                          ? '${(monthEarn / 1000).toStringAsFixed(monthEarn >= 10000 ? 0 : 1)}к ₸'
                          : '0 ₸',
                      label: 'За месяц',
                      accent: t.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionLabel(
                    icon: Icons.calendar_today_rounded, label: 'СЕГОДНЯ'),
                if (today.isEmpty)
                  _EmptyHint(
                    icon: Icons.event_available_rounded,
                    title: 'На сегодня записей нет',
                    sub: 'Свободный день — отдохните или откройте новые слоты.',
                  )
                else
                  ...today.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _TimelineRow(booking: b, isNext: b == next),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextSessionHero extends StatelessWidget {
  final AppBooking? next;
  const _NextSessionHero({this.next});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    if (next == null) {
      return GlassCard(
        elevated: true,
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.event_note_rounded, color: t.textSec, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Нет предстоящих сессий',
                  style: TextStyle(
                      color: t.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
    final b = next!;
    final when = DateFormat('d MMMM · HH:mm', 'ru').format(b.startsAt);
    final mins = b.startsAt.difference(DateTime.now()).inMinutes;
    final soon = mins >= 0 && mins <= 120;
    final convId = b.conversationId;
    return GlassCard(
      elevated: true,
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('СЛЕДУЮЩАЯ СЕССИЯ',
                  style: TextStyle(
                      color: t.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3)),
              const SizedBox(width: 8),
              if (soon)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.teal.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: t.teal),
                      const SizedBox(width: 4),
                      Text(mins <= 0 ? 'сейчас' : 'через $mins мин',
                          style: TextStyle(
                              color: t.teal,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GradientAvatar(
                initials: b.clientName.isNotEmpty
                    ? b.clientName[0].toUpperCase()
                    : 'К',
                gradient: const [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
                size: 48,
                radius: 999,
                fontSize: 18,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.clientName,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('$when · ${b.formatLabel}',
                        style: TextStyle(color: t.textSec, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (convId == null || !b.joinable)
                      ? null
                      : () => context.push('/call/conv$convId'),
                  icon: const Icon(Icons.videocam_rounded, size: 18),
                  label: Text(b.joinable ? 'Войти' : 'По времени'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: b.joinable ? t.teal : t.textTer,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: convId == null
                      ? null
                      : () => context.push('/chats/$convId'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                  label: const Text('Чат'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.blue,
                    side: BorderSide(color: t.glassBorder),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
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

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? accent;
  const _StatCard(
      {required this.value, required this.label, this.icon, this.accent});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Expanded(
      child: GlassCard(
        elevated: true,
        radius: 18,
        padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: accent ?? t.text),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent ?? t.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: t.textSec, fontSize: 11.5, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final AppBooking booking;
  final bool isNext;
  const _TimelineRow({required this.booking, this.isNext = false});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final done = booking.startsAt
        .add(const Duration(minutes: 50))
        .isBefore(DateTime.now());
    final convId = booking.conversationId;
    return GlassCard(
      elevated: isNext,
      radius: 16,
      onTap: convId == null ? null : () => context.push('/chats/$convId'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Opacity(
        opacity: done ? 0.7 : 1,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(DateFormat('HH:mm').format(booking.startsAt),
                  style: TextStyle(
                      color: t.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
            GradientAvatar(
              initials: booking.clientName.isNotEmpty
                  ? booking.clientName[0].toUpperCase()
                  : 'К',
              gradient: const [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
              size: 32,
              radius: 999,
              fontSize: 13,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600)),
                  Text(booking.formatLabel,
                      style: TextStyle(color: t.textSec, fontSize: 11.5)),
                ],
              ),
            ),
            if (done)
              Icon(Icons.check_circle_rounded, size: 18, color: t.teal)
            else if (isNext)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: t.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Следующая',
                    style: TextStyle(
                        color: t.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  const _EmptyHint(
      {required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Icon(icon, size: 48, color: t.textTer),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: t.text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textSec, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2 · Расписание (weekly availability editor)
// ════════════════════════════════════════════════════════════
class PsyScheduleScreen extends ConsumerStatefulWidget {
  const PsyScheduleScreen({super.key});

  @override
  ConsumerState<PsyScheduleScreen> createState() => _PsyScheduleState();
}

class _PsyScheduleState extends ConsumerState<PsyScheduleScreen> {
  static const _dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  // Slots a psychologist can switch on/off for each weekday.
  static const _allSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00', '14:00',
    '15:00', '16:00', '17:00', '18:00', '19:00', '20:00',
  ];

  int _selDay = DateTime.now().weekday; // 1..7
  bool _open = true;
  bool _saving = false;
  bool _loaded = false;
  Map<int, Set<String>> _avail = {};

  void _hydrate(Specialist? me) {
    if (_loaded || me == null) return;
    _loaded = true;
    _avail = {
      for (final e in me.availability.entries) e.key: e.value.toSet(),
    };
    _open = me.availability.values.any((l) => l.isNotEmpty) || true;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final payload = <String, List<String>>{};
    _avail.forEach((day, slots) {
      if (slots.isNotEmpty) {
        payload['$day'] = slots.toList()..sort();
      }
    });
    try {
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      await ref.read(apiClientProvider).put(
        'specialists/me',
        {'availability': payload, 'is_active': _open},
        token: token,
      );
      ref.invalidate(specialistMeProvider);
      ref.invalidate(specialistsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Расписание сохранено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: context.nuva.danger,
          content: Text(e is ApiException ? e.message : 'Не удалось сохранить',
              style: const TextStyle(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final me = ref.watch(specialistMeProvider).valueOrNull;
    _hydrate(me);
    final daySlots = _avail[_selDay] ?? <String>{};
    final bookings =
        ref.watch(incomingBookingsProvider).valueOrNull ?? const <AppBooking>[];
    // Dates of the current ISO week (Mon → Sun), so the strip shows real days.
    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final weekDates =
        List.generate(7, (i) => monday.add(Duration(days: i)));
    final selDate = weekDates[_selDay - 1];
    bool onCalendar(AppBooking b) => b.isConfirmed || b.isAwaitingPayment;
    int sessionsOn(DateTime d) =>
        bookings.where((b) => onCalendar(b) && _sameDay(b.startsAt, d)).length;
    final daySessions = bookings
        .where((b) => onCalendar(b) && _sameDay(b.startsAt, selDate))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _SpecHeader(
                title: 'Расписание',
                trailing: TextButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Сохраняем…' : 'Сохранить',
                      style: TextStyle(
                          color: t.blue,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 130),
                  children: [
                    // availability toggle
                    GlassCard(
                      elevated: true,
                      radius: 20,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [t.blue, t.teal],
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.event_available_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Приём открыт',
                                    style: TextStyle(
                                        color: t.text,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600)),
                                Text('Клиенты видят свободные слоты',
                                    style: TextStyle(
                                        color: t.textSec, fontSize: 12)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _open,
                            activeTrackColor: t.blue,
                            onChanged: (v) => setState(() => _open = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // week strip
                    Row(
                      children: List.generate(7, (i) {
                        final day = i + 1;
                        final on = day == _selDay;
                        final date = weekDates[i];
                        final isToday = _sameDay(date, today);
                        final hasSessions = sessionsOn(date) > 0;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _selDay = day),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: on
                                      ? LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [t.blue, t.blueDeep])
                                      : null,
                                  color: on ? null : t.glassBgUp,
                                  border: Border.all(
                                      color: on
                                          ? Colors.transparent
                                          : (isToday
                                              ? t.blue
                                              : t.glassBorder)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    Text(_dayNames[i],
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: on
                                              ? Colors.white70
                                              : t.textSec,
                                        )),
                                    const SizedBox(height: 3),
                                    Text('${date.day}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: on
                                              ? Colors.white
                                              : (isToday ? t.blue : t.text),
                                        )),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: hasSessions
                                            ? (on ? Colors.white : t.teal)
                                            : Colors.transparent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel(
                      icon: Icons.schedule_rounded,
                      label: 'СЛОТЫ · ${_dayNames[_selDay - 1]}',
                      trailing: Text(
                        '${daySlots.length} активно',
                        style: TextStyle(
                            color: t.textTer,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'Нажмите на время, чтобы открыть или закрыть слот для записи.',
                      style: TextStyle(
                          color: t.textSec, fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _allSlots.map((time) {
                        final on = daySlots.contains(time);
                        return GestureDetector(
                          onTap: () => setState(() {
                            final set = _avail.putIfAbsent(_selDay, () => {});
                            if (on) {
                              set.remove(time);
                            } else {
                              set.add(time);
                            }
                          }),
                          child: Container(
                            width: 86,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: on ? t.blue : t.glassBgUp,
                              border: Border.all(
                                  color: on ? t.blue : t.glassBorder,
                                  width: on ? 1.5 : 1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  on
                                      ? Icons.check_circle_rounded
                                      : Icons.add_circle_outline_rounded,
                                  size: 15,
                                  color: on ? Colors.white : t.textTer,
                                ),
                                const SizedBox(width: 5),
                                Text(time,
                                    style: TextStyle(
                                      color: on ? Colors.white : t.text,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 26),
                    _SectionLabel(
                      icon: Icons.people_alt_rounded,
                      label:
                          'ЗАПИСИ · ${_dayNames[_selDay - 1]} ${selDate.day}.${selDate.month.toString().padLeft(2, '0')}',
                      trailing: Text('${daySessions.length}',
                          style: TextStyle(
                              color: t.textTer,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (daySessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                            'На этот день записей пока нет — подтверждённые '
                            'заявки появятся здесь.',
                            style: TextStyle(
                                color: t.textSec, fontSize: 12.5, height: 1.4)),
                      )
                    else
                      ...daySessions.map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _ScheduleSessionRow(booking: b),
                          )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One confirmed session in the schedule's day view: "09:00 · Имя · формат".
class _ScheduleSessionRow extends StatelessWidget {
  final AppBooking booking;
  const _ScheduleSessionRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final paid = booking.isConfirmed && !booking.isAwaitingPayment;
    final cid = booking.clientId;
    return GlassCard(
      elevated: true,
      radius: 16,
      onTap: cid == null ? null : () => context.push('/psy/client/$cid'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(DateFormat('HH:mm').format(booking.startsAt),
                style: TextStyle(
                    color: t.text, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          GradientAvatar(
            initials: booking.clientName.isNotEmpty
                ? booking.clientName[0].toUpperCase()
                : 'К',
            gradient: const [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
            size: 32,
            radius: 999,
            fontSize: 13,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600)),
                Text(
                    '${booking.formatLabel}'
                    '${booking.isIntro ? ' · ознакомительная' : ''}',
                    style: TextStyle(color: t.textSec, fontSize: 11.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (paid ? t.teal : _amber).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(paid ? 'Подтверждена' : 'Ждёт оплаты',
                style: TextStyle(
                    color: paid ? t.teal : _amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 3 · Запросы (real call requests + new bookings)
// ════════════════════════════════════════════════════════════
class PsyRequestsScreen extends ConsumerWidget {
  const PsyRequestsScreen({super.key});

  Future<void> _acceptCall(WidgetRef ref, int convId) async {
    try {
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      await ref.read(apiClientProvider).post(
        'chat/conversations/$convId/call/',
        {'action': 'accept'},
        token: token,
      );
      ref.invalidate(conversationsProvider);
    } catch (_) {}
  }

  Future<void> _accept(BuildContext context, WidgetRef ref, AppBooking b) async {
    try {
      await ref.read(psyActionsProvider).accept(b.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(b.isIntro
              ? 'Принято — добавлено в расписание'
              : 'Принято — клиент получит счёт на оплату'),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: context.nuva.danger,
          content: Text(e is ApiException ? e.message : 'Не удалось принять',
              style: const TextStyle(color: Colors.white)),
        ));
      }
    }
  }

  Future<void> _decline(BuildContext context, WidgetRef ref, AppBooking b) async {
    final result = await showModalBottomSheet<_DeclineResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeclineSheet(booking: b),
    );
    if (result == null) return;
    try {
      await ref.read(psyActionsProvider).decline(
            b.id,
            reason: result.reason,
            proposed: result.proposed,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка отклонена')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: context.nuva.danger,
          content: Text(e is ApiException ? e.message : 'Не удалось отклонить',
              style: const TextStyle(color: Colors.white)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convos =
        ref.watch(conversationsProvider).valueOrNull ?? const <ApiConversation>[];
    final bookings =
        ref.watch(incomingBookingsProvider).valueOrNull ?? const <AppBooking>[];

    final callReqs = convos
        .where((c) => c.viewerIsSpecialist && c.callRequested && !c.callAccepted)
        .toList();
    final requests = bookings.where((b) => b.isRequest).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return AutoRefresh(
      interval: const Duration(seconds: 6),
      onTick: (ref) {
        ref.invalidate(conversationsProvider);
        ref.invalidate(incomingBookingsProvider);
      },
      child: Scaffold(
        body: GlassBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                _SpecHeader(
                    title: 'Запросы на подбор',
                    sub: requests.isEmpty
                        ? 'Заявки от клиентов'
                        : '${requests.length} ждут вашего решения'),
                Expanded(
                  child: (callReqs.isEmpty && requests.isEmpty)
                      ? ListView(
                          children: const [
                            SizedBox(height: 40),
                            _EmptyHint(
                              icon: Icons.inbox_rounded,
                              title: 'Нет новых запросов',
                              sub: 'Заявки клиентов появятся здесь. После '
                                  'подтверждения сессия перейдёт в Расписание.',
                            ),
                          ],
                        )
                      : ListView(
                          padding:
                              const EdgeInsets.fromLTRB(18, 4, 18, 130),
                          children: [
                            if (callReqs.isNotEmpty) ...[
                              const _SectionLabel(
                                  icon: Icons.videocam_rounded,
                                  label: 'ЗАПРОСЫ НА ЗВОНОК'),
                              ...callReqs.map((c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _CallRequestCard(
                                      convo: c,
                                      onAccept: () => _acceptCall(ref, c.id),
                                      onChat: () =>
                                          context.push('/chats/${c.id}'),
                                    ),
                                  )),
                              const SizedBox(height: 10),
                            ],
                            if (requests.isNotEmpty) ...[
                              const _SectionLabel(
                                  icon: Icons.person_add_alt_1_rounded,
                                  label: 'ЗАЯВКИ КЛИЕНТОВ'),
                              ...requests.map((b) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _RequestCard(
                                      booking: b,
                                      onAccept: () => _accept(context, ref, b),
                                      onDecline: () =>
                                          _decline(context, ref, b),
                                      onOpenClient: b.clientId == null
                                          ? null
                                          : () => context.push(
                                              '/psy/client/${b.clientId}'),
                                    ),
                                  )),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Result of the decline sheet: a reason and an optional proposed new time.
class _DeclineResult {
  final String reason;
  final DateTime? proposed;
  const _DeclineResult(this.reason, this.proposed);
}

class _CallRequestCard extends StatelessWidget {
  final ApiConversation convo;
  final VoidCallback onAccept;
  final VoidCallback onChat;
  const _CallRequestCard(
      {required this.convo, required this.onAccept, required this.onChat});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      elevated: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              GradientAvatar(
                initials: convo.otherInitials,
                gradient: convo.gradient,
                size: 48,
                radius: 999,
                fontSize: 18,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(convo.otherName,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.videocam_rounded, size: 14, color: t.teal),
                        const SizedBox(width: 5),
                        Text('Хочет видеозвонок',
                            style: TextStyle(
                                color: t.teal,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Принять'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: OutlinedButton(
                  onPressed: onChat,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.textSec,
                    side: BorderSide(color: t.glassBorder),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Открыть чат'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A rich client request card: avatar, %-match, intent, concern, message, time,
/// and Accept / Decline. Tapping the header opens the client's card.
class _RequestCard extends StatelessWidget {
  final AppBooking booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onOpenClient;
  const _RequestCard({
    required this.booking,
    required this.onAccept,
    required this.onDecline,
    this.onOpenClient,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final when = DateFormat('d MMMM · HH:mm', 'ru').format(booking.startsAt);
    final intro = booking.isIntro;
    return GlassCard(
      elevated: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpenClient,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                GradientAvatar(
                  initials: booking.clientName.isNotEmpty
                      ? booking.clientName[0].toUpperCase()
                      : 'К',
                  gradient: const [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
                  size: 48,
                  radius: 999,
                  fontSize: 18,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(booking.clientName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: t.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (booking.matchScore > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: t.teal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('${booking.matchScore}% совпадение',
                                  style: TextStyle(
                                      color: t.teal,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('$when · ${booking.formatLabel}',
                          style: TextStyle(color: t.textSec, fontSize: 12.5)),
                    ],
                  ),
                ),
                if (onOpenClient != null)
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: t.textTer),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Icon(
                intro
                    ? Icons.volunteer_activism_rounded
                    : Icons.workspace_premium_rounded,
                size: 16,
                color: intro ? t.teal : t.blue,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(booking.intentLabel,
                    style: TextStyle(
                        color: intro ? t.teal : t.blue,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (booking.concern.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.psychology_alt_rounded, size: 15, color: t.textSec),
                const SizedBox(width: 7),
                Text('Беспокоит: ',
                    style: TextStyle(color: t.textSec, fontSize: 12.5)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.glassBgUp,
                    border: Border.all(color: t.glassBorder),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(booking.concern,
                      style: TextStyle(
                          color: t.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
          if (booking.clientMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: t.glassBgUp,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('«${booking.clientMessage}»',
                  style: TextStyle(
                      color: t.textSec,
                      fontSize: 12.5,
                      height: 1.4,
                      fontStyle: FontStyle.italic)),
            ),
          ],
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Принять'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDecline,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Отклонить'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.textSec,
                    side: BorderSide(color: t.glassBorder),
                    minimumSize: const Size(0, 46),
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

/// Bottom sheet to decline a request: a reason (quick chips or free text) and
/// an optional proposed alternative date/time.
class _DeclineSheet extends StatefulWidget {
  final AppBooking booking;
  const _DeclineSheet({required this.booking});

  @override
  State<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<_DeclineSheet> {
  final _reason = TextEditingController();
  DateTime? _proposed;

  static const _quick = [
    'Не смогу в это время',
    'Не моя специализация',
    'Занят этот день',
  ];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (time == null) return;
    setState(() => _proposed =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 10,
        bottom: 18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: t.glassBorder),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Отклонить заявку',
                style: TextStyle(
                    color: t.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${widget.booking.clientName} получит ваш ответ.',
                style: TextStyle(color: t.textSec, fontSize: 13)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quick
                  .map((q) => GestureDetector(
                        onTap: () => setState(() => _reason.text = q),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _reason.text == q
                                ? t.blue.withValues(alpha: 0.14)
                                : t.glassBgUp,
                            border: Border.all(
                                color: _reason.text == q
                                    ? t.blue
                                    : t.glassBorder),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(q,
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reason,
              maxLines: 2,
              style: TextStyle(color: t.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Причина (необязательно)…',
                hintStyle: TextStyle(color: t.textTer, fontSize: 13.5),
                isDense: true,
                contentPadding: const EdgeInsets.all(14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: t.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: t.blue, width: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              radius: 14,
              onTap: _pickTime,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(Icons.event_repeat_rounded, size: 18, color: t.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _proposed == null
                          ? 'Предложить другое время'
                          : 'Предложено: ${DateFormat('d MMMM · HH:mm', 'ru').format(_proposed!)}',
                      style: TextStyle(
                          color: _proposed == null ? t.textSec : t.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_proposed != null)
                    GestureDetector(
                      onTap: () => setState(() => _proposed = null),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: t.textTer),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.textSec,
                      side: BorderSide(color: t.glassBorder),
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Назад'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(
                        _DeclineResult(_reason.text.trim(), _proposed)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Отклонить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 4 · Доходы (computed from bookings)
// ════════════════════════════════════════════════════════════
class PsyEarningsScreen extends ConsumerWidget {
  const PsyEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final bookings =
        ref.watch(incomingBookingsProvider).valueOrNull ?? const <AppBooking>[];
    final paid = bookings.where(_isPaid).toList();
    final now = DateTime.now();

    int monthSum(int year, int month) => paid
        .where((b) => b.startsAt.year == year && b.startsAt.month == month)
        .fold<int>(0, (s, b) => s + b.priceKzt);

    final thisMonth = monthSum(now.year, now.month);
    // last 5 months (oldest → newest)
    final months = List.generate(5, (i) {
      final d = DateTime(now.year, now.month - (4 - i), 1);
      return (d, monthSum(d.year, d.month));
    });
    final maxBar = months.fold<int>(1, (m, e) => e.$2 > m ? e.$2 : m);
    final total = paid.fold<int>(0, (s, b) => s + b.priceKzt);
    final paidCount = paid.length;
    final avg = paidCount > 0 ? (total / paidCount).round() : 0;
    // Intro (free) sessions count toward a reward milestone every 15.
    const introGoal = 15;
    final introCount = bookings
        .where((b) =>
            b.isIntro &&
            (b.status == 'scheduled' || b.status == 'completed'))
        .length;

    return AutoRefresh(
      interval: const Duration(seconds: 10),
      onTick: (ref) => ref.invalidate(incomingBookingsProvider),
      child: Scaffold(
        body: GlassBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                const _SpecHeader(title: 'Доходы'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 130),
                    children: [
                      // hero — this month
                      GlassCard(
                        elevated: true,
                        radius: 24,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('LLLL yyyy', 'ru')
                                .format(now)
                                .replaceFirstMapped(RegExp(r'^.'),
                                    (m) => m.group(0)!.toUpperCase()),
                                style: TextStyle(
                                    color: t.textSec, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(_kzt(thisMonth),
                                style: TextStyle(
                                  color: t.text,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                )),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 92,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: months.map((e) {
                                  final on = e.$1.month == now.month &&
                                      e.$1.year == now.year;
                                  final h = (e.$2 / maxBar) * 78 + 8;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            height: h,
                                            decoration: BoxDecoration(
                                              gradient: on
                                                  ? LinearGradient(
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
                                                      colors: [t.teal, t.blue])
                                                  : null,
                                              color:
                                                  on ? null : t.glassBgUp,
                                              border: Border.all(
                                                  color: on
                                                      ? Colors.transparent
                                                      : t.glassBorder),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          Text(
                                            DateFormat('LLL', 'ru')
                                                .format(e.$1),
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: on
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color:
                                                  on ? t.teal : t.textTer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // breakdown
                      GlassCard(
                        radius: 16,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: t.blue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.videocam_rounded,
                                  size: 18, color: t.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Оплаченные сессии',
                                      style: TextStyle(
                                          color: t.text, fontSize: 14)),
                                  Text(
                                      '$paidCount сессий · ${_kzt(avg)} ср.',
                                      style: TextStyle(
                                          color: t.textSec, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(_kzt(total),
                                style: TextStyle(
                                    color: t.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // intro (free) sessions + reward milestone
                      _IntroRewardCard(count: introCount, goal: introGoal),
                      const SizedBox(height: 14),
                      // payout
                      GlassCard(
                        elevated: true,
                        radius: 20,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Доступно к выводу',
                                style: TextStyle(
                                    color: t.textSec, fontSize: 12.5)),
                            const SizedBox(height: 2),
                            Text(_kzt(total),
                                style: TextStyle(
                                  color: t.text,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.6,
                                )),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Вывод средств скоро будет доступен'))),
                                icon: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 18),
                                label: const Text('Вывести средства'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: t.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  minimumSize: const Size(0, 50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Intro (free) sessions counter with progress to the next reward milestone.
/// Every [goal] free intros earns a monetary reward, so this is tracked.
class _IntroRewardCard extends StatelessWidget {
  final int count;
  final int goal;
  const _IntroRewardCard({required this.count, required this.goal});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final rewards = count ~/ goal;
    final inCycle = count % goal;
    final toGo = goal - inCycle;
    final progress = inCycle / goal;
    return GlassCard(
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: t.teal.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.volunteer_activism_rounded,
                    size: 20, color: t.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ознакомительные · бесплатные',
                        style: TextStyle(
                            color: t.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600)),
                    Text('Проведено: $count',
                        style: TextStyle(color: t.textSec, fontSize: 12)),
                  ],
                ),
              ),
              Text('$count',
                  style: TextStyle(
                      color: t.teal,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress == 0 && count > 0 ? 1 : progress,
              minHeight: 8,
              backgroundColor: t.glassBgUp,
              valueColor: AlwaysStoppedAnimation(t.teal),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 15, color: _amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rewards > 0
                      ? 'Награды получены: $rewards · ещё $toGo до следующей'
                      : 'Ещё $toGo бесплатных сессий до денежного вознаграждения',
                  style: TextStyle(color: t.textSec, fontSize: 12, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 5 · Профиль (public listing preview + settings)
// ════════════════════════════════════════════════════════════
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
                      initials: name.isNotEmpty ? name[0].toUpperCase() : 'П',
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
                              color: (me?.isVerified ?? false)
                                  ? t.teal.withValues(alpha: 0.15)
                                  : t.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (me?.isVerified ?? false)
                                      ? Icons.verified_rounded
                                      : Icons.psychology_rounded,
                                  size: 13,
                                  color: (me?.isVerified ?? false)
                                      ? t.teal
                                      : t.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                    (me?.isVerified ?? false)
                                        ? 'Проверенный психолог'
                                        : 'Психолог',
                                    style: TextStyle(
                                        color: (me?.isVerified ?? false)
                                            ? t.teal
                                            : t.blue,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_outlined, color: t.textTer, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (me != null && !me.isVerified) ...[
                const _VerifyBanner(),
                const SizedBox(height: 18),
              ],
              Row(
                children: [
                  Icon(Icons.search_rounded, size: 14, color: t.teal),
                  const SizedBox(width: 7),
                  Text('КАК ВАС ВИДЯТ КЛИЕНТЫ',
                      style: TextStyle(
                          color: t.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0)),
                ],
              ),
              const SizedBox(height: 10),
              if (me == null)
                GlassCard(
                  elevated: true,
                  radius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: t.textSec, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Профиль специалиста ещё не создан — клиенты вас '
                              'не видят. Заполните его, чтобы появиться в каталоге.',
                              style: TextStyle(
                                  color: t.textSec,
                                  fontSize: 13,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/onboarding/specialist'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Заполнить профиль'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                GestureDetector(
                  onTap: () => context.push('/psy/cabinet'),
                  child: _CatalogPreviewCard(
                      me: me, name: name, avatar: user?.avatar ?? ''),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/psy/cabinet'),
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('Редактировать кабинет'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.blue,
                      side: BorderSide(color: t.glassBorder),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Text('НАСТРОЙКИ',
                  style: TextStyle(
                      color: t.textTer,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1)),
              const SizedBox(height: 10),
              _row(t, Icons.storefront_rounded, 'Редактировать кабинет',
                  () => context.push('/psy/cabinet')),
              _row(t, Icons.edit_outlined, 'Личный профиль и аватар',
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
              child:
                  Text(label, style: TextStyle(color: t.text, fontSize: 14.5)),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: t.textTer),
          ],
        ),
      ),
    );
  }
}

/// The catalog card exactly as a client sees it in search — a live preview.
class _CatalogPreviewCard extends StatelessWidget {
  final Specialist me;
  final String name;
  final String avatar;
  const _CatalogPreviewCard(
      {required this.me, required this.name, required this.avatar});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      elevated: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                avatar: avatar,
                initials: name.isNotEmpty ? name[0].toUpperCase() : 'П',
                gradient: me.avatarGradient,
                size: 54,
                radius: 16,
                fontSize: 22,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me.fullName.trim().isEmpty ? name : me.fullName,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: _amber),
                        const SizedBox(width: 4),
                        Text(me.rating > 0 ? me.rating.toStringAsFixed(1) : '—',
                            style: TextStyle(
                                color: t.text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text('${me.reviewCount} отзывов',
                            style:
                                TextStyle(color: t.textSec, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${me.title} · ${me.yearsExperience} лет опыта · ${_kzt(me.sessionPriceKzt)}',
            style: TextStyle(color: t.textSec, fontSize: 12.5),
          ),
          if (me.worksWith.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  me.worksWith.take(5).map((w) => Tag(label: w)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
