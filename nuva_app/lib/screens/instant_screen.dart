import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/strings.dart';
import '../models/booking.dart';
import '../services/api_client.dart';
import '../services/backend_auth.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';

/// "Поговорить сейчас" funnel with graceful degradation.
///
/// States: searching → (matched | fallback | offline). From the fallback the
/// client can leave a callback request (→ waiting, polled until a psychologist
/// claims it → claimed). A matched/claimed session offers video or chat.
///
/// Video uses a public Jitsi instance opened in a new tab — NOT private enough
/// for mental-health calls in production. TODO(prod): self-host Jitsi or use
/// JaaS before launch (see docs/VIDEO_CALL.md).
class InstantScreen extends ConsumerStatefulWidget {
  /// Optional concern carried from the quiz / home, used to seed the request.
  final String concern;
  const InstantScreen({super.key, this.concern = ''});

  @override
  ConsumerState<InstantScreen> createState() => _InstantScreenState();
}

enum _Phase { searching, matched, fallback, waiting, claimed, offline }

class _InstantScreenState extends ConsumerState<InstantScreen> {
  _Phase _phase = _Phase.searching;
  AppBooking? _booking; // set on match or on claim
  int _respondWithin = 15;
  int? _requestId;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _match());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  ApiClient get _api => ref.read(apiClientProvider);
  String? get _token => ref.read(backendAuthProvider.notifier).accessToken;

  Future<void> _match() async {
    setState(() => _phase = _Phase.searching);
    try {
      final res = await _api.post(
        'bookings/instant',
        {'concern': widget.concern},
        token: _token,
      );
      if ((res['available'] as bool?) == true) {
        ref.invalidate(bookingsProvider);
        setState(() {
          _booking = AppBooking.fromJson(res['booking'] as Map<String, dynamic>);
          _phase = _Phase.matched;
        });
      } else {
        setState(() {
          _respondWithin = (res['respond_within_min'] as num?)?.toInt() ?? 15;
          _phase = _Phase.fallback;
        });
      }
    } catch (_) {
      // Offline / backend unreachable — degrade, never crash.
      setState(() => _phase = _Phase.offline);
    }
  }

  Future<void> _leaveRequest(String channel) async {
    setState(() => _phase = _Phase.searching);
    try {
      final res = await _api.post(
        'bookings/instant/request',
        {'concern': widget.concern, 'channel': channel},
        token: _token,
      );
      _requestId = (res['id'] as num?)?.toInt();
      _respondWithin = (res['respond_within_min'] as num?)?.toInt() ?? 15;
      setState(() => _phase = _Phase.waiting);
      _startPolling();
    } catch (_) {
      setState(() => _phase = _Phase.offline);
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    final id = _requestId;
    if (id == null) return;
    try {
      final res = await _api.get('bookings/instant/request/$id', token: _token);
      final status = (res['status'] ?? '') as String;
      if (status == 'claimed' && res['booking'] != null) {
        _poll?.cancel();
        ref.invalidate(bookingsProvider);
        setState(() {
          _booking = AppBooking.fromJson(res['booking'] as Map<String, dynamic>);
          _phase = _Phase.claimed;
        });
      } else if (status == 'cancelled' || status == 'expired') {
        _poll?.cancel();
        setState(() => _phase = _Phase.fallback);
      }
    } catch (_) {
      // transient — keep polling
    }
  }

  Future<void> _cancelRequest() async {
    final id = _requestId;
    _poll?.cancel();
    if (id != null) {
      try {
        await _api.post('bookings/instant/request/$id/cancel', const {},
            token: _token);
      } catch (_) {/* ignore */}
    }
    if (mounted) context.pop();
  }

  void _openChannel(String channel) {
    final b = _booking;
    if (b == null) return;
    final convId = b.conversationId;
    if (channel == 'video' && convId != null) {
      context.push('/call/conv$convId');
    } else if (convId != null) {
      context.push('/chats/$convId');
    } else {
      context.go('/chats');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _Header(title: s.talkNow, onClose: () => context.pop()),
              Expanded(child: _body(s)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(S s) {
    switch (_phase) {
      case _Phase.searching:
        return _SearchingView(label: s.instantSearching);
      case _Phase.matched:
      case _Phase.claimed:
        return _MatchedView(
          title: _phase == _Phase.claimed ? s.instantClaimed : s.instantMatched,
          booking: _booking!,
          onVideo: () => _openChannel('video'),
          onChat: () => _openChannel('chat'),
        );
      case _Phase.fallback:
        return _FallbackView(
          respondWithin: _respondWithin,
          concern: widget.concern,
          onLeaveRequest: _leaveRequest,
          onBot: () => context.push('/intake'),
          onCatalog: () => context.go('/specialists'),
        );
      case _Phase.waiting:
        return _WaitingView(
          respondWithin: _respondWithin,
          onCancel: _cancelRequest,
          onBot: () => context.push('/intake'),
        );
      case _Phase.offline:
        return _OfflineView(
          onRetry: _match,
          onCatalog: () => context.go('/specialists'),
        );
    }
  }
}

// ─── Views ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const _Header({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: t.text, size: 22),
          ),
          const SizedBox(width: 4),
          Text(title,
              style: TextStyle(
                  color: t.text, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SearchingView extends StatelessWidget {
  final String label;
  const _SearchingView({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseAvatar(),
          const SizedBox(height: 28),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: t.text, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: t.blue),
          ),
        ],
      ),
    );
  }
}

class _PulseAvatar extends StatefulWidget {
  @override
  State<_PulseAvatar> createState() => _PulseAvatarState();
}

class _PulseAvatarState extends State<_PulseAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final v = _c.value;
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final phase in [0.0, 0.5])
                Opacity(
                  opacity: (1 - ((v + phase) % 1)).clamp(0.0, 1.0) * 0.4,
                  child: Container(
                    width: 80 + ((v + phase) % 1) * 60,
                    height: 80 + ((v + phase) % 1) * 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: t.blue, width: 2),
                    ),
                  ),
                ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [t.blue, t.teal]),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 38),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MatchedView extends ConsumerWidget {
  final String title;
  final AppBooking booking;
  final VoidCallback onVideo;
  final VoidCallback onChat;
  const _MatchedView({
    required this.title,
    required this.booking,
    required this.onVideo,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.teal, t.blue]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 22),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: t.text, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(booking.specialistName,
              style: TextStyle(color: t.textSec, fontSize: 15)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: t.teal.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(s.instantFree,
                style: TextStyle(
                    color: t.teal, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 28),
          Text(s.instantPickChannel,
              style: TextStyle(
                  color: t.text, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ChannelButton(
                  icon: Icons.videocam_rounded,
                  label: s.instantVideo,
                  filled: true,
                  onTap: onVideo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChannelButton(
                  icon: Icons.chat_bubble_rounded,
                  label: s.instantChat,
                  filled: false,
                  onTap: onChat,
                ),
              ),
            ],
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _ChannelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _ChannelButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: filled ? t.blue : t.glassBgUp,
          border: filled ? null : Border.all(color: t.glassBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: filled ? Colors.white : t.blue, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: filled ? Colors.white : t.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _FallbackView extends ConsumerWidget {
  final int respondWithin;
  final String concern;
  final ValueChanged<String> onLeaveRequest;
  final VoidCallback onBot;
  final VoidCallback onCatalog;
  const _FallbackView({
    required this.respondWithin,
    required this.concern,
    required this.onLeaveRequest,
    required this.onBot,
    required this.onCatalog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: t.blue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.schedule_rounded, color: t.blue, size: 38),
          ),
        ),
        const SizedBox(height: 20),
        Text(s.instantNoneTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: t.text, fontSize: 21, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(s.instantNoneBody(respondWithin),
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textSec, fontSize: 14, height: 1.5)),
        const SizedBox(height: 24),
        // Primary CTA: leave a callback request (default channel = chat for
        // lowest friction; the psychologist can switch to video on claim).
        PrimaryButton(
          label: s.instantLeaveRequest,
          onPressed: () => onLeaveRequest('chat'),
        ),
        const SizedBox(height: 12),
        _SecondaryCard(
          icon: Icons.auto_awesome_rounded,
          label: s.instantTalkToBot,
          onTap: onBot,
        ),
        const SizedBox(height: 10),
        _SecondaryCard(
          icon: Icons.psychology_rounded,
          label: s.instantBrowseCatalog,
          onTap: onCatalog,
        ),
      ],
    );
  }
}

class _SecondaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      onTap: onTap,
      elevated: true,
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: t.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: t.text, fontSize: 14.5, fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: t.textTer),
        ],
      ),
    );
  }
}

class _WaitingView extends ConsumerWidget {
  final int respondWithin;
  final VoidCallback onCancel;
  final VoidCallback onBot;
  const _WaitingView({
    required this.respondWithin,
    required this.onCancel,
    required this.onBot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          _PulseAvatar(),
          const SizedBox(height: 24),
          Text(s.instantWaitingTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: t.text, fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(s.instantWaitingBody(respondWithin),
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textSec, fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          PrimaryButton(label: s.instantTalkToBot, onPressed: onBot),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onCancel,
            child: Text(s.instantCancelRequest,
                style: TextStyle(color: t.textSec, fontSize: 14)),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _OfflineView extends ConsumerWidget {
  final VoidCallback onRetry;
  final VoidCallback onCatalog;
  const _OfflineView({required this.onRetry, required this.onCatalog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: t.danger.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off_rounded, color: t.danger, size: 36),
          ),
          const SizedBox(height: 20),
          Text(s.instantOfflineTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: t.text, fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(s.instantOfflineBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textSec, fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          PrimaryButton(label: s.instantBrowseCatalog, onPressed: onCatalog),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: Text('Повторить', style: TextStyle(color: t.blue)),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
