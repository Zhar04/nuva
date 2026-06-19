import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend_auth.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';
import '../widgets/nuva_logo.dart';

/// First screen on launch: the ripple logo pulsing (rings expand/contract
/// together) over the glass backdrop, then hands off to the real start route.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.82, end: 1.12)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _go();
  }

  Future<void> _go() async {
    // Let the brand animation play, then wait for session restore to settle so
    // the centralized router redirect (app_router.dart) can route a signed-in
    // or offline-guest user off /splash first. If it did, we're unmounted and
    // bail; otherwise the user is genuinely unauthenticated and we pick the
    // first-run intro vs the login screen.
    await Future.delayed(const Duration(milliseconds: 1700));
    while (mounted && ref.read(backendAuthProvider).restoring) {
      await Future.delayed(const Duration(milliseconds: 80));
    }
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;
    if (!mounted) return;
    context.go(onboarded ? '/auth' : '/');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Scaffold(
      body: GlassBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: t.blue.withValues(alpha: 0.35),
                        blurRadius: 44,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: NuvaLogo(size: 104, color: t.blue, accent: t.teal),
                ),
              ),
              const SizedBox(height: 30),
              Text('Nuva',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  )),
              const SizedBox(height: 6),
              Text("you're not alone",
                  style: TextStyle(color: t.textSec, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
