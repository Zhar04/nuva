import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calls [onTick] every [interval] while mounted — a lightweight stand-in for
/// realtime updates (the backend has no websockets). Wrap a screen subtree so
/// lists (chats, incoming sessions, call requests) refresh on their own instead
/// of only on a manual pull-to-refresh.
class AutoRefresh extends ConsumerStatefulWidget {
  final Duration interval;
  final void Function(WidgetRef ref) onTick;
  final Widget child;
  const AutoRefresh({
    super.key,
    required this.onTick,
    required this.child,
    this.interval = const Duration(seconds: 5),
  });

  @override
  ConsumerState<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends ConsumerState<AutoRefresh> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(widget.interval, (_) {
      if (mounted) widget.onTick(ref);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
