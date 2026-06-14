import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/strings.dart';
import '../models/community.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

final selectedTagProvider = StateProvider<String>((_) => 'Все');

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    final tag = ref.watch(selectedTagProvider);
    final feed = tag == 'Все'
        ? communityFeed
        : communityFeed.where((p) => p.tags.contains(tag)).toList();

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.communityTitle,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        )),
                    const SizedBox(height: 2),
                    Text(s.communityHint,
                        style: TextStyle(
                          color: t.textSec,
                          fontSize: 13,
                          height: 1.4,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: communityTags.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final tagLabel = communityTags[i];
                    return Tag(
                      label: tagLabel,
                      selected: tagLabel == tag,
                      onTap: () => ref.read(selectedTagProvider.notifier).state = tagLabel,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  itemCount: feed.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = feed[i];
                    return _PostCard(
                      post: p,
                      onTap: () => context.push('/community/${p.id}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: t.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => context.push('/community/compose'),
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: Text(s.compose,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;

    return GlassCard(
      onTap: onTap,
      elevated: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientAvatar(
                initials: post.author.alias
                    .split(' ')
                    .map((e) => e.characters.first)
                    .take(2)
                    .join(),
                gradient: post.author.gradient,
                size: 38,
                radius: 999,
                fontSize: 13,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(post.author.alias,
                            style: TextStyle(
                              color: t.text,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(width: 6),
                        Icon(Icons.lock_outline_rounded,
                            color: t.textTer, size: 11),
                      ],
                    ),
                    Text(post.timeLabel,
                        style: TextStyle(color: t.textTer, fontSize: 11)),
                  ],
                ),
              ),
              if (post.isSupported)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_rounded, size: 11, color: t.teal),
                      const SizedBox(width: 4),
                      Text(s.supportive,
                          style: TextStyle(
                            color: t.teal,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.text,
            style: TextStyle(
              color: t.text,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: post.tags
                .map((tag) => Tag(label: '# $tag'))
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Action(icon: Icons.favorite_outline_rounded, count: post.likes),
              const SizedBox(width: 16),
              _Action(icon: Icons.chat_bubble_outline_rounded, count: post.replies),
              const Spacer(),
              Icon(Icons.ios_share_rounded, size: 16, color: t.textTer),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final int count;
  const _Action({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Row(
      children: [
        Icon(icon, size: 16, color: t.textSec),
        const SizedBox(width: 5),
        Text('$count',
            style: TextStyle(
              color: t.textSec,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}
