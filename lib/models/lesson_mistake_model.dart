/// A missed lesson answer, retained so the learner can revisit it.
///
/// One row per (lesson, step): repeating the same mistake bumps [missCount]
/// rather than appending a new record, which is what makes "you have missed
/// this 3 times" meaningful.
class LessonMistake {
  const LessonMistake({
    required this.id,
    required this.moduleId,
    required this.lessonId,
    required this.stepId,
    required this.stepIndex,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.selectedIndex,
    required this.explanation,
    required this.missCount,
    required this.resolved,
    required this.lastMissedAt,
  });

  final String id;
  final String moduleId;
  final String lessonId;
  final String stepId;
  final int stepIndex;
  final String question;
  final List<String> options;
  final int correctIndex;
  final int selectedIndex;
  final String explanation;

  /// How many times this step has been answered wrong.
  final int missCount;

  /// True once the learner later answered this step correctly.
  final bool resolved;

  final DateTime lastMissedAt;

  bool get isOpen => !resolved;

  /// Missed more than once — worth surfacing above one-off slips.
  bool get isRepeated => missCount > 1;

  String get correctAnswer =>
      (correctIndex >= 0 && correctIndex < options.length)
          ? options[correctIndex]
          : '—';

  String? get selectedAnswer =>
      (selectedIndex >= 0 && selectedIndex < options.length)
          ? options[selectedIndex]
          : null;

  factory LessonMistake.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    int clampIndex(Object? raw) {
      final value = (raw as num?)?.toInt() ?? -1;
      if (value < 0 || value >= options.length) return -1;
      return value;
    }

    return LessonMistake(
      id: json['id'] as String? ?? '',
      moduleId: json['module_id'] as String? ?? '',
      lessonId: json['lesson_id'] as String? ?? '',
      stepId: json['step_id'] as String? ?? '',
      stepIndex: (json['step_index'] as num?)?.toInt() ?? 0,
      question: json['question'] as String? ?? '',
      options: options,
      correctIndex: clampIndex(json['correct_index']),
      selectedIndex: clampIndex(json['selected_index']),
      explanation: json['explanation'] as String? ?? '',
      missCount: (json['miss_count'] as num?)?.toInt() ?? 1,
      resolved: json['resolved'] as bool? ?? false,
      lastMissedAt:
          DateTime.tryParse(json['last_missed_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}

/// Spaced-repetition state for one lesson-sized concept.
class ConceptReviewSchedule {
  const ConceptReviewSchedule({
    required this.moduleId,
    required this.lessonId,
    required this.strength,
    required this.dueAt,
    required this.lastOutcome,
    this.lastReviewedAt,
  });

  final String moduleId;
  final String lessonId;

  /// Leitner box, 0–5. Missing demotes by one, a good review promotes by one.
  final int strength;

  final DateTime dueAt;
  final String lastOutcome;
  final DateTime? lastReviewedAt;

  bool isDue({DateTime? now}) =>
      !dueAt.isAfter(now ?? DateTime.now());

  /// Whether the concept has climbed far enough to be considered settled.
  bool get isRetained => strength >= 4;

  factory ConceptReviewSchedule.fromJson(Map<String, dynamic> json) {
    return ConceptReviewSchedule(
      moduleId: json['module_id'] as String? ?? '',
      lessonId: json['lesson_id'] as String? ?? '',
      strength: (json['strength'] as num?)?.toInt() ?? 0,
      dueAt: DateTime.tryParse(json['due_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      lastOutcome: json['last_outcome'] as String? ?? 'missed',
      lastReviewedAt:
          DateTime.tryParse(json['last_reviewed_at'] as String? ?? '')?.toLocal(),
    );
  }
}
