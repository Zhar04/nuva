import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_profile.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';

/// Registration entry: choose a role with a warm, non-clinical name.
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    void pick(UserRole role, String route) {
      ref.read(userProfileProvider.notifier).update(role: role);
      context.go(route);
    }

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Кто вы в Nuva?',
                    style: TextStyle(
                      color: t.text,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    )),
                const SizedBox(height: 8),
                Text(
                  'Это поможет настроить приложение под вас. Выбор можно поменять позже.',
                  style: TextStyle(color: t.textSec, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 28),
                _RoleCard(
                  icon: Icons.self_improvement_rounded,
                  title: 'Ищу поддержку',
                  sub: 'Найти своего психолога, выговориться, разобраться в себе.',
                  gradient: [t.blue, t.teal],
                  onTap: () => pick(UserRole.seeker, '/onboarding/user'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.psychology_rounded,
                  title: 'Я психолог',
                  sub: 'Принимать клиентов, вести сессии и публиковаться в Nuva.',
                  gradient: const [Color(0xFF7E8BD9), Color(0xFFB39DDB)],
                  onTap: () => pick(UserRole.psychologist, '/onboarding/specialist'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      onTap: onTap,
      elevated: true,
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: gradient.last.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                Text(sub,
                    style:
                        TextStyle(color: t.textSec, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 15, color: t.textTer),
        ],
      ),
    );
  }
}
