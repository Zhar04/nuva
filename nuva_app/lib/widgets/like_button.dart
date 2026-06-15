import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/data.dart';
import '../theme/theme.dart';

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
          Icon(
            liked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            size: iconSize,
            color: liked ? active : t.textSec,
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
