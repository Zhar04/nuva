import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_profile.dart';
import '../services/backend_auth.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';
import '../widgets/onboarding_kit.dart';
import '../widgets/user_avatar.dart';

/// Edit the local user profile (avatar stub, name, bio, MBTI, gender, age).
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _State();
}

class _State extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _age;
  String? _gender;
  String? _mbti;
  String _avatar = '';
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(userProfileProvider);
    _name = TextEditingController(text: p.name == 'Аноним' ? '' : p.name);
    _bio = TextEditingController(text: p.bio);
    _age = TextEditingController(text: p.age?.toString() ?? '');
    _gender = p.gender;
    _mbti = p.mbti;
    _avatar = ref.read(backendAuthProvider).user?.avatar ?? '';
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Фото обновлено')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: context.nuva.danger,
            content: const Text('Не удалось загрузить фото',
                style: TextStyle(color: Colors.white))));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    await ref.read(userProfileProvider.notifier).update(
          name: name.isEmpty ? 'Аноним' : name,
          bio: _bio.text.trim(),
          age: int.tryParse(_age.text.trim()),
          gender: _gender,
          mbti: _mbti,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
    context.pop();
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
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: t.text, size: 18),
                    ),
                    Text('Редактировать профиль',
                        style: TextStyle(
                          color: t.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        )),
                    const Spacer(),
                    TextButton(
                      onPressed: _save,
                      child: Text('Сохранить',
                          style: TextStyle(
                            color: t.blue,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _pickAvatar,
                          child: SizedBox(
                            width: 104,
                            height: 104,
                            child: Stack(
                              children: [
                                UserAvatar(
                                  avatar: _avatar,
                                  initials: _name.text.trim().isEmpty
                                      ? 'А'
                                      : _name.text.trim().characters.first
                                          .toUpperCase(),
                                  gradient: [t.blue, t.teal],
                                  size: 104,
                                  radius: 999,
                                  fontSize: 38,
                                ),
                                if (_uploading)
                                  const Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black54,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: t.blue,
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: t.surface, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      OnboardField(
                        label: 'Имя или псевдоним',
                        hint: 'Как к вам обращаться',
                        controller: _name,
                      ),
                      const SizedBox(height: 14),
                      OnboardField(
                        label: 'О себе',
                        hint: 'Пара слов о себе (необязательно)',
                        controller: _bio,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 14),
                      OnboardField(
                        label: 'Возраст',
                        hint: 'Например, 27',
                        controller: _age,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Text('Пол',
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
                      const SizedBox(height: 8),
                      Text('Тип личности (MBTI)',
                          style: TextStyle(
                              color: t.textSec,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.push('/mbti'),
                        child: Row(
                          children: [
                            Icon(Icons.quiz_outlined, color: t.blue, size: 16),
                            const SizedBox(width: 6),
                            Text('Пройти тест на тип личности',
                                style: TextStyle(
                                  color: t.blue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
