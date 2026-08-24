import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/models/module_quiz_progress_model.dart';
import 'package:algebrix/services/quiz_repository.dart';

/// State management for Module Quizzes progression, high score tracking,
/// module lock prerequisites (60% mark on Quiz 1 to unlock Module 2),
/// and overall performance analytics.
class QuizProvider extends ChangeNotifier {
  QuizProvider({required QuizRepository repository})
      : _repository = repository;

  final QuizRepository _repository;

  String? _accountId;
  int _accountGeneration = 0;
  final Map<String, ModuleQuizProgress> _progressMap = {};
  bool _isLoading = false;
  String? _errorMessage;

  String? get accountId => _accountId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, ModuleQuizProgress> get progressMap =>
      Map.unmodifiable(_progressMap);

  /// Binds the provider to an authenticated account.
  void bindAccount(String? accountId) {
    if (_accountId == accountId) return;

    _accountGeneration++;
    _accountId = accountId;
    _progressMap.clear();
    _errorMessage = null;

    if (accountId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    unawaited(_hydrateQuizProgress(accountId, _accountGeneration));
  }

  /// Hydrates all module quiz progress for the active user.
  Future<void> _hydrateQuizProgress(String accountId, int generation) async {
    try {
      final list = await _repository.fetchAllQuizProgress();
      if (_accountId != accountId || _accountGeneration != generation) return;

      _progressMap.clear();
      for (final p in list) {
        _progressMap[p.moduleId] = p;
      }
      _errorMessage = null;
    } catch (e) {
      if (_accountId != accountId || _accountGeneration != generation) return;
      _errorMessage = 'Could not load quiz scores: $e';
    } finally {
      if (_accountId == accountId && _accountGeneration == generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Refreshes quiz progress from repository.
  Future<void> reload() async {
    final accountId = _accountId;
    if (accountId == null) return;
    final gen = ++_accountGeneration;
    _isLoading = true;
    notifyListeners();
    await _hydrateQuizProgress(accountId, gen);
  }

  /// Gets the quiz progress for [moduleId] (or initial default if never attempted).
  ModuleQuizProgress getQuizProgress(String moduleId) {
    return _progressMap[moduleId] ??
        ModuleQuizProgress.initial(
          userId: _accountId ?? '',
          moduleId: moduleId,
        );
  }

  /// Returns true if the user scored at least 60% on the specified module quiz.
  bool isModuleQuizPassed(String moduleId) {
    final progress = _progressMap[moduleId];
    return progress != null && progress.passed;
  }

  /// Checks whether a Module is unlocked.
  ///
  /// Module 1 is always unlocked.
  /// Module 2 unlocks ONLY when Module 1 Quiz has been passed with at least a 60% mark.
  bool isModuleUnlocked(String moduleId) {
    if (moduleId == 'module1') return true;
    if (moduleId == 'module2') {
      return isModuleQuizPassed('module1');
    }
    // Future modules unlock sequentially upon passing prior quiz
    if (moduleId == 'module3') {
      return isModuleQuizPassed('module2');
    }
    return false;
  }

  /// Checks whether a specific Module's Quiz is unlocked.
  ///
  /// Module 1 Quiz unlocks only when all lessons in Module 1 are completed.
  /// Module 2 Quiz unlocks only when Module 2 is unlocked AND all Module 2 lessons are completed.
  bool isQuizUnlocked(String moduleId, LessonProvider lessonProvider) {
    if (moduleId == 'module1') {
      return lessonProvider.isModuleCompleted('module1');
    }
    if (moduleId == 'module2') {
      return isModuleUnlocked('module2') &&
          lessonProvider.isModuleCompleted('module2');
    }
    return false;
  }

  /// Records a completed quiz attempt result and updates high scores.
  Future<ModuleQuizProgress> recordQuizResult({
    required String moduleId,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      final updated = await _repository.saveQuizResult(
        moduleId: moduleId,
        score: score,
        totalQuestions: totalQuestions,
      );
      _progressMap[moduleId] = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      // Fallback local memory update if network drops
      final current = getQuizProgress(moduleId);
      final percentage =
          totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;
      final isPassedThisAttempt = percentage >= 60.0;

      final localUpdated = ModuleQuizProgress(
        userId: _accountId ?? '',
        moduleId: moduleId,
        highScore: score > current.highScore ? score : current.highScore,
        totalQuestions: totalQuestions,
        bestPercentage: percentage > current.bestPercentage
            ? percentage
            : current.bestPercentage,
        passed: current.passed || isPassedThisAttempt,
        attemptsCount: current.attemptsCount + 1,
        lastScore: score,
        lastPercentage: percentage,
        lastAttemptAt: DateTime.now(),
      );

      _progressMap[moduleId] = localUpdated;
      notifyListeners();
      return localUpdated;
    }
  }

  /// Generates the high-level analytics summary across all quizzes.
  QuizAnalyticsSummary get analytics {
    return QuizAnalyticsSummary.fromProgressList(_progressMap.values.toList());
  }
}
