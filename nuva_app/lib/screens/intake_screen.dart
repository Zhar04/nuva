import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/strings.dart';
import '../services/claude_service.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';

final _claudeProvider = Provider((_) => ClaudeService());

class IntakeScreen extends ConsumerStatefulWidget {
  const IntakeScreen({super.key, this.onboarding = false});

  /// When reached as an onboarding step, exits lead to registration (/auth).
  final bool onboarding;

  @override
  ConsumerState<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends ConsumerState<IntakeScreen> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final List<ChatTurn> _turns = [];
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Seed first assistant message after first frame to access providers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = S.of(ref);
      setState(() {
        _turns.add(ChatTurn('assistant', s.intakeFirstMessage));
      });
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _skip() =>
      context.go(widget.onboarding ? '/auth?mode=register' : '/home');

  bool _isSkipCommand(String text) {
    final c = text.toLowerCase();
    return c == '/skip' || c == '/skip-onboarding' || c == '/home';
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    // Escape hatch: type /skip (or /skip-onboarding) to bypass the AI intake.
    if (_isSkipCommand(text)) {
      _input.clear();
      _skip();
      return;
    }
    final lang = ref.read(langProvider);
    setState(() {
      _turns.add(ChatTurn('user', text));
      _input.clear();
      _sending = true;
      _error = null;
    });
    _scrollToEnd();

    try {
      final reply = await ref.read(_claudeProvider).reply(
            history: _turns,
            userLanguage: lang.locale.languageCode,
          );
      setState(() {
        _turns.add(ChatTurn('assistant', reply));
        _sending = false;
      });
      _scrollToEnd();
    } catch (e) {
      setState(() {
        _sending = false;
        _error = S.of(ref).aiError;
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _IntakeHeader(
                title: s.intakeTitle,
                step: 'Шаг 2 из 4',
                skipLabel: s.skip,
                onSkip: _skip,
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _turns.length + (_sending ? 1 : 0) + (_error != null ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i < _turns.length) {
                      return _Bubble(turn: _turns[i]);
                    }
                    if (_sending && i == _turns.length) {
                      return const _TypingBubble();
                    }
                    return _ErrorBubble(message: _error!);
                  },
                ),
              ),
              _Composer(
                controller: _input,
                hint: s.inputHint,
                sending: _sending,
                onSend: _send,
              ),
              if (_turns.length > 4)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: PrimaryButton(
                    label: s.findSpecialist,
                    onPressed: () => context.go(widget.onboarding
                        ? '/auth?mode=register'
                        : '/specialists'),
                  ),
                )
              else
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntakeHeader extends StatelessWidget {
  final String title;
  final String step;
  final String skipLabel;
  final VoidCallback onSkip;
  const _IntakeHeader({
    required this.title,
    required this.step,
    required this.skipLabel,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GlassCard(
        elevated: true,
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    step,
                    style: TextStyle(color: t.textSec, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onSkip,
              child: Text(
                skipLabel,
                style: TextStyle(
                  color: t.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatTurn turn;
  const _Bubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final isUser = turn.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _AssistantAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? t.blue : t.glassBgUp,
                border: isUser
                    ? null
                    : Border.all(color: t.glassBorder, width: 1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
              ),
              child: Text(
                turn.content,
                style: TextStyle(
                  color: isUser ? Colors.white : t.text,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.blue, t.teal],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const _AssistantAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: t.glassBgUp,
              border: Border.all(color: t.glassBorder),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: List.generate(3, (i) {
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  child: _Dot(delay: i * 160),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: t.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  final String message;
  const _ErrorBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.danger.withOpacity(0.12),
          border: Border.all(color: t.danger.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message,
          style: TextStyle(color: t.danger, fontSize: 13),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool sending;
  final VoidCallback onSend;
  const _Composer({
    required this.controller,
    required this.hint,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GlassCard(
        elevated: true,
        radius: 22,
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: t.text, fontSize: 15),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: t.textTer),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: sending ? t.textTer : t.blue,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: sending ? null : onSend,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_upward_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
