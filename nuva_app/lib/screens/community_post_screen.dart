import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/community.dart';
import '../services/api_client.dart';
import '../services/backend_auth.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';
import '../widgets/like_button.dart';

class CommunityPostScreen extends ConsumerStatefulWidget {
  final String postId;
  const CommunityPostScreen({super.key, required this.postId});

  @override
  ConsumerState<CommunityPostScreen> createState() => _State();
}

class _State extends ConsumerState<CommunityPostScreen> {
  final _input = TextEditingController();
  bool _sending = false;

  int get _postId => int.tryParse(widget.postId) ?? -1;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  CommunityPost? _mockPost() {
    for (final p in communityFeed) {
      if (p.id == widget.postId) return p;
    }
    return null;
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      await ref.read(apiClientProvider).post(
        'community/posts/$_postId/replies/',
        {'text': text},
        token: token,
      );
      _input.clear();
      ref.invalidate(communityRepliesProvider(_postId));
      ref.invalidate(communityPostProvider(_postId));
      ref.invalidate(communityFeedProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: context.nuva.danger,
          content: Text(e is ApiException ? e.message : 'Не удалось отправить',
              style: const TextStyle(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;
    final postAsync = ref.watch(communityPostProvider(_postId));
    final post = postAsync.valueOrNull ?? _mockPost();
    final replies =
        ref.watch(communityRepliesProvider(_postId)).valueOrNull ??
            const <CommunityReply>[];

    if (post == null) {
      return Scaffold(
        body: GlassBackdrop(
          child: SafeArea(
            child: Center(
              child: postAsync.isLoading
                  ? const CircularProgressIndicator()
                  : Text('Пост недоступен',
                      style: TextStyle(color: t.textSec)),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: t.text, size: 18),
                    ),
                    Text(s.communityTitle,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    _PostHero(post: post),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          '${replies.length} ${s.lang == AppLang.en ? "replies" : "ответов"}',
                          style: TextStyle(
                            color: t.textSec,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (replies.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            s.lang == AppLang.en
                                ? 'Be the first to reply'
                                : 'Будьте первым, кто ответит',
                            style: TextStyle(color: t.textTer, fontSize: 13),
                          ),
                        ),
                      ),
                    ...replies.map((r) => _ReplyCard(reply: r)),
                  ],
                ),
              ),
              _Composer(controller: _input, hint: s.replyHint, onSend: _send),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostHero extends StatelessWidget {
  final CommunityPost post;
  const _PostHero({required this.post});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      elevated: true,
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientAvatar(
                initials: 'А',
                gradient: post.author.gradient,
                size: 44,
                radius: 999,
                fontSize: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.author.alias,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(post.timeLabel,
                        style: TextStyle(color: t.textTer, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.text,
              style: TextStyle(
                color: t.text,
                fontSize: 15,
                height: 1.55,
              )),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: post.tags.map((x) => Tag(label: '# $x')).toList(),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: t.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              LikeButton(
                likeKey: 'post:${post.id}',
                path: 'community/posts/${post.id}/like/',
                baseLiked: post.liked,
                baseCount: post.likes,
              ),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline_rounded,
                  color: t.textSec, size: 15),
              const SizedBox(width: 6),
              Text('${post.replies}',
                  style: TextStyle(
                    color: t.textSec,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyCard extends ConsumerWidget {
  final CommunityReply reply;
  const _ReplyCard({required this.reply});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GradientAvatar(
                  initials: reply.author.alias.characters.first,
                  gradient: reply.author.gradient,
                  size: 30,
                  radius: 999,
                  fontSize: 12,
                ),
                const SizedBox(width: 8),
                Text(reply.author.alias,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
                if (reply.fromSpecialist) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(s.fromSpecialist,
                        style: TextStyle(
                          color: t.blue,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ],
                const Spacer(),
                Text(reply.timeLabel,
                    style: TextStyle(color: t.textTer, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(reply.text,
                style: TextStyle(color: t.text, fontSize: 13.5, height: 1.45)),
            const SizedBox(height: 8),
            LikeButton(
              likeKey: 'reply:${reply.id}',
              path: 'community/replies/${reply.id}/like/',
              baseLiked: reply.liked,
              baseCount: reply.likes,
              iconSize: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;
  const _Composer({
    required this.controller,
    required this.hint,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Container(
      decoration: BoxDecoration(
        color: t.surface.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: t.divider)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              style: TextStyle(color: t.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: t.textTer, fontSize: 13),
                filled: true,
                fillColor: t.glassBgUp,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: t.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: t.blue, width: 1.4),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: t.blue,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
