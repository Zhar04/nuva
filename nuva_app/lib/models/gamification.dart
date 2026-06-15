import 'package:flutter/material.dart';

/// Gamification + mood-journal models. Driven by the backend `/journal/stats/`
/// (points/level/streak/achievements computed from real activity) and
/// `/journal/moods/` (the mood history).

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

/// Maps a backend achievement key to its icon + gradient (view-only data).
const _achVisuals = <String, (IconData, List<Color>)>{
  'first_step': (
    Icons.flag_rounded,
    [Color(0xFF5EA0F0), Color(0xFF8FC4F7)]
  ),
  'streak_7': (
    Icons.local_fire_department_rounded,
    [Color(0xFFF5A65B), Color(0xFFF7C48B)]
  ),
  'open_heart': (
    Icons.favorite_rounded,
    [Color(0xFFF06595), Color(0xFFF7A8C4)]
  ),
  'marathon': (
    Icons.military_tech_rounded,
    [Color(0xFF36C9B6), Color(0xFF7FE0D4)]
  ),
};

@immutable
class GamificationState {
  final int points;
  final int level;
  final int streak;
  final bool todayLogged;
  final String resetLabel;
  final List<Achievement> achievements;
  final CourseProgress? course;
  const GamificationState({
    required this.points,
    required this.level,
    required this.resetLabel,
    required this.achievements,
    required this.course,
    this.streak = 0,
    this.todayLogged = false,
  });

  int get pointsThisLevel => points % 500;
  int get levelSpan => 500;
  double get levelFraction =>
      (pointsThisLevel / levelSpan).clamp(0, 1).toDouble();

  factory GamificationState.fromJson(Map<String, dynamic> m) {
    final achievements = ((m['achievements'] as List?) ?? const []).map((a) {
      final am = a as Map<String, dynamic>;
      final key = (am['key'] ?? '') as String;
      final vis = _achVisuals[key] ??
          (
            Icons.star_rounded,
            const [Color(0xFF8E9BE6), Color(0xFFB3BCF0)]
          );
      return Achievement(
        title: (am['title'] ?? '') as String,
        issuer: (am['issuer'] ?? 'Nuva') as String,
        icon: vis.$1,
        gradient: vis.$2,
        unlocked: (am['unlocked'] as bool?) ?? false,
      );
    }).toList();
    final streakLabel = m['streak_label'] as String?;
    final monthDays = (m['mood_days_this_month'] as num?)?.toInt() ?? 0;
    final goal = (m['monthly_goal'] as num?)?.toInt() ?? 30;
    return GamificationState(
      points: (m['points'] as num?)?.toInt() ?? 0,
      level: (m['level'] as num?)?.toInt() ?? 1,
      streak: (m['streak'] as num?)?.toInt() ?? 0,
      todayLogged: (m['today_logged'] as bool?) ?? false,
      resetLabel: streakLabel != null && streakLabel.isNotEmpty
          ? '🔥 $streakLabel'
          : 'Отмечай настроение каждый день',
      achievements: achievements,
      course: CourseProgress(
        title: 'Дневник настроения',
        specialist: 'Цель месяца',
        done: monthDays,
        total: goal,
      ),
    );
  }
}

/// Fallback used while the backend stats are loading / unavailable.
const gamificationFallback = GamificationState(
  points: 0,
  level: 1,
  resetLabel: 'Отмечай настроение каждый день',
  achievements: [],
  course: null,
);

/// A mood check-in from `/journal/moods/`.
@immutable
class MoodEntry {
  final int mood; // 1..5
  final String note;
  final DateTime day;
  const MoodEntry({required this.mood, required this.note, required this.day});

  factory MoodEntry.fromJson(Map<String, dynamic> m) => MoodEntry(
        mood: (m['mood'] as num?)?.toInt() ?? 3,
        note: (m['note'] ?? '') as String,
        day: DateTime.tryParse('${m['day']}') ?? DateTime.now(),
      );
}

/// Label / icon / colour for a mood value (1=sad … 5=great). Shared by the
/// home check-in row and the journal history.
const moodVisuals = <int, (String, IconData, Color)>{
  1: ('Грустно', Icons.sentiment_very_dissatisfied_rounded, Color(0xFF8E9BE6)),
  2: ('Тревожно', Icons.sentiment_dissatisfied_rounded, Color(0xFFF2A65A)),
  3: ('Так себе', Icons.sentiment_neutral_rounded, Color(0xFF93A0B5)),
  4: ('Норм', Icons.sentiment_satisfied_rounded, Color(0xFF49C6C0)),
  5: ('Хорошо', Icons.sentiment_very_satisfied_rounded, Color(0xFF5DC98A)),
};
