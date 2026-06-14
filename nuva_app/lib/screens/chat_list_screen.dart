import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/strings.dart';
import '../models/chat.dart';
import '../models/specialist.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: t.text, size: 18),
                    ),
                    Text(s.chats,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        )),
                  ],
                ),
              ),
              if (mockChats.isEmpty)
                Expanded(child: _Empty(s: s))
              else
                Expanded(
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: mockChats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final chat = mockChats[i];
                      final sp = specialistCatalog.byId(chat.specialistId);
                      return _ChatTile(
                        chat: chat,
                        sp: sp,
                        onTap: () => context.push('/chats/${chat.id}'),
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
}

class _ChatTile extends ConsumerWidget {
  final Chat chat;
  final Specialist sp;
  final VoidCallback onTap;
  const _ChatTile({
    required this.chat,
    required this.sp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    final last = chat.lastMessage;
    final preview = last == null
        ? ''
        : (last.sender == MsgSender.user ? 'Вы: ' : '') + last.text;
    final unread = chat.unreadCount;

    return GlassCard(
      onTap: onTap,
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Stack(
            children: [
              GradientAvatar(
                initials: sp.initials,
                gradient: sp.avatarGradient,
                size: 52,
                radius: 16,
                fontSize: 19,
              ),
              if (chat.specialistOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: t.teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(sp.fullName,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, color: t.blue, size: 12),
                    const Spacer(),
                    if (last != null)
                      Text(_when(last.sentAt),
                          style: TextStyle(color: t.textTer, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread > 0 ? t.text : t.textSec,
                          fontSize: 13,
                          fontWeight: unread > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.blue,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _when(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return '${diff.inHours} ч';
    if (diff.inDays < 7) return '${diff.inDays} д';
    return '${d.day}.${d.month.toString().padLeft(2, '0')}';
  }
}

class _Empty extends StatelessWidget {
  final S s;
  const _Empty({required this.s});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: t.textTer),
            const SizedBox(height: 16),
            Text(s.noChats,
                style: TextStyle(
                  color: t.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            Text(
              s.noChatsSub,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textSec, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
