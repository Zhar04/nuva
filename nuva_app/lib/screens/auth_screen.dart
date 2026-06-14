import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/strings.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';

/// Phone-OTP sign-in with an "enter anonymously" shortcut. Non-blocking: the
/// app is usable without it; this just attaches a real Supabase identity so
/// RLS-protected writes (posts, bookings, mood) work.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phone = TextEditingController(text: '+7');
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    final t = context.nuva;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? t.danger : t.teal,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
  }

  Future<void> _sendCode() async {
    final s = S.of(ref);
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).sendOtp(_phone.text.trim());
      if (!mounted) return;
      setState(() => _codeSent = true);
      _snack(s.otpSent);
    } catch (_) {
      _snack(s.authError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final s = S.of(ref);
    setState(() => _busy = true);
    try {
      final ok = await ref.read(authServiceProvider).verifyOtp(
            phoneE164: _phone.text.trim(),
            code: _code.text.trim(),
          );
      if (!mounted) return;
      if (ok) {
        context.go('/home');
      } else {
        _snack(s.authError, error: true);
      }
    } catch (_) {
      _snack(s.authError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _anon() async {
    final s = S.of(ref);
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signInAnonymously();
      if (!mounted) return;
      _snack(s.signedInAnon);
      context.go('/home');
    } catch (_) {
      _snack(s.authError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;

    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.textTer),
          filled: true,
          fillColor: t.glassBgUp,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: t.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: t.blue, width: 1.4),
          ),
        );

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: t.text, size: 18),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [t.blue, t.teal]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 20),
                Text(s.signInTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    )),
                const SizedBox(height: 8),
                Text(s.signInSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.textSec, fontSize: 14, height: 1.5)),
                const SizedBox(height: 28),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: t.text, fontSize: 16),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: deco(s.phoneNumber),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: t.text, fontSize: 16, letterSpacing: 4),
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: deco(s.smsCode),
                  ),
                ],
                const SizedBox(height: 18),
                PrimaryButton(
                  label: _codeSent ? s.verifyCode : s.sendCode,
                  onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _anon,
                  child: Text(s.continueAnon,
                      style: TextStyle(
                        color: t.textSec,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                ),
                const Spacer(),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
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
