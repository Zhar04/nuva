// Widget tests for the entry quiz. They drive the real UI for the first steps
// to prove the step renders, the Next button gates on a selection, and the
// branching advances. No network: navigation through steps never hits the API
// (the lead POST only fires on the final "Show matches" tap).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuva/l10n/strings.dart';
import 'package:nuva/screens/quiz_screen.dart';
import 'package:nuva/theme/theme.dart';

Future<void> _pumpQuiz(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: NuvaTheme.light(),
        home: const QuizScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  const ru = S(AppLang.ru);

  testWidgets('step 1 renders and Next is disabled until a choice is made',
      (tester) async {
    await _pumpQuiz(tester);

    // First question: "для кого".
    expect(find.text(ru.quizQWho), findsOneWidget);

    // The Next button exists but is disabled (no selection yet).
    final nextButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text(ru.quizNext),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(nextButton.onPressed, isNull);
  });

  testWidgets('selecting an option enables Next and advances to topics',
      (tester) async {
    await _pumpQuiz(tester);

    // Pick "Для себя".
    await tester.tap(find.text(ru.quizWhoSelf));
    await tester.pump();

    // Next is now enabled.
    final nextButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text(ru.quizNext),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(nextButton.onPressed, isNotNull);

    // Advance → step 2 is the topics question.
    await tester.tap(find.text(ru.quizNext));
    await tester.pumpAndSettle();
    expect(find.text(ru.quizQTopics), findsOneWidget);
  });

  testWidgets('severe severity branches to the self-harm crisis question',
      (tester) async {
    await _pumpQuiz(tester);

    // Step 1: who → self.
    await tester.tap(find.text(ru.quizWhoSelf));
    await tester.pump();
    await tester.tap(find.text(ru.quizNext));
    await tester.pumpAndSettle();

    // Step 2: pick a topic so we can advance.
    expect(find.text(ru.quizQTopics), findsOneWidget);
    await tester.tap(find.text('Тревога').first);
    await tester.pump();
    await tester.tap(find.text(ru.quizNext));
    await tester.pumpAndSettle();

    // Step 3: severity → choose "очень тяжело" (severe).
    expect(find.text(ru.quizQSeverity), findsOneWidget);
    await tester.tap(find.text(ru.quizSevSevere));
    await tester.pump();
    await tester.tap(find.text(ru.quizNext));
    await tester.pumpAndSettle();

    // Branch: the crisis self-harm sub-question appears (not the goal step).
    expect(find.text(ru.quizCrisisAsk), findsOneWidget);
  });
}
