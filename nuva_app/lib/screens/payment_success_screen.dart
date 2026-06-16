import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';
import 'booking_screen.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final BookingDraft draft;

  /// True when this confirms a *request* was sent (booking → request →
  /// confirmation flow) rather than a completed payment.
  final bool requested;
  const PaymentSuccessScreen(
      {super.key, required this.draft, this.requested = false});

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _addToCalendar() async {
    final d = widget.draft;
    final start = DateTime.parse('${d.dateIso}T${d.time}:00');
    final end = start.add(const Duration(minutes: 50));
    String f(DateTime x) => DateFormat("yyyyMMdd'T'HHmmss").format(x);
    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent('Сессия с ${d.specialist.fullName} · Nuva')}'
      '&dates=${f(start)}/${f(end)}'
      '&details=${Uri.encodeComponent('Сессия в приложении Nuva.')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть календарь')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;
    final d = widget.draft;
    final dateLabel =
        DateFormat('d MMMM, EEEE', 'ru').format(DateTime.parse(d.dateIso));

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _c,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [t.teal, t.blue]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: t.teal.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.check_rounded, color: Colors.white, size: 56),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.requested ? 'Запрос отправлен' : s.bookingConfirmed,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.requested
                      ? 'Психолог рассмотрит заявку и подтвердит время. '
                          'Когда подтвердит — увидите её в записях'
                          '${widget.draft.intent == 'intro' ? '' : ' и сможете оплатить'}.'
                      : s.successSub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.textSec,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                GlassCard(
                  elevated: true,
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GradientAvatar(
                            initials: d.specialist.initials,
                            gradient: d.specialist.avatarGradient,
                            size: 44,
                            radius: 12,
                            fontSize: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.specialist.fullName,
                                    style: TextStyle(
                                      color: t.text,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    )),
                                Text(d.specialist.title,
                                    style: TextStyle(
                                        color: t.textSec, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(height: 1, color: t.divider),
                      const SizedBox(height: 12),
                      _kv(Icons.calendar_today_rounded, dateLabel, t),
                      const SizedBox(height: 8),
                      _kv(Icons.schedule_rounded,
                          '${d.time} · ${s.duration50}', t),
                      const SizedBox(height: 8),
                      _kv(
                        switch (d.format) {
                          SessionFormat.video => Icons.videocam_rounded,
                          SessionFormat.audio => Icons.headset_mic_rounded,
                          SessionFormat.chat => Icons.chat_bubble_rounded,
                        },
                        switch (d.format) {
                          SessionFormat.video => s.video,
                          SessionFormat.audio => s.audio,
                          SessionFormat.chat => s.chat,
                        },
                        t,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!widget.requested) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _addToCalendar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.glassBgUp,
                        foregroundColor: t.text,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: t.glassBorder),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              color: t.text, size: 18),
                          const SizedBox(width: 8),
                          Text(s.addToCalendar,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(s.backHome),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(IconData icon, String text, t) {
    return Row(
      children: [
        Icon(icon, size: 16, color: t.textSec),
        const SizedBox(width: 10),
        Text(text,
            style: TextStyle(
              color: t.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}
