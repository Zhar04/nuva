import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';
import '../services/api_client.dart';
import '../services/backend_auth.dart';
import '../services/data.dart';
import '../theme/theme.dart';
import '../widgets/glass.dart';

/// "Как вас видят клиенты" — the psychologist edits their public catalog
/// listing: selling bio, methods, topics, languages, education and diplomas.
/// Saves to `PUT /specialists/me`.
class PsyCabinetEditScreen extends ConsumerStatefulWidget {
  const PsyCabinetEditScreen({super.key});

  @override
  ConsumerState<PsyCabinetEditScreen> createState() => _PsyCabinetEditState();
}

class _PsyCabinetEditState extends ConsumerState<PsyCabinetEditScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _title = TextEditingController();
  final _about = TextEditingController();
  final _years = TextEditingController();
  final _price = TextEditingController();
  List<String> _methods = [];
  List<String> _topics = [];
  List<String> _languages = [];
  List<String> _diplomas = [];
  final List<_EduRow> _education = [];
  bool _loaded = false;
  bool _saving = false;

  static const _commonLangs = ['Қазақша', 'Русский', 'English'];

  void _hydrate(Specialist? me) {
    if (_loaded || me == null) return;
    _loaded = true;
    _firstName.text = me.firstName;
    _lastName.text = me.lastName;
    _title.text = me.title;
    _about.text = me.about;
    _years.text = me.yearsExperience > 0 ? '${me.yearsExperience}' : '';
    _price.text = me.sessionPriceKzt > 0 ? '${me.sessionPriceKzt}' : '';
    _methods = [...me.approaches];
    _topics = [...me.worksWith];
    _languages = [...me.languages];
    _diplomas = [...me.diplomas];
    for (final e in me.education) {
      _education.add(_EduRow(e.institution, e.degree, e.years));
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _title.dispose();
    _about.dispose();
    _years.dispose();
    _price.dispose();
    for (final e in _education) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final payload = {
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'title': _title.text.trim(),
      'about': _about.text.trim(),
      'years_experience': int.tryParse(_years.text.trim()) ?? 0,
      'session_price_kzt': int.tryParse(_price.text.trim()) ?? 0,
      'approaches': _methods,
      'works_with': _topics,
      'languages': _languages,
      'diplomas': _diplomas,
      'education': _education
          .where((e) => e.inst.text.trim().isNotEmpty ||
              e.deg.text.trim().isNotEmpty)
          .map((e) => {
                'institution': e.inst.text.trim(),
                'degree': e.deg.text.trim(),
                'years': e.yrs.text.trim(),
              })
          .toList(),
    };
    try {
      final token = ref.read(backendAuthProvider.notifier).accessToken;
      await ref
          .read(apiClientProvider)
          .put('specialists/me', payload, token: token);
      ref.invalidate(specialistMeProvider);
      ref.invalidate(specialistsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлён')),
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: context.nuva.danger,
          content: Text(e is ApiException ? e.message : 'Не удалось сохранить',
              style: const TextStyle(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final me = ref.watch(specialistMeProvider).valueOrNull;
    _hydrate(me);

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 18, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: t.text, size: 18),
                    ),
                    Expanded(
                      child: Text('Кабинет психолога',
                          style: TextStyle(
                            color: t.text,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          )),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Сохраняем…' : 'Сохранить',
                          style: TextStyle(
                              color: t.blue,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: t.teal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.visibility_rounded,
                              size: 18, color: t.teal),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Как вас видят клиенты в каталоге. Заполните, '
                              'чтобы привлечь больше обращений.',
                              style: TextStyle(
                                  color: t.textSec,
                                  fontSize: 12.5,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Label('Имя и фамилия'),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(controller: _firstName, hint: 'Имя'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Field(controller: _lastName, hint: 'Фамилия'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Label('Специализация'),
                    _Field(
                        controller: _title,
                        hint: 'Напр.: Клинический психолог · КПТ'),
                    const SizedBox(height: 18),
                    _Label('О себе'),
                    _Field(
                      controller: _about,
                      hint: 'Продающее профессиональное био: с кем и как '
                          'работаете, в чём помогаете, ваш подход…',
                      maxLines: 6,
                      minLines: 4,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Опыт, лет'),
                              _Field(
                                controller: _years,
                                hint: '0',
                                keyboardType: TextInputType.number,
                                digitsOnly: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Цена сессии, ₸'),
                              _Field(
                                controller: _price,
                                hint: '18000',
                                keyboardType: TextInputType.number,
                                digitsOnly: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Label('Методы'),
                    _Hint('Ключевые слова: КПТ, EMDR, гештальт, схема-терапия…'),
                    _ChipsEditor(
                      values: _methods,
                      hint: 'Добавить метод',
                      onChanged: (v) => setState(() => _methods = v),
                    ),
                    const SizedBox(height: 18),
                    _Label('Темы'),
                    _Hint('С чем работаете: тревога, отношения, выгорание…'),
                    _ChipsEditor(
                      values: _topics,
                      hint: 'Добавить тему',
                      onChanged: (v) => setState(() => _topics = v),
                    ),
                    const SizedBox(height: 18),
                    _Label('Языки приёма'),
                    _LanguagesEditor(
                      common: _commonLangs,
                      values: _languages,
                      onChanged: (v) => setState(() => _languages = v),
                    ),
                    const SizedBox(height: 18),
                    _Label('Образование'),
                    ..._education.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _EduCard(
                            row: entry.value,
                            onRemove: () => setState(
                                () => _education.removeAt(entry.key)),
                          ),
                        )),
                    _AddButton(
                      label: 'Добавить образование',
                      onTap: () =>
                          setState(() => _education.add(_EduRow('', '', ''))),
                    ),
                    const SizedBox(height: 18),
                    _Label('Дипломы и сертификаты'),
                    _Hint('Названия дипломов и сертификатов.'),
                    _ChipsEditor(
                      values: _diplomas,
                      hint: 'Добавить документ',
                      onChanged: (v) => setState(() => _diplomas = v),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(_saving ? 'Сохраняем…' : 'Сохранить профиль',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Holds the three controllers for one education entry.
class _EduRow {
  final TextEditingController inst;
  final TextEditingController deg;
  final TextEditingController yrs;
  _EduRow(String i, String d, String y)
      : inst = TextEditingController(text: i),
        deg = TextEditingController(text: d),
        yrs = TextEditingController(text: y);

  void dispose() {
    inst.dispose();
    deg.dispose();
    yrs.dispose();
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              color: t.text, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: TextStyle(color: t.textSec, fontSize: 12, height: 1.35)),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int minLines;
  final TextInputType? keyboardType;
  final bool digitsOnly;
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.minLines = 1,
    this.keyboardType,
    this.digitsOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      inputFormatters:
          digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: TextStyle(color: t.text, fontSize: 14, height: 1.4),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: t.textTer, fontSize: 13.5),
        isDense: true,
        filled: true,
        fillColor: t.glassBgUp,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.blue, width: 1.4),
        ),
      ),
    );
  }
}

/// Removable keyword chips with an inline add field.
class _ChipsEditor extends StatefulWidget {
  final List<String> values;
  final String hint;
  final ValueChanged<List<String>> onChanged;
  const _ChipsEditor({
    required this.values,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_ChipsEditor> createState() => _ChipsEditorState();
}

class _ChipsEditorState extends State<_ChipsEditor> {
  final _input = TextEditingController();

  void _add() {
    final v = _input.text.trim();
    if (v.isEmpty || widget.values.contains(v)) {
      _input.clear();
      return;
    }
    widget.onChanged([...widget.values, v]);
    _input.clear();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.values.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.values
                  .map((v) => Container(
                        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
                        decoration: BoxDecoration(
                          color: t.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(v,
                                style: TextStyle(
                                    color: t.blue,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () => widget.onChanged(
                                  widget.values.where((x) => x != v).toList()),
                              child: Icon(Icons.close_rounded,
                                  size: 15, color: t.blue),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                onSubmitted: (_) => _add(),
                style: TextStyle(color: t.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: t.textTer, fontSize: 13.5),
                  isDense: true,
                  filled: true,
                  fillColor: t.glassBgUp,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: t.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: t.blue, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _add,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: t.blue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Common languages as toggle chips, plus free-text add for others.
class _LanguagesEditor extends StatelessWidget {
  final List<String> common;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  const _LanguagesEditor({
    required this.common,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final all = <String>{...common, ...values}.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: all.map((lang) {
        final on = values.contains(lang);
        return GestureDetector(
          onTap: () => onChanged(on
              ? values.where((x) => x != lang).toList()
              : [...values, lang]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: on ? t.blue : t.glassBgUp,
              border: Border.all(color: on ? t.blue : t.glassBorder),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (on) ...[
                  const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                ],
                Text(lang,
                    style: TextStyle(
                        color: on ? Colors.white : t.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EduCard extends StatelessWidget {
  final _EduRow row;
  final VoidCallback onRemove;
  const _EduCard({required this.row, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    InputDecoration deco(String h) => InputDecoration(
          hintText: h,
          hintStyle: TextStyle(color: t.textTer, fontSize: 13),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.blue, width: 1.3),
          ),
        );
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.inst,
                  style: TextStyle(color: t.text, fontSize: 13.5),
                  decoration: deco('Учебное заведение'),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.delete_outline_rounded,
                    size: 20, color: t.textTer),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: row.deg,
                  style: TextStyle(color: t.text, fontSize: 13.5),
                  decoration: deco('Степень / квалификация'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: row.yrs,
                  style: TextStyle(color: t.text, fontSize: 13.5),
                  decoration: deco('Годы'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.glassBgUp,
          border: Border.all(color: t.glassBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: t.blue),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: t.blue,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
