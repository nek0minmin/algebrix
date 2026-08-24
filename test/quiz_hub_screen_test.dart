import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/core/providers/quiz_provider.dart';
import 'package:algebrix/models/lesson_progress_model.dart';
import 'package:algebrix/screens/quiz/quiz_hub_screen.dart';
import 'package:algebrix/services/progress_repository.dart';
import 'package:algebrix/services/quiz_repository.dart';

class _FakeProgressRepository implements ProgressRepository {
  @override
  Future<LearningProfileSnapshot> fetchCurrentProfile() async {
    return const LearningProfileSnapshot(
      userId: 'student_1',
      xp: 0,
      level: 1,
      levelTitle: 'Math Beginner',
      streak: 1,
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
    final progress = LessonProgress(
      userId: 'student_1',
      moduleId: moduleId,
      lessonId: lessonId,
      contentVersion: 1,
      status: LessonProgressStatus.completed,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastStepIndex: stepIndex,
    );
    return RecordLessonStepResult(
      progress: progress,
      xpAwarded: 0,
      stepXpAwarded: 0,
      completionXpAwarded: 0,
      totalXp: 0,
      level: 1,
      levelTitle: 'Math Beginner',
      completionRequirementsMet: true,
    );
  }
}

void main() {
  testWidgets('QuizHubScreen renders performance analytics and module quiz cards', (tester) async {
    final quizRepo = MemoryQuizRepository();
    final progressRepo = _FakeProgressRepository();

    final quizProvider = QuizProvider(repository: quizRepo);
    final lessonProvider = LessonProvider(repository: progressRepo);

    quizProvider.bindAccount('student_1');
    lessonProvider.bindAccount('student_1');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: quizProvider),
          ChangeNotifierProvider.value(value: lessonProvider),
        ],
        child: const MaterialApp(
          home: QuizHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Header and Analytics
    expect(find.text('Quizzes & Mastery'), findsOneWidget);
    expect(find.text('Your Performance'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.text('Quizzes Passed'), findsOneWidget);
    expect(find.text('Attempts'), findsOneWidget);

    // Verify Module Quiz Cards
    expect(find.text('MODULE 1 QUIZ'), findsOneWidget);
    expect(find.text('Welcome to Algebra!'), findsOneWidget);
    expect(find.text('MODULE 2 QUIZ'), findsOneWidget);

    // Module 1 is locked because 0/6 lessons are completed
    expect(find.text('Complete all 6 Module 1 lessons'), findsOneWidget);
    expect(find.text('Tap to view lessons (0/6)'), findsOneWidget);

    // Expand analytics breakdown
    expect(find.text('View Detailed Breakdown'), findsOneWidget);
    await tester.tap(find.text('View Detailed Breakdown'));
    await tester.pumpAndSettle();

    expect(find.text('Hide Detailed Breakdown'), findsOneWidget);
    expect(find.text('Total Plays'), findsOneWidget);
    expect(find.text('Passes'), findsOneWidget);
    expect(find.text('Retries / Fails'), findsOneWidget);
  });
}
