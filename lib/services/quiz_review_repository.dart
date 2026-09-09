import 'package:algebrix/models/quiz_attempt_review_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// How many attempts are retained per module.
///
/// The `quiz_attempt_reviews_enforce_retention` trigger is the real authority;
/// this constant keeps client-side state in step with it.
const int kMaxRetainedAttemptsPerModule = 3;

/// Persistence boundary for the quiz review log.
///
/// Intentionally separate from [QuizRepository]: that owns scoring and module
/// unlocks, this owns an append-only archive that nothing else reads.
abstract interface class QuizReviewRepository {
  /// Fetches every retained attempt for the current user, newest first.
  Future<List<QuizAttemptReview>> fetchRecentAttempts();

  /// Archives a completed attempt. Older attempts beyond the retention cap
  /// are pruned server-side.
  Future<void> saveAttempt({
    required String moduleId,
    required String moduleTitle,
    required int score,
    required int totalQuestions,
    required List<ReviewedQuestion> items,
  });

  /// Removes every retained attempt for one module.
  Future<void> clearModuleAttempts(String moduleId);
}

/// Supabase-backed implementation of [QuizReviewRepository].
class SupabaseQuizReviewRepository implements QuizReviewRepository {
  SupabaseQuizReviewRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<QuizAttemptReview>> fetchRecentAttempts() async {
    final userId = _requireAuthenticatedUser();

    final rows = await _client
        .from('quiz_attempt_reviews')
        .select()
        .eq('user_id', userId)
        .order('taken_at', ascending: false);

    return rows.map((row) => QuizAttemptReview.fromJson(row)).toList();
  }

  @override
  Future<void> saveAttempt({
    required String moduleId,
    required String moduleTitle,
    required int score,
    required int totalQuestions,
    required List<ReviewedQuestion> items,
  }) async {
    _requireAuthenticatedUser();
    if (items.isEmpty) return;

    // user_id and taken_at are column defaults; the INSERT grant excludes them.
    await _client.from('quiz_attempt_reviews').insert({
      'module_id': moduleId,
      'module_title': moduleTitle,
      'score': score,
      'total_questions': totalQuestions,
      'items': items.map((item) => item.toJson()).toList(),
    });
  }

  @override
  Future<void> clearModuleAttempts(String moduleId) async {
    final userId = _requireAuthenticatedUser();

    await _client
        .from('quiz_attempt_reviews')
        .delete()
        .eq('user_id', userId)
        .eq('module_id', moduleId);
  }

  String _requireAuthenticatedUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User must be authenticated to access quiz reviews.');
    }
    return user.id;
  }
}

/// In-memory implementation for tests and offline mode.
///
/// Applies the same retention cap as the database trigger so behaviour under
/// test matches production.
class MemoryQuizReviewRepository implements QuizReviewRepository {
  final List<QuizAttemptReview> _attempts = [];
  int _sequence = 0;

  String activeUserId = 'test_user';

  /// When set, every call throws this instead of succeeding.
  Object? failure;

  @override
  Future<List<QuizAttemptReview>> fetchRecentAttempts() async {
    if (failure != null) throw failure!;
    final sorted = [..._attempts]
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return sorted;
  }

  @override
  Future<void> saveAttempt({
    required String moduleId,
    required String moduleTitle,
    required int score,
    required int totalQuestions,
    required List<ReviewedQuestion> items,
  }) async {
    if (failure != null) throw failure!;
    if (items.isEmpty) return;

    _attempts.add(
      QuizAttemptReview(
        id: 'attempt_${_sequence++}',
        moduleId: moduleId,
        moduleTitle: moduleTitle,
        score: score,
        totalQuestions: totalQuestions,
        items: items,
        takenAt: DateTime.now().add(Duration(microseconds: _sequence)),
      ),
    );

    _pruneModule(moduleId);
  }

  @override
  Future<void> clearModuleAttempts(String moduleId) async {
    if (failure != null) throw failure!;
    _attempts.removeWhere((attempt) => attempt.moduleId == moduleId);
  }

  void _pruneModule(String moduleId) {
    final forModule = _attempts
        .where((attempt) => attempt.moduleId == moduleId)
        .toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

    if (forModule.length <= kMaxRetainedAttemptsPerModule) return;

    final stale = forModule.skip(kMaxRetainedAttemptsPerModule).toSet();
    _attempts.removeWhere(stale.contains);
  }
}
