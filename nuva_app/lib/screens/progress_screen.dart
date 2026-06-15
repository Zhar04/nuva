import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/gamification.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

/// Compact gamification card for the profile (taps through to /progress).
class GamificationCard extends ConsumerWidget {
  const GamificationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final g = ref.watch(gamificationProvider).valueOrNull ?? gamificationFallback;

    return GlassCard(
      onTap: () => context.push('/progress'),
      elevated: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [t.blue, t.teal]),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text('Lv ${g.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${g.points} очков',
                        style: TextStyle(
                          color: t.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        )),
                    Text(g.resetLabel,
                        style: TextStyle(color: t.textTer, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: t.textTer),
            ],
          ),
          const SizedBox(height: 12),
          _Bar(fraction: g.levelFraction, color: t.blue),
          const SizedBox(height: 6),
          Text('${g.pointsThisLevel}/${g.levelSpan} до уровня ${g.level + 1}',
              style: TextStyle(color: t.textSec, fontSize: 11)),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final a in g.achievements.take(4)) ...[
                _Badge(a: a, size: 38),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final g = ref.watch(gamificationProvider).valueOrNull ?? gamificationFallback;

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
                    Text('Прогресс',
                        style: TextStyle(
                          color: t.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [t.blue, t.teal],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: t.blue.withValues(alpha: 0.35),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Уровень ${g.level}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 2),
                            Text('${g.points} очков · ${g.resetLabel}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12.5)),
                            const SizedBox(height: 14),
                            _Bar(
                                fraction: g.levelFraction,
                                color: Colors.white,
                                track: Colors.white24),
                            const SizedBox(height: 6),
                            Text(
                                '${g.pointsThisLevel}/${g.levelSpan} до уровня ${g.level + 1}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      SectionLabel(label: 'Достижения'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 14,
                        children: g.achievements
                            .map((a) => SizedBox(
                                  width: 96,
                                  child: Column(
                                    children: [
                                      _Badge(a: a, size: 64),
                                      const SizedBox(height: 6),
                                      Text(a.title,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          style: TextStyle(
                                            color: a.unlocked
                                                ? t.text
                                                : t.textTer,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                          )),
                                      Text(
                                          a.unlocked
                                              ? a.issuer
                                              : 'не открыто',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: t.textTer,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 22),
                      if (g.course != null) ...[
                        SectionLabel(label: 'Текущий курс'),
                        GlassCard(
                          elevated: true,
                          radius: 20,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.course!.title,
                                  style: TextStyle(
                                      color: t.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              Text('с ${g.course!.specialist}',
                                  style: TextStyle(
                                      color: t.textSec, fontSize: 12.5)),
                              const SizedBox(height: 12),
                              _Bar(fraction: g.course!.fraction, color: t.teal),
                              const SizedBox(height: 6),
                              Text(
                                  '${g.course!.done} из ${g.course!.total} сессий',
                                  style: TextStyle(
                                      color: t.textSec, fontSize: 12)),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Поделиться прогрессом — скоро'))),
                                  icon: const Icon(Icons.ios_share_rounded,
                                      size: 16),
                                  label: const Text('Поделиться прогрессом'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: t.blue,
                                    side: BorderSide(color: t.blue),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Achievement a;
  final double size;
  const _Badge({required this.a, required this.size});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: a.unlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: a.gradient)
            : null,
        color: a.unlocked ? null : t.glassBgUp,
        shape: BoxShape.circle,
        border: a.unlocked ? null : Border.all(color: t.glassBorder),
        boxShadow: a.unlocked
            ? [
                BoxShadow(
                  color: a.gradient.last.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Icon(
        a.unlocked ? a.icon : Icons.lock_outline_rounded,
        color: a.unlocked ? Colors.white : t.textTer,
        size: size * 0.42,
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double fraction;
  final Color color;
  final Color? track;
  const _Bar({required this.fraction, required this.color, this.track});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 8,
        backgroundColor: track ?? t.glassBgUp,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
