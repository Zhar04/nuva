import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/strings.dart';
import '../services/api_client.dart';
import '../services/backend_auth.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../widgets/glass.dart';

InputDecoration _deco(NuvaTokens t, String hint, IconData icon) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: t.textTer),
      prefixIcon: Icon(icon, color: t.textSec, size: 20),
      filled: true,
      fillColor: t.glassBgUp,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: t.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: t.blue, width: 1.4),
      ),
    );

/// Step 1: ask for the email, fire `/auth/password/reset`. The response is the
/// same whether or not the account exists (no enumeration), so we always show a
/// neutral "check your email" confirmation.
class PasswordResetRequestScreen extends ConsumerStatefulWidget {
  const PasswordResetRequestScreen({super.key});

  @override
  ConsumerState<PasswordResetRequestScreen> createState() =>
      _RequestState();
}

class _RequestState extends ConsumerState<PasswordResetRequestScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .post('auth/password/reset', {'email': email});
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      // Even on a transport hiccup, show the neutral message — never reveal more.
      if (mounted) setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;
    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/auth'),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: t.text, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                Text(s.resetTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(_sent ? s.resetSent : s.resetRequestHint,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: t.textSec, fontSize: 14, height: 1.5)),
                const SizedBox(height: 24),
                if (!_sent) ...[
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: TextStyle(color: t.text, fontSize: 15),
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration:
                        _deco(t, 'Email', Icons.alternate_email_rounded),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: s.resetSend,
                    onPressed: _busy ? null : _submit,
                  ),
                ] else ...[
                  Icon(Icons.mark_email_read_rounded, color: t.teal, size: 56),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: s.haveAccount,
                    onPressed: () => context.go('/auth'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 2: opened from the email link (`/reset-password?uid=&token=`). Sets a
/// new password via `/auth/password/reset/confirm`.
class PasswordResetConfirmScreen extends ConsumerStatefulWidget {
  final String uid;
  final String token;
  const PasswordResetConfirmScreen(
      {super.key, required this.uid, required this.token});

  @override
  ConsumerState<PasswordResetConfirmScreen> createState() => _ConfirmState();
}

class _ConfirmState extends ConsumerState<PasswordResetConfirmScreen> {
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
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

  Future<void> _submit() async {
    final pw = _password.text;
    if (pw.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).post('auth/password/reset/confirm', {
        'uid': widget.uid,
        'token': widget.token,
        'password': pw,
      });
      _snack(S.of(ref).resetDone);
      if (mounted) context.go('/auth');
    } on ApiException catch (e) {
      // A bad/expired token comes back as a detail error; weak password as a
      // password field error.
      final detail = e.body['detail'];
      _snack(detail is String ? detail : e.message, error: true);
    } on NetworkException {
      _snack('Нет связи с сервером. Проверьте интернет.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;
    final badLink = widget.uid.isEmpty || widget.token.isEmpty;
    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(s.resetTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(badLink ? s.resetInvalidLink : s.resetNewPassword,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: t.textSec, fontSize: 14, height: 1.5)),
                const SizedBox(height: 24),
                if (badLink)
                  PrimaryButton(
                    label: s.forgotPassword,
                    onPressed: () => context.go('/auth/forgot'),
                  )
                else ...[
                  TextField(
                    controller: _password,
                    obscureText: true,
                    style: TextStyle(color: t.text, fontSize: 15),
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration: _deco(t, s.resetNewPassword,
                        Icons.lock_outline_rounded),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(s.pwHint,
                        style: TextStyle(
                            color: t.textTer, fontSize: 11.5, height: 1.4)),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: s.resetSave,
                    onPressed: _busy ? null : _submit,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
