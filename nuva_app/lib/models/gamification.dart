import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gamification (Phase: prototype, local mock). Points reset monthly;
/// achievements are awarded by psychologists after a completed course
/// (IronMan-style badges); a course progress bar is shareable (Strava-like).
/// Phase 1: drive from Supabase (points ledger + achievements + course tables).

@immutable
class Achievement {
  final String title;
  final String issuer;
  final IconData icon;
  final List<Color> gradient;
  final bool unlocked;
  const Achievement({
    required this.title,
    required this.issuer,
    required this.icon,
    required this.gradient,
    required this.unlocked,
  });
}

@immutable
class CourseProgress {
  final String title;
  final String specialist;
  final int done;
  final int total;
  const CourseProgress({
    required this.title,
    required this.specialist,
    required this.done,
    required this.total,
  });
  double get fraction => total == 0 ? 0 : (done / total).clamp(0, 1).toDouble();
}

@immutable
class GamificationState {
  final int points;
  final int level;
  final String resetLabel;
  final List<Achievement> achievements;
  final CourseProgress? course;
  const GamificationState({
    required this.points,
    required this.level,
    required this.resetLabel,
    required this.achievements,
    required this.course,
  });

  int get pointsThisLevel => points % 500;
  int get levelSpan => 500;
  double get levelFraction => (pointsThisLevel / levelSpan).clamp(0, 1).toDouble();
}

final gamificationProvider = Provider<GamificationState>((_) {
  return const GamificationState(
    points: 340,
    level: 3,
    resetLabel: 'Очки обнуляются 1-го числа месяца',
    achievements: [
      Achievement(
        title: 'Первый шаг',
        issuer: 'Nuva',
        icon: Icons.flag_rounded,
        gradient: [Color(0xFF5EA0F0), Color(0xFF8FC4F7)],
        unlocked: true,
      ),
      Achievement(
        title: '7 дней подряд',
        issuer: 'Nuva',
        icon: Icons.local_fire_department_rounded,
        gradient: [Color(0xFFF5A65B), Color(0xFFF7C48B)],
        unlocked: true,
      ),
      Achievement(
        title: 'Марафон спокойствия',
        issuer: 'Айгуль С.',
        icon: Icons.military_tech_rounded,
        gradient: [Color(0xFF36C9B6), Color(0xFF7FE0D4)],
        unlocked: false,
      ),
      Achievement(
        title: 'Завершил курс',
        issuer: 'психолог',
        icon: Icons.workspace_premium_rounded,
        gradient: [Color(0xFFB39DDB), Color(0xFFD4B5F0)],
        unlocked: false,
      ),
    ],
    course: CourseProgress(
      title: 'Управление тревогой',
      specialist: 'Айгуль С.',
      done: 4,
      total: 8,
    ),
  );
});
