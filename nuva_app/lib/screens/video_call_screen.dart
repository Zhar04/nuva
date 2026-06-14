import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/strings.dart';
import '../models/specialist.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';

/// Phase-0 visual stub. Phase 1: Daily.co or Agora WebRTC.
class VideoCallScreen extends ConsumerStatefulWidget {
  final String specialistId;
  const VideoCallScreen({super.key, required this.specialistId});

  @override
  ConsumerState<VideoCallScreen> createState() => _State();
}

class _State extends ConsumerState<VideoCallScreen> {
  bool _connecting = true;
  bool _camOn = true;
  bool _micOn = true;
  bool _speakerOn = true;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _connecting = false);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed = _elapsed + const Duration(seconds: 1));
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;
    final sp = specialistCatalog.byId(widget.specialistId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video — full screen gradient (placeholder until WebRTC).
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: sp.avatarGradient
                      .map((c) => Color.alphaBlend(
                          Colors.black.withValues(alpha: 0.45), c))
                      .toList(),
                ),
              ),
            ),
          ),
          // Center remote avatar (visible while connecting + as visual anchor)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PulseAvatar(initials: sp.initials, gradient: sp.avatarGradient),
                const SizedBox(height: 18),
                Text(sp.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    )),
                const SizedBox(height: 6),
                Text(
                  _connecting ? s.connecting : _fmt(_elapsed),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Local self-view (PiP)
          Positioned(
            top: 48,
            right: 16,
            child: Container(
              width: 96,
              height: 132,
              decoration: BoxDecoration(
                color: const Color(0xFF1B2230),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _camOn
                  ? const Center(
                      child: Icon(Icons.person_rounded,
                          color: Colors.white24, size: 44),
                    )
                  : Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.videocam_off_rounded,
                            color: Colors.white70, size: 20),
                      ),
                    ),
            ),
          ),
          // Top status bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _connecting ? t.danger : t.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _connecting ? 'СОЕДИНЯЕМ' : 'В ЭФИРЕ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CtrlButton(
                        icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                        active: _micOn,
                        onTap: () => setState(() => _micOn = !_micOn),
                      ),
                      _CtrlButton(
                        icon: _camOn
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        active: _camOn,
                        onTap: () => setState(() => _camOn = !_camOn),
                      ),
                      _CtrlButton(
                        icon: _speakerOn
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        active: _speakerOn,
                        onTap: () =>
                            setState(() => _speakerOn = !_speakerOn),
                      ),
                      _CtrlButton(
                        icon: Icons.chat_bubble_rounded,
                        active: true,
                        onTap: () {},
                      ),
                      _EndCallButton(onTap: () => context.pop()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseAvatar extends StatefulWidget {
  final String initials;
  final List<Color> gradient;
  const _PulseAvatar({required this.initials, required this.gradient});

  @override
  State<_PulseAvatar> createState() => _PulseAvatarState();
}

class _PulseAvatarState extends State<_PulseAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ...List.generate(3, (i) {
                final progress = (_c.value + i / 3) % 1;
                return Opacity(
                  opacity: (1 - progress) * 0.45,
                  child: Container(
                    width: 120 + progress * 90,
                    height: 120 + progress * 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.gradient.last,
                        width: 1.4,
                      ),
                    ),
                  ),
                );
              }),
              GradientAvatar(
                initials: widget.initials,
                gradient: widget.gradient,
                size: 120,
                radius: 999,
                fontSize: 42,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CtrlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _CtrlButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: active
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.white60,
          size: 22,
        ),
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFE04B4D),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE04B4D).withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.call_end_rounded,
            color: Colors.white, size: 24),
      ),
    );
  }
}
