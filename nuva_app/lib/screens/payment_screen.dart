import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/booking.dart';
import '../services/api_client.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';

enum PayMethod { card, kaspi, apple, google }

/// Pays a session the psychologist has already CONFIRMED (status
/// `pending_payment`). Reached from the client's "Запрос подтверждён — ждёт
/// оплаты" surface. The acquirer is still mocked; the real action is the
/// `bookings/{id}/pay` transition.
class PaymentScreen extends ConsumerStatefulWidget {
  final AppBooking booking;
  const PaymentScreen({super.key, required this.booking});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PayMethod _method = PayMethod.kaspi;
  bool _processing = false;
  bool _done = false;

  Future<void> _pay() async {
    setState(() => _processing = true);
    try {
      await ref.read(psyActionsProvider).pay(widget.booking.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      final msg =
          e is ApiException ? 'Ошибка ${e.status}: ${e.message}' : 'Сеть: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: context.nuva.danger,
        duration: const Duration(seconds: 6),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ));
      return;
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _processing = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;
    final b = widget.booking;
    final total = b.priceKzt + b.serviceFeeKzt;
    final priceLabel = NumberFormat.currency(
      locale: 'ru_KZ',
      symbol: '₸',
      decimalDigits: 0,
    ).format(total);

    if (_done) return _PaidView(booking: b);

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
                      _OrderSummary(booking: b),
                      const SizedBox(height: 22),
                      SectionLabel(label: s.paymentMethod),
                      _MethodTile(
                        title: s.payWithKaspi,
                        subtitle:
                            'Kaspi Gold · ${_method == PayMethod.kaspi ? "•••• 4128" : ""}',
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
                      if (_method == PayMethod.card) const _CardRedirectNote(),
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
        // For card, the action is a redirect to the acquirer's hosted page, so
        // the label reflects that rather than "pay" inside the app.
        label: _method == PayMethod.card
            ? '${s.continueToPayment} · $priceLabel'
            : '${s.pay} · $priceLabel',
        processing: _processing,
        onTap: _pay,
      ),
    );
  }
}

/// Success view shown in place after the pay transition lands.
class _PaidView extends StatelessWidget {
  final AppBooking booking;
  const _PaidView({required this.booking});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final when =
        DateFormat('d MMMM · HH:mm', 'ru').format(booking.startsAt);
    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
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
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 56),
                ),
                const SizedBox(height: 22),
                Text('Оплачено',
                    style: TextStyle(
                      color: t.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    )),
                const SizedBox(height: 8),
                Text(
                  'Сессия с ${booking.specialistName} закреплена за вами — '
                  '$when. Откройте её из записей или чата.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.textSec, fontSize: 14, height: 1.5),
                ),
                const Spacer(),
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
                    child: const Text('На главную'),
                  ),
                ),
              ],
            ),
          ),
        ),
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
  final AppBooking booking;
  const _OrderSummary({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    final fmt = NumberFormat.currency(
        locale: 'ru_KZ', symbol: '₸', decimalDigits: 0);
    final dateLabel =
        DateFormat('d MMMM, EEEE', 'ru').format(booking.startsAt);

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
                initials: booking.specialistInitials.isNotEmpty
                    ? booking.specialistInitials
                    : 'П',
                gradient: booking.gradient,
                size: 44,
                radius: 12,
                fontSize: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.specialistName,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        )),
                    Text('Подтверждено · ждёт оплаты',
                        style: TextStyle(color: t.teal, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: t.divider),
          const SizedBox(height: 10),
          row(s.pickDate, dateLabel),
          row(s.pickTime, DateFormat('HH:mm').format(booking.startsAt)),
          row(s.format, booking.formatLabel),
          row(s.sessionPrice, fmt.format(booking.priceKzt)),
          row(s.serviceFee, fmt.format(booking.serviceFeeKzt)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(height: 1, color: t.divider),
          ),
          row(s.total, fmt.format(booking.priceKzt + booking.serviceFeeKzt),
              bold: true),
        ],
      ),
    );
  }
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

/// Replaces the old in-app PAN/CVV form. Card entry is delegated to the
/// acquirer's hosted page (CloudPayments / ePay widget or an Apple/Google Pay
/// token), so the card number and CVV never touch the app — that keeps Nuva out
/// of PCI-DSS scope. The actual redirect is wired when the acquirer is
/// integrated; today the "Оплатить" bar still drives the real
/// `bookings/{id}/pay` transition (mock acquirer).
class _CardRedirectNote extends ConsumerWidget {
  const _CardRedirectNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.shield_outlined, color: t.teal, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.cardRedirectTitle,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.cardRedirectBody,
                    style: TextStyle(
                      color: t.textSec,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
