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

class _CalmScreen extends ConsumerWidget {
  const _CalmScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    final items = [
      ('Дыхание 4-7-8', '5 мин · тревога', Icons.air_rounded, t.teal),
      ('Дождь в лесу', '30 мин · сон', Icons.cloud_rounded, t.blue),
      ('Сканирование тела', '12 мин · напряжение', Icons.self_improvement_rounded,
          const Color(0xFFB39DDB)),
      ('Утренняя практика', '8 мин · фокус', Icons.wb_sunny_rounded,
          const Color(0xFFF5C26B)),
      ('Заземление 5-4-3-2-1', '4 мин · паника', Icons.spa_rounded,
          const Color(0xFFFF9E80)),
    ];

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.tabCalm,
                      style: TextStyle(
                        color: t.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                      )),
                  const SizedBox(height: 2),
                  Text('Короткие практики, чтобы выдохнуть',
                      style: TextStyle(color: t.textSec, fontSize: 13)),
                  const SizedBox(height: 18),
                  Container(
                    height: 180,
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
                          blurRadius: 32,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('РЕКОМЕНДОВАНО',
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
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                )),
                            SizedBox(height: 4),
                            Text('5 минут · дыхание 4-7-8',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                )),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.play_arrow_rounded,
                                  color: t.blue, size: 26),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: t.glassBgUp,
                          border: Border.all(color: t.glassBorder),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: item.$4.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.$3, color: item.$4, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.$1,
                                      style: TextStyle(
                                        color: t.text,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  Text(item.$2,
                                      style: TextStyle(
                                        color: t.textSec,
                                        fontSize: 12,
                                      )),
                                ],
                              ),
                            ),
                            Icon(Icons.play_circle_outline_rounded,
                                color: t.textSec, size: 24),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
