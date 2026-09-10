/// Represents a learner's identity and lesson progress in Algebrix.
///
/// Deliberately carries no XP, level, streak, or badge data: Algebrix measures
/// progress by lessons finished, quiz accuracy, and concept mastery, none of
/// which need a points economy. Designed for immutability with [copyWith] for
/// safe state updates.
class UserModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final List<String> completedLessonIds;
  final DateTime lastActive;

  const UserModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.completedLessonIds = const [],
    required this.lastActive,
  });

  /// Creates a copy of this model with selective field overrides.
  UserModel copyWith({
    String? name,
    String? avatarUrl,
    List<String>? completedLessonIds,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  /// Placeholder user for development and UI prototyping.
  static UserModel placeholder() {
    return UserModel(
      id: 'user_001',
      name: 'Jass',
      completedLessonIds: const ['1.1', '1.2', '1.3'],
      lastActive: DateTime.now(),
    );
  }
}
