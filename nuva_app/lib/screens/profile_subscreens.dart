import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/specialist.dart';
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

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final sp = specialistCatalog;
    Widget session(Specialist s, String when, bool upcoming) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
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
                      Text(when,
                          style: TextStyle(color: t.textSec, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: upcoming
                        ? t.blue.withValues(alpha: 0.15)
                        : t.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(upcoming ? 'Скоро' : 'Завершена',
                      style: TextStyle(
                          color: upcoming ? t.blue : t.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        );

    return _Sub(
      title: 'Мои сессии',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label: 'Предстоящие'),
          session(sp[0], 'Завтра · 14:00 · Видео', true),
          const SizedBox(height: 14),
          SectionLabel(label: 'Прошедшие'),
          session(sp[1], '3 июня · 18:00 · Видео', false),
          session(sp[2], '27 мая · 12:00 · Чат', false),
        ],
      ),
    );
  }
}

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  static const _entries = <(String, String, IconData, Color)>[
    ('Сегодня', 'Норм', Icons.sentiment_satisfied_rounded, Color(0xFF49C6C0)),
    ('Вчера', 'Тревожно', Icons.sentiment_dissatisfied_rounded,
        Color(0xFFF2A65A)),
    ('2 дня назад', 'Хорошо', Icons.sentiment_very_satisfied_rounded,
        Color(0xFF5DC98A)),
    ('3 дня назад', 'Так себе', Icons.sentiment_neutral_rounded,
        Color(0xFF93A0B5)),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return _Sub(
      title: 'Дневник настроения',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Отмечайте настроение на главной — оно появится здесь.',
              style: TextStyle(color: t.textSec, fontSize: 13)),
          const SizedBox(height: 16),
          ..._entries.map((e) => Padding(
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
                            e.$4.withValues(alpha: 0.95),
                            e.$4.withValues(alpha: 0.55),
                          ]),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(e.$3, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.$2,
                                style: TextStyle(
                                    color: t.text,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600)),
                            Text(e.$1,
                                style: TextStyle(
                                    color: t.textTer, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final favs = specialistCatalog.take(2).toList();
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
