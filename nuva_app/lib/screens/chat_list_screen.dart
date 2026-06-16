import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/strings.dart';
import '../models/chat.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/auto_refresh.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

class ChatListScreen extends ConsumerWidget {
  final bool showBack;
  final String? title;
  const ChatListScreen({super.key, this.showBack = true, this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;

    return AutoRefresh(
      interval: const Duration(seconds: 6),
      onTick: (ref) => ref.invalidate(conversationsProvider),
      child: Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(showBack ? 8 : 20, 8, 20, 8),
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: t.text, size: 18),
                      ),
                    Text(title ?? s.chats,
                        style: TextStyle(
                          color: t.text,
                          fontSize: showBack ? 22 : 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        )),
                  ],
                ),
              ),
              Expanded(
                child: ref.watch(conversationsProvider).when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _Empty(s: s),
                      data: (chats) {
                        if (chats.isEmpty) return _Empty(s: s);
                        return RefreshIndicator(
                          color: t.blue,
                          backgroundColor: t.surface,
                          onRefresh: () async {
                            ref.invalidate(conversationsProvider);
                            await ref.read(conversationsProvider.future);
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: chats.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final chat = chats[i];
                              return _ChatTile(
                                chat: chat,
                                onTap: () =>
                                    context.push('/chats/${chat.id}'),
                              );
                            },
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ApiConversation chat;
  final VoidCallback onTap;
  const _ChatTile({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final unread = chat.unread;
    final preview = chat.lastText == null
        ? ''
        : (chat.lastSender == MsgSender.user ? 'Вы: ' : '') + chat.lastText!;

    return GlassCard(
      onTap: onTap,
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          GradientAvatar(
            initials: chat.otherInitials,
            gradient: chat.gradient,
            size: 52,
            radius: 16,
            fontSize: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(chat.otherName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, color: t.blue, size: 12),
                    const Spacer(),
                    Text(_when(chat.updatedAt),
                        style: TextStyle(color: t.textTer, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread > 0 ? t.text : t.textSec,
                          fontSize: 13,
                          fontWeight:
                              unread > 0 ? FontWeight.w600 : FontWeight.w400,
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
    final diff = DateTime.now().difference(d);
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
    return ListView(
      // ListView so pull-to-refresh still works on the empty state.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
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
      ],
    );
  }
}
