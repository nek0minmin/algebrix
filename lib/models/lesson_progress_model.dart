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

/// Authoritative gamification totals from the signed-in account's profile row.
///
/// This intentionally excludes authentication metadata. Supabase RLS limits
/// the underlying profile query to the current account.
class LearningProfileSnapshot {
  const LearningProfileSnapshot({
    required this.userId,
    required this.xp,
    required this.level,
    required this.levelTitle,
    required this.streak,
  });

  final String userId;
  final int xp;
  final int level;
  final String levelTitle;
  final int streak;

  factory LearningProfileSnapshot.fromJson(Map<String, dynamic> json) {
    return LearningProfileSnapshot(
      userId: json['id'] as String,
      xp: (json['xp'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      levelTitle: json['level_title'] as String,
      streak: (json['streak'] as num).toInt(),
    );
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
/// [xpAwarded] is the sum committed by this call. It is zero when the same
/// correct answer or completion is retried, making UI retries safe.
class RecordLessonStepResult {
  const RecordLessonStepResult({
    required this.progress,
    required this.xpAwarded,
    required this.stepXpAwarded,
    required this.completionXpAwarded,
    required this.totalXp,
    required this.level,
    required this.levelTitle,
    required this.completionRequirementsMet,
  });

  final LessonProgress progress;
  final int xpAwarded;
  final int stepXpAwarded;
  final int completionXpAwarded;
  final int totalXp;
  final int level;
  final String levelTitle;
  final bool completionRequirementsMet;

  factory RecordLessonStepResult.fromJson(Map<String, dynamic> json) {
    return RecordLessonStepResult(
      progress: LessonProgress.fromJson(
        Map<String, dynamic>.from(json['progress'] as Map),
      ),
      xpAwarded: (json['xp_awarded'] as num).toInt(),
      stepXpAwarded: (json['step_xp_awarded'] as num).toInt(),
      completionXpAwarded: (json['completion_xp_awarded'] as num).toInt(),
      totalXp: (json['total_xp'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      levelTitle: json['level_title'] as String,
      completionRequirementsMet: json['completion_requirements_met'] as bool,
    );
  }
}
