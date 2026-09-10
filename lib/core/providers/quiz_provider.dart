import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/data/lesson_catalog.dart';
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
  /// The first module in the catalog is always open; every module after it
  /// unlocks when the previous module's quiz has been passed at 60% or better.
  ///
  /// Stated once and derived from catalog order, rather than one branch per
  /// module — a new module inherits the rule instead of needing a new branch.
  bool isModuleUnlocked(String moduleId) {
    final modules = LessonCatalog.modules;
    final index = modules.indexWhere((module) => module.id == moduleId);

    // A module this build does not ship stays locked.
    if (index < 0) return false;
    if (index == 0) return true;

    return isModuleQuizPassed(modules[index - 1].id);
  }

  /// Checks whether a specific Module's Quiz is unlocked.
  ///
  /// A quiz opens once its module is unlocked and every lesson in it is
  /// complete. Module 1 previously skipped the unlock check, which was
  /// equivalent only because the first module is always unlocked.
  bool isQuizUnlocked(String moduleId, LessonProvider lessonProvider) {
    if (LessonCatalog.moduleById(moduleId) == null) return false;

    return isModuleUnlocked(moduleId) &&
        lessonProvider.isModuleCompleted(moduleId);
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
