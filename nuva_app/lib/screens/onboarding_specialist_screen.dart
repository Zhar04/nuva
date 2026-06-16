import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/backend_auth.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';
import '../widgets/onboarding_kit.dart';
import '../widgets/user_avatar.dart';

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
  String _avatar = '';
  bool _uploadingAvatar = false;
  String? _uploadingDoc;
  final Set<String> _expertise = {};

  Future<void> _pickAvatar() async {
    if (_uploadingAvatar) return;
    final url = await pickImageDataUrl();
    if (url == null) return;
    setState(() {
      _avatar = url;
      _uploadingAvatar = true;
    });
    try {
      // Only sync to the backend if we already have an account; otherwise keep
      // the local preview (the new flow registers before onboarding, so this
      // normally runs signed in).
      if (ref.read(backendAuthProvider).isSignedIn) {
        await ref.read(backendAuthProvider.notifier).updateProfile(avatar: url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: context.nuva.danger,
          content: Text('Не удалось загрузить фото: $e',
              style: const TextStyle(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _uploadDoc(String title) async {
    if (_uploadingDoc != null) return;
    final url = await pickImageDataUrl(maxWidth: 1400, quality: 82);
    if (url == null) return;
    setState(() => _uploadingDoc = title);
    try {
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      final mime = url.substring(5, url.indexOf(';'));
      await ref.read(apiClientProvider).post(
        'documents/',
        {'title': title, 'data': url, 'content_type': mime},
        token: token,
      );
      if (mounted) setState(() => _docs[title] = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: context.nuva.danger,
          content: Text(e is ApiException ? e.message : 'Не удалось загрузить',
              style: const TextStyle(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingDoc = null);
    }
  }
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
        return true; // documents are recommended but can be added later
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
    // Create the psychologist's own catalog profile so clients can find them.
    final parts = _name.text.trim().split(' ');
    try {
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      await ref.read(apiClientProvider).put(
        'specialists/me',
        {
          'first_name': parts.isNotEmpty ? parts.first : _name.text.trim(),
          'last_name': parts.length > 1 ? parts.sublist(1).join(' ') : '',
          'title': 'Психолог',
          'works_with': _expertise.toList(),
          'approaches': const <String>[],
          'years_experience': int.tryParse(_exp.text.trim()) ?? 0,
          'languages': const ['Русский'],
          'session_price_kzt': 15000,
        },
        token: token,
      );
      ref.invalidate(specialistsProvider);
      // The backend promoted this account to 'psychologist'; reload the cached
      // user so the app shows the specialist cabinet instead of the client tabs.
      await ref.read(backendAuthProvider.notifier).reloadUser();
    } catch (_) {/* profile can be edited later in the cabinet */}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Профиль отправлен на проверку. После подтверждения документов '
              'вы появитесь в каталоге.')),
    );
    context.go('/home');
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
                            ? 'П'
                            : _name.text.trim().characters.first.toUpperCase(),
                        gradient: const [Color(0xFF7E8BD9), Color(0xFFB39DDB)],
                        size: 96,
                        radius: 999,
                        fontSize: 34,
                      ),
                      if (_uploadingAvatar)
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
            const SizedBox(height: 8),
            Center(
              child: Text(
                _avatar.isNotEmpty
                    ? 'Фото добавлено'
                    : 'Нажмите, чтобы добавить фото (можно позже)',
                style: TextStyle(
                    color: _avatar.isNotEmpty ? t.teal : t.textTer,
                    fontSize: 12),
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
                  onTap: () => _uploadDoc(doc),
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
                        if (_uploadingDoc == doc)
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                        else
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
            Text('Фото диплома/сертификата. Видно только модерации Nuva.',
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
