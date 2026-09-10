/// Persisted status for one learner's lesson.
enum LessonProgressStatus {
  inProgress('in_progress'),
  completed('completed');

  const LessonProgressStatus(this.databaseValue);

  final String databaseValue;

  static LessonProgressStatus fromDatabase(String value) {
    return LessonProgressStatus.values.firstWhere(
      (status) => status.databaseValue == value,
      orElse: () =>
          throw FormatException('Unknown lesson progress status: $value'),
    );
  }
}

/// Identity of the signed-in account's profile row.
///
/// The profiles table still carries legacy xp, level, and streak columns, but
/// nothing in the app reads them: progress is measured in lessons finished,
/// quiz accuracy, and concept mastery. This intentionally excludes
/// authentication metadata. Supabase RLS limits the underlying profile query to
/// the current account.
class LearningProfileSnapshot {
  const LearningProfileSnapshot({required this.userId});

  final String userId;

  factory LearningProfileSnapshot.fromJson(Map<String, dynamic> json) {
    return LearningProfileSnapshot(userId: json['id'] as String);
  }
}

/// Account-scoped resume and completion state returned by Supabase.
class LessonProgress {
  const LessonProgress({
    required this.userId,
    required this.moduleId,
    required this.lessonId,
    required this.contentVersion,
    required this.status,
    required this.startedAt,
    required this.updatedAt,
    this.lastStepId,
    this.lastStepIndex,
    this.completedAt,
  });

  final String userId;
  final String moduleId;
  final String lessonId;
  final int contentVersion;
  final String? lastStepId;
  final int? lastStepIndex;
  final LessonProgressStatus status;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      userId: json['user_id'] as String,
      moduleId: json['module_id'] as String,
      lessonId: json['lesson_id'] as String,
      contentVersion: (json['content_version'] as num).toInt(),
      lastStepId: json['last_step_id'] as String?,
      lastStepIndex: (json['last_step_index'] as num?)?.toInt(),
      status: LessonProgressStatus.fromDatabase(json['status'] as String),
      startedAt: DateTime.parse(json['started_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: _parseNullableDate(json['completed_at']),
    );
  }

  static DateTime? _parseNullableDate(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

/// Authoritative result of recording one lesson step.
///
/// The `record_lesson_step` RPC still returns xp_awarded, level, and friends;
/// they are simply not read. Leaving the server contract alone keeps the
/// progress-recording path — the most load-bearing call in the app — untouched
/// by the removal of the points economy.
class RecordLessonStepResult {
  const RecordLessonStepResult({
    required this.progress,
    required this.completionRequirementsMet,
  });

  final LessonProgress progress;
  final bool completionRequirementsMet;

  factory RecordLessonStepResult.fromJson(Map<String, dynamic> json) {
    return RecordLessonStepResult(
      progress: LessonProgress.fromJson(
        Map<String, dynamic>.from(json['progress'] as Map),
      ),
      completionRequirementsMet: json['completion_requirements_met'] as bool,
    );
  }
}
