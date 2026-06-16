import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mbti.dart';
import '../models/user_profile.dart';
import '../services/backend_auth.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';

/// 16-type personality test. One statement at a time → 4-letter result,
/// saved to the profile (local + backend).
class MbtiScreen extends ConsumerStatefulWidget {
  const MbtiScreen({super.key});

  @override
  ConsumerState<MbtiScreen> createState() => _State();
}

class _State extends ConsumerState<MbtiScreen> {
  int _i = 0;
  final List<int?> _answers = List.filled(mbtiQuestions.length, null);
  String? _result;

  void _answer(int value) {
    setState(() => _answers[_i] = value);
    Future.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      if (_i < mbtiQuestions.length - 1) {
        setState(() => _i++);
      } else {
        _finish();
      }
    });
  }

  Future<void> _finish() async {
    final type = computeMbti(_answers.map((e) => e ?? 0).toList());
    setState(() => _result = type);
    await ref.read(userProfileProvider.notifier).update(mbti: type);
    try {
      await ref.read(backendAuthProvider.notifier).updateProfile(mbti: type);
    } catch (_) {/* saved locally regardless */}
  }

  void _back() {
    if (_i == 0) {
      context.pop();
    } else {
      setState(() => _i--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    if (_result != null) return _ResultView(type: _result!);

    final q = mbtiQuestions[_i];
    final progress = (_i + 1) / mbtiQuestions.length;
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: t.glassBgUp,
                          valueColor: AlwaysStoppedAnimation(t.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${_i + 1}/${mbtiQuestions.length}',
                        style: TextStyle(color: t.textSec, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Text(q.text,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            letterSpacing: -0.4,
                          )),
                      const SizedBox(height: 28),
                      ...mbtiOptions.map((o) {
                        final selected = _answers[_i] == o.$2;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => _answer(o.$2),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 15),
                              decoration: BoxDecoration(
                                color: selected ? t.blue : t.glassBgUp,
                                border: Border.all(
                                    color:
                                        selected ? t.blue : t.glassBorder,
                                    width: selected ? 1.5 : 1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(o.$1,
                                  style: TextStyle(
                                    color: selected ? Colors.white : t.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
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

class _ResultView extends StatelessWidget {
  final String type;
  const _ResultView({required this.type});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final info = mbtiInfo[type] ?? ('Личность', '');
    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [t.blue, t.teal],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: t.blue.withValues(alpha: 0.4),
                        blurRadius: 36,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      )),
                ),
                const SizedBox(height: 24),
                Text(info.$1,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 10),
                Text(info.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.textSec, fontSize: 15, height: 1.5)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.teal.withValues(alpha: 0.10),
                    border: Border.all(color: t.teal.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: t.teal, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Тип сохранён в профиле — поможет подобрать специалиста.',
                          style: TextStyle(
                              color: t.teal, fontSize: 12.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PrimaryButton(label: 'Готово', onPressed: () => context.pop()),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
