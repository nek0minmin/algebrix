import 'package:algebrix/models/module_quiz_progress_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persistence boundary for module quiz high scores, attempts, and unlock progress.
abstract interface class QuizRepository {
  /// Fetches quiz progress for all modules for the current authenticated user.
  Future<List<ModuleQuizProgress>> fetchAllQuizProgress();

  /// Fetches quiz progress for a specific module.
  Future<ModuleQuizProgress?> fetchQuizProgress(String moduleId);

  /// Saves or updates a quiz attempt result.
  ///
  /// Uses "best score wins" logic for high scores, while incrementing total attempts.
  Future<ModuleQuizProgress> saveQuizResult({
    required String moduleId,
    required int score,
    required int totalQuestions,
  });
}

/// Supabase-backed implementation of [QuizRepository].
class SupabaseQuizRepository implements QuizRepository {
  SupabaseQuizRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<ModuleQuizProgress>> fetchAllQuizProgress() async {
    final userId = _requireAuthenticatedUser();

    return _withRetry(() async {
      final rows = await _client
          .from('module_quiz_progress')
          .select()
          .eq('user_id', userId)
          .order('module_id', ascending: true);

      return rows.map((row) => ModuleQuizProgress.fromJson(row)).toList();
    });
  }

  @override
  Future<ModuleQuizProgress?> fetchQuizProgress(String moduleId) async {
    final userId = _requireAuthenticatedUser();

    return _withRetry(() async {
      final row = await _client
          .from('module_quiz_progress')
          .select()
          .eq('user_id', userId)
          .eq('module_id', moduleId)
          .maybeSingle();

      if (row == null) return null;
      return ModuleQuizProgress.fromJson(row);
    });
  }

  @override
  Future<ModuleQuizProgress> saveQuizResult({
    required String moduleId,
    required int score,
    required int totalQuestions,
  }) async {
    final userId = _requireAuthenticatedUser();
    final percentage = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;
    final isPassedThisAttempt = percentage >= 60.0;

    return _withRetry(() async {
      final existing = await _client
          .from('module_quiz_progress')
          .select()
          .eq('user_id', userId)
          .eq('module_id', moduleId)
          .maybeSingle();

      if (existing == null) {
        final newRecord = {
          'user_id': userId,
          'module_id': moduleId,
          'high_score': score,
          'total_questions': totalQuestions,
          'best_percentage': percentage,
          'passed': isPassedThisAttempt,
          'attempts_count': 1,
          'last_score': score,
          'last_percentage': percentage,
          'last_attempt_at': DateTime.now().toIso8601String(),
        };

        final inserted = await _client
            .from('module_quiz_progress')
            .insert(newRecord)
            .select()
            .single();

        return ModuleQuizProgress.fromJson(inserted);
      }

      final prevHighScore = (existing['high_score'] as num?)?.toInt() ?? 0;
      final prevBestPercentage = (existing['best_percentage'] as num?)?.toDouble() ?? 0.0;
      final prevPassed = existing['passed'] as bool? ?? false;
      final prevAttempts = (existing['attempts_count'] as num?)?.toInt() ?? 0;

      final newHighScore = score > prevHighScore ? score : prevHighScore;
      final newBestPercentage = percentage > prevBestPercentage ? percentage : prevBestPercentage;
      final newPassed = prevPassed || isPassedThisAttempt;

      final updatedRecord = {
        'high_score': newHighScore,
        'total_questions': totalQuestions,
        'best_percentage': newBestPercentage,
        'passed': newPassed,
        'attempts_count': prevAttempts + 1,
        'last_score': score,
        'last_percentage': percentage,
        'last_attempt_at': DateTime.now().toIso8601String(),
      };

      final updated = await _client
          .from('module_quiz_progress')
          .update(updatedRecord)
          .eq('user_id', userId)
          .eq('module_id', moduleId)
          .select()
          .single();

      return ModuleQuizProgress.fromJson(updated);
    });
  }

  String _requireAuthenticatedUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User must be authenticated to access quiz progress.');
    }
    return user.id;
  }

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= 2) rethrow;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }
}

/// In-memory implementation of [QuizRepository] for unit/widget tests and offline mode.
class MemoryQuizRepository implements QuizRepository {
  final Map<String, Map<String, ModuleQuizProgress>> _userProgress = {};

  String activeUserId = 'test_user';

  @override
  Future<List<ModuleQuizProgress>> fetchAllQuizProgress() async {
    final map = _userProgress[activeUserId] ?? {};
    return map.values.toList();
  }

  @override
  Future<ModuleQuizProgress?> fetchQuizProgress(String moduleId) async {
    final map = _userProgress[activeUserId] ?? {};
    return map[moduleId];
  }

  @override
  Future<ModuleQuizProgress> saveQuizResult({
    required String moduleId,
    required int score,
    required int totalQuestions,
  }) async {
    final map = _userProgress.putIfAbsent(activeUserId, () => {});
    final existing = map[moduleId];

    final percentage = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;
    final isPassedThisAttempt = percentage >= 60.0;

    if (existing == null) {
      final record = ModuleQuizProgress(
        userId: activeUserId,
        moduleId: moduleId,
        highScore: score,
        totalQuestions: totalQuestions,
        bestPercentage: percentage,
        passed: isPassedThisAttempt,
        attemptsCount: 1,
        lastScore: score,
        lastPercentage: percentage,
        lastAttemptAt: DateTime.now(),
      );
      map[moduleId] = record;
      return record;
    }

    final newHighScore = score > existing.highScore ? score : existing.highScore;
    final newBestPercentage = percentage > existing.bestPercentage ? percentage : existing.bestPercentage;
    final newPassed = existing.passed || isPassedThisAttempt;

    final updated = ModuleQuizProgress(
      userId: activeUserId,
      moduleId: moduleId,
      highScore: newHighScore,
      totalQuestions: totalQuestions,
      bestPercentage: newBestPercentage,
      passed: newPassed,
      attemptsCount: existing.attemptsCount + 1,
      lastScore: score,
      lastPercentage: percentage,
      lastAttemptAt: DateTime.now(),
    );

    map[moduleId] = updated;
    return updated;
  }
}
