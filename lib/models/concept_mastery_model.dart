/// How well a learner has mastered one lesson-sized concept.
enum MasteryBand {
  mastered,
  solid,
  shaky,
  needsWork,
  notAssessed;

  String get label => switch (this) {
        MasteryBand.mastered => 'Mastered',
        MasteryBand.solid => 'Solid',
        MasteryBand.shaky => 'Shaky',
        MasteryBand.needsWork => 'Needs work',
        MasteryBand.notAssessed => 'Not assessed',
      };

  /// Ordering weight, strongest first. Unassessed concepts sort last in both
  /// directions — they are absent evidence, not weak evidence.
  int get rank => switch (this) {
        MasteryBand.mastered => 4,
        MasteryBand.solid => 3,
        MasteryBand.shaky => 2,
        MasteryBand.needsWork => 1,
        MasteryBand.notAssessed => 0,
      };
}

/// Aggregated evidence for one lesson, drawn from three sources:
/// quiz questions attributed to it, missed lesson answers inside it, and its
/// spaced-review state.
class ConceptMastery {
  const ConceptMastery({
    required this.moduleId,
    required this.moduleTitle,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonNumberLabel,
    required this.quizQuestionsSeen,
    required this.quizQuestionsCorrect,
    required this.openMisses,
    required this.totalMissCount,
    required this.reviewStrength,
    this.lastMissedAt,
    this.reviewDueAt,
    this.isScheduled = false,
  });

  final String moduleId;
  final String moduleTitle;
  final String lessonId;
  final String lessonTitle;

  /// Positional label, e.g. "2.3".
  final String lessonNumberLabel;

  /// Quiz questions across retained attempts attributed to this lesson.
  final int quizQuestionsSeen;
  final int quizQuestionsCorrect;

  /// Lesson mistakes in this lesson that have not since been answered right.
  final int openMisses;

  /// Total times lesson answers here have been missed, open or resolved.
  final int totalMissCount;

  /// Leitner box 0–5; 0 when the concept has never been scheduled.
  final int reviewStrength;

  final DateTime? lastMissedAt;
  final DateTime? reviewDueAt;

  /// Whether a spaced-review row exists. Once it does, the schedule governs
  /// when the concept resurfaces instead of the raw accuracy signal.
  final bool isScheduled;

  bool get hasQuizEvidence => quizQuestionsSeen > 0;
  bool get hasEvidence => hasQuizEvidence || totalMissCount > 0;

  /// Quiz accuracy as a percentage, or null when this concept has never
  /// appeared in a quiz.
  double? get quizAccuracy => hasQuizEvidence
      ? (quizQuestionsCorrect / quizQuestionsSeen) * 100
      : null;

  int get quizQuestionsMissed => quizQuestionsSeen - quizQuestionsCorrect;

  MasteryBand get band {
    if (!hasEvidence) return MasteryBand.notAssessed;

    final accuracy = quizAccuracy;

    // An open mistake the learner has not yet corrected is hard evidence, and
    // caps the band no matter how good the quiz numbers look.
    if (accuracy == null) {
      return openMisses > 0 ? MasteryBand.needsWork : MasteryBand.solid;
    }

    final raw = accuracy >= 85
        ? MasteryBand.mastered
        : accuracy >= 70
            ? MasteryBand.solid
            : accuracy >= 50
                ? MasteryBand.shaky
                : MasteryBand.needsWork;

    if (openMisses > 0 && raw.rank > MasteryBand.shaky.rank) {
      return MasteryBand.shaky;
    }
    return raw;
  }

  bool isDue({DateTime? now}) {
    final dueAt = reviewDueAt;
    if (dueAt == null) return false;
    return !dueAt.isAfter(now ?? DateTime.now());
  }

  /// Whether this concept should appear in the learner's practice queue.
  ///
  /// Once scheduled, the Leitner ladder decides — that is the whole point of
  /// spacing, and a concept just reviewed should stay quiet even if its
  /// historical accuracy is still poor. Before scheduling, the raw signals
  /// decide.
  bool needsReview({DateTime? now}) {
    if (!hasEvidence) return false;
    if (isScheduled) return isDue(now: now);

    if (openMisses > 0) return true;
    final accuracy = quizAccuracy;
    return accuracy != null && accuracy < 70;
  }

  /// Why this concept is in the practice queue, in the learner's words.
  ///
  /// The Leitner box number is an implementation detail — "Box 3/5" told a
  /// 13-year-old nothing. This says what actually put it there.
  String get practiceReason {
    if (openMisses > 0) {
      return openMisses == 1
          ? '1 mistake to fix'
          : '$openMisses mistakes to fix';
    }
    final accuracy = quizAccuracy;
    if (accuracy != null && accuracy < 70) {
      return 'Missed in a recent quiz';
    }
    if (isScheduled) return 'Time to look at this again';
    return 'Worth another look';
  }

  /// Quiz record in words, or null when this concept has never been quizzed.
  String? get quizSummary {
    if (!hasQuizEvidence) return null;
    return '$quizQuestionsCorrect of $quizQuestionsSeen quiz '
        '${quizQuestionsSeen == 1 ? 'question' : 'questions'} right';
  }

  /// Sort key for "weakest first", lower is weaker.
  ///
  /// Falls back to accuracy inside a band, then to open mistakes, so two
  /// "Needs work" concepts still order sensibly.
  double get weaknessScore {
    if (!hasEvidence) return 1000; // unassessed sorts to the end
    final accuracy = quizAccuracy ?? (openMisses > 0 ? 40.0 : 75.0);
    return accuracy - (openMisses * 5);
  }
}

/// Roll-up across every concept, for the analytics header.
class MasterySummary {
  const MasterySummary({
    required this.assessedCount,
    required this.masteredCount,
    required this.needsReviewCount,
    required this.dueNowCount,
    required this.overallAccuracy,
    required this.openMistakeCount,
  });

  final int assessedCount;
  final int masteredCount;
  final int needsReviewCount;
  final int dueNowCount;

  /// Weighted accuracy across every attributed quiz question, or null when no
  /// quiz has been taken yet.
  final double? overallAccuracy;

  final int openMistakeCount;

  bool get hasData => assessedCount > 0;

  double get masteredFraction =>
      assessedCount == 0 ? 0 : masteredCount / assessedCount;

  factory MasterySummary.from(
    List<ConceptMastery> concepts, {
    DateTime? now,
  }) {
    final assessed = concepts.where((c) => c.hasEvidence).toList();

    var seen = 0;
    var correct = 0;
    for (final concept in assessed) {
      seen += concept.quizQuestionsSeen;
      correct += concept.quizQuestionsCorrect;
    }

    return MasterySummary(
      assessedCount: assessed.length,
      masteredCount:
          assessed.where((c) => c.band == MasteryBand.mastered).length,
      needsReviewCount:
          assessed.where((c) => c.needsReview(now: now)).length,
      dueNowCount: assessed.where((c) => c.isDue(now: now)).length,
      overallAccuracy: seen > 0 ? (correct / seen) * 100 : null,
      openMistakeCount:
          assessed.fold(0, (sum, c) => sum + c.openMisses),
    );
  }
}
