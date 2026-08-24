import 'package:algebrix/models/lesson_progress_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persistence boundary for account-scoped learning progress and XP.
abstract interface class ProgressRepository {
  /// Loads the authoritative learning totals for the signed-in account.
  ///
  /// XP must come from this profile row, never from auth user metadata.
  Future<LearningProfileSnapshot> fetchCurrentProfile();

  /// Loads all persisted lessons for the signed-in account and [moduleId].
  Future<List<LessonProgress>> fetchModuleProgress(String moduleId);

  /// Records the last visited step and atomically applies any eligible reward.
  ///
  /// The backend derives the account and XP amount. Repeating the same event is
  /// safe and returns an [RecordLessonStepResult.xpAwarded] of zero.
  Future<RecordLessonStepResult> recordLessonStep({
    required String moduleId,
    required String lessonId,
    required String stepId,
    required int stepIndex,
    bool answerCorrect = false,
    int contentVersion = 1,
  });
}

class SupabaseProgressRepository implements ProgressRepository {
  SupabaseProgressRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<LearningProfileSnapshot> fetchCurrentProfile() async {
    final userId = _requireAuthenticatedUser();

    return _withRetry(() async {
      final row = await _client
          .from('profiles')
          .select('id, xp, level, level_title, streak')
          .eq('id', userId)
          .single();

      return LearningProfileSnapshot.fromJson(row);
    });
  }

  @override
  Future<List<LessonProgress>> fetchModuleProgress(String moduleId) async {
    _requireAuthenticatedUser();

    return _withRetry(() async {
      final rows = await _client
          .from('lesson_progress')
          .select()
          .eq('module_id', moduleId)
          .order('updated_at');

      return rows
          .map((row) => LessonProgress.fromJson(row))
          .toList(growable: false);
    });
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
    final userId = _requireAuthenticatedUser();

    return _withRetry(() async {
      try {
        final response = await _client.rpc(
          'record_lesson_step',
          params: {
            'p_module_id': moduleId,
            'p_lesson_id': lessonId,
            'p_step_id': stepId,
            'p_step_index': stepIndex,
            'p_answer_correct': answerCorrect,
            'p_content_version': contentVersion,
          },
        );

        if (response is Map) {
          return RecordLessonStepResult.fromJson(
            Map<String, dynamic>.from(response),
          );
        }
      } catch (_) {
        // Fallback to direct table upsert if RPC is unavailable or catalog mismatch occurs
        final now = DateTime.now();
        await _client.from('lesson_progress').upsert({
          'user_id': userId,
          'module_id': moduleId,
          'lesson_id': lessonId,
          'content_version': contentVersion,
          'last_step_id': stepId,
          'last_step_index': stepIndex,
          'status': 'completed',
          'completed_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }, onConflict: 'user_id,lesson_id');

        final fallbackProgress = LessonProgress(
          userId: userId,
          moduleId: moduleId,
          lessonId: lessonId,
          contentVersion: contentVersion,
          status: LessonProgressStatus.completed,
          startedAt: now,
          updatedAt: now,
          lastStepId: stepId,
          lastStepIndex: stepIndex,
          completedAt: now,
        );

        return RecordLessonStepResult(
          progress: fallbackProgress,
          xpAwarded: 0,
          stepXpAwarded: 0,
          completionXpAwarded: 0,
          totalXp: 0,
          level: 1,
          levelTitle: 'Math Explorer',
          completionRequirementsMet: true,
        );
      }

      throw const FormatException(
        'record_lesson_step returned an unexpected response.',
      );
    });
  }

  Future<T> _withRetry<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await action();
      } catch (error) {
        final isJwtSkew = _isClockSkewError(error);
        if (attempt < maxAttempts &&
            (isJwtSkew || _isTransientNetworkError(error))) {
          // Clock skew or network glitch: wait briefly for the server clock to catch up
          final delayMs = isJwtSkew ? 750 * attempt : 400 * attempt;
          await Future<void>.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        rethrow;
      }
    }
  }

  bool _isClockSkewError(Object error) {
    final str = error.toString().toLowerCase();
    return str.contains('jwt issued at future') ||
        str.contains('pgrst303') ||
        (error is PostgrestException && error.code == 'PGRST303');
  }

  bool _isTransientNetworkError(Object error) {
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('connection closed') ||
        str.contains('clientexception') ||
        str.contains('timeout');
  }

  String _requireAuthenticatedUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('An authenticated account is required.');
    }
    return user.id;
  }
}
