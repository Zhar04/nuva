import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/strings.dart';
import '../models/specialist.dart';
import '../services/backend_auth.dart';
import '../services/data.dart';
import '../services/lead_capture.dart';
import '../theme/theme.dart';
import '../widgets/avatar.dart';
import '../widgets/glass.dart';
import '../widgets/onboarding_kit.dart';

/// Entry quiz — a branching onboarding funnel run BEFORE auth. It captures a
/// lead (anonymous, with consent), matches 1–3 specialists, then routes to
/// registration. Public route: reachable by a guest.
///
/// Branching: the step order is computed from the answers (a graph, not a fixed
/// list), and a "severe + self-harm" answer short-circuits the whole funnel to
/// crisis resources — we never push someone in crisis toward the sales flow.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

/// The branching steps, in their natural order. The crisis sub-question only
/// appears when severity == severe.
enum _Step { who, topics, severity, crisis, goal, format, urgency, contact }

class _QuizScreenState extends ConsumerState<QuizScreen> {
  // ── Answers ──────────────────────────────────────────────────────
  String? _who; // self / relative / child
  final Set<String> _topics = {};
  String? _severity; // mild / moderate / severe
  bool? _selfHarm; // only asked when severe
  String? _goal;
  String _format = 'online';
  String _language = 'ru';
  String? _urgency;
  String _budget = 'any';
  final _contact = TextEditingController();
  bool _consent = false;

  // ── Flow state ───────────────────────────────────────────────────
  final List<_Step> _history = [_Step.who];
  bool _submitting = false;
  bool _crisis = false;
  String? _error;

  _Step get _current => _history.last;

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  /// Topic chips depend on the "for whom" branch (marketing: feels tailored).
  List<String> get _topicOptions {
    switch (_who) {
      case 'child':
        return const [
          'Школа', 'Поведение', 'Тревога', 'Отношения в семье',
          'Подростковый возраст', 'Сон', 'Самооценка',
        ];
      case 'relative':
        return const [
          'Тревога', 'Депрессия', 'Зависимость', 'Конфликты',
          'Поддержка', 'Выгорание', 'Утрата',
        ];
      default:
        return const [
          'Тревога', 'Выгорание', 'Сон', 'Отношения', 'Самооценка',
          'Утрата', 'Стресс', 'Депрессия',
        ];
    }
  }

  /// Next step after [from] given current answers (the branching graph).
  _Step? _nextStep(_Step from) {
    switch (from) {
      case _Step.who:
        return _Step.topics;
      case _Step.topics:
        return _Step.severity;
      case _Step.severity:
        return _severity == 'severe' ? _Step.crisis : _Step.goal;
      case _Step.crisis:
        return _Step.goal;
      case _Step.goal:
        return _Step.format;
      case _Step.format:
        return _Step.urgency;
      case _Step.urgency:
        return _Step.contact;
      case _Step.contact:
        return null; // → submit
    }
  }

  bool get _canAdvance {
    switch (_current) {
      case _Step.who:
        return _who != null;
      case _Step.topics:
        return _topics.isNotEmpty;
      case _Step.severity:
        return _severity != null;
      case _Step.crisis:
        return _selfHarm != null;
      case _Step.goal:
        return _goal != null;
      case _Step.format:
        return true; // format + language have defaults
      case _Step.urgency:
        return _urgency != null;
      case _Step.contact:
        return _consent && _contactValid;
    }
  }

  bool get _contactValid {
    final v = _contact.text.trim();
    if (v.isEmpty) return false;
    final phone = RegExp(r'^\+?\d[\d\s().\-]{6,}\d$');
    final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final handle = RegExp(r'^@?[\w.]{3,}$');
    return phone.hasMatch(v) || email.hasMatch(v) || handle.hasMatch(v);
  }

  // Progress: count of "real" steps (the crisis sub-question is a detour, so we
  // base the bar on the 7 main steps for a steady, honest feel).
  static const _mainSteps = 7;
  int get _progressIndex {
    const order = [
      _Step.who, _Step.topics, _Step.severity, _Step.goal,
      _Step.format, _Step.urgency, _Step.contact,
    ];
    final i = order.indexOf(_current);
    return i < 0 ? order.length - 1 : i;
  }

  void _advance() {
    if (!_canAdvance) return;
    // Crisis short-circuit: severe + self-harm → resources, leave the funnel.
    if (_current == _Step.crisis && _selfHarm == true) {
      setState(() => _crisis = true);
      return;
    }
    final next = _nextStep(_current);
    if (next == null) {
      _submit();
      return;
    }
    setState(() => _history.add(next));
  }

  void _back() {
    if (_history.length == 1) {
      context.canPop() ? context.pop() : context.go('/');
    } else {
      setState(() => _history.removeLast());
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final api = ref.read(apiClientProvider);
    final goalLabel = _goalLabel(ref);
    final payload = {
      'for_whom': _who ?? 'self',
      'topics': _topics.toList(),
      'severity': _severity ?? '',
      'goal': goalLabel,
      'format': _format,
      'language': _language,
      'urgency': _urgency ?? '',
      'budget': _budget,
      'contact': _contact.text.trim(),
      'consent': _consent,
    };

    List<_QuizMatch> results;
    int? leadId;
    try {
      final res = await api.post('leads/', payload);
      leadId = (res['lead_id'] as num?)?.toInt();
      results = _parseResults(res['results']);
    } catch (_) {
      // Offline-safe: fall back to a local ranking over the bundled catalog and
      // skip the lead POST (no leadId → register flow won't try to link).
      results = await _offlineMatch();
    }

    await savePendingLead(PendingLead(
      leadId: leadId,
      topics: _topics.toList(),
      goal: goalLabel,
    ));

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _QuizResultScreen(results: results),
    ));
  }

  String _goalLabel(WidgetRef ref) {
    final s = S.of(ref);
    return switch (_goal) {
      'understand' => s.quizGoalUnderstand,
      'cope' => s.quizGoalCope,
      'relations' => s.quizGoalRelations,
      'decision' => s.quizGoalDecision,
      _ => '',
    };
  }

  List<_QuizMatch> _parseResults(dynamic raw) {
    return ((raw as List?) ?? const []).map((e) {
      final m = e as Map<String, dynamic>;
      return _QuizMatch(
        Specialist.fromMap(m['specialist'] as Map<String, dynamic>),
        (m['match_score'] as num?)?.toInt() ?? 0,
        ((m['reasons'] as List?) ?? const [])
            .map((x) => x.toString())
            .toList(),
      );
    }).toList();
  }

  /// Local ranking when the backend is unreachable — keeps the funnel working
  /// offline (and never crashes). Mirrors the server's overlap heuristic.
  Future<List<_QuizMatch>> _offlineMatch() async {
    final list = await ref.read(specialistsProvider.future);
    final wanted = _topics.map((t) => t.toLowerCase()).toSet();
    final scored = list.map((sp) {
      final tags = {
        ...sp.worksWith.map((w) => w.toLowerCase()),
        ...sp.approaches.map((a) => a.toLowerCase()),
      };
      final overlap = wanted.intersection(tags);
      final score = (55 + overlap.length * 13 + (sp.rating - 4.5) * 8)
          .clamp(40, 99)
          .round();
      final reasons = <String>[
        if (overlap.isNotEmpty)
          'Работает с: ${sp.worksWith.take(3).join(', ')}'
        else
          'Подходит по общему профилю',
        if (sp.rating >= 4.7) 'Высокий рейтинг · ${sp.rating}',
      ];
      return _QuizMatch(sp, score, reasons);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref);
    final t = context.nuva;

    if (_crisis) return _CrisisView(onBack: () => context.go('/'));

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                title: s.quizTitle,
                stepLabel:
                    '${s.quizStepOf} ${_progressIndex + 1}/$_mainSteps',
                progress: (_progressIndex + 1) / _mainSteps,
                onBack: _back,
                onSkip: () => context.go('/role'),
                skipLabel: s.skip,
              ),
              Expanded(
                child: _submitting
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                        child: _stepBody(s),
                      ),
              ),
              if (!_submitting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(_error!,
                              style:
                                  TextStyle(color: t.danger, fontSize: 13)),
                        ),
                      PrimaryButton(
                        label: _current == _Step.contact
                            ? s.quizShowResults
                            : s.quizNext,
                        onPressed: _canAdvance ? _advance : null,
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

  Widget _stepBody(S s) {
    final t = context.nuva;
    switch (_current) {
      case _Step.who:
        return _QuestionBlock(
          title: s.quizQWho,
          child: SingleSelect(
            options: [s.quizWhoSelf, s.quizWhoRelative, s.quizWhoChild],
            value: _whoLabel(s),
            onChanged: (v) => setState(() {
              _who = v == s.quizWhoSelf
                  ? 'self'
                  : v == s.quizWhoRelative
                      ? 'relative'
                      : 'child';
              _topics.clear(); // topic set is branch-dependent
            }),
          ),
        );
      case _Step.topics:
        return _QuestionBlock(
          title: s.quizQTopics,
          subtitle: s.quizQTopicsHint,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topicOptions.map((tp) {
              final sel = _topics.contains(tp);
              return Tag(
                label: tp,
                selected: sel,
                onTap: () => setState(() =>
                    sel ? _topics.remove(tp) : _topics.add(tp)),
              );
            }).toList(),
          ),
        );
      case _Step.severity:
        return _QuestionBlock(
          title: s.quizQSeverity,
          child: SingleSelect(
            options: [s.quizSevMild, s.quizSevModerate, s.quizSevSevere],
            value: switch (_severity) {
              'mild' => s.quizSevMild,
              'moderate' => s.quizSevModerate,
              'severe' => s.quizSevSevere,
              _ => null,
            },
            onChanged: (v) => setState(() {
              _severity = v == s.quizSevMild
                  ? 'mild'
                  : v == s.quizSevModerate
                      ? 'moderate'
                      : 'severe';
              if (_severity != 'severe') _selfHarm = null;
            }),
          ),
        );
      case _Step.crisis:
        return _QuestionBlock(
          title: s.quizCrisisAsk,
          child: SingleSelect(
            options: [s.quizCrisisNo, s.quizCrisisYes],
            value: _selfHarm == null
                ? null
                : (_selfHarm! ? s.quizCrisisYes : s.quizCrisisNo),
            onChanged: (v) =>
                setState(() => _selfHarm = v == s.quizCrisisYes),
          ),
        );
      case _Step.goal:
        return _QuestionBlock(
          title: s.quizQGoal,
          child: SingleSelect(
            options: [
              s.quizGoalUnderstand,
              s.quizGoalCope,
              s.quizGoalRelations,
              s.quizGoalDecision,
            ],
            value: switch (_goal) {
              'understand' => s.quizGoalUnderstand,
              'cope' => s.quizGoalCope,
              'relations' => s.quizGoalRelations,
              'decision' => s.quizGoalDecision,
              _ => null,
            },
            onChanged: (v) => setState(() {
              _goal = v == s.quizGoalUnderstand
                  ? 'understand'
                  : v == s.quizGoalCope
                      ? 'cope'
                      : v == s.quizGoalRelations
                          ? 'relations'
                          : 'decision';
            }),
          ),
        );
      case _Step.format:
        return _QuestionBlock(
          title: s.quizQFormat,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleSelect(
                options: [s.quizFormatOnline, s.quizFormatOffline],
                value: _format == 'online'
                    ? s.quizFormatOnline
                    : s.quizFormatOffline,
                onChanged: (v) => setState(() =>
                    _format = v == s.quizFormatOnline ? 'online' : 'offline'),
              ),
              const SizedBox(height: 8),
              Text(s.quizLangLabel,
                  style: TextStyle(
                      color: t.textSec,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ('ru', 'Русский'),
                  ('kk', 'Қазақша'),
                  ('en', 'English'),
                ].map((l) {
                  return Tag(
                    label: l.$2,
                    selected: _language == l.$1,
                    onTap: () => setState(() => _language = l.$1),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      case _Step.urgency:
        return _QuestionBlock(
          title: s.quizQUrgency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleSelect(
                options: [s.quizUrgWeek, s.quizUrgMonth, s.quizUrgExploring],
                value: switch (_urgency) {
                  'this_week' => s.quizUrgWeek,
                  'this_month' => s.quizUrgMonth,
                  'exploring' => s.quizUrgExploring,
                  _ => null,
                },
                onChanged: (v) => setState(() {
                  _urgency = v == s.quizUrgWeek
                      ? 'this_week'
                      : v == s.quizUrgMonth
                          ? 'this_month'
                          : 'exploring';
                }),
              ),
              const SizedBox(height: 12),
              Text(s.quizQBudget,
                  style: TextStyle(
                      color: t.textSec,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ('eco', s.quizBudgetEco),
                  ('mid', s.quizBudgetMid),
                  ('premium', s.quizBudgetPremium),
                  ('any', s.quizBudgetAny),
                ].map((b) {
                  return Tag(
                    label: b.$2,
                    selected: _budget == b.$1,
                    onTap: () => setState(() => _budget = b.$1),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      case _Step.contact:
        return _QuestionBlock(
          title: s.quizQContact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardField(
                label: s.quizContactHint,
                hint: s.quizContactHint,
                controller: _contact,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _ConsentRow(
                value: _consent,
                label: s.quizConsent,
                onChanged: (v) => setState(() => _consent = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 14, color: t.textTer),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(s.quizPrivacyNote,
                        style: TextStyle(
                            color: t.textTer, fontSize: 11.5, height: 1.4)),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  String? _whoLabel(S s) => switch (_who) {
        'self' => s.quizWhoSelf,
        'relative' => s.quizWhoRelative,
        'child' => s.quizWhoChild,
        _ => null,
      };
}

class _QuizMatch {
  final Specialist sp;
  final int score;
  final List<String> reasons;
  _QuizMatch(this.sp, this.score, this.reasons);
}

// ─── Pieces ─────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final String stepLabel;
  final double progress;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final String skipLabel;
  const _Header({
    required this.title,
    required this.stepLabel,
    required this.progress,
    required this.onBack,
    required this.onSkip,
    required this.skipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: t.text, size: 18),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    Text(stepLabel,
                        style: TextStyle(color: t.textSec, fontSize: 12)),
                  ],
                ),
              ),
              TextButton(
                onPressed: onSkip,
                child: Text(skipLabel,
                    style: TextStyle(
                        color: t.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
        ],
      ),
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _QuestionBlock({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title,
            style: TextStyle(
              color: t.text,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.4,
            )),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!,
              style: TextStyle(color: t.textSec, fontSize: 14, height: 1.4)),
        ],
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  const _ConsentRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: value ? t.blue : t.glassBgUp,
              border: Border.all(
                  color: value ? t.blue : t.glassBorder, width: 1.4),
              borderRadius: BorderRadius.circular(7),
            ),
            child: value
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(color: t.text, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _CrisisView extends ConsumerWidget {
  final VoidCallback onBack;
  const _CrisisView({required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: t.danger.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.health_and_safety_rounded,
                      color: t.danger, size: 40),
                ),
                const SizedBox(height: 20),
                Text(s.quizCrisisTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: t.danger.withValues(alpha: 0.08),
                    border: Border.all(color: t.danger.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(s.quizCrisisBody,
                      style: TextStyle(
                          color: t.text, fontSize: 14.5, height: 1.5)),
                ),
                const Spacer(),
                PrimaryButton(label: s.quizBack, onPressed: onBack),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Result ─────────────────────────────────────────────────────────

class _QuizResultScreen extends ConsumerWidget {
  final List<_QuizMatch> results;
  const _QuizResultScreen({required this.results});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(ref);
    final t = context.nuva;
    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: t.text, size: 18),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: t.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(s.quizResultTitle,
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(s.quizResultSub,
                        style: TextStyle(
                            color: t.textSec, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 18),
                    if (results.isEmpty)
                      Text(s.quizResultEmpty,
                          style: TextStyle(color: t.textTer, fontSize: 14))
                    else
                      ...results.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ResultCard(match: m),
                          )),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  16 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: PrimaryButton(
                  label: s.quizResultCta,
                  onPressed: () => context.go('/auth?mode=register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final _QuizMatch match;
  const _ResultCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final t = context.nuva;
    final sp = match.sp;
    return GlassCard(
      elevated: true,
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          GradientAvatar(
            initials: sp.initials,
            gradient: sp.avatarGradient,
            size: 52,
            radius: 16,
            fontSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sp.fullName,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(sp.title,
                    style: TextStyle(color: t.textSec, fontSize: 12.5)),
                const SizedBox(height: 4),
                Text(match.reasons.join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.textTer, fontSize: 11.5, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [t.blue, t.teal]),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${match.score}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 2),
              Text('совпадение',
                  style: TextStyle(color: t.textTer, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}
