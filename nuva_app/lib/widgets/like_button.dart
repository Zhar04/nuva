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
  const LikeButton({
    super.key,
    required this.likeKey,
    required this.path,
    required this.baseLiked,
    required this.baseCount,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.nuva;
    final override = ref.watch(likeProvider)[likeKey];
    final liked = override?.liked ?? baseLiked;
    final count = override?.count ?? baseCount;
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
            color: liked ? t.danger : t.textSec,
          ),
          const SizedBox(width: 5),
          Text('$count',
              style: TextStyle(
                color: t.textSec,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
