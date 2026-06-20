import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true); // intro slides seen (once per device)
    if (!mounted) return;
    context.go('/role'); // pick a role first → then register with that role
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;
    final pages = [
      (s.obTitle1, s.obSub1, Icons.search_rounded),
      (s.obTitle2, s.obSub2, Icons.auto_awesome_rounded),
      (s.obTitle3, s.obSub3, Icons.lock_rounded),
    ];

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _Header(),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: pages.length,
                  itemBuilder: (_, i) {
                    final (title, sub, icon) = pages[i];
                    return _OnboardingPage(title: title, sub: sub, icon: icon);
                  },
                ),
              ),
              const SizedBox(height: 8),
              _Dots(count: pages.length, active: _page),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: _page == pages.length - 1 ? s.start : s.next,
                      onPressed: () {
                        if (_page == pages.length - 1) {
                          _finish();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    // Entry point #1 into the matching quiz — guests can jump
                    // straight to a personalized match before signing up.
                    _QuizCta(
                      label: s.quizCtaEntry,
                      sub: s.quizCtaSub,
                      onTap: () => context.push('/quiz'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        s.skip,
                        style: TextStyle(color: t.textSec),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary CTA on the intro that opens the matching quiz (lead capture).
class _QuizCta extends StatelessWidget {
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _QuizCta({required this.label, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      onTap: onTap,
      elevated: true,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.blue, t.teal]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub,
                    style: TextStyle(
                        color: t.textSec, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: t.textTer),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _LangPill(lang: lang, onTap: () {
            final next = AppLang.values[(lang.index + 1) % AppLang.values.length];
            ref.read(langProvider.notifier).state = next;
          }),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final AppLang lang;
  final VoidCallback onTap;
  const _LangPill({required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      onTap: onTap,
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      elevated: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language_rounded, size: 16, color: t.blue),
          const SizedBox(width: 6),
          Text(
            lang.code,
            style: TextStyle(
              color: t.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String sub;
  final IconData icon;
  const _OnboardingPage({
    required this.title,
    required this.sub,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [t.blue.withOpacity(0.25), t.blue.withOpacity(0)],
              ),
            ),
            child: Icon(icon, size: 48, color: t.blue),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.text,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.textSec,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;
  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isOn = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isOn ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOn ? t.blue : t.textTer,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
