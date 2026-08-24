/// Data model representing a user's progress, high score, and attempts for a specific module quiz.
class ModuleQuizProgress {
  const ModuleQuizProgress({
    required this.userId,
    required this.moduleId,
    required this.highScore,
    required this.totalQuestions,
    required this.bestPercentage,
    required this.passed,
    required this.attemptsCount,
    required this.lastScore,
    required this.lastPercentage,
    required this.lastAttemptAt,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String moduleId;
  final int highScore;
  final int totalQuestions;
  final double bestPercentage;
  final bool passed;
  final int attemptsCount;
  final int lastScore;
  final double lastPercentage;
  final DateTime lastAttemptAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Returns true if this quiz has been taken at least once.
  bool get hasAttempted => attemptsCount > 0;

  /// Formatted best accuracy percentage string (e.g., '87%').
  String get formattedBestPercentage => '${bestPercentage.round()}%';

  /// Star rating (1-3 stars) based on best accuracy.
  int get starRating {
    if (bestPercentage >= 80) return 3;
    if (bestPercentage >= 60) return 2;
    if (bestPercentage > 0) return 1;
    return 0;
  }

  factory ModuleQuizProgress.initial({
    required String userId,
    required String moduleId,
    int totalQuestions = 10,
  }) {
    return ModuleQuizProgress(
      userId: userId,
      moduleId: moduleId,
      highScore: 0,
      totalQuestions: totalQuestions,
      bestPercentage: 0.0,
      passed: false,
      attemptsCount: 0,
      lastScore: 0,
      lastPercentage: 0.0,
      lastAttemptAt: DateTime.now(),
    );
  }

  factory ModuleQuizProgress.fromJson(Map<String, dynamic> json) {
    return ModuleQuizProgress(
      userId: json['user_id'] as String? ?? '',
      moduleId: json['module_id'] as String? ?? '',
      highScore: (json['high_score'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 10,
      bestPercentage: (json['best_percentage'] as num?)?.toDouble() ?? 0.0,
      passed: json['passed'] as bool? ?? false,
      attemptsCount: (json['attempts_count'] as num?)?.toInt() ?? 0,
      lastScore: (json['last_score'] as num?)?.toInt() ?? 0,
      lastPercentage: (json['last_percentage'] as num?)?.toDouble() ?? 0.0,
      lastAttemptAt: json['last_attempt_at'] != null
          ? DateTime.tryParse(json['last_attempt_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'module_id': moduleId,
        'high_score': highScore,
        'total_questions': totalQuestions,
        'best_percentage': bestPercentage,
        'passed': passed,
        'attempts_count': attemptsCount,
        'last_score': lastScore,
        'last_percentage': lastPercentage,
        'last_attempt_at': lastAttemptAt.toIso8601String(),
      };
}

/// Aggregated performance summary across all module quizzes.
class QuizAnalyticsSummary {
  const QuizAnalyticsSummary({
    required this.totalQuizzesAttempted,
    required this.totalQuizzesPassed,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.overallAccuracyPercentage,
    required this.totalAttempts,
    required this.masteryLevel,
  });

  final int totalQuizzesAttempted;
  final int totalQuizzesPassed;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final double overallAccuracyPercentage;
  final int totalAttempts;
  final String masteryLevel;

  factory QuizAnalyticsSummary.fromProgressList(List<ModuleQuizProgress> progressList) {
    if (progressList.isEmpty) {
      return const QuizAnalyticsSummary(
        totalQuizzesAttempted: 0,
        totalQuizzesPassed: 0,
        totalQuestionsAnswered: 0,
        totalCorrectAnswers: 0,
        overallAccuracyPercentage: 0.0,
        totalAttempts: 0,
        masteryLevel: 'Novice Explorer',
      );
    }

    int attemptedCount = 0;
    int passedCount = 0;
    int totalQuestions = 0;
    int totalCorrect = 0;
    int totalAttemptsSum = 0;

    for (final p in progressList) {
      if (p.hasAttempted) {
        attemptedCount++;
        totalAttemptsSum += p.attemptsCount;
        totalQuestions += p.totalQuestions;
        totalCorrect += p.highScore;
      }
      if (p.passed) {
        passedCount++;
      }
    }

    final overallAccuracy = totalQuestions > 0
        ? (totalCorrect / totalQuestions) * 100
        : 0.0;

    String level = 'Novice Explorer';
    if (passedCount >= 2 && overallAccuracy >= 85) {
      level = 'Algebra Master';
    } else if (passedCount >= 1 && overallAccuracy >= 60) {
      level = 'Equation Scholar';
    } else if (attemptedCount >= 1) {
      level = 'Rising Problem Solver';
    }

    return QuizAnalyticsSummary(
      totalQuizzesAttempted: attemptedCount,
      totalQuizzesPassed: passedCount,
      totalQuestionsAnswered: totalQuestions,
      totalCorrectAnswers: totalCorrect,
      overallAccuracyPercentage: overallAccuracy,
      totalAttempts: totalAttemptsSum,
      masteryLevel: level,
    );
  }
}
