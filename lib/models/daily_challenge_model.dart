/// Represents a daily challenge for gamification engagement.
///
/// Challenges reset daily and award XP upon completion.
/// Progress is tracked as questions completed out of total.
class DailyChallengeModel {
  final String id;
  final String title;
  final String description;
  final int totalQuestions;
  final int completedQuestions;
  final int xpReward;
  final DateTime date;

  const DailyChallengeModel({
    required this.id,
    required this.title,
    this.description = '',
    this.totalQuestions = 5,
    this.completedQuestions = 0,
    this.xpReward = 20,
    required this.date,
  });

  /// Completion progress from 0.0 to 1.0.
  double get progress =>
      totalQuestions > 0 ? completedQuestions / totalQuestions : 0.0;

  /// Progress display string (e.g., "2 / 5").
  String get progressDisplay => '$completedQuestions / $totalQuestions';

  /// Whether the challenge is fully completed.
  bool get isCompleted => completedQuestions >= totalQuestions;

  /// Creates a copy of this model with selective field overrides.
  DailyChallengeModel copyWith({
    String? title,
    String? description,
    int? totalQuestions,
    int? completedQuestions,
    int? xpReward,
  }) {
    return DailyChallengeModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      completedQuestions: completedQuestions ?? this.completedQuestions,
      xpReward: xpReward ?? this.xpReward,
      date: date,
    );
  }

  /// Placeholder challenge for development and UI prototyping.
  static DailyChallengeModel placeholder() {
    return DailyChallengeModel(
      id: 'dc_001',
      title: 'Solve 5 equations',
      description: 'Practice one-step equations today!',
      totalQuestions: 5,
      completedQuestions: 2,
      xpReward: 20,
      date: DateTime.now(),
    );
  }
}
