import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';
import 'booking_screen.dart';

enum PayMethod { card, kaspi, apple, google }

class PaymentScreen extends ConsumerStatefulWidget {
  final BookingDraft draft;
  const PaymentScreen({super.key, required this.draft});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PayMethod _method = PayMethod.kaspi;
  bool _processing = false;

  // Card form
  final _card = TextEditingController();
  final _exp = TextEditingController();
  final _cvv = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _card.dispose();
    _exp.dispose();
    _cvv.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _processing = false);
    context.go('/payment-success', extra: widget.draft);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;
    final total = widget.draft.specialist.sessionPriceKzt + 1000;
    final priceLabel = NumberFormat.currency(
      locale: 'ru_KZ',
      symbol: '₸',
      decimalDigits: 0,
    ).format(total);

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _Header(title: s.payment),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OrderSummary(draft: widget.draft),
                      const SizedBox(height: 22),
                      SectionLabel(label: s.paymentMethod),
                      _MethodTile(
                        title: s.payWithKaspi,
                        subtitle: 'Kaspi Gold · ${_method == PayMethod.kaspi ? "•••• 4128" : ""}',
                        color: const Color(0xFFEF3124),
                        icon: Icons.account_balance_wallet_rounded,
                        selected: _method == PayMethod.kaspi,
                        badge: 'KZ',
                        onTap: () => setState(() => _method = PayMethod.kaspi),
                      ),
                      const SizedBox(height: 10),
                      _MethodTile(
                        title: s.payWithCard,
                        subtitle: 'Visa · Mastercard · Halyk',
                        color: t.blue,
                        icon: Icons.credit_card_rounded,
                        selected: _method == PayMethod.card,
                        onTap: () => setState(() => _method = PayMethod.card),
                      ),
                      if (_method == PayMethod.card) _CardForm(
                        card: _card,
                        exp: _exp,
                        cvv: _cvv,
                        name: _name,
                      ),
                      const SizedBox(height: 10),
                      _MethodTile(
                        title: s.payWithApple,
                        subtitle: 'Touch ID · Face ID',
                        color: Colors.black,
                        icon: Icons.apple_rounded,
                        selected: _method == PayMethod.apple,
                        onTap: () => setState(() => _method = PayMethod.apple),
                      ),
                      const SizedBox(height: 10),
                      _MethodTile(
                        title: s.payWithGoogle,
                        subtitle: 'Бесконтактная оплата',
                        color: const Color(0xFF4285F4),
                        icon: Icons.g_mobiledata_rounded,
                        selected: _method == PayMethod.google,
                        onTap: () => setState(() => _method = PayMethod.google),
                      ),
                      const SizedBox(height: 18),
                      _SecurityNote(text: s.securedBy),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _PayBar(
        label: '${s.pay} · $priceLabel',
        processing: _processing,
        onTap: _pay,
      ),
    );
  }
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

class _OrderSummary extends ConsumerWidget {
  final BookingDraft draft;
  const _OrderSummary({required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    final fmt = NumberFormat.currency(
        locale: 'ru_KZ', symbol: '₸', decimalDigits: 0);
    final dateLabel =
        DateFormat('d MMMM, EEEE', 'ru').format(DateTime.parse(draft.dateIso));

    Widget row(String l, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
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
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientAvatar(
                initials: draft.specialist.initials,
                gradient: draft.specialist.avatarGradient,
                size: 44,
                radius: 12,
                fontSize: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(draft.specialist.fullName,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(draft.specialist.title,
                        style: TextStyle(color: t.textSec, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: t.divider),
          const SizedBox(height: 10),
          row(s.pickDate, dateLabel),
          row(s.pickTime, draft.time),
          row(s.format, _formatLabel(draft.format, s)),
          row(s.sessionPrice, fmt.format(draft.specialist.sessionPriceKzt)),
          row(s.serviceFee, fmt.format(1000)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(height: 1, color: t.divider),
          ),
          row(s.total, fmt.format(draft.specialist.sessionPriceKzt + 1000),
              bold: true),
        ],
      ),
    );
  }

  String _formatLabel(SessionFormat f, S s) => switch (f) {
        SessionFormat.video => s.video,
        SessionFormat.audio => s.audio,
        SessionFormat.chat => s.chat,
      };
}

class _MethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;
  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
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
          color: t.glassBgUp,
          border: Border.all(
            color: selected ? t.blue : t.glassBorder,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          )),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: t.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(badge!,
                              style: TextStyle(
                                color: t.teal,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle,
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

class _CardForm extends ConsumerWidget {
  final TextEditingController card;
  final TextEditingController exp;
  final TextEditingController cvv;
  final TextEditingController name;
  const _CardForm({
    required this.card,
    required this.exp,
    required this.cvv,
    required this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    InputDecoration deco(String h) => InputDecoration(
          hintText: h,
          hintStyle: TextStyle(color: t.textTer, fontSize: 13.5),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.blue, width: 1.4),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: card,
              decoration: deco(s.cardNumber),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
                _CardNumberFormatter(),
              ],
              style: TextStyle(color: t.text, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: exp,
                    decoration: deco(s.expiry + ' · MM/YY'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryFormatter(),
                    ],
                    style: TextStyle(color: t.text, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: cvv,
                    decoration: deco(s.cvv),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: TextStyle(color: t.text, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: name,
              decoration: deco(s.holderName),
              style: TextStyle(color: t.text, fontSize: 14),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final out = buf.toString();
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll('/', '');
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 2) buf.write('/');
      buf.write(d[i]);
    }
    final out = buf.toString();
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  final String text;
  const _SecurityNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: t.teal),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: t.textSec, fontSize: 11.5, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _PayBar extends StatelessWidget {
  final String label;
  final bool processing;
  final VoidCallback onTap;
  const _PayBar({
    required this.label,
    required this.processing,
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
          onPressed: processing ? null : onTap,
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
          child: processing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}
