import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/strings.dart';
import '../models/community.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';
import '../widgets/like_button.dart';

final selectedTagProvider = StateProvider<String>((_) => 'Все');

const _replyGradient = [Color(0xFF93D8B5), Color(0xFFB7E8CC)];
const _composerGradient = [Color(0xFF7FB7E8), Color(0xFFA3D8F4)];

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    final tag = ref.watch(selectedTagProvider);
    final feedAsync = ref.watch(communityFeedProvider(tag));

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Text(s.communityTitle,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    )),
              ),
              // Inline composer (Threads-style) → opens the compose screen.
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _Composer(
                  onTap: () => context.push('/community/compose'),
                ),
              ),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: communityTags.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final tagLabel = communityTags[i];
                    return Tag(
                      label: tagLabel,
                      selected: tagLabel == tag,
                      onTap: () => ref
                          .read(selectedTagProvider.notifier)
                          .state = tagLabel,
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: feedAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (feed) => RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(communityFeedProvider);
                      await ref.read(communityFeedProvider(tag).future);
                    },
                    color: t.blue,
                    backgroundColor: t.surface,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 130),
                      itemCount: feed.length,
                      itemBuilder: (_, i) => _PostCard(
                        post: feed[i],
                        onTap: () => context.push('/community/${feed[i].id}'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final VoidCallback onTap;
  const _Composer({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      onTap: onTap,
      elevated: true,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              const GradientAvatar(
                initials: '',
                gradient: _composerGradient,
                size: 34,
                radius: 999,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text('Поделиться переживанием…',
                    style: TextStyle(color: t.textTer, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: t.divider),
          const SizedBox(height: 11),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: t.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 13, color: t.blue),
                    const SizedBox(width: 6),
                    Text('Публиковать анонимно',
                        style: TextStyle(
                          color: t.blue,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Опубликовать'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  const _PostCard({required this.post, required this.onTap});

  String _idLabel() {
    final i = post.author.alias.indexOf('#');
    return i >= 0 ? post.author.alias.substring(i) : 'ID';
  }

  String _hashtags() =>
      post.tags.map((x) => '#${x.toLowerCase()}').join('  ');

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientAvatar(
              initials: '',
              gradient: post.author.gradient,
              size: 38,
              radius: 999,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // author row: Анонимно + lock-ID chip + time
                  Row(
                    children: [
                      Text('Анонимно',
                          style: TextStyle(
                            color: t.text,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.glassBgUp,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 10, color: t.textTer),
                            const SizedBox(width: 3),
                            Text(_idLabel(),
                                style: TextStyle(
                                  color: t.textTer,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text('· ${post.timeLabel}',
                          style: TextStyle(color: t.textTer, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(post.text,
                      style: TextStyle(
                        color: t.text,
                        fontSize: 14.5,
                        height: 1.45,
                      )),
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_hashtags(),
                        style: TextStyle(
                          color: t.blue,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                  if (post.topReplyText != null) ...[
                    const SizedBox(height: 12),
                    _ReplyPreview(
                      text: post.topReplyText!,
                      fromSpecialist: post.topReplyFromSpecialist,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      LikeButton(
                        likeKey: 'post:${post.id}',
                        path: 'community/posts/${post.id}/like/',
                        baseLiked: post.liked,
                        baseCount: post.likes,
                        iconSize: 17,
                        activeColor: t.teal,
                        label: 'Поддержать',
                      ),
                      const SizedBox(width: 18),
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 16, color: t.textSec),
                      const SizedBox(width: 6),
                      Text('${post.replies}',
                          style: TextStyle(
                            color: t.textSec,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Threaded (Reddit/Threads-style) reply preview shown under a feed post.
class _ReplyPreview extends StatelessWidget {
  final String text;
  final bool fromSpecialist;
  const _ReplyPreview({required this.text, required this.fromSpecialist});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: t.divider, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientAvatar(
            initials: '',
            gradient: _replyGradient,
            size: 26,
            radius: 999,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Анонимно',
                        style: TextStyle(
                          color: t.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                    if (fromSpecialist) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: t.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('специалист',
                            style: TextStyle(
                              color: t.blue,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textSec,
                      fontSize: 13,
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
