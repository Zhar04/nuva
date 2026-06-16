import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_profile.dart';
import '../services/backend_auth.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';
import '../widgets/onboarding_kit.dart';
import '../widgets/user_avatar.dart';

/// "Ищу поддержку" onboarding: basics → MBTI → 4 calm intro questions →
/// hands off to the AI module (/intake, which has /skip). Prototype: local state.
class OnboardingUserScreen extends ConsumerStatefulWidget {
  const OnboardingUserScreen({super.key});

  @override
  ConsumerState<OnboardingUserScreen> createState() => _State();
}

class _State extends ConsumerState<OnboardingUserScreen> {
  int _step = 0;
  final _name = TextEditingController();
  final _age = TextEditingController();
  String? _gender;
  String? _mbti;
  String _avatar = '';
  bool _uploading = false;
  final Map<int, String> _answers = {};

  Future<void> _pickAvatar() async {
    if (_uploading) return;
    final url = await pickImageDataUrl();
    if (url == null) return;
    setState(() {
      _avatar = url;
      _uploading = true;
    });
    try {
      await ref.read(backendAuthProvider.notifier).updateProfile(avatar: url);
    } catch (_) {
      /* keep the local preview even if the upload fails */
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  static const _titles = [
    'Расскажите о себе',
    'Ваш тип личности',
    'Что вас привело?',
    'Как часто это беспокоит?',
    'Удобный формат',
    'Опыт терапии',
  ];

  static const _questions = {
    2: ['Тревога и стресс', 'Отношения', 'Выгорание', 'Утрата', 'Самооценка', 'Пока сложно сказать'],
    3: ['Почти каждый день', 'Несколько раз в неделю', 'Время от времени'],
    4: ['Видео-сессии', 'Аудио', 'Переписка', 'Пока не знаю'],
    5: ['Да, был полезен', 'Да, но не очень', 'Нет, впервые'],
  };

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  bool get _canNext {
    if (_step == 0) return _name.text.trim().isNotEmpty;
    if (_step >= 2 && _step <= 5) return _answers[_step] != null;
    return true; // MBTI step optional
  }

  void _next() {
    if (_step < _titles.length - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step == 0) {
      context.go('/role');
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _finish() async {
    await ref.read(userProfileProvider.notifier).update(
          name: _name.text.trim(),
          age: int.tryParse(_age.text.trim()),
          gender: _gender,
          mbti: _mbti,
          onboarded: true,
        );
    if (mounted) context.go('/intake');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _back,
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: t.text, size: 18),
                    ),
                    Expanded(child: StepDots(count: _titles.length, active: _step)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_titles[_step],
                          style: TextStyle(
                            color: t.text,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          )),
                      const SizedBox(height: 18),
                      _stepBody(t),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 4, 24, 12 + MediaQuery.viewPaddingOf(context).bottom),
                child: PrimaryButton(
                  label: _step == _titles.length - 1 ? 'Готово' : 'Далее',
                  onPressed: _canNext ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody(t) {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pickAvatar,
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    children: [
                      UserAvatar(
                        avatar: _avatar,
                        initials: _name.text.trim().isEmpty
                            ? 'А'
                            : _name.text.trim().characters.first.toUpperCase(),
                        gradient: [t.blue, t.teal],
                        size: 96,
                        radius: 999,
                        fontSize: 34,
                      ),
                      if (_uploading)
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: Colors.black54),
                            child: Center(
                              child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4, color: Colors.white)),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: t.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: t.surface, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            OnboardField(
              label: 'Как к вам обращаться',
              hint: 'Имя или псевдоним',
              controller: _name,
            ),
            const SizedBox(height: 14),
            OnboardField(
              label: 'Возраст (необязательно)',
              hint: 'Например, 27',
              controller: _age,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text('Пол (необязательно)',
                style: TextStyle(
                    color: t.textSec,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SingleSelect(
              options: genderOptions,
              value: _gender,
              onChanged: (v) => setState(() => _gender = v),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Помогает психологу понять, как вам комфортнее. Можно пропустить.',
                style: TextStyle(color: t.textSec, fontSize: 13, height: 1.4)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: mbtiTypes.map((m) {
                final sel = m == _mbti;
                return GestureDetector(
                  onTap: () => setState(() => _mbti = sel ? null : m),
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? t.blue : t.glassBgUp,
                      border: Border.all(
                          color: sel ? t.blue : t.glassBorder,
                          width: sel ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(m,
                        style: TextStyle(
                          color: sel ? Colors.white : t.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.teal.withValues(alpha: 0.1),
                border: Border.all(color: t.teal.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: t.teal, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Не уверены в типе? Позже в профиле можно пройти более точный тест (16Personalities).',
                      style: TextStyle(color: t.teal, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return SingleSelect(
          options: _questions[_step]!,
          value: _answers[_step],
          onChanged: (v) => setState(() => _answers[_step] = v),
        );
    }
  }
}
