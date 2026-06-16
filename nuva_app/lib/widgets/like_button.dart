import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/data.dart';
import '../theme/theme.dart';
import 'nuva_logo.dart';

/// Heart that fills with the active colour and pulses (squash→stretch→settle)
/// the moment it becomes liked.
class _PulseHeart extends StatefulWidget {
  final bool liked;
  final Color color;
  final double size;
  const _PulseHeart({
    required this.liked,
    required this.color,
    required this.size,
  });

  @override
  State<_PulseHeart> createState() => _PulseHeartState();
}

class _PulseHeartState extends State<_PulseHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.18), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 30),
  ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void didUpdateWidget(covariant _PulseHeart old) {
    super.didUpdateWidget(old);
    if (widget.liked && !old.liked) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: NuvaHeartIcon(
        size: widget.size,
        color: widget.color,
        filled: widget.liked,
        strokeWidth: 2,
      ),
    );
  }
}

/// A heart + count that toggles a like through [likeProvider] (single source of
/// truth, server-reconciled). [likeKey] is e.g. `"post:5"` / `"reply:3"`;
/// [path] is the backend toggle endpoint. [baseLiked]/[baseCount] are the
/// values from the loaded item, used until the provider holds an override.
class LikeButton extends ConsumerWidget {
  final String likeKey;
  final String path;
  final bool baseLiked;
  final int baseCount;
  final double iconSize;

  /// Colour when liked. Defaults to danger (red heart); the community feed
  /// passes teal for the "Поддержать" treatment.
  final Color? activeColor;

  /// Optional trailing label after the count, e.g. "· Поддержать".
  final String? label;

  const LikeButton({
    super.key,
    required this.likeKey,
    required this.path,
    required this.baseLiked,
    required this.baseCount,
    this.iconSize = 16,
    this.activeColor,
    this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final override = ref.watch(likeProvider)[likeKey];
    final liked = override?.liked ?? baseLiked;
    final count = override?.count ?? baseCount;
    final active = activeColor ?? t.danger;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          ref.read(likeProvider.notifier).toggle(likeKey, path, liked, count),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseHeart(
            liked: liked,
            color: liked ? active : t.textSec,
            size: iconSize,
          ),
          const SizedBox(width: 6),
          Text(
            label == null ? '$count' : '$count · $label',
            style: TextStyle(
              color: liked ? active : t.textSec,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
