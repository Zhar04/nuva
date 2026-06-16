import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/backend_auth.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';

/// Email + password sign-in / registration against the Nuva backend (JWT).
/// Non-blocking: "Продолжить без аккаунта" keeps the app usable.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialRegister = false});

  /// Start in registration mode (from onboarding) vs login mode (existing user).
  final bool initialRegister;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  late bool _register = widget.initialRegister;
  bool _busy = false;
  bool _navigating = false; // suppress the auto-redirect during a submit

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
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
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      _snack('Введите email и пароль', error: true);
      return;
    }
    _navigating = true;
    setState(() => _busy = true);
    final auth = ref.read(backendAuthProvider.notifier);
    // Role was chosen on /role before landing here; register with it so the
    // backend account has the correct role (psychologist → cabinet, not seeker).
    final role = ref.read(userProfileProvider).role;
    try {
      if (_register) {
        await auth.register(
            email: email,
            password: password,
            name: _name.text.trim(),
            role: role.storage);
        _snack('Аккаунт создан');
        if (mounted) {
          context.go(role == UserRole.psychologist
              ? '/onboarding/specialist'
              : '/onboarding/user');
        }
      } else {
        await auth.login(email: email, password: password);
        _snack('С возвращением!');
        if (mounted) context.go('/home');
      }
    } on ApiException catch (e) {
      _navigating = false;
      _snack(e.message, error: true);
    } catch (_) {
      _navigating = false;
      _snack('Нет связи с сервером. Бэкенд запущен?', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final authState = ref.watch(backendAuthProvider);

    // While restoring a saved session, show a loader (no login-form flash).
    if (authState.restoring) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    // Returning user who arrived already signed in → straight to the app.
    // Suppressed during a submit so register can route to onboarding (/role).
    if (authState.isSignedIn && !_navigating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
    }

    InputDecoration deco(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.textTer),
          prefixIcon: Icon(icon, color: t.textSec, size: 20),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: t.text, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [t.blue, t.teal]),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: Colors.white, size: 34),
                  ),
                ),
                const SizedBox(height: 20),
                Text(_register ? 'Создать аккаунт' : 'Вход в Nuva',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    )),
                const SizedBox(height: 8),
                Text(
                  _register
                      ? 'Email и пароль — этого достаточно для начала.'
                      : 'Войдите по email и паролю.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.textSec, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 26),
                if (_register) ...[
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: t.text, fontSize: 15),
                    decoration: deco('Имя или псевдоним', Icons.person_outline),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: TextStyle(color: t.text, fontSize: 15),
                  decoration: deco('Email', Icons.alternate_email_rounded),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  style: TextStyle(color: t.text, fontSize: 15),
                  onSubmitted: (_) => _busy ? null : _submit(),
                  decoration: deco('Пароль (мин. 8 символов)',
                      Icons.lock_outline_rounded),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: _register ? 'Зарегистрироваться' : 'Войти',
                  onPressed: _busy ? null : _submit,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _register = !_register),
                  child: Text(
                    _register
                        ? 'Уже есть аккаунт? Войти'
                        : 'Нет аккаунта? Зарегистрироваться',
                    style: TextStyle(
                        color: t.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
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
