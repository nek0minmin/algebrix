import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/core/providers/quiz_provider.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';
import 'package:algebrix/models/lesson_progress_model.dart';
import 'package:algebrix/services/progress_repository.dart';
import 'package:algebrix/services/quiz_repository.dart';

class _FakeProgressRepository implements ProgressRepository {
  final Map<String, List<LessonProgress>> _progress = {};

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
  Future<List<LessonProgress>> fetchModuleProgress(String moduleId) async {
    return _progress[moduleId] ?? [];
  }

  @override
  Future<RecordLessonStepResult> recordLessonStep({
    required String moduleId,
    required String lessonId,
    required String stepId,
    required int stepIndex,
    bool answerCorrect = false,
    int contentVersion = 1,
  }) async {
    final list = _progress.putIfAbsent(moduleId, () => []);
    final existingIndex = list.indexWhere((l) => l.lessonId == lessonId);
    final isLastStep = stepId == 'step_final' || stepIndex >= 5;

    final progress = LessonProgress(
      userId: 'student_1',
      moduleId: moduleId,
      lessonId: lessonId,
      contentVersion: 1,
      status: isLastStep ? LessonProgressStatus.completed : LessonProgressStatus.inProgress,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastStepIndex: stepIndex,
      completedAt: isLastStep ? DateTime.now() : null,
    );

    if (existingIndex >= 0) {
      list[existingIndex] = progress;
    } else {
      list.add(progress);
    }

    return RecordLessonStepResult(
      progress: progress,
      xpAwarded: 0,
      stepXpAwarded: 0,
      completionXpAwarded: 0,
      totalXp: 0,
      level: 1,
      levelTitle: 'Math Beginner',
      completionRequirementsMet: isLastStep,
    );
  }
}

void main() {
  group('Module & Quiz Progression Unit Tests', () {
    late _FakeProgressRepository progressRepo;
    late MemoryQuizRepository quizRepo;
    late LessonProvider lessonProvider;
    late QuizProvider quizProvider;

    setUp(() async {
      progressRepo = _FakeProgressRepository();
      quizRepo = MemoryQuizRepository();
      lessonProvider = LessonProvider(repository: progressRepo);
      quizProvider = QuizProvider(repository: quizRepo);

      lessonProvider.bindAccount('student_1');
      quizProvider.bindAccount('student_1');

      while (lessonProvider.isHydrating || quizProvider.isLoading) {
        await Future<void>.delayed(Duration.zero);
      }
    });

    test('new account starts with only Module 1 Lesson 1 unlocked', () {
      // Module 1 is unlocked by default
      expect(quizProvider.isModuleUnlocked('module1'), isTrue);

      // Lesson 1 is unlocked initially
      expect(
        lessonProvider.isLessonUnlocked(module1.lessons[0].lessonId, module1.lessons),
        isTrue,
      );

      // Subsequent lessons (L2 - L6) are locked initially
      for (int i = 1; i < module1.lessons.length; i++) {
        expect(
          lessonProvider.isLessonUnlocked(module1.lessons[i].lessonId, module1.lessons),
          isFalse,
          reason: 'Lesson ${module1.lessons[i].lessonId} should be locked initially',
        );
      }
    });

    test('Module 1 Quiz is locked until all Module 1 lessons are completed', () async {
      // Incomplete state
      expect(lessonProvider.isModuleCompleted('module1'), isFalse);
      expect(quizProvider.isQuizUnlocked('module1', lessonProvider), isFalse);

      // Complete lessons 1 to 5
      for (int i = 0; i < 5; i++) {
        await progressRepo.recordLessonStep(
          moduleId: 'module1',
          lessonId: module1.lessons[i].lessonId,
          stepId: 'step_final',
          stepIndex: 5,
        );
      }
      await lessonProvider.retryHydration();

      expect(lessonProvider.completedLessonsInModule('module1'), 5);
      expect(lessonProvider.isModuleCompleted('module1'), isFalse);
      expect(quizProvider.isQuizUnlocked('module1', lessonProvider), isFalse);

      // Complete 6th lesson
      await progressRepo.recordLessonStep(
        moduleId: 'module1',
        lessonId: module1.lessons[5].lessonId,
        stepId: 'step_final',
        stepIndex: 5,
      );
      await lessonProvider.retryHydration();

      expect(lessonProvider.completedLessonsInModule('module1'), 6);
      expect(lessonProvider.isModuleCompleted('module1'), isTrue);
      expect(quizProvider.isQuizUnlocked('module1', lessonProvider), isTrue);
    });

    test('Module 2 remains locked if student scores under 60% on Module 1 Quiz', () async {
      // Initial state
      expect(quizProvider.isModuleUnlocked('module2'), isFalse);

      // Score 5/10 (50.0% < 60%)
      final result = await quizProvider.recordQuizResult(
        moduleId: 'module1',
        score: 5,
        totalQuestions: 10,
      );

      expect(result.highScore, 5);
      expect(result.bestPercentage, 50.0);
      expect(result.passed, isFalse);
      expect(quizProvider.isModuleQuizPassed('module1'), isFalse);
      expect(quizProvider.isModuleUnlocked('module2'), isFalse);
    });

    test('Module 2 unlocks when student scores at least 60% on Module 1 Quiz', () async {
      // Score 6/10 (60.0%)
      final result = await quizProvider.recordQuizResult(
        moduleId: 'module1',
        score: 6,
        totalQuestions: 10,
      );

      expect(result.highScore, 6);
      expect(result.bestPercentage, 60.0);
      expect(result.passed, isTrue);
      expect(quizProvider.isModuleQuizPassed('module1'), isTrue);
      expect(quizProvider.isModuleUnlocked('module2'), isTrue);
    });

    test('High scores and attempts are properly managed and updated', () async {
      // Attempt 1: 5/10
      await quizProvider.recordQuizResult(
        moduleId: 'module1',
        score: 5,
        totalQuestions: 10,
      );
      var progress = quizProvider.getQuizProgress('module1');
      expect(progress.highScore, 5);
      expect(progress.attemptsCount, 1);
      expect(progress.passed, isFalse);

      // Attempt 2: 8/10 (higher score)
      await quizProvider.recordQuizResult(
        moduleId: 'module1',
        score: 8,
        totalQuestions: 10,
      );
      progress = quizProvider.getQuizProgress('module1');
      expect(progress.highScore, 8);
      expect(progress.bestPercentage, 80.0);
      expect(progress.attemptsCount, 2);
      expect(progress.passed, isTrue);
      expect(progress.starRating, 3);

      // Attempt 3: 6/10 (lower score does not reduce high score)
      await quizProvider.recordQuizResult(
        moduleId: 'module1',
        score: 6,
        totalQuestions: 10,
      );
      progress = quizProvider.getQuizProgress('module1');
      expect(progress.highScore, 8); // Kept 8
      expect(progress.bestPercentage, 80.0);
      expect(progress.lastScore, 6);
      expect(progress.attemptsCount, 3);
      expect(progress.passed, isTrue);
    });

    test('Analytics summary calculates accurate aggregated metrics', () async {
      await quizProvider.recordQuizResult(
        moduleId: 'module1',
        score: 8,
        totalQuestions: 10,
      );
      await quizProvider.recordQuizResult(
        moduleId: 'module2',
        score: 10,
        totalQuestions: 10,
      );

      final summary = quizProvider.analytics;
      expect(summary.totalQuizzesAttempted, 2);
      expect(summary.totalQuizzesPassed, 2);
      expect(summary.totalQuestionsAnswered, 20);
      expect(summary.totalCorrectAnswers, 18);
      expect(summary.overallAccuracyPercentage, 90.0);
      expect(summary.masteryLevel, 'Algebra Master');
    });
  });
}
