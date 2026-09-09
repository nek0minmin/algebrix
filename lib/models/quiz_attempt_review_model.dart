/// A single question as it was answered during a quiz attempt.
///
/// Snapshotted at submit time rather than regenerated, because module quizzes
/// are AI-generated per attempt — the exact wording a learner saw only exists
/// here.
class ReviewedQuestion {
  const ReviewedQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.selectedIndex,
    required this.explanation,
    required this.subLessonTitle,
    required this.difficulty,
  });

  final String question;
  final List<String> options;
  final int correctIndex;

  /// Index the learner chose, or -1 if the question was never answered.
  final int selectedIndex;

  final String explanation;
  final String subLessonTitle;
  final int difficulty;

  bool get wasAnswered => selectedIndex >= 0;
  bool get isCorrect => wasAnswered && selectedIndex == correctIndex;
  bool get isMissed => !isCorrect;

  String get correctAnswer =>
      (correctIndex >= 0 && correctIndex < options.length)
          ? options[correctIndex]
          : '—';

  String? get selectedAnswer =>
      (selectedIndex >= 0 && selectedIndex < options.length)
          ? options[selectedIndex]
          : null;

  /// Human label for the progressive difficulty band.
  String get difficultyLabel => switch (difficulty) {
        1 => 'Foundations',
        2 => 'Procedural',
        _ => 'Mastery',
      };

  factory ReviewedQuestion.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    int clampIndex(Object? raw) {
      final value = (raw as num?)?.toInt() ?? -1;
      if (value < 0 || value >= options.length) return -1;
      return value;
    }

    // A correctIndex outside the options list would be unreviewable, so fall
    // back to 0 rather than rendering a question with no right answer.
    final rawCorrect = clampIndex(json['correctIndex']);

    return ReviewedQuestion(
      question: json['question'] as String? ?? 'Question',
      options: options,
      correctIndex: rawCorrect >= 0 ? rawCorrect : (options.isEmpty ? -1 : 0),
      selectedIndex: clampIndex(json['selectedIndex']),
      explanation: json['explanation'] as String? ?? '',
      subLessonTitle: json['subLessonTitle'] as String? ?? 'Algebra Concept',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'selectedIndex': selectedIndex,
        'explanation': explanation,
        'subLessonTitle': subLessonTitle,
        'difficulty': difficulty,
      };
}

/// One archived quiz attempt, retained for review after the quiz is over.
class QuizAttemptReview {
  const QuizAttemptReview({
    required this.id,
    required this.moduleId,
    required this.moduleTitle,
    required this.score,
    required this.totalQuestions,
    required this.items,
    required this.takenAt,
  });

  final String id;
  final String moduleId;
  final String moduleTitle;
  final int score;
  final int totalQuestions;
  final List<ReviewedQuestion> items;
  final DateTime takenAt;

  double get percentage =>
      totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;

  /// Matches the 60% mastery threshold used by module unlocks.
  bool get passed => percentage >= 60.0;

  List<ReviewedQuestion> get missedQuestions =>
      items.where((item) => item.isMissed).toList();

  int get missedCount => missedQuestions.length;

  bool get isPerfect => missedCount == 0 && items.isNotEmpty;

  factory QuizAttemptReview.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];

    return QuizAttemptReview(
      id: json['id'] as String? ?? '',
      moduleId: json['module_id'] as String? ?? '',
      moduleTitle: json['module_title'] as String? ?? 'Module',
      score: (json['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ReviewedQuestion.fromJson)
          .toList(),
      takenAt: DateTime.tryParse(json['taken_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
