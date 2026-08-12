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

    final row = await _client
        .from('profiles')
        .select('id, xp, level, level_title, streak')
        .eq('id', userId)
        .single();

    return LearningProfileSnapshot.fromJson(row);
  }

  @override
  Future<List<LessonProgress>> fetchModuleProgress(String moduleId) async {
    _requireAuthenticatedUser();

    final rows = await _client
        .from('lesson_progress')
        .select()
        .eq('module_id', moduleId)
        .order('updated_at');

    return rows
        .map((row) => LessonProgress.fromJson(row))
        .toList(growable: false);
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
    _requireAuthenticatedUser();

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

    if (response is! Map) {
      throw const FormatException(
        'record_lesson_step returned an unexpected response.',
      );
    }

    return RecordLessonStepResult.fromJson(Map<String, dynamic>.from(response));
  }

  String _requireAuthenticatedUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('An authenticated account is required.');
    }
    return user.id;
  }
}
