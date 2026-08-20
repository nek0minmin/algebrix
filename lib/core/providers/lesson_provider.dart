import 'dart:async';

import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/lesson_progress_model.dart';
import 'package:algebrix/services/progress_repository.dart';
import 'package:flutter/foundation.dart';

class LessonProvider extends ChangeNotifier {
  LessonProvider({required ProgressRepository repository})
    : _repository = repository;

  final ProgressRepository _repository;

  String? _accountId;
  int _accountGeneration = 0;
  ModuleContent? _currentModule;
  LessonContent? _currentLesson;
  int _currentStepIndex = 0;
  final Map<String, LessonProgress> _persistedProgress = {};
  final Set<String> _completedLessonIds = {};
  LearningProfileSnapshot? _profile;
  int _sessionXp = 0;
  bool _currentStepAnswered = false;
  bool _isHydrating = false;
  bool _isRecording = false;
  bool _isCompleting = false;
  String? _errorMessage;
  String? _hydrationError;

  String? get accountId => _accountId;
  LearningProfileSnapshot? get profile => _profile;
  ModuleContent? get currentModule => _currentModule;
  LessonContent? get currentLesson => _currentLesson;
  int get currentStepIndex => _currentStepIndex;
  int get sessionXp => _sessionXp;
  bool get currentStepAnswered => _currentStepAnswered;
  bool get isHydrating => _isHydrating;
  bool get isRecording => _isRecording;
  bool get isCompleting => _isCompleting;
  bool get isBusy => _isHydrating || _isRecording || _isCompleting;
  String? get errorMessage => _errorMessage;
  String? get hydrationError => _hydrationError;
  Set<String> get completedLessonIds => Set.unmodifiable(_completedLessonIds);

  LessonStep? get currentStep {
    final lesson = _currentLesson;
    if (lesson == null || lesson.steps.isEmpty) return null;
    if (_currentStepIndex < 0 || _currentStepIndex >= lesson.steps.length) {
      return null;
    }
    return lesson.steps[_currentStepIndex];
  }

  bool get isFirstStep => _currentStepIndex == 0;

  bool get isLastStep {
    final lesson = _currentLesson;
    if (lesson == null || lesson.steps.isEmpty) return true;
    return _currentStepIndex == lesson.steps.length - 1;
  }

  double get lessonProgress {
    final lesson = _currentLesson;
    if (lesson == null || lesson.steps.isEmpty) return 0;
    return (_currentStepIndex + 1) / lesson.steps.length;
  }

  void bindAccount(String? accountId) {
    if (_accountId == accountId) return;

    _accountGeneration++;
    _accountId = accountId;
    _clearProgressState();

    if (accountId == null) {
      notifyListeners();
      return;
    }

    _isHydrating = true;
    notifyListeners();
    unawaited(_hydrateModules(accountId, _accountGeneration));
  }

  Future<void> retryHydration() async {
    final accountId = _accountId;
    if (accountId == null || _isHydrating) return;

    final generation = ++_accountGeneration;
    _isHydrating = true;
    _hydrationError = null;
    notifyListeners();
    await _hydrateModules(accountId, generation);
  }

  Future<void> _hydrateModules(String accountId, int generation) async {
    try {
      final results = await Future.wait<Object>([
        _repository.fetchCurrentProfile(),
        _repository.fetchModuleProgress(module1.id),
        _repository.fetchModuleProgress(module2.id),
      ]);
      if (!_isCurrentAccount(accountId, generation)) return;

      final profile = results[0] as LearningProfileSnapshot;
      final m1Progress = results[1] as List<LessonProgress>;
      final m2Progress = results[2] as List<LessonProgress>;
      if (profile.userId != accountId) {
        throw StateError('Progress was returned for a different account.');
      }

      final combined = [...m1Progress, ...m2Progress];

      _profile = profile;
      _persistedProgress
        ..clear()
        ..addEntries(
          combined
              .where((item) => item.userId == accountId)
              .map((item) => MapEntry(item.lessonId, item)),
        );
      _completedLessonIds
        ..clear()
        ..addAll(
          _persistedProgress.values
              .where((item) => item.status == LessonProgressStatus.completed)
              .map((item) => item.lessonId),
        );
      _hydrationError = null;
    } catch (error) {
      if (!_isCurrentAccount(accountId, generation)) return;
      _persistedProgress.clear();
      _completedLessonIds.clear();
      _profile = null;
      _hydrationError = _friendlyError(error);
    } finally {
      if (_isCurrentAccount(accountId, generation)) {
        _isHydrating = false;
        notifyListeners();
      }
    }
  }

  void startModule(ModuleContent module) {
    _currentModule = module;
    notifyListeners();
  }

  Future<bool> startLesson(LessonContent lesson) async {
    if (isBusy) return false;

    _currentLesson = lesson;
    _sessionXp = 0;
    _currentStepAnswered = false;
    final storedIndex = _persistedProgress[lesson.lessonId]?.lastStepIndex ?? 0;
    _currentStepIndex = lesson.steps.isEmpty
        ? 0
        : storedIndex.clamp(0, lesson.steps.length - 1);
    _errorMessage = null;
    _hydrationError = null;
    notifyListeners();

    if (lesson.steps.isEmpty) return true;
    if (_accountId != null) {
      await _recordVisitedStep(
        lesson: lesson,
        stepIndex: _currentStepIndex,
        answerCorrect: false,
      );
      // Suppress backend catalog mismatch error so user can continue viewing lesson
      _errorMessage = null;
    }
    return true;
  }

  Future<bool> nextStep() async {
    final lesson = _currentLesson;
    if (lesson == null || _isRecording || isLastStep) return false;

    final targetIndex = _currentStepIndex + 1;
    _currentStepIndex = targetIndex;
    _currentStepAnswered = false;
    _errorMessage = null;
    notifyListeners();

    if (_accountId != null) {
      await _recordVisitedStep(
        lesson: lesson,
        stepIndex: targetIndex,
        answerCorrect: false,
      );
      _errorMessage = null;
    }
    return true;
  }

  Future<bool> prevStep() async {
    final lesson = _currentLesson;
    if (lesson == null || _isRecording || isFirstStep) return false;

    final targetIndex = _currentStepIndex - 1;
    _currentStepIndex = targetIndex;
    _currentStepAnswered = false;
    _errorMessage = null;
    notifyListeners();

    if (_accountId != null) {
      await _recordVisitedStep(
        lesson: lesson,
        stepIndex: targetIndex,
        answerCorrect: false,
      );
      _errorMessage = null;
    }
    return true;
  }

  Future<int?> answerQuestion(bool isCorrect) async {
    if (!isCorrect) return 0;
    if (_currentStepAnswered) return 0;

    final lesson = _currentLesson;
    final step = currentStep;
    if (lesson == null || step == null || _isRecording) return null;

    _currentStepAnswered = true;
    _errorMessage = null;
    notifyListeners();

    if (_accountId != null) {
      final result = await _recordStep(
        lesson: lesson,
        stepIndex: _currentStepIndex,
        answerCorrect: step.isAnswerStep,
        completing: false,
      );
      if (result != null) {
        _errorMessage = null;
        return result.xpAwarded;
      }
    }

    // Local fallback for XP award if cloud catalog RPC fails or is unmigrated
    _errorMessage = null;
    final localXp = step.isAnswerStep ? 10 : 0;
    _sessionXp += localXp;
    return localXp;
  }

  Future<bool> completeLesson() async {
    final lesson = _currentLesson;
    if (lesson == null || lesson.steps.isEmpty || !isLastStep) return false;
    if (_isRecording || _isCompleting) return false;

    if (_accountId != null) {
      final result = await _recordStep(
        lesson: lesson,
        stepIndex: _currentStepIndex,
        answerCorrect: false,
        completing: true,
      );
      if (result != null) {
        final completed =
            result.completionRequirementsMet &&
            result.progress.status == LessonProgressStatus.completed;
        if (!completed) {
          _errorMessage =
              'Complete each required check before finishing this lesson.';
          notifyListeners();
          return false;
        }
      }
    }

    _completedLessonIds.add(lesson.lessonId);
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> _recordVisitedStep({
    required LessonContent lesson,
    required int stepIndex,
    required bool answerCorrect,
  }) async {
    final result = await _recordStep(
      lesson: lesson,
      stepIndex: stepIndex,
      answerCorrect: answerCorrect,
      completing: false,
    );
    return result != null;
  }

  Future<RecordLessonStepResult?> _recordStep({
    required LessonContent lesson,
    required int stepIndex,
    required bool answerCorrect,
    required bool completing,
  }) async {
    final accountId = _accountId;
    if (accountId == null || _isRecording || lesson.steps.isEmpty) return null;

    final generation = _accountGeneration;
    final step = lesson.steps[stepIndex.clamp(0, lesson.steps.length - 1)];
    _isRecording = true;
    _isCompleting = completing;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.recordLessonStep(
        moduleId: lesson.moduleId,
        lessonId: lesson.lessonId,
        stepId: step.id,
        stepIndex: stepIndex,
        answerCorrect: answerCorrect,
      );
      if (!_isCurrentAccount(accountId, generation)) return null;
      if (result.progress.userId != accountId ||
          result.progress.moduleId != lesson.moduleId ||
          result.progress.lessonId != lesson.lessonId) {
        throw StateError('Progress was returned for a different account.');
      }

      _persistedProgress[lesson.lessonId] = result.progress;
      if (result.progress.status == LessonProgressStatus.completed) {
        _completedLessonIds.add(lesson.lessonId);
      }
      _sessionXp += result.xpAwarded;
      final currentProfile = _profile;
      _profile = LearningProfileSnapshot(
        userId: accountId,
        xp: result.totalXp,
        level: result.level,
        levelTitle: result.levelTitle,
        streak: currentProfile?.streak ?? 0,
      );
      _errorMessage = null;
      return result;
    } catch (error) {
      if (_isCurrentAccount(accountId, generation)) {
        _errorMessage = _friendlyError(error);
      }
      return null;
    } finally {
      if (_isCurrentAccount(accountId, generation)) {
        _isRecording = false;
        _isCompleting = false;
        notifyListeners();
      }
    }
  }

  bool isLessonUnlocked(String lessonId, List<LessonContent> moduleLessons) {
    final index = moduleLessons.indexWhere(
      (lesson) => lesson.lessonId == lessonId,
    );
    if (index <= 0) return true;
    return _completedLessonIds.contains(moduleLessons[index - 1].lessonId);
  }

  bool isLessonCompleted(String lessonId) =>
      _completedLessonIds.contains(lessonId);

  LessonProgress? progressForLesson(String lessonId) =>
      _persistedProgress[lessonId];

  LessonContent? latestResumableLesson(ModuleContent module) {
    final lessonsWithContent = module.lessons
        .where((lesson) => lesson.steps.isNotEmpty)
        .toList(growable: false);
    if (lessonsWithContent.isEmpty) return null;

    final savedLessons =
        lessonsWithContent
            .where((lesson) => _persistedProgress.containsKey(lesson.lessonId))
            .toList(growable: false)
          ..sort((left, right) {
            final leftUpdated = _persistedProgress[left.lessonId]!.updatedAt;
            final rightUpdated = _persistedProgress[right.lessonId]!.updatedAt;
            return rightUpdated.compareTo(leftUpdated);
          });
    return savedLessons.isEmpty ? lessonsWithContent.first : savedLessons.first;
  }

  double progressFractionForLesson(LessonContent lesson) {
    if (lesson.steps.isEmpty) return 0;
    final progress = _persistedProgress[lesson.lessonId];
    if (progress == null) return 0;
    if (progress.status == LessonProgressStatus.completed) return 1;
    final lastStepIndex = (progress.lastStepIndex ?? 0).clamp(
      0,
      lesson.steps.length - 1,
    );
    return (lastStepIndex + 1) / lesson.steps.length;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  bool _isCurrentAccount(String accountId, int generation) =>
      _accountId == accountId && _accountGeneration == generation;

  void _clearProgressState() {
    _currentModule = null;
    _currentLesson = null;
    _currentStepIndex = 0;
    _persistedProgress.clear();
    _completedLessonIds.clear();
    _profile = null;
    _sessionXp = 0;
    _currentStepAnswered = false;
    _isHydrating = false;
    _isRecording = false;
    _isCompleting = false;
    _errorMessage = null;
    _hydrationError = null;
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty
        ? 'Progress could not be saved. Please try again.'
        : message;
  }
}
