import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/chat.dart';
import '../models/specialist.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    final lang = ref.watch(langProvider);

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              _Header(s: s),
              const SizedBox(height: 18),
              _UpcomingSession(s: s),
              const SizedBox(height: 22),
              SectionLabel(label: s.mySessions),
              _Menu(items: [
                _MenuItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: s.chats,
                  trailing: '${mockChats.length}',
                  onTap: () => context.push('/chats'),
                ),
                _MenuItem(
                  icon: Icons.event_rounded,
                  label: s.mySessions,
                  trailing: '3',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.book_outlined,
                  label: s.myJournal,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.favorite_outline_rounded,
                  label: 'Избранные специалисты',
                  trailing: '2',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 22),
              SectionLabel(label: 'Настройки'),
              _Menu(items: [
                _MenuItem(
                  icon: Icons.account_circle_outlined,
                  label: s.signIn,
                  onTap: () => context.push('/auth'),
                ),
                _MenuItem(
                  icon: Icons.language_rounded,
                  label: s.language,
                  trailing: lang.code,
                  onTap: () {
                    final next = AppLang.values[
                        (lang.index + 1) % AppLang.values.length];
                    ref.read(langProvider.notifier).state = next;
                  },
                ),
                _MenuItem(
                  icon: Icons.notifications_none_rounded,
                  label: s.notifications,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: s.privacy,
                  onTap: () => context.push('/legal/privacy'),
                ),
                _MenuItem(
                  icon: Icons.description_outlined,
                  label: 'Пользовательское соглашение',
                  onTap: () => context.push('/legal/terms'),
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  label: 'О приложении',
                  onTap: () => context.push('/legal/about'),
                ),
                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  label: s.helpSupport,
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 22),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                  child: Text(
                    s.signOut,
                    style: TextStyle(color: t.danger, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Nuva 0.1 · KZ',
                  style: TextStyle(color: t.textTer, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final S s;
  const _Header({required this.s});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Row(
      children: [
        const GradientAvatar(
          initials: 'А',
          gradient: [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
          size: 64,
          radius: 20,
          fontSize: 26,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Анонимный',
                      style: TextStyle(
                        color: t.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      )),
                  const SizedBox(width: 6),
                  Icon(Icons.lock_outline_rounded,
                      color: t.textTer, size: 16),
                ],
              ),
              const SizedBox(height: 2),
              Text('Профиль защищён · KZ',
                  style: TextStyle(color: t.textSec, fontSize: 13)),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.settings_outlined, color: t.text, size: 22),
        ),
      ],
    );
  }
}

class _UpcomingSession extends ConsumerWidget {
  final S s;
  const _UpcomingSession({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final sp = specialistCatalog.first;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dateLabel = DateFormat('d MMMM', 'ru').format(tomorrow);

    return GlassCard(
      elevated: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: t.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: t.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Ближайшая сессия',
                        style: TextStyle(
                          color: t.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        )),
                  ],
                ),
              ),
              const Spacer(),
              Text('$dateLabel · 14:00',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GradientAvatar(
                initials: sp.initials,
                gradient: sp.avatarGradient,
                size: 44,
                radius: 14,
                fontSize: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sp.fullName,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    Text('Видео · 50 минут',
                        style: TextStyle(color: t.textSec, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: t.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.videocam_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Войти',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
}

class _Menu extends StatelessWidget {
  final List<_MenuItem> items;
  const _Menu({required this.items});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      elevated: true,
      radius: 18,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: items[i].onTap,
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(18) : Radius.zero,
                bottom: i == items.length - 1
                    ? const Radius.circular(18)
                    : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Icon(items[i].icon, color: t.text, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(items[i].label,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                    if (items[i].trailing != null) ...[
                      Text(items[i].trailing!,
                          style: TextStyle(
                            color: t.textSec,
                            fontSize: 13,
                          )),
                      const SizedBox(width: 6),
                    ],
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: t.textTer),
                  ],
                ),
              ),
            ),
            if (i < items.length - 1)
              Container(
                margin: const EdgeInsets.only(left: 44),
                height: 1,
                color: t.divider,
              ),
          ],
        ],
      ),
    );
  }
}
