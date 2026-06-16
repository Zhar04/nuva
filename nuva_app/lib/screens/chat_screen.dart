import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/chat.dart';
import '../services/api_client.dart';
import '../services/backend_auth.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

// Mirrors the server-side CONTACT_RE: phone numbers, URLs, @handles and the
// common contact / external-call services. Keeps communication on-platform.
final _contactRe = RegExp(
  r'(\+?\d[\d\s().\-]{7,}\d)'
  r'|(https?://)|(www\.)'
  r'|(@[\w.]{2,})'
  r'|(t\.me|wa\.me|zoom\.us|zoom|meet\.google|g\.co/|instagram|instagr'
  r'|whatsapp|telegram|viber|skype|facebook|fb\.com|vk\.com|youtu'
  r'|телеграм|вотсап|ватсап|инстаграм|вайбер|скайп|вконтакте)',
  caseSensitive: false,
  unicode: true,
);

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId; // conversation id
  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _State();
}

class _State extends ConsumerState<ChatScreen> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  bool _showContactWarning = false;
  bool _sending = false;
  bool _markedRead = false;
  int _lastCount = 0;

  /// Locally-appended messages awaiting the server refetch (optimistic UI).
  final List<ApiMessage> _optimistic = [];

  /// Polls the thread for new messages / call state while it's open — a
  /// lightweight stand-in for realtime (no websockets on this backend).
  Timer? _poll;

  int get _convoId => int.tryParse(widget.chatId) ?? -1;

  /// The conversation this screen shows, if loaded (for viewer-aware sending).
  ApiConversation? _currentConvo() {
    final convos =
        ref.read(conversationsProvider).valueOrNull ?? const <ApiConversation>[];
    for (final c in convos) {
      if (c.id == _convoId) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _input.addListener(_check);
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      ref.invalidate(messagesProvider(_convoId));
      ref.invalidate(conversationsProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _check() {
    final has = _contactRe.hasMatch(_input.text);
    if (has != _showContactWarning) {
      setState(() => _showContactWarning = has);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (_contactRe.hasMatch(text)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: context.nuva.danger,
        content: Text(S.of(ref).contactWarning,
            style: const TextStyle(color: Colors.white)),
      ));
      return;
    }
    // The bubble side is derived from the sender, so the optimistic message
    // must carry the *viewer's* sender — otherwise the psychologist's own
    // message renders on the client's side until the server echo arrives.
    final mine = (_currentConvo()?.viewerIsSpecialist ?? false)
        ? MsgSender.specialist
        : MsgSender.user;
    final optimistic = ApiMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      sender: mine,
      text: text,
      isRead: false,
      sentAt: DateTime.now(),
    );
    setState(() {
      _optimistic.add(optimistic);
      _input.clear();
      _sending = true;
    });
    _toEnd();
    try {
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      await ref.read(apiClientProvider).post(
        'chat/conversations/$_convoId/messages/',
        {'text': text},
        token: token,
      );
      ref.invalidate(messagesProvider(_convoId));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      _optimistic.remove(optimistic);
      if (mounted) {
        final msg = e is ApiException ? e.message : 'Не удалось отправить';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: context.nuva.danger,
          content: Text(msg, style: const TextStyle(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _callAction(String action) async {
    try {
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      await ref.read(apiClientProvider).post(
        'chat/conversations/$_convoId/call/',
        {'action': action},
        token: token,
      );
      ref.invalidate(conversationsProvider);
      ref.invalidate(messagesProvider(_convoId));
    } catch (_) {}
  }

  void _onVideo(ApiConversation? convo) {
    if (convo == null) {
      context.push('/call/conv$_convoId');
      return;
    }
    if (convo.callAccepted) {
      context.push('/call/conv$_convoId');
    } else if (convo.viewerIsSpecialist) {
      _callAction('accept'); // specialist agrees → both can join
    } else {
      _callAction('request'); // client asks for a call
    }
  }

  void _toEnd({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent + 240;
      if (jump) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(target,
            duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);

    final convos = ref.watch(conversationsProvider).valueOrNull ??
        const <ApiConversation>[];
    ApiConversation? found;
    for (final c in convos) {
      if (c.id == _convoId) {
        found = c;
        break;
      }
    }
    final convo = found; // final -> promotable inside closures
    final messagesAsync = ref.watch(messagesProvider(_convoId));
    final server = messagesAsync.valueOrNull ?? const <ApiMessage>[];

    // Merge server + still-pending optimistic messages (drop ones the server
    // has now echoed back, matched by the same sender + text).
    final pending = _optimistic
        .where((o) =>
            !server.any((m) => m.sender == o.sender && m.text == o.text))
        .toList();
    final messages = [...server, ...pending];

    // Opening the thread marks specialist messages read on the server; refresh
    // the list once so the unread badge clears.
    if (!_markedRead && messagesAsync.hasValue) {
      _markedRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(conversationsProvider);
      });
    }
    if (messages.length != _lastCount) {
      _lastCount = messages.length;
      _toEnd(jump: true);
    }

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                name: convo?.otherName ?? 'Чат',
                subtitle: convo == null
                    ? ''
                    : (convo.viewerIsSpecialist ? 'Клиент' : convo.title),
                initials: convo?.otherInitials ?? '·',
                gradient: convo?.gradient ??
                    const [Color(0xFF7FB7E8), Color(0xFFA3D8F4)],
                onVideo: () => _onVideo(convo),
              ),
              Expanded(
                child: messagesAsync.isLoading && server.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final m = messages[i];
                          final prev = i > 0 ? messages[i - 1] : null;
                          final showDate = prev == null ||
                              prev.sentAt.day != m.sentAt.day ||
                              prev.sentAt.month != m.sentAt.month;
                          return Column(
                            children: [
                              if (showDate) _DateChip(date: m.sentAt),
                              _MessageBubble(
                                  msg: m,
                                  viewerIsSpecialist:
                                      convo?.viewerIsSpecialist ?? false,
                                  gradient: convo?.gradient ??
                                      const [
                                        Color(0xFF7FB7E8),
                                        Color(0xFFA3D8F4)
                                      ]),
                            ],
                          );
                        },
                      ),
              ),
              if (convo != null &&
                  (convo.callRequested || convo.callAccepted))
                _CallBar(
                  convo: convo,
                  onJoin: () => context.push('/call/conv$_convoId'),
                  onAccept: () => _callAction('accept'),
                  onCancel: () => _callAction('end'),
                ),
              if (_showContactWarning) _ContactWarn(text: s.contactWarning),
              _Composer(
                controller: _input,
                hint: s.messagePlaceholder,
                onSend: _send,
                disabled: _showContactWarning || _sending,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final String name;
  final String subtitle;
  final String initials;
  final List<Color> gradient;
  final VoidCallback? onVideo;
  const _Header({
    required this.name,
    required this.subtitle,
    required this.initials,
    required this.gradient,
    this.onVideo,
  });

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
            initials: initials,
            gradient: gradient,
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
                      child: Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, color: t.blue, size: 12),
                  ],
                ),
                Text(
                  subtitle.isEmpty ? s.psychologist : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textSec, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onVideo,
            icon: Icon(Icons.videocam_outlined, color: t.text, size: 22),
          ),
        ],
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
  final ApiMessage msg;
  final List<Color> gradient;
  final bool viewerIsSpecialist;
  const _MessageBubble({
    required this.msg,
    required this.gradient,
    this.viewerIsSpecialist = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: Text(msg.text,
                    style: TextStyle(color: t.teal, fontSize: 12, height: 1.4)),
              ),
            ],
          ),
        ),
      );
    }
    // "Mine" (right, blue) depends on the viewer: the specialist's own messages
    // are sender=specialist; the client's own are sender=user.
    final isUser = viewerIsSpecialist
        ? msg.sender == MsgSender.specialist
        : msg.sender == MsgSender.user;
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
                  Text(time,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.65)
                            : t.textTer,
                        fontSize: 10,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallBar extends StatelessWidget {
  final ApiConversation convo;
  final VoidCallback onJoin;
  final VoidCallback onAccept;
  final VoidCallback onCancel;
  const _CallBar({
    required this.convo,
    required this.onJoin,
    required this.onAccept,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final accepted = convo.callAccepted;
    final isSpec = convo.viewerIsSpecialist;
    final String text;
    final Widget action;
    if (accepted) {
      text = 'Звонок принят';
      action = _btn(t.teal, Colors.white, 'Войти', onJoin);
    } else if (isSpec) {
      text = 'Клиент запросил видеозвонок';
      action = _btn(t.blue, Colors.white, 'Принять', onAccept);
    } else {
      text = 'Ожидаем психолога…';
      action = _btn(t.glassBgUp, t.textSec, 'Отменить', onCancel);
    }
    final accent = accepted ? t.teal : t.blue;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.videocam_rounded, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: t.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          action,
        ],
      ),
    );
  }

  Widget _btn(Color bg, Color fg, String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(0, 36),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
