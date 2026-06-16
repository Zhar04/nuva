import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/specialist.dart';
import '../services/api_client.dart';
import '../services/backend_auth.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

enum SessionFormat { video, audio, chat }

/// Default concern tags offered when a specialist hasn't listed their own.
const _defaultConcerns = [
  'Тревога', 'Отношения', 'Стресс', 'Самооценка', 'Выгорание', 'Утрата',
];

class BookingScreen extends ConsumerStatefulWidget {
  final String specialistId;
  const BookingScreen({super.key, required this.specialistId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _dateIndex = 0;
  String? _slot;
  SessionFormat _format = SessionFormat.video;
  String _intent = 'intro'; // intro | package
  String? _concern;
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  /// Lightweight, deterministic "% совпадения" sent with the request so the
  /// psychologist sees a match hint. Higher when the concern is one the
  /// specialist explicitly works with.
  int _matchScore(Specialist sp) {
    final base = sp.worksWith.contains(_concern) ? 90 : 76;
    final h = (sp.id.hashCode ^ (_concern?.hashCode ?? 0)).abs() % 8;
    return (base + h).clamp(40, 99);
  }

  Future<void> _sendRequest(Specialist sp, DateTime date) async {
    if (_slot == null || _concern == null || _sending) return;
    setState(() => _sending = true);
    final dateIso = DateFormat('yyyy-MM-dd').format(date);
    final isIntro = _intent == 'intro';
    try {
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      await ref.read(apiClientProvider).post(
        'bookings/',
        {
          'specialist': int.tryParse(sp.id),
          'starts_at': '${dateIso}T$_slot:00',
          'format': _format.name,
          'intent': _intent,
          'is_intro': isIntro,
          'concern': _concern,
          'client_message': _message.text.trim(),
          'price_kzt': isIntro ? 0 : sp.sessionPriceKzt,
          'match_score': _matchScore(sp),
        },
        token: token,
      );
      ref.invalidate(bookingsProvider);
      if (!mounted) return;
      context.go(
        '/payment-success?requested=1',
        extra: BookingDraft(
          specialist: sp,
          dateIso: dateIso,
          time: _slot!,
          format: _format,
          intent: _intent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      final msg = e is ApiException
          ? 'Ошибка ${e.status}: ${e.message}'
          : token == null
              ? 'Нет входа в аккаунт. Войдите заново.'
              : 'Сеть/CORS: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: context.nuva.danger,
        duration: const Duration(seconds: 6),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final list =
        ref.watch(specialistsProvider).valueOrNull ?? specialistCatalog;
    final sp = list.firstWhere(
      (e) => e.id == widget.specialistId,
      orElse: () {
        try {
          return specialistCatalog.byId(widget.specialistId);
        } catch (_) {
          return list.isNotEmpty ? list.first : specialistCatalog.first;
        }
      },
    );
    final now = DateTime.now();
    final dates = List.generate(14, (i) => now.add(Duration(days: i + 1)));
    final concerns = sp.worksWith.isNotEmpty ? sp.worksWith : _defaultConcerns;
    final isIntro = _intent == 'intro';

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _Header(title: 'Заявка на сессию'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 170),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SpecialistStrip(sp: sp),
                      const SizedBox(height: 22),
                      SectionLabel(label: 'Тип сессии'),
                      _IntentSelector(
                        value: _intent,
                        priceKzt: sp.sessionPriceKzt,
                        onChanged: (v) => setState(() => _intent = v),
                      ),
                      const SizedBox(height: 22),
                      SectionLabel(label: 'Что беспокоит'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: concerns.map((c) {
                          final on = _concern == c;
                          return _ChoiceChip(
                            label: c,
                            selected: on,
                            onTap: () => setState(() => _concern = c),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      SectionLabel(label: s.format),
                      _FormatSelector(
                        value: _format,
                        onChanged: (v) => setState(() => _format = v),
                      ),
                      const SizedBox(height: 22),
                      SectionLabel(label: s.pickDate),
                      SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: dates.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final d = dates[i];
                            final selected = i == _dateIndex;
                            return _DateChip(
                              date: d,
                              selected: selected,
                              onTap: () => setState(() {
                                _dateIndex = i;
                                _slot = null;
                              }),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      SectionLabel(label: s.pickTime),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: sp.availableSlots.map((slot) {
                          final selected = _slot == slot;
                          return _SlotChip(
                            label: slot,
                            selected: selected,
                            onTap: () => setState(() => _slot = slot),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      SectionLabel(label: 'Сообщение психологу · необязательно'),
                      _MessageField(controller: _message),
                      const SizedBox(height: 22),
                      _Summary(sp: sp, format: _format, isIntro: isIntro),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _RequestBar(
        enabled: _slot != null && _concern != null && !_sending,
        sending: _sending,
        priceLabel: isIntro
            ? 'Бесплатно'
            : NumberFormat.currency(
                locale: 'ru_KZ', symbol: '₸', decimalDigits: 0,
              ).format(sp.sessionPriceKzt + 1000),
        onTap: () => _sendRequest(sp, dates[_dateIndex]),
      ),
    );
  }
}

class BookingDraft {
  final Specialist specialist;
  final String dateIso;
  final String time;
  final SessionFormat format;
  final String intent;
  const BookingDraft({
    required this.specialist,
    required this.dateIso,
    required this.time,
    required this.format,
    this.intent = 'intro',
  });
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: t.text, size: 18),
          ),
          Text(
            title,
            style: TextStyle(
              color: t.text,
              fontSize: 19,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialistStrip extends StatelessWidget {
  final Specialist sp;
  const _SpecialistStrip({required this.sp});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      elevated: true,
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          GradientAvatar(
            initials: sp.initials,
            gradient: sp.avatarGradient,
            size: 48,
            radius: 14,
            fontSize: 17,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sp.fullName,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    )),
                Text(sp.title,
                    style: TextStyle(color: t.textSec, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.star_rounded, color: t.teal, size: 16),
              const SizedBox(width: 2),
              Text('${sp.rating}',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

/// Intro (free) vs paid package — drives whether payment happens later.
class _IntentSelector extends StatelessWidget {
  final String value;
  final int priceKzt;
  final ValueChanged<String> onChanged;
  const _IntentSelector(
      {required this.value, required this.priceKzt, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _IntentTile(
          icon: Icons.volunteer_activism_rounded,
          title: 'Ознакомительная сессия',
          sub: 'Бесплатно · знакомство 20–30 мин',
          selected: value == 'intro',
          onTap: () => onChanged('intro'),
        ),
        const SizedBox(height: 10),
        _IntentTile(
          icon: Icons.workspace_premium_rounded,
          title: 'Полная сессия / пакет',
          sub: '${NumberFormat.currency(locale: 'ru_KZ', symbol: '₸', decimalDigits: 0).format(priceKzt)} · 50 минут',
          selected: value == 'package',
          onTap: () => onChanged('package'),
        ),
      ],
    );
  }
}

class _IntentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  const _IntentTile({
    required this.icon,
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? t.blue.withValues(alpha: 0.14) : t.glassBgUp,
          border: Border.all(
            color: selected ? t.blue : t.glassBorder,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? t.blue : t.glassBgUp,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : t.textSec, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: t.text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(sub,
                      style: TextStyle(color: t.textSec, fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? t.blue : Colors.transparent,
                border: Border.all(
                  color: selected ? t.blue : t.textTer,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? t.blue : t.glassBgUp,
          border: Border.all(color: selected ? t.blue : t.glassBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : t.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MessageField extends StatelessWidget {
  final TextEditingController controller;
  const _MessageField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: 3,
        minLines: 2,
        style: TextStyle(color: t.text, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Коротко опишите, с чем хотите поработать…',
          hintStyle: TextStyle(color: t.textTer, fontSize: 13.5),
        ),
      ),
    );
  }
}

class _FormatSelector extends ConsumerWidget {
  final SessionFormat value;
  final ValueChanged<SessionFormat> onChanged;
  const _FormatSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    Widget item(SessionFormat f, IconData icon, String label) {
      return Expanded(
        child: _FormatTile(
          icon: icon,
          label: label,
          selected: value == f,
          onTap: () => onChanged(f),
        ),
      );
    }

    return Row(
      children: [
        item(SessionFormat.video, Icons.videocam_rounded, s.video),
        const SizedBox(width: 10),
        item(SessionFormat.audio, Icons.headset_mic_rounded, s.audio),
        const SizedBox(width: 10),
        item(SessionFormat.chat, Icons.chat_bubble_rounded, s.chat),
      ],
    );
  }
}

class _FormatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FormatTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? t.blue.withValues(alpha: 0.18) : t.glassBgUp,
          border: Border.all(
            color: selected ? t.blue : t.glassBorder,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? t.blue : t.text, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? t.blue : t.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  static const _dayNames = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
  static const _monthNames = [
    'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        decoration: BoxDecoration(
          color: selected ? t.blue : t.glassBgUp,
          border: Border.all(color: selected ? t.blue : t.glassBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _dayNames[(date.weekday - 1) % 7],
              style: TextStyle(
                color: selected ? Colors.white.withValues(alpha: 0.8) : t.textSec,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? Colors.white : t.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _monthNames[date.month - 1],
              style: TextStyle(
                color: selected ? Colors.white.withValues(alpha: 0.7) : t.textTer,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? t.blue : t.glassBgUp,
          border: Border.all(color: selected ? t.blue : t.glassBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : t.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  final Specialist sp;
  final SessionFormat format;
  final bool isIntro;
  const _Summary(
      {required this.sp, required this.format, required this.isIntro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    final fmt = NumberFormat.currency(
        locale: 'ru_KZ', symbol: '₸', decimalDigits: 0);
    Widget row(String l, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(l,
                  style: TextStyle(
                    color: bold ? t.text : t.textSec,
                    fontSize: bold ? 15 : 13,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  )),
              const Spacer(),
              Text(v,
                  style: TextStyle(
                    color: t.text,
                    fontSize: bold ? 17 : 13,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        );

    return GlassCard(
      elevated: true,
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isIntro ? 'Ознакомительная сессия' : s.paymentSummary,
              style: TextStyle(
                color: t.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          if (isIntro)
            Text(
              'Это знакомство — бесплатно. Оплата не нужна. После подтверждения '
              'психологом сессия появится в ваших записях.',
              style: TextStyle(color: t.textSec, fontSize: 12.5, height: 1.45),
            )
          else ...[
            row('${s.sessionPrice} · ${s.duration50}',
                fmt.format(sp.sessionPriceKzt)),
            row(s.serviceFee, fmt.format(1000)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(height: 1, color: t.divider),
            ),
            row('К оплате после подтверждения',
                fmt.format(sp.sessionPriceKzt + 1000), bold: true),
          ],
        ],
      ),
    );
  }
}

/// Bottom bar — sends the request (no payment yet).
class _RequestBar extends StatelessWidget {
  final bool enabled;
  final bool sending;
  final String priceLabel;
  final VoidCallback onTap;
  const _RequestBar({
    required this.enabled,
    required this.sending,
    required this.priceLabel,
    required this.onTap,
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
        16, 12, 16, 12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? t.blue : t.textTer,
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
          child: sending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Отправить запрос'),
                    const SizedBox(width: 10),
                    Text('·  $priceLabel',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      ),
    );
  }
}
