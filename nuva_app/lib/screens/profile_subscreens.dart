import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/booking.dart';
import '../models/gamification.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

/// Shared simple scaffold for profile sub-screens.
class _Sub extends StatelessWidget {
  final String title;
  final Widget child;
  const _Sub({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: t.text, size: 18),
                    ),
                    Text(title,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        )),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final async = ref.watch(bookingsProvider);

    Widget card(AppBooking b) {
      final when = DateFormat('d MMMM · HH:mm', 'ru').format(b.startsAt);
      final up = b.isUpcoming;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          elevated: true,
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              GradientAvatar(
                  initials:
                      b.specialistInitials.isEmpty ? 'А' : b.specialistInitials,
                  gradient: b.gradient,
                  size: 46,
                  radius: 14,
                  fontSize: 17),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.specialistName,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600)),
                    Text('$when · ${b.formatLabel}',
                        style: TextStyle(color: t.textSec, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (up ? t.blue : t.teal).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(up ? 'Скоро' : b.statusLabel,
                    style: TextStyle(
                        color: up ? t.blue : t.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return _Sub(
      title: 'Мои сессии',
      child: async.when(
        loading: () => const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator())),
        error: (_, __) => Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text('Не удалось загрузить сессии',
                style: TextStyle(color: t.textSec))),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded, color: t.textTer, size: 48),
                  const SizedBox(height: 12),
                  Text('Пока нет записей',
                      style: TextStyle(
                          color: t.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Запишитесь к специалисту — сессия появится здесь.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: t.textSec, fontSize: 13)),
                ],
              ),
            );
          }
          final upcoming = bookings.where((b) => b.isUpcoming).toList();
          final past = bookings.where((b) => !b.isUpcoming).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (upcoming.isNotEmpty) ...[
                SectionLabel(label: 'Предстоящие'),
                ...upcoming.map(card),
                const SizedBox(height: 14),
              ],
              if (past.isNotEmpty) ...[
                SectionLabel(label: 'Прошедшие'),
                ...past.map(card),
              ],
            ],
          );
        },
      ),
    );
  }
}

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = d0.difference(d).inDays;
    if (diff <= 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    if (diff < 7) return '$diff дн. назад';
    return DateFormat('d MMMM', 'ru').format(day);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final moods =
        ref.watch(moodHistoryProvider).valueOrNull ?? const <MoodEntry>[];
    return _Sub(
      title: 'Дневник настроения',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Отмечайте настроение на главной — оно появится здесь.',
              style: TextStyle(color: t.textSec, fontSize: 13)),
          const SizedBox(height: 16),
          if (moods.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('Пока нет записей',
                    style: TextStyle(color: t.textTer, fontSize: 13)),
              ),
            ),
          ...moods.map((e) {
            final vis = moodVisuals[e.mood] ?? moodVisuals[3]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                elevated: true,
                radius: 16,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          vis.$3.withValues(alpha: 0.95),
                          vis.$3.withValues(alpha: 0.55),
                        ]),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(vis.$2, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vis.$1,
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600)),
                          if (e.note.isNotEmpty)
                            Text(e.note,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: t.textSec, fontSize: 12.5)),
                          Text(_dayLabel(e.day),
                              style:
                                  TextStyle(color: t.textTer, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final favs = ref.watch(favoritesProvider).valueOrNull ?? const [];
    if (favs.isEmpty) {
      return _Sub(
        title: 'Избранные специалисты',
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Text(
            'Пока пусто. Откройте профиль специалиста и нажмите ♥, '
            'чтобы сохранить его здесь.',
            style: TextStyle(color: t.textSec, fontSize: 14, height: 1.5),
          ),
        ),
      );
    }
    return _Sub(
      title: 'Избранные специалисты',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: favs
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    onTap: () => context.push('/specialists/${s.id}'),
                    elevated: true,
                    radius: 18,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        GradientAvatar(
                            initials: s.initials,
                            gradient: s.avatarGradient,
                            size: 46,
                            radius: 14,
                            fontSize: 17),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.fullName,
                                  style: TextStyle(
                                      color: t.text,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600)),
                              Text(s.title,
                                  style: TextStyle(
                                      color: t.textSec, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.favorite_rounded, color: t.danger, size: 20),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, bool> _toggles = {
    'Напоминания о сессиях': true,
    'Новые сообщения': true,
    'Ответы в сообществе': false,
    'Тишина ночью (22:00–8:00)': true,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return _Sub(
      title: 'Уведомления',
      child: GlassCard(
        elevated: true,
        radius: 18,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < _toggles.length; i++) ...[
              SwitchListTile(
                value: _toggles.values.elementAt(i),
                onChanged: (v) => setState(
                    () => _toggles[_toggles.keys.elementAt(i)] = v),
                activeColor: t.blue,
                title: Text(_toggles.keys.elementAt(i),
                    style: TextStyle(color: t.text, fontSize: 14)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              ),
              if (i < _toggles.length - 1)
                Divider(height: 1, color: t.divider, indent: 14, endIndent: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    Widget tile(IconData i, String title, String sub, Color c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            elevated: true,
            radius: 16,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(i, color: c, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: t.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600)),
                      Text(sub,
                          style: TextStyle(color: t.textSec, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return _Sub(
      title: 'Помощь и поддержка',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label: 'Срочная помощь'),
          tile(Icons.favorite_rounded, 'Линия доверия Казахстан', '150',
              t.danger),
          tile(Icons.local_hospital_rounded, 'Экстренные службы', '112',
              t.danger),
          const SizedBox(height: 12),
          SectionLabel(label: 'Связаться с Nuva'),
          tile(Icons.mail_outline_rounded, 'Поддержка', 'hello@nuva.kz', t.blue),
          tile(Icons.privacy_tip_outlined, 'Вопросы о данных',
              'privacy@nuva.kz', t.teal),
          const SizedBox(height: 12),
          SectionLabel(label: 'Частые вопросы'),
          tile(Icons.help_outline_rounded, 'Как проходит сессия?',
              'Видео, аудио или чат — на ваш выбор', t.blue),
          tile(Icons.lock_outline_rounded, 'Конфиденциально ли это?',
              'Да. Вы решаете, чем делиться', t.teal),
        ],
      ),
    );
  }
}
