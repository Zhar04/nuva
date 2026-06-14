import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../theme/theme.dart';
import 'community_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'specialists_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _idx = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);

    final pages = const [
      HomeScreen(),
      SpecialistsScreen(showBack: false),
      CommunityScreen(),
      _CalmScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _idx, children: pages),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavBar(
              index: _idx,
              items: [
                (Icons.home_rounded, s.tabHome),
                (Icons.search_rounded, s.tabSpecialists),
                (Icons.forum_rounded, s.tabCommunity),
                (Icons.spa_rounded, s.tabCalm),
                (Icons.person_rounded, s.tabProfile),
              ],
              onTap: (i) => setState(() => _idx = i),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating Liquid-Glass tab bar (iOS-26 / App Store style): a frosted capsule
/// detached from the bottom edge; the active tab expands into a gradient pill
/// showing icon + label, inactive tabs are icon-only.
class _FloatingNavBar extends StatelessWidget {
  final int index;
  final List<(IconData, String)> items;
  final ValueChanged<int> onTap;
  const _FloatingNavBar({
    required this.index,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        10 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: t.surface.withValues(alpha: t.dark ? 0.55 : 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    t.dark ? const Color(0x40FFFFFF) : const Color(0x55FFFFFF),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: t.dark ? 0.40 : 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: t.blue.withValues(alpha: t.dark ? 0.20 : 0.12),
                  blurRadius: 24,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(items.length, (i) {
                final on = i == index;
                final item = items[i];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: on ? 16 : 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: on
                          ? LinearGradient(colors: [t.blue, t.blueDeep])
                          : null,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: on
                          ? [
                              BoxShadow(
                                color: t.blue.withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.$1,
                          size: 22,
                          color: on ? Colors.white : t.textTer,
                        ),
                        if (on) ...[
                          const SizedBox(width: 7),
                          Text(
                            item.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Покой — immersive calm space (Endel / Mediatopia vibe): a "now" hero,
/// a horizontal rail of ambient sound scenes, and categorized sessions.
/// Audio is out of scope tonight, so controls show a "скоро" toast.
class _CalmScreen extends ConsumerWidget {
  const _CalmScreen();

  static const _scenes = <(String, IconData, List<Color>)>[
    ('Дождь', Icons.water_drop_rounded, [Color(0xFF4A6FA5), Color(0xFF6B93C7)]),
    ('Лес', Icons.forest_rounded, [Color(0xFF3E7C5A), Color(0xFF6BA585)]),
    ('Океан', Icons.waves_rounded, [Color(0xFF2E7DA6), Color(0xFF58A7C9)]),
    ('Ночь', Icons.nightlight_round, [Color(0xFF3B3A6B), Color(0xFF5E5C9E)]),
    ('Костёр', Icons.local_fire_department_rounded,
        [Color(0xFFA55A3E), Color(0xFFC98A5E)]),
  ];

  static const _categories =
      <(String, List<(String, String, IconData, Color)>)>[
    (
      'Сон',
      [
        ('Дождь в лесу', '30 мин', Icons.cloud_rounded, Color(0xFF5EA0F0)),
        ('Глубокий сон', '45 мин', Icons.bedtime_rounded, Color(0xFF7E8BD9)),
      ]
    ),
    (
      'Снять тревогу',
      [
        ('Дыхание 4-7-8', '5 мин', Icons.air_rounded, Color(0xFF36C9B6)),
        ('Заземление 5-4-3-2-1', '4 мин', Icons.spa_rounded,
            Color(0xFFFF9E80)),
      ]
    ),
    (
      'Фокус',
      [
        ('Утренняя практика', '8 мин', Icons.wb_sunny_rounded,
            Color(0xFFF5C26B)),
        ('Сканирование тела', '12 мин', Icons.self_improvement_rounded,
            Color(0xFFB39DDB)),
      ]
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: t.backdrop),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.tabCalm,
                            style: TextStyle(
                              color: t.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                            )),
                        const SizedBox(height: 2),
                        Text('Дыши. Замедлись. Восстановись.',
                            style: TextStyle(color: t.textSec, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _CalmHero(
                      onTap: () => _soon(context, 'Когда тревога нарастает'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _CalmSectionLabel(label: 'Звуковые сцены'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _scenes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _SceneCard(
                        name: _scenes[i].$1,
                        icon: _scenes[i].$2,
                        gradient: _scenes[i].$3,
                        onTap: () => _soon(context, _scenes[i].$1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  for (final cat in _categories) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _CalmSectionLabel(label: cat.$1),
                    ),
                    const SizedBox(height: 10),
                    ...cat.$2.map((it) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _SessionRow(
                            title: it.$1,
                            meta: it.$2,
                            icon: it.$3,
                            color: it.$4,
                            onTap: () => _soon(context, it.$1),
                          ),
                        )),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _soon(BuildContext context, String name) {
  final t = context.nuva;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.surfaceElevated,
      content: Text('«$name» — аудио скоро добавим',
          style: TextStyle(color: t.text)),
    ));
}

class _CalmSectionLabel extends StatelessWidget {
  final String label;
  const _CalmSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Text(
      label,
      style: TextStyle(
        color: t.text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _CalmHero extends StatelessWidget {
  final VoidCallback onTap;
  const _CalmHero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 184,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.blue, t.teal],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: t.blue.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('СЕЙЧАС ДЛЯ ВАС',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  )),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Когда тревога нарастает',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      height: 1.2,
                    )),
                SizedBox(height: 4),
                Text('5 минут · дыхание 4-7-8',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child:
                      Icon(Icons.play_arrow_rounded, color: t.blue, size: 28),
                ),
                const SizedBox(width: 12),
                const Text('Начать сейчас',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _SceneCard({
    required this.name,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 124,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white70, size: 15),
                    const SizedBox(width: 4),
                    Text('Ambient',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        )),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String title;
  final String meta;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SessionRow({
    required this.title,
    required this.meta,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.glassBgUp,
          border: Border.all(color: t.glassBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.95),
                    color.withValues(alpha: 0.55),
                  ],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 22),
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
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(meta,
                      style: TextStyle(color: t.textSec, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.play_circle_outline_rounded,
                color: t.textSec, size: 26),
          ],
        ),
      ),
    );
  }
}
