import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/providers/mastery_provider.dart';
import 'package:algebrix/core/providers/quiz_review_provider.dart';
import 'package:algebrix/models/quiz_attempt_review_model.dart';
import 'package:algebrix/screens/review/attempt_review_screen.dart';
import 'package:algebrix/screens/review/quiz_attempts_tab.dart';
import 'package:algebrix/screens/review/review_date_format.dart';
import 'package:algebrix/screens/review/review_hub_screen.dart';
import 'package:algebrix/services/mastery_repository.dart';
import 'package:algebrix/services/quiz_review_repository.dart';

ReviewedQuestion _question({
  String question = 'Solve x + 2 = 5',
  int correctIndex = 0,
  int selectedIndex = 0,
}) {
  return ReviewedQuestion(
    question: question,
    options: const ['3', '5', '7'],
    correctIndex: correctIndex,
    selectedIndex: selectedIndex,
    explanation: 'Subtract 2 from both sides.',
    subLessonTitle: 'One-step equations',
    difficulty: 1,
  );
}

Future<void> _recordAttempt(
  QuizReviewProvider provider, {
  String moduleId = 'module1',
  int score = 2,
  List<ReviewedQuestion>? items,
}) {
  return provider.recordAttempt(
    moduleId: moduleId,
    moduleTitle: 'Welcome to Algebra!',
    score: score,
    totalQuestions: 3,
    items: items ??
        [
          _question(),
          _question(question: 'Solve y - 1 = 4'),
          _question(question: 'Solve 2z = 8', selectedIndex: 2),
        ],
  );
}

void main() {
  group('ReviewedQuestion', () {
    test('marks a matching selection as correct', () {
      final item = _question(correctIndex: 1, selectedIndex: 1);
      expect(item.isCorrect, isTrue);
      expect(item.isMissed, isFalse);
      expect(item.selectedAnswer, '5');
      expect(item.correctAnswer, '5');
    });

    test('marks a mismatched selection as missed', () {
      final item = _question(correctIndex: 1, selectedIndex: 2);
      expect(item.isCorrect, isFalse);
      expect(item.isMissed, isTrue);
      expect(item.selectedAnswer, '7');
      expect(item.correctAnswer, '5');
    });

    test('treats an unanswered question as missed, not correct', () {
      final item = _question(correctIndex: 0, selectedIndex: -1);
      expect(item.wasAnswered, isFalse);
      expect(item.isCorrect, isFalse);
      expect(item.isMissed, isTrue);
      expect(item.selectedAnswer, isNull);
    });

    test('round-trips through JSON', () {
      final original = _question(correctIndex: 2, selectedIndex: 1);
      final restored = ReviewedQuestion.fromJson(original.toJson());

      expect(restored.question, original.question);
      expect(restored.options, original.options);
      expect(restored.correctIndex, 2);
      expect(restored.selectedIndex, 1);
      expect(restored.explanation, original.explanation);
      expect(restored.difficulty, 1);
    });

    test('clamps an out-of-range selectedIndex to unanswered', () {
      final restored = ReviewedQuestion.fromJson({
        'question': 'Q',
        'options': ['a', 'b'],
        'correctIndex': 0,
        'selectedIndex': 9,
      });

      expect(restored.selectedIndex, -1);
      expect(restored.wasAnswered, isFalse);
    });
  });

  group('QuizAttemptReview', () {
    test('computes percentage, pass mark, and missed count', () {
      final attempt = QuizAttemptReview(
        id: 'a1',
        moduleId: 'module1',
        moduleTitle: 'Welcome to Algebra!',
        score: 2,
        totalQuestions: 3,
        items: [
          _question(correctIndex: 0, selectedIndex: 0),
          _question(correctIndex: 0, selectedIndex: 0),
          _question(correctIndex: 0, selectedIndex: 1),
        ],
        takenAt: DateTime(2026, 9, 9),
      );

      expect(attempt.percentage, closeTo(66.67, 0.01));
      expect(attempt.passed, isTrue);
      expect(attempt.missedCount, 1);
      expect(attempt.isPerfect, isFalse);
    });

    test('fails below the 60% mastery threshold', () {
      final attempt = QuizAttemptReview(
        id: 'a2',
        moduleId: 'module1',
        moduleTitle: 'Welcome to Algebra!',
        score: 1,
        totalQuestions: 3,
        items: [_question()],
        takenAt: DateTime(2026, 9, 9),
      );

      expect(attempt.passed, isFalse);
    });
  });

  group('MemoryQuizReviewRepository retention', () {
    test('keeps only the newest 3 attempts per module', () async {
      final repository = MemoryQuizReviewRepository();

      for (var i = 0; i < 5; i++) {
        await repository.saveAttempt(
          moduleId: 'module1',
          moduleTitle: 'Welcome to Algebra!',
          score: i,
          totalQuestions: 3,
          items: [_question()],
        );
      }

      final attempts = await repository.fetchRecentAttempts();
      expect(attempts.length, kMaxRetainedAttemptsPerModule);
      // Newest first, so the last three scores written survive.
      expect(attempts.map((a) => a.score).toList(), [4, 3, 2]);
    });

    test('retention is per module, not global', () async {
      final repository = MemoryQuizReviewRepository();

      for (var i = 0; i < 4; i++) {
        await repository.saveAttempt(
          moduleId: 'module1',
          moduleTitle: 'Welcome to Algebra!',
          score: i,
          totalQuestions: 3,
          items: [_question()],
        );
      }
      await repository.saveAttempt(
        moduleId: 'module2',
        moduleTitle: 'Working with Expressions',
        score: 9,
        totalQuestions: 3,
        items: [_question()],
      );

      final attempts = await repository.fetchRecentAttempts();
      expect(attempts.where((a) => a.moduleId == 'module1').length, 3);
      expect(attempts.where((a) => a.moduleId == 'module2').length, 1);
    });
  });

  group('QuizReviewProvider', () {
    test('starts empty and hydrates on bindAccount', () async {
      final repository = MemoryQuizReviewRepository();
      await repository.saveAttempt(
        moduleId: 'module1',
        moduleTitle: 'Welcome to Algebra!',
        score: 3,
        totalQuestions: 3,
        items: [_question()],
      );

      final provider = QuizReviewProvider(repository: repository);
      expect(provider.hasAttempts, isFalse);

      provider.bindAccount('student_1');
      await Future<void>.delayed(Duration.zero);

      expect(provider.hasAttempts, isTrue);
      expect(provider.attempts.single.score, 3);
    });

    test('recordAttempt makes the attempt reviewable immediately', () async {
      final provider =
          QuizReviewProvider(repository: MemoryQuizReviewRepository());
      provider.bindAccount('student_1');
      await Future<void>.delayed(Duration.zero);

      await _recordAttempt(provider);

      expect(provider.attempts.length, 1);
      expect(provider.attemptsForModule('module1').length, 1);
      expect(provider.totalMissedCount, 1);
    });

    test('prunes local state to the retention cap', () async {
      final provider =
          QuizReviewProvider(repository: MemoryQuizReviewRepository());
      provider.bindAccount('student_1');
      await Future<void>.delayed(Duration.zero);

      for (var i = 0; i < 5; i++) {
        await _recordAttempt(provider, score: i);
      }

      expect(
        provider.attemptsForModule('module1').length,
        kMaxRetainedAttemptsPerModule,
      );
      expect(provider.attempts.first.score, 4);
    });

    test('a repository failure never loses the just-finished attempt', () async {
      final repository = MemoryQuizReviewRepository();
      final provider = QuizReviewProvider(repository: repository);
      provider.bindAccount('student_1');
      await Future<void>.delayed(Duration.zero);

      repository.failure = StateError('offline');
      await _recordAttempt(provider);

      // Optimistic insert survives so the learner can review right away.
      expect(provider.attempts.length, 1);
    });

    test('recordAttempt ignores an empty question list', () async {
      final provider =
          QuizReviewProvider(repository: MemoryQuizReviewRepository());
      provider.bindAccount('student_1');
      await Future<void>.delayed(Duration.zero);

      await provider.recordAttempt(
        moduleId: 'module1',
        moduleTitle: 'Welcome to Algebra!',
        score: 0,
        totalQuestions: 0,
        items: const [],
      );

      expect(provider.hasAttempts, isFalse);
    });

    test('clearModule removes only that module', () async {
      final provider =
          QuizReviewProvider(repository: MemoryQuizReviewRepository());
      provider.bindAccount('student_1');
      await Future<void>.delayed(Duration.zero);

      await _recordAttempt(provider, moduleId: 'module1');
      await _recordAttempt(provider, moduleId: 'module2');

      final success = await provider.clearModule('module1');

      expect(success, isTrue);
      expect(provider.attemptsForModule('module1'), isEmpty);
      expect(provider.attemptsForModule('module2').length, 1);
    });

    test('clearModule restores state when the repository fails', () async {
      final repository = MemoryQuizReviewRepository();
      final provider = QuizReviewProvider(repository: repository);
      provider.bindAccount('student_1');
      await Future<void>.delayed(Duration.zero);

      await _recordAttempt(provider);
      repository.failure = StateError('offline');

      final success = await provider.clearModule('module1');

      expect(success, isFalse);
      expect(provider.attemptsForModule('module1').length, 1);
      expect(provider.errorMessage, isNotNull);
    });

    test('switching accounts clears the previous learner\'s log', () async {
      final provider =
          QuizReviewProvider(repository: MemoryQuizReviewRepository());
      provider.bindAccount('student_1');
      await Future<void>.delayed(Duration.zero);
      await _recordAttempt(provider);
      expect(provider.hasAttempts, isTrue);

      provider.bindAccount(null);
      expect(provider.hasAttempts, isFalse);
    });
  });

  group('formatReviewTimestamp', () {
    final now = DateTime(2026, 9, 9, 14, 30);

    test('labels today with a clock time', () {
      final result =
          formatReviewTimestamp(DateTime(2026, 9, 9, 15, 4), now: now);
      expect(result, 'Today, 3:04 PM');
    });

    test('labels yesterday', () {
      final result =
          formatReviewTimestamp(DateTime(2026, 9, 8, 9, 12), now: now);
      expect(result, 'Yesterday, 9:12 AM');
    });

    test('labels the last week in days', () {
      final result = formatReviewTimestamp(DateTime(2026, 9, 6), now: now);
      expect(result, '3 days ago');
    });

    test('falls back to a date beyond a week', () {
      final result = formatReviewTimestamp(DateTime(2026, 8, 20), now: now);
      expect(result, '20 Aug');
    });

    test('includes the year for a different year', () {
      final result = formatReviewTimestamp(DateTime(2025, 8, 20), now: now);
      expect(result, '20 Aug 2025');
    });

    test('renders midnight and noon correctly', () {
      expect(formatClockTime(DateTime(2026, 9, 9, 0, 5)), '12:05 AM');
      expect(formatClockTime(DateTime(2026, 9, 9, 12, 0)), '12:00 PM');
    });
  });

  group('Review screens', () {
    Widget wrap(QuizReviewProvider provider, Widget child) {
      return ChangeNotifierProvider<QuizReviewProvider>.value(
        value: provider,
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    /// The hub itself needs the mastery graph too; these cases exercise the
    /// quiz tab, which is what owns the attempt list.
    Widget wrapHub(QuizReviewProvider provider, MasteryProvider mastery) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<QuizReviewProvider>.value(value: provider),
          ChangeNotifierProvider<MasteryProvider>.value(value: mastery),
        ],
        child: const MaterialApp(home: ReviewHubScreen()),
      );
    }

    testWidgets('QuizAttemptsTab shows an empty state with no attempts',
        (tester) async {
      final provider =
          QuizReviewProvider(repository: MemoryQuizReviewRepository());

      await tester.pumpWidget(wrap(provider, const QuizAttemptsTab()));
      await tester.pump();

      expect(find.text('No quizzes to review yet'), findsOneWidget);
    });

    testWidgets('QuizAttemptsTab lists a recorded attempt', (tester) async {
      final provider =
          QuizReviewProvider(repository: MemoryQuizReviewRepository());
      provider.bindAccount('student_1');
      await tester.pump();
      await _recordAttempt(provider);

      await tester.pumpWidget(wrap(provider, const QuizAttemptsTab()));
      await tester.pump();

      expect(find.text('Welcome to Algebra!'), findsOneWidget);
      expect(find.text('Latest attempt'), findsOneWidget);
      expect(find.text('1 to review'), findsOneWidget);
    });

    testWidgets('ReviewHubScreen opens on Practice and can switch to Quizzes',
        (tester) async {
      final quizReview =
          QuizReviewProvider(repository: MemoryQuizReviewRepository());
      final mastery = MasteryProvider(repository: MemoryMasteryRepository());
      quizReview.bindAccount('student_1');
      mastery.bindAccount('student_1');
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await _recordAttempt(quizReview);

      await tester.pumpWidget(wrapHub(quizReview, mastery));
      await tester.pumpAndSettle();

      // Practice is the default landing tab.
      expect(find.text('No practice queue yet'), findsOneWidget);

      await tester.tap(find.byKey(const Key('review-tab-quizzes')));
      await tester.pumpAndSettle();

      expect(find.text('Latest attempt'), findsOneWidget);
    });

    testWidgets('AttemptReviewScreen opens on missed questions and can show all',
        (tester) async {
      final attempt = QuizAttemptReview(
        id: 'a1',
        moduleId: 'module1',
        moduleTitle: 'Welcome to Algebra!',
        score: 1,
        totalQuestions: 2,
        items: [
          _question(question: 'Correct one', correctIndex: 0, selectedIndex: 0),
          _question(question: 'Missed one', correctIndex: 0, selectedIndex: 2),
        ],
        takenAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(home: AttemptReviewScreen(attempt: attempt)),
      );
      await tester.pump();

      // Defaults to the mistake log.
      expect(find.text('Missed one'), findsOneWidget);
      expect(find.text('Correct one'), findsNothing);

      await tester.tap(find.byKey(const Key('attempt-review-filter-all')));
      await tester.pump();

      // The previously hidden correct answer is now first in the list.
      expect(find.text('Correct one'), findsOneWidget);

      // The missed question is still listed, just further down than the
      // 600px-tall test viewport reaches.
      await tester.scrollUntilVisible(find.text('Missed one'), 200);
      expect(find.text('Missed one'), findsOneWidget);
    });

    testWidgets('AttemptReviewScreen marks the learner answer and the correct one',
        (tester) async {
      final attempt = QuizAttemptReview(
        id: 'a1',
        moduleId: 'module1',
        moduleTitle: 'Welcome to Algebra!',
        score: 0,
        totalQuestions: 1,
        items: [_question(correctIndex: 0, selectedIndex: 2)],
        takenAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(home: AttemptReviewScreen(attempt: attempt)),
      );
      await tester.pump();

      expect(find.text('Correct answer'), findsOneWidget);
      expect(find.text('Your answer'), findsOneWidget);
      expect(find.text('Subtract 2 from both sides.'), findsOneWidget);
    });

    testWidgets('AttemptReviewScreen hides the filter on a perfect attempt',
        (tester) async {
      final attempt = QuizAttemptReview(
        id: 'a1',
        moduleId: 'module1',
        moduleTitle: 'Welcome to Algebra!',
        score: 1,
        totalQuestions: 1,
        items: [_question(correctIndex: 0, selectedIndex: 0)],
        takenAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(home: AttemptReviewScreen(attempt: attempt)),
      );
      await tester.pump();

      expect(find.byKey(const Key('attempt-review-filter-all')), findsNothing);
      expect(find.text('A clean sweep — nothing to fix here.'), findsOneWidget);
    });
  });
}
