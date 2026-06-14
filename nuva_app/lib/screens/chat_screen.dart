import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/chat.dart';
import '../models/specialist.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

final _contactRe = RegExp(
  r'(\+?\d[\d\s\-]{8,})|(\b(?:whatsapp|telegram|wa\.me|t\.me|@[a-z0-9_]+)\b)',
  caseSensitive: false,
);

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _State();
}

class _State extends ConsumerState<ChatScreen> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  late List<Message> _messages;
  bool _showContactWarning = false;
  bool _specialistTyping = false;

  @override
  void initState() {
    super.initState();
    final chat = mockChats.firstWhere((c) => c.id == widget.chatId);
    _messages = List.of(chat.messages);
    _input.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd(jump: true));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _check() {
    final text = _input.text;
    final has = _contactRe.hasMatch(text);
    if (has != _showContactWarning) {
      setState(() => _showContactWarning = has);
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    if (_contactRe.hasMatch(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.nuva.danger,
          content: Text(S.of(ref).contactWarning,
              style: const TextStyle(color: Colors.white)),
        ),
      );
      return;
    }
    setState(() {
      _messages.add(Message(
        id: 'u${_messages.length}',
        sender: MsgSender.user,
        text: text,
        sentAt: DateTime.now(),
      ));
      _input.clear();
      _specialistTyping = true;
    });
    _toEnd();
    // Auto-reply simulation
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _specialistTyping = false;
        _messages.add(Message(
          id: 's${_messages.length}',
          sender: MsgSender.specialist,
          text:
              'Спасибо, что поделились. Запомним это и обсудим на сессии — попробуйте до тех пор отметить в дневнике, что предшествовало этому ощущению.',
          sentAt: DateTime.now(),
        ));
      });
      _toEnd();
    });
  }

  void _toEnd({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent + 240;
      if (jump) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(target,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;
    final chat = mockChats.firstWhere((c) => c.id == widget.chatId);
    final sp = specialistCatalog.byId(chat.specialistId);

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _Header(sp: sp, online: chat.specialistOnline, typing: _specialistTyping),
              if (chat.nextSessionAt != null)
                _SessionBanner(
                  at: chat.nextSessionAt!,
                  onJoin: () => context.push('/call/${sp.id}'),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: _messages.length + (_specialistTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_specialistTyping && i == _messages.length) {
                      return _TypingBubble(gradient: sp.avatarGradient);
                    }
                    final m = _messages[i];
                    final prev = i > 0 ? _messages[i - 1] : null;
                    final showDate = prev == null ||
                        prev.sentAt.day != m.sentAt.day ||
                        prev.sentAt.month != m.sentAt.month;
                    return Column(
                      children: [
                        if (showDate) _DateChip(date: m.sentAt),
                        _MessageBubble(msg: m, gradient: sp.avatarGradient),
                      ],
                    );
                  },
                ),
              ),
              if (_showContactWarning) _ContactWarn(text: s.contactWarning),
              _Composer(
                controller: _input,
                hint: s.messagePlaceholder,
                onSend: _send,
                disabled: _showContactWarning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final Specialist sp;
  final bool online;
  final bool typing;
  const _Header({required this.sp, required this.online, required this.typing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 18),
          ),
          GradientAvatar(
            initials: sp.initials,
            gradient: sp.avatarGradient,
            size: 38,
            radius: 999,
            fontSize: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(sp.fullName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, color: t.blue, size: 12),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.psychologist,
                        style: TextStyle(
                          color: t.blue,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  typing ? s.typing : (online ? s.online : s.offline),
                  style: TextStyle(
                    color: typing || online ? t.teal : t.textTer,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.videocam_outlined, color: t.text, size: 22),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_horiz_rounded, color: t.text, size: 22),
          ),
        ],
      ),
    );
  }
}

class _SessionBanner extends ConsumerWidget {
  final DateTime at;
  final VoidCallback onJoin;
  const _SessionBanner({required this.at, required this.onJoin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    final label = DateFormat('d MMMM · HH:mm', 'ru').format(at);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.blue.withValues(alpha: 0.95), t.teal.withValues(alpha: 0.95)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ближайшая сессия',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      )),
                  Text(label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: t.blue,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(s.joinVideo),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    final label = diff == 0
        ? 'Сегодня'
        : diff == 1
            ? 'Вчера'
            : DateFormat('d MMMM', 'ru').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: t.glassBgUp,
          border: Border.all(color: t.glassBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
              color: t.textSec,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            )),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final Message msg;
  final List<Color> gradient;
  const _MessageBubble({required this.msg, required this.gradient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    if (msg.sender == MsgSender.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: t.teal.withValues(alpha: 0.08),
            border: Border.all(color: t.teal.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: t.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg.text,
                  style: TextStyle(color: t.teal, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final isUser = msg.sender == MsgSender.user;
    final time = DateFormat('HH:mm').format(msg.sentAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            GradientAvatar(
              initials: 'А',
              gradient: gradient,
              size: 28,
              radius: 999,
              fontSize: 12,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? t.blue : t.glassBgUp,
                border: isUser ? null : Border.all(color: t.glassBorder),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : t.text,
                        fontSize: 14.5,
                        height: 1.4,
                      )),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white.withValues(alpha: 0.65)
                                : t.textTer,
                            fontSize: 10,
                          )),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead
                              ? Icons.done_all_rounded
                              : Icons.check_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final List<Color> gradient;
  const _TypingBubble({required this.gradient});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GradientAvatar(
            initials: 'А',
            gradient: gradient,
            size: 28,
            radius: 999,
            fontSize: 12,
          ),
          const SizedBox(width: 6),
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
        decoration: BoxDecoration(color: t.blue, shape: BoxShape.circle),
      ),
    );
  }
}

class _ContactWarn extends StatelessWidget {
  final String text;
  const _ContactWarn({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.danger.withValues(alpha: 0.12),
        border: Border.all(color: t.danger.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: t.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(color: t.danger, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;
  final bool disabled;
  const _Composer({
    required this.controller,
    required this.hint,
    required this.onSend,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Container(
      decoration: BoxDecoration(
        color: t.surface.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: t.divider)),
      ),
      padding: EdgeInsets.fromLTRB(
        10, 8, 10, 8 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.add_circle_outline_rounded,
                color: t.textSec, size: 24),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              style: TextStyle(color: t.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: t.textTer, fontSize: 13.5),
                filled: true,
                fillColor: t.glassBgUp,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: t.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: t.blue, width: 1.4),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: disabled ? t.textTer : t.blue,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: disabled ? null : onSend,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
