import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/booking.dart';
import '../services/api_client.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

/// The psychologist's private card for one client: profile, mood dynamics,
/// private notes and full session history. Reached by tapping a client in
/// Requests or Schedule.
class ClientDetailScreen extends ConsumerStatefulWidget {
  final int clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailState();
}

class _ClientDetailState extends ConsumerState<ClientDetailScreen> {
  final _note = TextEditingController();
  bool _noteLoaded = false;
  bool _savingNote = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_savingNote) return;
    setState(() => _savingNote = true);
    try {
      await ref
          .read(psyActionsProvider)
          .saveClientNote(widget.clientId, _note.text.trim());
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заметка сохранена')),
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
      if (mounted) setState(() => _savingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final async = ref.watch(clientCardProvider(widget.clientId));

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: t.text, size: 18),
                    ),
                    Text('Карточка клиента',
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
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _error(t),
                  data: (card) {
                    if (card == null) return _error(t);
                    if (!_noteLoaded) {
                      _noteLoaded = true;
                      _note.text = card.note;
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
                      children: [
                        _ClientHero(card: card),
                        const SizedBox(height: 20),
                        _MoodCard(trend: card.moodTrend),
                        const SizedBox(height: 18),
                        _NoteCard(
                          controller: _note,
                          saving: _savingNote,
                          onSave: _saveNote,
                        ),
                        const SizedBox(height: 18),
                        _HistoryCard(sessions: card.sessions),
                      ],
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

  Widget _error(t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'Не удалось загрузить карточку клиента. Она доступна только по '
            'клиентам, у которых есть записи к вам.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textSec, fontSize: 14, height: 1.4),
          ),
        ),
      );
}

class _ClientHero extends StatelessWidget {
  final ClientCard card;
  const _ClientHero({required this.card});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      elevated: true,
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          GradientAvatar(
            initials: card.name.isNotEmpty ? card.name[0].toUpperCase() : 'К',
            gradient: const [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
            size: 58,
            radius: 18,
            fontSize: 23,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.name,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (card.concern.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.psychology_alt_rounded,
                            size: 13, color: t.blue),
                        const SizedBox(width: 5),
                        Text(card.concern,
                            style: TextStyle(
                                color: t.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else
                  Text('Запрос без темы',
                      style: TextStyle(color: t.textSec, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final List<int> trend;
  const _MoodCard({required this.trend});

  static const _moodColors = [
    Color(0xFF8E9BE6), // 1
    Color(0xFFF2A65A), // 2
    Color(0xFF93A0B5), // 3
    Color(0xFF49C6C0), // 4
    Color(0xFF5DC98A), // 5
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: t.teal),
              const SizedBox(width: 8),
              Text('Динамика настроения',
                  style: TextStyle(
                      color: t.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          if (trend.isEmpty)
            Text('Клиент пока не отмечал настроение в дневнике.',
                style: TextStyle(color: t.textSec, fontSize: 13, height: 1.4))
          else
            SizedBox(
              height: 84,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.map((m) {
                  final clamped = m.clamp(1, 5);
                  final h = 16 + (clamped / 5) * 62;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        height: h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _moodColors[clamped - 1],
                              _moodColors[clamped - 1].withValues(alpha: 0.55),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (trend.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Последние ${trend.length} отметок · 1 (тяжело) → 5 (хорошо)',
                style: TextStyle(color: t.textTer, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;
  const _NoteCard({
    required this.controller,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: t.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Приватные заметки',
                    style: TextStyle(
                        color: t.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: saving ? null : onSave,
                child: Text(saving ? 'Сохраняем…' : 'Сохранить',
                    style: TextStyle(
                        color: t.blue,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Видны только вам.',
              style: TextStyle(color: t.textSec, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 5,
            minLines: 3,
            style: TextStyle(color: t.text, fontSize: 14, height: 1.45),
            decoration: InputDecoration(
              hintText: 'Запрос клиента, гипотезы, план работы, прогресс…',
              hintStyle: TextStyle(color: t.textTer, fontSize: 13.5),
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
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<ClientSession> sessions;
  const _HistoryCard({required this.sessions});

  String _fmtLabel(String f) => switch (f) {
        'audio' => 'Аудио',
        'chat' => 'Чат',
        _ => 'Видео',
      };

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: t.textSec),
              const SizedBox(width: 8),
              Text('История сессий',
                  style: TextStyle(
                      color: t.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${sessions.length}',
                  style: TextStyle(
                      color: t.textTer,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            Text('Сессий ещё не было.',
                style: TextStyle(color: t.textSec, fontSize: 13))
          else
            ...sessions.map((sess) {
              final done = sess.isDone;
              final when =
                  DateFormat('d MMM yyyy · HH:mm', 'ru').format(sess.startsAt);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: (done ? t.teal : t.blue).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        done
                            ? Icons.check_rounded
                            : Icons.schedule_rounded,
                        size: 17,
                        color: done ? t.teal : t.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(when,
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600)),
                          Text(
                              '${_fmtLabel(sess.format)}'
                              '${sess.isIntro ? ' · ознакомительная' : ''}'
                              '${sess.concern.isNotEmpty ? ' · ${sess.concern}' : ''}',
                              style:
                                  TextStyle(color: t.textSec, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Text(
                      sess.isIntro
                          ? 'Бесплатно'
                          : _kztShort(sess.priceKzt),
                      style: TextStyle(
                          color: t.textSec,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _kztShort(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return '$b ₸';
  }
}
