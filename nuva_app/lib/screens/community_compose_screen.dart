import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/community.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

class CommunityComposeScreen extends ConsumerStatefulWidget {
  const CommunityComposeScreen({super.key});

  @override
  ConsumerState<CommunityComposeScreen> createState() => _State();
}

class _State extends ConsumerState<CommunityComposeScreen> {
  final _text = TextEditingController();
  final Set<String> _picked = {};

  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = _text.text.trim();
    if (text.length < 4 || _busy) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final danger = context.nuva.danger;
    final s = S.of(ref);
    setState(() => _busy = true);
    try {
      await ref
          .read(dbProvider)
          .publishPost(text: text, tags: _picked.toList());
      ref.invalidate(communityFeedProvider);
      navigator.maybePop();
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(
        backgroundColor: danger,
        content: Text(s.signInToPost,
            style: const TextStyle(color: Colors.white)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;
    final canPublish = _text.text.trim().length >= 4;

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.close_rounded, color: t.text, size: 22),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: (canPublish && !_busy) ? _publish : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canPublish ? t.blue : t.textTer,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(s.publish),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GradientAvatar(
                            initials: 'А',
                            gradient: const [
                              Color(0xFF7FE0D4),
                              Color(0xFFB0EDE5),
                            ],
                            size: 38,
                            radius: 999,
                            fontSize: 14,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Тихий ветер #82',
                                      style: TextStyle(
                                        color: t.text,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  const SizedBox(width: 6),
                                  Icon(Icons.lock_outline_rounded,
                                      color: t.textTer, size: 12),
                                ],
                              ),
                              Text(s.communityHint,
                                  style: TextStyle(
                                      color: t.textTer, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _text,
                        autofocus: true,
                        minLines: 6,
                        maxLines: 14,
                        maxLength: 500,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: t.text,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: s.composeHint,
                          hintStyle: TextStyle(color: t.textTer, fontSize: 15),
                          border: InputBorder.none,
                          counterStyle: TextStyle(color: t.textTer, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Теги',
                          style: TextStyle(
                            color: t.textTer,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          )),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: communityTags
                            .where((x) => x != 'Все')
                            .map((tag) {
                          final picked = _picked.contains(tag);
                          return Tag(
                            label: tag,
                            selected: picked,
                            onTap: () => setState(() {
                              if (picked) {
                                _picked.remove(tag);
                              } else {
                                _picked.add(tag);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: t.teal.withValues(alpha: 0.1),
                          border: Border.all(
                              color: t.teal.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined,
                                color: t.teal, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Каждый пост проходит проверку. Никаких контактов, рекламы и оценочных суждений.',
                                style: TextStyle(
                                  color: t.teal,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
