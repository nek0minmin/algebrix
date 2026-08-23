import 'dart:async';

import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/lesson_progress_model.dart';
import 'package:algebrix/services/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'account changes clear state and hydrate only the active account',
    () async {
      var profile = _profile('user_1', xp: 120);
      var progress = [_progress('user_1', stepIndex: 6, completed: true)];
      final repository = _ScriptedRepository(
        fetchProfile: () async => profile,
        fetchProgress: (_) async => progress,
        record: _defaultRecord,
      );
      final provider = LessonProvider(repository: repository);

      provider.bindAccount('user_1');
      await _waitForHydration(provider);
      expect(provider.profile?.xp, 120);
      expect(provider.isLessonCompleted('m1_l1'), isTrue);

      profile = _profile('user_2', xp: 7);
      progress = [];
      provider.bindAccount('user_2');
      expect(provider.profile, isNull);
      expect(provider.completedLessonIds, isEmpty);
      expect(provider.sessionXp, 0);

      await _waitForHydration(provider);
      expect(provider.profile?.userId, 'user_2');
      expect(provider.profile?.xp, 7);

      provider.bindAccount(null);
      expect(provider.profile, isNull);
      expect(provider.completedLessonIds, isEmpty);
    },
  );

  test('late hydration results cannot overwrite a newer account', () async {
    final oldProfile = Completer<LearningProfileSnapshot>();
    final oldProgress = Completer<List<LessonProgress>>();
    var profileCalls = 0;
    var progressCalls = 0;
    final repository = _ScriptedRepository(
      fetchProfile: () {
        profileCalls++;
        return profileCalls == 1
            ? oldProfile.future
            : Future.value(_profile('user_2', xp: 22));
      },
      fetchProgress: (_) {
        progressCalls++;
        return progressCalls == 1 ? oldProgress.future : Future.value([]);
      },
      record: _defaultRecord,
    );
    final provider = LessonProvider(repository: repository);

    provider.bindAccount('user_1');
    provider.bindAccount('user_2');
    await _waitForHydration(provider);
    expect(provider.profile?.userId, 'user_2');

    oldProfile.complete(_profile('user_1', xp: 999));
    oldProgress.complete([_progress('user_1', stepIndex: 6, completed: true)]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.profile?.userId, 'user_2');
    expect(provider.profile?.xp, 22);
    expect(provider.completedLessonIds, isEmpty);
  });

  test('account changes and logout clear the prior hydration error', () async {
    var shouldFail = true;
    var activeUser = 'user_1';
    final repository = _ScriptedRepository(
      fetchProfile: () async {
        if (shouldFail) throw Exception('Profile unavailable.');
        return _profile(activeUser);
      },
      fetchProgress: (_) async => [],
      record: _defaultRecord,
    );
    final provider = LessonProvider(repository: repository);

    provider.bindAccount('user_1');
    await _waitForHydration(provider);
    expect(provider.hydrationError, contains('Profile unavailable'));

    shouldFail = false;
    activeUser = 'user_2';
    provider.bindAccount('user_2');
    expect(provider.hydrationError, isNull);
    await _waitForHydration(provider);
    expect(provider.profile?.userId, 'user_2');

    shouldFail = true;
    provider.bindAccount('user_3');
    await _waitForHydration(provider);
    expect(provider.hydrationError, isNotNull);

    provider.bindAccount(null);
    expect(provider.hydrationError, isNull);
    expect(provider.profile, isNull);
  });

  test('resume index is clamped to current lesson content', () async {
    final repository = _ScriptedRepository(
      fetchProfile: () async => _profile('user_1'),
      fetchProgress: (_) async => [_progress('user_1', stepIndex: 99)],
      record: _defaultRecord,
    );
    final provider = LessonProvider(repository: repository);
    provider.bindAccount('user_1');
    await _waitForHydration(provider);
    provider.startModule(module1);

    expect(await provider.startLesson(module1.lessons.first), isTrue);
    expect(provider.currentStepIndex, module1.lessons.first.steps.length - 1);
    expect(provider.currentStep?.id, 'step7');
  });

  test('dashboard resume exposes the saved lesson and progress', () async {
    final repository = _ScriptedRepository(
      fetchProfile: () async => _profile('user_1'),
      fetchProgress: (_) async => [_progress('user_1', stepIndex: 3)],
      record: _defaultRecord,
    );
    final provider = LessonProvider(repository: repository);
    provider.bindAccount('user_1');
    await _waitForHydration(provider);

    final lesson = provider.latestResumableLesson(module1);
    expect(lesson?.lessonId, 'm1_l1');
    expect(provider.progressForLesson('m1_l1')?.lastStepIndex, 3);
    expect(provider.progressFractionForLesson(lesson!), 4 / 7);
  });

  test('correct answer XP is authoritative and idempotent', () async {
    final calls = <_RecordCall>[];
    var totalXp = 100;
    var awarded = false;
    final repository = _ScriptedRepository(
      fetchProfile: () async => _profile('user_1', xp: totalXp),
      fetchProgress: (_) async => [_progress('user_1', stepIndex: 3)],
      record: (call) async {
        calls.add(call);
        final xp = call.answerCorrect && !awarded ? 10 : 0;
        if (call.answerCorrect) awarded = true;
        totalXp += xp;
        return _result(call, xpAwarded: xp, totalXp: totalXp);
      },
    );
    final provider = LessonProvider(repository: repository);
    provider.bindAccount('user_1');
    await _waitForHydration(provider);
    provider.startModule(module1);
    await provider.startLesson(module1.lessons.first);

    expect(await provider.answerQuestion(true), 10);
    expect(await provider.answerQuestion(true), 0);
    expect(provider.sessionXp, 10);
    expect(provider.profile?.xp, 110);
    expect(calls.where((call) => call.answerCorrect).single.stepId, 'step4');
  });

  test('explicit scoring metadata supports globally unique step IDs', () async {
    final calls = <_RecordCall>[];
    final repository = _ScriptedRepository(
      fetchProfile: () async => _profile('user_1'),
      fetchProgress: (_) async => [],
      record: (call) async {
        calls.add(call);
        return _result(call, xpAwarded: call.answerCorrect ? 10 : 0);
      },
    );
    final provider = LessonProvider(repository: repository);
    const lesson = LessonContent(
      lessonId: 'm1_l2',
      title: 'Constants',
      moduleId: 'module1',
      moduleTitle: 'Algebra Foundations',
      objective: 'Identify constants.',
      xyAsset: '',
      steps: [
        LessonStep(
          id: 'm1_l2_s05',
          type: LessonStepType.activity,
          isAnswerStep: true,
        ),
      ],
    );

    provider.bindAccount('user_1');
    await _waitForHydration(provider);
    provider.startModule(module1);
    expect(await provider.startLesson(lesson), isTrue);
    expect(await provider.answerQuestion(true), 10);

    expect(calls.last.stepId, 'm1_l2_s05');
    expect(calls.last.answerCorrect, isTrue);
  });

  test('record failures remain retryable without advancing', () async {
    var shouldFail = true;
    final repository = _ScriptedRepository(
      fetchProfile: () async => _profile('user_1'),
      fetchProgress: (_) async => [],
      record: (call) async {
        if (shouldFail) throw Exception('Network unavailable.');
        return _result(call);
      },
    );
    final provider = LessonProvider(repository: repository);
    provider.bindAccount('user_1');
    await _waitForHydration(provider);
    provider.startModule(module1);

    expect(await provider.startLesson(module1.lessons.first), isFalse);
    expect(provider.currentStepIndex, 0);
    expect(provider.errorMessage, contains('Network unavailable'));

    shouldFail = false;
    expect(await provider.startLesson(module1.lessons.first), isTrue);
    expect(provider.errorMessage, isNull);
  });

  test(
    'final navigation is gated by authoritative completion result',
    () async {
      var completionAllowed = false;
      var totalXp = 0;
      final repository = _ScriptedRepository(
        fetchProfile: () async => _profile('user_1'),
        fetchProgress: (_) async => [_progress('user_1', stepIndex: 6)],
        record: (call) async {
          final completes = call.stepId == 'step7' && completionAllowed;
          final xp = completes ? 25 : 0;
          totalXp += xp;
          return _result(
            call,
            xpAwarded: xp,
            totalXp: totalXp,
            completed: completes,
            requirementsMet: completes,
          );
        },
      );
      final provider = LessonProvider(repository: repository);
      provider.bindAccount('user_1');
      await _waitForHydration(provider);
      provider.startModule(module1);
      await provider.startLesson(module1.lessons.first);

      expect(await provider.completeLesson(), isFalse);
      expect(provider.isLessonCompleted('m1_l1'), isFalse);
      expect(provider.sessionXp, 0);

      completionAllowed = true;
      expect(await provider.completeLesson(), isTrue);
      expect(provider.isLessonCompleted('m1_l1'), isTrue);
      expect(provider.sessionXp, 25);
      expect(provider.profile?.xp, 25);
    },
  );

  test(
    'revisiting a completed lesson starts at step 0 and does not award repeat XP',
    () async {
      final repository = _ScriptedRepository(
        fetchProfile: () async => _profile('user_1', xp: 50),
        fetchProgress: (_) async => [
          _progress('user_1', stepIndex: 6, completed: true),
        ],
        record: (call) async => _result(call, totalXp: 50),
      );
      final provider = LessonProvider(repository: repository);
      provider.bindAccount('user_1');
      await _waitForHydration(provider);
      provider.startModule(module1);

      expect(provider.isLessonCompleted('m1_l1'), isTrue);

      // Starting the completed lesson must start at step 0 (first page)
      expect(await provider.startLesson(module1.lessons.first), isTrue);
      expect(provider.currentStepIndex, 0);

      // Answering questions within completed lesson awards 0 XP
      final xpAwarded = await provider.answerQuestion(true);
      expect(xpAwarded, 0);
      expect(provider.sessionXp, 0);
      expect(provider.profile?.xp, 50);
    },
  );
}

class _RecordCall {
  const _RecordCall({
    required this.moduleId,
    required this.lessonId,
    required this.stepId,
    required this.stepIndex,
    required this.answerCorrect,
    required this.contentVersion,
  });

  final String moduleId;
  final String lessonId;
  final String stepId;
  final int stepIndex;
  final bool answerCorrect;
  final int contentVersion;
}

class _ScriptedRepository implements ProgressRepository {
  _ScriptedRepository({
    required this.fetchProfile,
    required this.fetchProgress,
    required this.record,
  });

  final Future<LearningProfileSnapshot> Function() fetchProfile;
  final Future<List<LessonProgress>> Function(String moduleId) fetchProgress;
  final Future<RecordLessonStepResult> Function(_RecordCall call) record;

  @override
  Future<LearningProfileSnapshot> fetchCurrentProfile() => fetchProfile();

  @override
  Future<List<LessonProgress>> fetchModuleProgress(String moduleId) =>
      fetchProgress(moduleId);

  @override
  Future<RecordLessonStepResult> recordLessonStep({
    required String moduleId,
    required String lessonId,
    required String stepId,
    required int stepIndex,
    bool answerCorrect = false,
    int contentVersion = 1,
  }) => record(
    _RecordCall(
      moduleId: moduleId,
      lessonId: lessonId,
      stepId: stepId,
      stepIndex: stepIndex,
      answerCorrect: answerCorrect,
      contentVersion: contentVersion,
    ),
  );
}

LearningProfileSnapshot _profile(String userId, {int xp = 0}) {
  return LearningProfileSnapshot(
    userId: userId,
    xp: xp,
    level: 1,
    levelTitle: 'Math Beginner',
    streak: 3,
  );
}

LessonProgress _progress(
  String userId, {
  required int stepIndex,
  bool completed = false,
}) {
  return LessonProgress(
    userId: userId,
    moduleId: module1.id,
    lessonId: module1.lessons.first.lessonId,
    contentVersion: 1,
    lastStepId: 'step${stepIndex + 1}',
    lastStepIndex: stepIndex,
    status: completed
        ? LessonProgressStatus.completed
        : LessonProgressStatus.inProgress,
    startedAt: DateTime(2026),
    updatedAt: DateTime(2026),
    completedAt: completed ? DateTime(2026) : null,
  );
}

Future<RecordLessonStepResult> _defaultRecord(_RecordCall call) async =>
    _result(call);

RecordLessonStepResult _result(
  _RecordCall call, {
  int xpAwarded = 0,
  int totalXp = 0,
  bool completed = false,
  bool requirementsMet = false,
}) {
  return RecordLessonStepResult(
    progress: LessonProgress(
      userId: 'user_1',
      moduleId: call.moduleId,
      lessonId: call.lessonId,
      contentVersion: call.contentVersion,
      lastStepId: call.stepId,
      lastStepIndex: call.stepIndex,
      status: completed
          ? LessonProgressStatus.completed
          : LessonProgressStatus.inProgress,
      startedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      completedAt: completed ? DateTime(2026) : null,
    ),
    xpAwarded: xpAwarded,
    stepXpAwarded: completed ? 0 : xpAwarded,
    completionXpAwarded: completed ? xpAwarded : 0,
    totalXp: totalXp,
    level: 1,
    levelTitle: 'Math Beginner',
    completionRequirementsMet: requirementsMet,
  );
}

Future<void> _waitForHydration(LessonProvider provider) async {
  while (provider.isHydrating) {
    await Future<void>.delayed(Duration.zero);
  }
}
