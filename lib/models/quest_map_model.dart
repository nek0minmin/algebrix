/// A themed game world on the quest map (e.g. "Balands").
///
/// Each land contains a fixed number of levels. Lands are locked behind a
/// cumulative star gate defined by [unlockStarsRequired].
class QuestLand {
  const QuestLand({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.sortOrder,
    required this.totalLevels,
    required this.unlockStarsRequired,
  });

  final String id;
  final String name;
  final String subtitle;
  final int sortOrder;
  final int totalLevels;
  final int unlockStarsRequired;

  /// Whether this land is unlocked given the user's total stars across all lands.
  bool isUnlocked(int totalStarsCollected) =>
      totalStarsCollected >= unlockStarsRequired;

  /// Maximum possible stars in this land.
  int get maxStars => totalLevels * 3;

  factory QuestLand.fromJson(Map<String, dynamic> json) {
    return QuestLand(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
      totalLevels: (json['total_levels'] as num).toInt(),
      unlockStarsRequired: (json['unlock_stars_required'] as num).toInt(),
    );
  }
}

/// Per-user progress on a specific quest level.
///
/// Tracks star rating, best move count, and whether the reasoning challenge
/// was passed. Instances are persisted to Supabase.
class QuestLevelProgress {
  const QuestLevelProgress({
    required this.userId,
    required this.landId,
    required this.levelNumber,
    required this.starsEarned,
    this.bestMoves,
    required this.reasoningPassed,
    this.completedAt,
  });

  final String userId;
  final String landId;
  final int levelNumber;

  /// Star rating for this level (0–3).
  final int starsEarned;
  final int? bestMoves;
  final bool reasoningPassed;
  final DateTime? completedAt;

  bool get isCompleted => starsEarned > 0;

  factory QuestLevelProgress.fromJson(Map<String, dynamic> json) {
    return QuestLevelProgress(
      userId: json['user_id'] as String,
      landId: json['land_id'] as String,
      levelNumber: (json['level_number'] as num).toInt(),
      starsEarned: (json['stars_earned'] as num).toInt(),
      bestMoves: (json['best_moves'] as num?)?.toInt(),
      reasoningPassed: json['reasoning_passed'] as bool,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': userId,
      'land_id': landId,
      'level_number': levelNumber,
      'stars_earned': starsEarned,
      'best_moves': bestMoves,
      'reasoning_passed': reasoningPassed,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

/// Static definition of a quest level's content.
///
/// These live in code rather than the database. Each definition describes what
/// a level contains and how hard it is.
class QuestLevelDefinition {
  const QuestLevelDefinition({
    required this.levelNumber,
    required this.difficulty,
    required this.description,
  });

  /// Level number within the land (1–10).
  final int levelNumber;

  /// Numeric difficulty rating (1–10), mapped to a human-readable label via
  /// [difficultyLabel].
  final int difficulty;

  /// Short description of the level content, e.g. "Simple addition".
  final String description;

  /// Human-readable difficulty label.
  String get difficultyLabel {
    if (difficulty <= 3) return 'Easy';
    if (difficulty <= 6) return 'Medium';
    if (difficulty <= 8) return 'Hard';
    return 'Expert';
  }
}
