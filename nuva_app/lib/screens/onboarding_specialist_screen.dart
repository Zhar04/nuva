import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_profile.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';
import '../widgets/onboarding_kit.dart';

/// "Я психолог" onboarding — skips the AI module entirely. Collects photo,
/// basics, expertise, and documents (diploma/certs upload STUBBED in prototype).
/// Final step submits for moderation (mock) → /home.
class OnboardingSpecialistScreen extends ConsumerStatefulWidget {
  const OnboardingSpecialistScreen({super.key});

  @override
  ConsumerState<OnboardingSpecialistScreen> createState() => _State();
}

class _State extends ConsumerState<OnboardingSpecialistScreen> {
  int _step = 0;
  final _name = TextEditingController();
  final _exp = TextEditingController();
  bool _photoAttached = false;
  final Set<String> _expertise = {};
  final Map<String, bool> _docs = {
    'Диплом о психологическом образовании': false,
    'Сертификаты о повышении квалификации': false,
    'Трудовая книжка (необязательно)': false,
  };

  static const _titles = [
    'Профиль специалиста',
    'Ваша экспертиза',
    'Документы',
    'Готово к проверке',
  ];

  static const _areas = [
    'Тревога', 'Депрессия', 'Отношения', 'Семья и пары', 'Травма', 'ПТСР',
    'Утрата', 'Выгорание', 'Самооценка', 'Подростки', 'Зависимости', 'Кризис',
  ];

  @override
  void dispose() {
    _name.dispose();
    _exp.dispose();
    super.dispose();
  }

  bool get _canNext {
    switch (_step) {
      case 0:
        return _name.text.trim().isNotEmpty;
      case 1:
        return _expertise.isNotEmpty;
      case 2:
        return _docs['Диплом о психологическом образовании'] == true;
      default:
        return true;
    }
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
          role: UserRole.psychologist,
          name: _name.text.trim(),
          onboarded: true,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Заявка отправлена на проверку. Мы свяжемся с вами.')),
    );
    context.go('/auth?mode=register');
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
                    Expanded(
                        child: StepDots(count: _titles.length, active: _step)),
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
                  label: _step == _titles.length - 1
                      ? 'Отправить на проверку'
                      : 'Далее',
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
              child: AvatarPickerStub(
                initials: _name.text.trim().isEmpty
                    ? 'П'
                    : _name.text.trim().characters.first.toUpperCase(),
                gradient: const [Color(0xFF7E8BD9), Color(0xFFB39DDB)],
                onTap: () {
                  setState(() => _photoAttached = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Фото прикреплено (демо-загрузка)')),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _photoAttached ? 'Фото добавлено' : 'Фото обязательно',
                style: TextStyle(
                    color: _photoAttached ? t.teal : t.textTer, fontSize: 12),
              ),
            ),
            const SizedBox(height: 18),
            OnboardField(
              label: 'Имя и фамилия',
              hint: 'Как в дипломе',
              controller: _name,
            ),
            const SizedBox(height: 14),
            OnboardField(
              label: 'Стаж (лет)',
              hint: 'Например, 8',
              controller: _exp,
              keyboardType: TextInputType.number,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Выберите направления, с которыми работаете.',
                style: TextStyle(color: t.textSec, fontSize: 13)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _areas.map((a) {
                final sel = _expertise.contains(a);
                return GestureDetector(
                  onTap: () => setState(() =>
                      sel ? _expertise.remove(a) : _expertise.add(a)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? t.blue : t.glassBgUp,
                      border: Border.all(
                          color: sel ? t.blue : t.glassBorder,
                          width: sel ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(a,
                        style: TextStyle(
                          color: sel ? Colors.white : t.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Загрузите документы в PDF или PNG. Они видны только модерации Nuva.',
                style: TextStyle(color: t.textSec, fontSize: 13, height: 1.4)),
            const SizedBox(height: 16),
            ..._docs.keys.map((doc) {
              final attached = _docs[doc] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _docs[doc] = !attached);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.glassBgUp,
                      border: Border.all(
                          color: attached
                              ? t.teal.withValues(alpha: 0.6)
                              : t.glassBorder),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          attached
                              ? Icons.check_circle_rounded
                              : Icons.upload_file_rounded,
                          color: attached ? t.teal : t.blue,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(doc,
                              style: TextStyle(
                                color: t.text,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              )),
                        ),
                        Text(
                          attached ? 'Прикреплено' : 'Загрузить',
                          style: TextStyle(
                            color: attached ? t.teal : t.blue,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Text('Демо: загрузка файлов появится с подключением хранилища.',
                style: TextStyle(color: t.textTer, fontSize: 11.5)),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReviewRow(label: 'Имя', value: _name.text.trim()),
            _ReviewRow(
                label: 'Направления', value: _expertise.join(', ')),
            _ReviewRow(
                label: 'Документы',
                value:
                    '${_docs.values.where((v) => v).length} из ${_docs.length} прикреплено'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.blue.withValues(alpha: 0.1),
                border: Border.all(color: t.blue.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: t.blue, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'После проверки документов вы появитесь в каталоге психологов Nuva.',
                      style: TextStyle(color: t.text, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: t.textSec, fontSize: 13)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: TextStyle(
                    color: t.text, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
