import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:algebrix/models/quiz_attempt_review_model.dart';
import 'package:algebrix/services/quiz_review_repository.dart';

/// State for the quiz review log — the learner's recent attempts, kept so
/// questions can be revisited after the quiz screen is gone.
///
/// Deliberately isolated from `QuizProvider`: nothing here affects scoring,
/// high scores, or module unlocks. Removing this provider would leave quiz
/// behaviour unchanged.
class QuizReviewProvider extends ChangeNotifier {
  QuizReviewProvider({required QuizReviewRepository repository})
      : _repository = repository;

  final QuizReviewRepository _repository;

  String? _accountId;
  int _accountGeneration = 0;
  List<QuizAttemptReview> _attempts = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? get accountId => _accountId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Every retained attempt across all modules, newest first.
  List<QuizAttemptReview> get attempts => List.unmodifiable(_attempts);

  bool get hasAttempts => _attempts.isNotEmpty;

  /// Retained attempts for one module, newest first.
  List<QuizAttemptReview> attemptsForModule(String moduleId) =>
      List.unmodifiable(
        _attempts.where((attempt) => attempt.moduleId == moduleId),
      );

  /// Module ids that have at least one retained attempt, newest activity first.
  List<String> get moduleIdsWithAttempts {
    final seen = <String>[];
    for (final attempt in _attempts) {
      if (!seen.contains(attempt.moduleId)) seen.add(attempt.moduleId);
    }
    return List.unmodifiable(seen);
  }

  /// Total questions missed across every retained attempt.
  int get totalMissedCount =>
      _attempts.fold(0, (sum, attempt) => sum + attempt.missedCount);

  /// The most recent attempt overall, or null when nothing is retained.
  QuizAttemptReview? get latestAttempt =>
      _attempts.isEmpty ? null : _attempts.first;

  /// Binds the provider to an authenticated account and hydrates its log.
  void bindAccount(String? accountId) {
    if (_accountId == accountId) return;

    _accountGeneration++;
    _accountId = accountId;
    _attempts = [];
    _errorMessage = null;

    if (accountId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    unawaited(_hydrate(accountId, _accountGeneration));
  }

  Future<void> _hydrate(String accountId, int generation) async {
    try {
      final fetched = await _repository.fetchRecentAttempts();
      if (_accountId != accountId || _accountGeneration != generation) return;

      _attempts = _sortedNewestFirst(fetched);
      _errorMessage = null;
    } catch (e) {
      if (_accountId != accountId || _accountGeneration != generation) return;
      _errorMessage = 'Could not load your quiz review history.';
      debugPrint('Quiz review hydration failed: $e');
    } finally {
      if (_accountId == accountId && _accountGeneration == generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Refreshes the log from the repository.
  Future<void> reload() async {
    final accountId = _accountId;
    if (accountId == null) return;
    final generation = ++_accountGeneration;
    _isLoading = true;
    notifyListeners();
    await _hydrate(accountId, generation);
  }

  /// Archives a finished attempt.
  ///
  /// Never throws — the quiz screen calls this as the learner reaches the
  /// results view, and a review-log failure must not disturb that. The attempt
  /// is added locally first so it is reviewable immediately; if the write
  /// fails, it survives only until the next reload.
  Future<void> recordAttempt({
    required String moduleId,
    required String moduleTitle,
    required int score,
    required int totalQuestions,
    required List<ReviewedQuestion> items,
  }) async {
    if (items.isEmpty) return;

    final optimistic = QuizAttemptReview(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      moduleId: moduleId,
      moduleTitle: moduleTitle,
      score: score,
      totalQuestions: totalQuestions,
      items: items,
      takenAt: DateTime.now(),
    );

    _attempts = _sortedNewestFirst([optimistic, ..._attempts]);
    _pruneModule(moduleId);
    notifyListeners();

    try {
      await _repository.saveAttempt(
        moduleId: moduleId,
        moduleTitle: moduleTitle,
        score: score,
        totalQuestions: totalQuestions,
        items: items,
      );
    } catch (e) {
      // Kept locally for this session; the next reload reflects the server.
      debugPrint('Quiz review save failed: $e');
    }
  }

  /// Clears every retained attempt for one module.
  Future<bool> clearModule(String moduleId) async {
    final previous = _attempts;

    _attempts = _attempts
        .where((attempt) => attempt.moduleId != moduleId)
        .toList();
    notifyListeners();

    try {
      await _repository.clearModuleAttempts(moduleId);
      return true;
    } catch (e) {
      _attempts = previous;
      _errorMessage = 'Could not clear your review history.';
      debugPrint('Quiz review clear failed: $e');
      notifyListeners();
      return false;
    }
  }

  List<QuizAttemptReview> _sortedNewestFirst(List<QuizAttemptReview> source) {
    final sorted = [...source]
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return sorted;
  }

  /// Mirrors the server retention trigger so local state cannot drift past it.
  void _pruneModule(String moduleId) {
    final forModule =
        _attempts.where((attempt) => attempt.moduleId == moduleId).toList();
    if (forModule.length <= kMaxRetainedAttemptsPerModule) return;

    final stale = forModule.skip(kMaxRetainedAttemptsPerModule).toSet();
    _attempts = _attempts.where((a) => !stale.contains(a)).toList();
  }
}
