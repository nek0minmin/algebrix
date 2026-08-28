import 'dart:async';

import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/lesson_progress_model.dart';
import 'package:algebrix/screens/lessons/lesson_screen.dart';
import 'package:algebrix/widgets/lesson/content_card.dart';
import 'package:algebrix/widgets/lesson/interactive_choice_grid.dart';
import 'package:algebrix/services/progress_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('wrong answers do not complete the step or award XP', () async {
    final provider = LessonProvider(repository: _FakeProgressRepository());
    provider.bindAccount('user_1');
    await _waitForHydration(provider);
    provider.startModule(module1);
    await provider.startLesson(module1.lessons.first);
    await provider.nextStep();
    await provider.nextStep();
    await provider.nextStep();

    await provider.answerQuestion(false);

    expect(provider.currentStepAnswered, isFalse);
    expect(provider.sessionXp, 0);

    await provider.answerQuestion(true);

    expect(provider.currentStepAnswered, isTrue);
    expect(provider.sessionXp, 10);
  });

  testWidgets('wrong choice remains visible and the learner can retry', (
    tester,
  ) async {
    var isAnswered = false;
    final attempts = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return InteractiveChoiceGrid(
                choices: const [
                  ChoiceOption(label: '3'),
                  ChoiceOption(label: '7', isCorrect: true),
                ],
                isAnswered: isAnswered,
                onAnswered: (index, isCorrect) {
                  attempts.add(isCorrect);
                  if (isCorrect) {
                    setState(() => isAnswered = true);
                  }
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(attempts, [false]);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('7'));
    await tester.pumpAndSettle();

    expect(attempts, [false, true]);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('a pending answer ignores a second immediate tap', (
    tester,
  ) async {
    final pendingAnswer = Completer<void>();
    final attempts = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveChoiceGrid(
            choices: const [
              ChoiceOption(label: '3'),
              ChoiceOption(label: '7', isCorrect: true),
            ],
            isAnswered: false,
            onAnswered: (index, isCorrect) {
              attempts.add(isCorrect);
              return pendingAnswer.future;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('7'));
    await tester.tap(find.text('3'));
    expect(attempts, [true]);

    pendingAnswer.complete();
    await tester.pump();
  });

  testWidgets('Step 1 shows one Xy and the complete topic entrance', (
    tester,
  ) async {
    final provider = LessonProvider(repository: _FakeProgressRepository());
    provider.bindAccount('user_1');
    while (provider.isHydrating) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    provider.startModule(module1);
    await provider.startLesson(module1.lessons.first);

    await tester.pumpWidget(
      ChangeNotifierProvider<LessonProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: const LessonScreen(),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('LESSON 1 · ALGEBRA FOUNDATIONS'), findsOneWidget);
    expect(find.text('Variables'), findsWidgets);
    expect(find.text('Letters that can hold a mystery value.'), findsOneWidget);
    expect(find.text('XY’S CLUE'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(const ValueKey('variables-intro-xy')), findsOneWidget);
  });

  testWidgets('Step 2 variable samples remain circular on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(20),
                  child: ContentCard(
                    title: 'What is a Variable?',
                    body: 'A variable can hold a value.',
                    bulletPoints: ['x', 'y', 'a', 'b', 'n'],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('COMMON VARIABLES'), findsOneWidget);
    final chipFinders = [
      'x',
      'y',
      'a',
      'b',
      'n',
    ].map((letter) => find.byKey(ValueKey('variable-chip-$letter'))).toList();
    final chipCenters = chipFinders.map(tester.getCenter).toList();

    for (final finder in chipFinders) {
      expect(tester.getSize(finder), const Size.square(44));
    }
    expect(chipCenters.map((center) => center.dy).toSet(), hasLength(1));
    for (var index = 1; index < chipCenters.length; index++) {
      expect(chipCenters[index].dx, greaterThan(chipCenters[index - 1].dx));
    }
    expect(tester.takeException(), isNull);
  });
}

Future<void> _waitForHydration(LessonProvider provider) async {
  while (provider.isHydrating) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _FakeProgressRepository implements ProgressRepository {
  int _totalXp = 0;
  final Set<String> _awardedSteps = {};

  @override
  Future<LearningProfileSnapshot> fetchCurrentProfile() async {
    return const LearningProfileSnapshot(
      userId: 'user_1',
      xp: 0,
      level: 1,
      levelTitle: 'Math Beginner',
      streak: 0,
    );
  }

  @override
  Future<List<LessonProgress>> fetchModuleProgress(String moduleId) async => [];

  @override
  Future<RecordLessonStepResult> recordLessonStep({
    required String moduleId,
    required String lessonId,
    required String stepId,
    required int stepIndex,
    bool answerCorrect = false,
    int contentVersion = 1,
  }) async {
    final eventKey = '$lessonId:$stepId';
    final xpAwarded = answerCorrect && _awardedSteps.add(eventKey) ? 10 : 0;
    _totalXp += xpAwarded;
    return RecordLessonStepResult(
      progress: LessonProgress(
        userId: 'user_1',
        moduleId: moduleId,
        lessonId: lessonId,
        contentVersion: contentVersion,
        lastStepId: stepId,
        lastStepIndex: stepIndex,
        status: LessonProgressStatus.inProgress,
        startedAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      xpAwarded: xpAwarded,
      stepXpAwarded: xpAwarded,
      completionXpAwarded: 0,
      totalXp: _totalXp,
      level: 1,
      levelTitle: 'Math Beginner',
      completionRequirementsMet: false,
    );
  }
}
