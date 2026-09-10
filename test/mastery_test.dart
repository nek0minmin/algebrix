import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/providers/mastery_provider.dart';
import 'package:algebrix/data/lesson_catalog.dart';
import 'package:algebrix/models/concept_mastery_model.dart';
import 'package:algebrix/models/quiz_attempt_review_model.dart';
import 'package:algebrix/screens/review/lesson_mistakes_tab.dart';
import 'package:algebrix/screens/review/mastery_tab.dart';
import 'package:algebrix/screens/review/practice_queue_tab.dart';
import 'package:algebrix/services/concept_resolver.dart';
import 'package:algebrix/services/mastery_repository.dart';

ReviewedQuestion _question({
  required String subLessonTitle,
  required bool correct,
}) {
  return ReviewedQuestion(
    question: 'Q',
    options: const ['a', 'b'],
    correctIndex: 0,
    selectedIndex: correct ? 0 : 1,
    explanation: 'Because.',
    subLessonTitle: subLessonTitle,
    difficulty: 1,
  );
}

QuizAttemptReview _attempt({
  String id = 'a1',
  String moduleId = 'module2',
  required List<ReviewedQuestion> items,
}) {
  return QuizAttemptReview(
    id: id,
    moduleId: moduleId,
    moduleTitle: 'Working with Expressions',
    score: items.where((i) => i.isCorrect).length,
    totalQuestions: items.length,
    items: items,
    takenAt: DateTime(2026, 9, 9),
  );
}

/// Binds a provider and lets its initial hydration settle.
///
/// `testWidgets` runs inside a fake-async zone where a bare `Future.delayed`
/// never fires, so widget tests must pass their [tester] and let `runAsync`
/// drive the real event loop instead.
Future<MasteryProvider> _boundProvider(
  MemoryMasteryRepository repository, {
  WidgetTester? tester,
}) async {
  final provider = MasteryProvider(repository: repository);
  provider.bindAccount('student_1');

  if (tester == null) {
    await Future<void>.delayed(Duration.zero);
  } else {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  return provider;
}

void main() {
  group('LessonCatalog', () {
    test('registers all three modules and every lesson', () {
      expect(LessonCatalog.modules.length, 3);
      expect(LessonCatalog.totalLessons, 21);
    });

    test('resolves lessons and their owning module', () {
      expect(LessonCatalog.lessonById('m2_l3')?.title, isNotNull);
      expect(LessonCatalog.moduleForLesson('m2_l3')?.id, 'module2');
      expect(LessonCatalog.lessonById('nope'), isNull);
    });

    test('builds positional labels', () {
      expect(LessonCatalog.lessonNumberLabel('m1_l1'), '1.1');
      expect(LessonCatalog.lessonNumberLabel('m3_l8'), '3.8');
      expect(LessonCatalog.lessonLabel('m1_l1'), startsWith('1.1 · '));
    });

    test('finds a lesson step index by id', () {
      final lesson = LessonCatalog.lessonById('m1_l1')!;
      final stepId = lesson.steps.first.id;

      expect(LessonCatalog.stepIndexOf('m1_l1', stepId), 0);
      expect(LessonCatalog.stepIndexOf('m1_l1', 'no_such_step'), isNull);
    });

    test('finds the first question step so practice skips the intro', () {
      final index = LessonCatalog.firstAnswerStepIndex('m1_l1');

      expect(index, isNotNull);
      expect(index, greaterThan(0));
    });
  });

  group('ConceptResolver', () {
    const resolver = ConceptResolver();

    test('matches a lesson title directly', () {
      expect(
        resolver.resolveLessonId('Distributive Property', moduleId: 'module2'),
        'm2_l3',
      );
    });

    test('matches on keywords rather than the exact title', () {
      expect(
        resolver.resolveLessonId('Combining like terms', moduleId: 'module2'),
        'm2_l2',
      );
      expect(
        resolver.resolveLessonId('Order of operations', moduleId: 'module1'),
        'm1_l6',
      );
    });

    test('falls back across modules when the stated module has no match', () {
      // A Module 3 quiz can legitimately test a Module 1 prerequisite.
      expect(
        resolver.resolveLessonId('coefficient', moduleId: 'module3'),
        'm1_l5',
      );
    });

    test('returns null rather than guessing on an unrelated label', () {
      expect(resolver.resolveLessonId('Watermelon recipes'), isNull);
      expect(resolver.resolveLessonId(''), isNull);
      expect(resolver.resolveLessonId(null), isNull);
    });

    test('prefers the longer, more specific keyword', () {
      // "combining like terms" must beat the bare "terms" of m1_l3.
      expect(
        resolver.resolveLessonId('Combining like terms'),
        'm2_l2',
      );
    });
  });

  group('ConceptMastery bands', () {
    ConceptMastery concept({
      int seen = 0,
      int correct = 0,
      int openMisses = 0,
      int totalMisses = 0,
      bool isScheduled = false,
      DateTime? dueAt,
    }) {
      return ConceptMastery(
        moduleId: 'module2',
        moduleTitle: 'Working with Expressions',
        lessonId: 'm2_l3',
        lessonTitle: 'Distributive Property',
        lessonNumberLabel: '2.3',
        quizQuestionsSeen: seen,
        quizQuestionsCorrect: correct,
        openMisses: openMisses,
        totalMissCount: totalMisses,
        reviewStrength: 0,
        reviewDueAt: dueAt,
        isScheduled: isScheduled,
      );
    }

    test('is unassessed with no evidence at all', () {
      final c = concept();
      expect(c.band, MasteryBand.notAssessed);
      expect(c.quizAccuracy, isNull);
      expect(c.needsReview(), isFalse);
    });

    test('bands by quiz accuracy', () {
      expect(concept(seen: 10, correct: 9).band, MasteryBand.mastered);
      expect(concept(seen: 10, correct: 7).band, MasteryBand.solid);
      expect(concept(seen: 10, correct: 5).band, MasteryBand.shaky);
      expect(concept(seen: 10, correct: 2).band, MasteryBand.needsWork);
    });

    test('an open mistake caps a good quiz score at shaky', () {
      final c = concept(seen: 10, correct: 10, openMisses: 1, totalMisses: 1);
      expect(c.quizAccuracy, 100);
      expect(c.band, MasteryBand.shaky);
    });

    test('lesson misses alone are enough to band a concept', () {
      expect(
        concept(openMisses: 1, totalMisses: 1).band,
        MasteryBand.needsWork,
      );
      expect(
        concept(openMisses: 0, totalMisses: 2).band,
        MasteryBand.solid,
        reason: 'a mistake later corrected is evidence of recovery',
      );
    });

    test('unscheduled concepts are judged on raw signals', () {
      expect(concept(seen: 10, correct: 5).needsReview(), isTrue);
      expect(concept(seen: 10, correct: 9).needsReview(), isFalse);
      expect(concept(openMisses: 1, totalMisses: 1).needsReview(), isTrue);
    });

    test('once scheduled, the ladder governs instead of accuracy', () {
      final now = DateTime(2026, 9, 9);

      // Poor accuracy but reviewed and pushed out: stays quiet.
      final settled = concept(
        seen: 10,
        correct: 3,
        isScheduled: true,
        dueAt: now.add(const Duration(days: 7)),
      );
      expect(settled.needsReview(now: now), isFalse);

      // Same accuracy, now due: comes back.
      final due = concept(
        seen: 10,
        correct: 3,
        isScheduled: true,
        dueAt: now.subtract(const Duration(minutes: 1)),
      );
      expect(due.needsReview(now: now), isTrue);
    });
  });

  group('MemoryMasteryRepository', () {
    test('increments the miss count for a repeated mistake', () async {
      final repository = MemoryMasteryRepository();

      for (var i = 0; i < 3; i++) {
        await repository.recordLessonMiss(
          moduleId: 'module2',
          lessonId: 'm2_l3',
          stepId: 'step4',
          stepIndex: 3,
          question: 'Expand 2(x+3)',
          options: const ['2x+6', '2x+3'],
          correctIndex: 0,
          selectedIndex: 1,
          explanation: 'Multiply both terms.',
        );
      }

      final mistakes = await repository.fetchLessonMistakes();
      expect(mistakes.length, 1, reason: 'one row per lesson step');
      expect(mistakes.single.missCount, 3);
      expect(mistakes.single.isRepeated, isTrue);
    });

    test('resolving only succeeds while a mistake is open', () async {
      final repository = MemoryMasteryRepository();
      await repository.recordLessonMiss(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        stepId: 'step4',
        stepIndex: 3,
        question: 'Q',
        options: const ['a'],
        correctIndex: 0,
        selectedIndex: -1,
        explanation: '',
      );

      expect(
        await repository.resolveLessonMiss(lessonId: 'm2_l3', stepId: 'step4'),
        isTrue,
      );
      expect(
        await repository.resolveLessonMiss(lessonId: 'm2_l3', stepId: 'step4'),
        isFalse,
        reason: 'already closed',
      );
      expect(
        await repository.resolveLessonMiss(lessonId: 'm2_l3', stepId: 'never'),
        isFalse,
      );
    });

    test('climbs and falls through the Leitner ladder', () async {
      final repository = MemoryMasteryRepository();
      final now = DateTime(2026, 9, 9);
      repository.clock = () => now;

      Future<int> strength() async =>
          (await repository.fetchReviewSchedule()).single.strength;

      await repository.scheduleReview(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        outcome: ReviewOutcome.missed,
      );
      expect(await strength(), 0);
      expect((await repository.fetchReviewSchedule()).single.dueAt, now);

      for (var i = 0; i < 3; i++) {
        await repository.scheduleReview(
          moduleId: 'module2',
          lessonId: 'm2_l3',
          outcome: ReviewOutcome.reviewed,
        );
      }
      expect(await strength(), 3);
      expect(
        (await repository.fetchReviewSchedule()).single.dueAt,
        now.add(const Duration(days: 7)),
      );

      await repository.scheduleReview(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        outcome: ReviewOutcome.missed,
      );
      expect(await strength(), 2, reason: 'a miss demotes by one');
    });

    test('strength is clamped to the 0-5 range', () async {
      final repository = MemoryMasteryRepository();

      for (var i = 0; i < 10; i++) {
        await repository.scheduleReview(
          moduleId: 'module2',
          lessonId: 'm2_l3',
          outcome: ReviewOutcome.reviewed,
        );
      }
      expect((await repository.fetchReviewSchedule()).single.strength, 5);

      for (var i = 0; i < 10; i++) {
        await repository.scheduleReview(
          moduleId: 'module2',
          lessonId: 'm2_l3',
          outcome: ReviewOutcome.missed,
        );
      }
      expect((await repository.fetchReviewSchedule()).single.strength, 0);
    });
  });

  group('MasteryProvider aggregation', () {
    test('attributes quiz questions to the lesson that teaches them', () async {
      final provider = await _boundProvider(MemoryMasteryRepository());

      provider.syncQuizAttempts([
        _attempt(items: [
          _question(subLessonTitle: 'Distributive Property', correct: false),
          _question(subLessonTitle: 'Distributive Property', correct: false),
          _question(subLessonTitle: 'Combining like terms', correct: true),
        ]),
      ]);

      final distributive = provider.conceptFor('m2_l3')!;
      expect(distributive.quizQuestionsSeen, 2);
      expect(distributive.quizQuestionsCorrect, 0);
      expect(distributive.band, MasteryBand.needsWork);

      final combining = provider.conceptFor('m2_l2')!;
      expect(combining.quizQuestionsSeen, 1);
      expect(combining.quizAccuracy, 100);
    });

    test('ignores questions whose concept cannot be resolved', () async {
      final provider = await _boundProvider(MemoryMasteryRepository());

      provider.syncQuizAttempts([
        _attempt(items: [
          _question(subLessonTitle: 'Watermelon recipes', correct: false),
        ]),
      ]);

      expect(provider.summary.assessedCount, 0);
    });

    test('ranks weakest and strongest concepts', () async {
      final provider = await _boundProvider(MemoryMasteryRepository());

      provider.syncQuizAttempts([
        _attempt(items: [
          _question(subLessonTitle: 'Distributive Property', correct: false),
          _question(subLessonTitle: 'Distributive Property', correct: false),
          _question(subLessonTitle: 'Combining like terms', correct: true),
          _question(subLessonTitle: 'Combining like terms', correct: true),
        ]),
      ]);

      expect(provider.weakestFirst.first.lessonId, 'm2_l3');
      expect(provider.strongestFirst.first.lessonId, 'm2_l2');
      expect(provider.topPriority?.lessonId, 'm2_l3');
    });

    test('a lesson miss enters the practice queue and demotes the concept',
        () async {
      final repository = MemoryMasteryRepository();
      final provider = await _boundProvider(repository);

      await provider.recordLessonMiss(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        stepId: 'step4',
        stepIndex: 3,
        question: 'Expand 2(x+3)',
        options: const ['2x+6', '2x+3'],
        correctIndex: 0,
        selectedIndex: 1,
        explanation: 'Multiply both terms.',
      );

      expect(provider.hasOpenLessonMistakes, isTrue);
      expect(provider.needsReview.map((c) => c.lessonId), contains('m2_l3'));
      expect(provider.conceptFor('m2_l3')!.openMisses, 1);
    });

    test('answering right later closes the mistake and promotes', () async {
      final repository = MemoryMasteryRepository();
      final provider = await _boundProvider(repository);

      await provider.recordLessonMiss(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        stepId: 'step4',
        stepIndex: 3,
        question: 'Q',
        options: const ['a', 'b'],
        correctIndex: 0,
        selectedIndex: 1,
        explanation: '',
      );
      expect(provider.conceptFor('m2_l3')!.reviewStrength, 0);

      await provider.recordLessonSuccess(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        stepId: 'step4',
      );

      expect(provider.hasOpenLessonMistakes, isFalse);
      expect(provider.conceptFor('m2_l3')!.reviewStrength, 1);
    });

    test('a first-time correct answer does not inflate the ladder', () async {
      final repository = MemoryMasteryRepository();
      final provider = await _boundProvider(repository);

      await provider.recordLessonSuccess(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        stepId: 'step4',
      );

      expect(await repository.fetchReviewSchedule(), isEmpty);
    });

    test('a finished quiz demotes every concept it missed, once', () async {
      final repository = MemoryMasteryRepository();
      final provider = await _boundProvider(repository);

      await provider.registerQuizAttempt(
        _attempt(items: [
          _question(subLessonTitle: 'Distributive Property', correct: false),
          _question(subLessonTitle: 'Distributive Property', correct: false),
          _question(subLessonTitle: 'Combining like terms', correct: true),
        ]),
      );

      final schedule = await repository.fetchReviewSchedule();
      expect(schedule.length, 1, reason: 'only the missed concept is scheduled');
      expect(schedule.single.lessonId, 'm2_l3');
    });

    test('a perfect quiz schedules nothing', () async {
      final repository = MemoryMasteryRepository();
      final provider = await _boundProvider(repository);

      await provider.registerQuizAttempt(
        _attempt(items: [
          _question(subLessonTitle: 'Distributive Property', correct: true),
        ]),
      );

      expect(await repository.fetchReviewSchedule(), isEmpty);
    });

    test('clearConcept forgets mistakes and schedule together', () async {
      final repository = MemoryMasteryRepository();
      final provider = await _boundProvider(repository);

      await provider.recordLessonMiss(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        stepId: 'step4',
        stepIndex: 3,
        question: 'Q',
        options: const ['a'],
        correctIndex: 0,
        selectedIndex: -1,
        explanation: '',
      );

      expect(await provider.clearConcept('m2_l3'), isTrue);
      expect(provider.hasOpenLessonMistakes, isFalse);
      expect(await repository.fetchReviewSchedule(), isEmpty);
    });

    test('a repository failure never throws out of a lesson', () async {
      final repository = MemoryMasteryRepository();
      final provider = await _boundProvider(repository);
      repository.failure = StateError('offline');

      await expectLater(
        provider.recordLessonMiss(
          moduleId: 'module2',
          lessonId: 'm2_l3',
          stepId: 'step4',
          stepIndex: 3,
          question: 'Q',
          options: const ['a'],
          correctIndex: 0,
          selectedIndex: -1,
          explanation: '',
        ),
        completes,
      );
      await expectLater(
        provider.registerQuizAttempt(
          _attempt(items: [
            _question(subLessonTitle: 'Distributive Property', correct: false),
          ]),
        ),
        completes,
      );
    });

    test('switching accounts drops the previous learner\'s mastery', () async {
      final provider = await _boundProvider(MemoryMasteryRepository());
      await provider.recordLessonMiss(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        stepId: 'step4',
        stepIndex: 3,
        question: 'Q',
        options: const ['a'],
        correctIndex: 0,
        selectedIndex: -1,
        explanation: '',
      );
      expect(provider.hasOpenLessonMistakes, isTrue);

      provider.bindAccount(null);
      expect(provider.hasOpenLessonMistakes, isFalse);
    });

    test('summary rolls up accuracy, mastery, and open mistakes', () async {
      final provider = await _boundProvider(MemoryMasteryRepository());

      provider.syncQuizAttempts([
        _attempt(items: [
          _question(subLessonTitle: 'Distributive Property', correct: false),
          _question(subLessonTitle: 'Combining like terms', correct: true),
          _question(subLessonTitle: 'Combining like terms', correct: true),
        ]),
      ]);

      final summary = provider.summary;
      expect(summary.assessedCount, 2);
      expect(summary.masteredCount, 1);
      expect(summary.overallAccuracy, closeTo(66.67, 0.01));
      expect(summary.needsReviewCount, 1);
    });
  });

  group('Review tabs', () {
    Widget wrap(MasteryProvider provider, Widget child) {
      return ChangeNotifierProvider<MasteryProvider>.value(
        value: provider,
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('PracticeQueueTab shows an empty state with nothing due',
        (tester) async {
      final provider = await _boundProvider(MemoryMasteryRepository(), tester: tester);

      await tester.pumpWidget(wrap(provider, const PracticeQueueTab()));
      await tester.pump();

      expect(find.text('No practice queue yet'), findsOneWidget);
    });

    testWidgets('PracticeQueueTab lists a due concept', (tester) async {
      final provider = await _boundProvider(MemoryMasteryRepository(), tester: tester);
      provider.syncQuizAttempts([
        _attempt(items: [
          _question(subLessonTitle: 'Distributive Property', correct: false),
        ]),
      ]);

      await tester.pumpWidget(wrap(provider, const PracticeQueueTab()));
      await tester.pump();

      expect(find.text('1 concept to practice'), findsOneWidget);
      expect(find.byKey(const Key('concept-tile-m2_l3')), findsOneWidget);
    });

    testWidgets('MasteryTab groups concepts into disjoint bands',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = await _boundProvider(MemoryMasteryRepository(), tester: tester);
      provider.syncQuizAttempts([
        _attempt(items: [
          _question(subLessonTitle: 'Distributive Property', correct: false),
          _question(subLessonTitle: 'Combining like terms', correct: true),
        ]),
      ]);

      await tester.pumpWidget(wrap(provider, const MasteryTab()));
      await tester.pump();

      expect(find.text('Needs work (1)'), findsOneWidget);
      expect(find.text('Mastered (1)'), findsOneWidget);

      // The old page listed the same set twice, so a concept showed up under
      // both "least mastered" and "most mastered". One tile each now.
      expect(find.byKey(const Key('concept-tile-m2_l3')), findsOneWidget);
      expect(find.byKey(const Key('concept-tile-m2_l2')), findsOneWidget);

      // The page states where its numbers come from.
      expect(find.textContaining('last 3 quiz attempts'), findsOneWidget);
    });

    testWidgets('MasteryTab spells out the quiz record in words',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = await _boundProvider(MemoryMasteryRepository(), tester: tester);
      provider.syncQuizAttempts([
        _attempt(items: [
          _question(subLessonTitle: 'Distributive Property', correct: true),
          _question(subLessonTitle: 'Distributive Property', correct: false),
          _question(subLessonTitle: 'Distributive Property', correct: false),
          _question(subLessonTitle: 'Distributive Property', correct: false),
        ]),
      ]);

      await tester.pumpWidget(wrap(provider, const MasteryTab()));
      await tester.pump();

      // Was the cryptic "1/4 quiz".
      expect(find.text('1 of 4 quiz questions right'), findsOneWidget);
    });

    testWidgets('MasteryTab shows an empty state before any evidence',
        (tester) async {
      final provider = await _boundProvider(MemoryMasteryRepository(), tester: tester);

      await tester.pumpWidget(wrap(provider, const MasteryTab()));
      await tester.pump();

      expect(find.text('No mastery data yet'), findsOneWidget);
    });

    testWidgets('LessonMistakesTab renders an open mistake with both answers',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = await _boundProvider(MemoryMasteryRepository(), tester: tester);
      await provider.recordLessonMiss(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        stepId: 'step4',
        stepIndex: 3,
        question: 'Expand 2(x+3)',
        options: const ['2x+6', '2x+3'],
        correctIndex: 0,
        selectedIndex: 1,
        explanation: 'Multiply both terms.',
      );

      await tester.pumpWidget(wrap(provider, const LessonMistakesTab()));
      await tester.pump();

      expect(find.text('Expand 2(x+3)'), findsOneWidget);
      expect(find.text('Correct answer'), findsOneWidget);
      expect(find.text('Your answer'), findsOneWidget);
      expect(find.text('Multiply both terms.'), findsOneWidget);
      expect(find.text('Practice this step'), findsOneWidget);
    });

    testWidgets('LessonMistakesTab flags a repeated mistake', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = await _boundProvider(MemoryMasteryRepository(), tester: tester);
      for (var i = 0; i < 3; i++) {
        await provider.recordLessonMiss(
          moduleId: 'module2',
          lessonId: 'm2_l3',
          stepId: 'step4',
          stepIndex: 3,
          question: 'Expand 2(x+3)',
          options: const ['2x+6', '2x+3'],
          correctIndex: 0,
          selectedIndex: 1,
          explanation: '',
        );
      }

      await tester.pumpWidget(wrap(provider, const LessonMistakesTab()));
      await tester.pump();

      expect(find.text('Missed 3×'), findsOneWidget);
    });

    testWidgets('LessonMistakesTab is empty once mistakes are resolved',
        (tester) async {
      final provider = await _boundProvider(MemoryMasteryRepository(), tester: tester);
      await provider.recordLessonMiss(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        stepId: 'step4',
        stepIndex: 3,
        question: 'Q',
        options: const ['a', 'b'],
        correctIndex: 0,
        selectedIndex: 1,
        explanation: '',
      );
      await provider.recordLessonSuccess(
        moduleId: 'module2',
        lessonId: 'm2_l3',
        stepId: 'step4',
      );

      await tester.pumpWidget(wrap(provider, const LessonMistakesTab()));
      await tester.pump();

      expect(find.text('No open lesson mistakes'), findsOneWidget);
    });
  });
}
