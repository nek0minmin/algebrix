/// Represents a learner's profile and progress in Algebrix.
///
/// Includes gamification data (XP, level, streak, badges) and
/// learning progress (completed lessons). Designed for immutability
/// with [copyWith] for safe state updates.
class UserModel {
  final String id;
  final String name;
  final int xp;
  final int level;
  final String levelTitle;
  final int streak;
  final String? avatarUrl;
  final List<String> badges;
  final List<String> completedLessonIds;
  final DateTime lastActive;

  const UserModel({
    required this.id,
    required this.name,
    this.xp = 0,
    this.level = 1,
    this.levelTitle = 'Math Beginner',
    this.streak = 0,
    this.avatarUrl,
    this.badges = const [],
    this.completedLessonIds = const [],
    required this.lastActive,
  });

  /// Progress within the current level (0.0 to 1.0).
  double get levelProgress => (xp % 1000) / 1000;

  /// XP remaining to reach the next level.
  int get xpForNextLevel => 1000 - (xp % 1000);

  /// Total XP display string (e.g., "850 / 1000 XP").
  String get xpDisplayString => '${xp % 1000} / 1000 XP';

  /// Creates a copy of this model with selective field overrides.
  UserModel copyWith({
    String? name,
    int? xp,
    int? level,
    String? levelTitle,
    int? streak,
    String? avatarUrl,
    List<String>? badges,
    List<String>? completedLessonIds,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      streak: streak ?? this.streak,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      badges: badges ?? this.badges,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  /// Placeholder user for development and UI prototyping.
  static UserModel placeholder() {
    return UserModel(
      id: 'user_001',
      name: 'Jass',
      xp: 850,
      level: 7,
      levelTitle: 'Math Explorer',
      streak: 12,
      badges: const ['first_lesson', 'streak_7', 'quiz_master'],
      completedLessonIds: const ['1.1', '1.2', '1.3'],
      lastActive: DateTime.now(),
    );
  }
}
