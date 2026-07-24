/// Status of a lesson in the learning path.
enum LessonStatus {
  notStarted,
  inProgress,
  completed,
  locked,
}

/// Represents a single lesson within a module.
///
/// Each lesson belongs to a module (e.g., "Linear Equations") and tracks
/// step-based progress. Supports lock/unlock state for sequential learning.
class LessonModel {
  final String id;
  final String title;
  final String moduleId;
  final String moduleTitle;
  final int totalSteps;
  final int completedSteps;
  final bool isLocked;
  final String? iconLabel;
  final LessonStatus status;

  const LessonModel({
    required this.id,
    required this.title,
    required this.moduleId,
    required this.moduleTitle,
    this.totalSteps = 5,
    this.completedSteps = 0,
    this.isLocked = false,
    this.iconLabel,
    this.status = LessonStatus.notStarted,
  });

  /// Completion progress from 0.0 to 1.0.
  double get progress =>
      totalSteps > 0 ? completedSteps / totalSteps : 0.0;

  /// Percentage string for display (e.g., "60%").
  String get progressPercent => '${(progress * 100).round()}%';

  /// Whether the lesson is fully completed.
  bool get isCompleted => completedSteps >= totalSteps;

  /// Creates a copy of this model with selective field overrides.
  LessonModel copyWith({
    String? title,
    String? moduleTitle,
    int? totalSteps,
    int? completedSteps,
    bool? isLocked,
    String? iconLabel,
    LessonStatus? status,
  }) {
    return LessonModel(
      id: id,
      title: title ?? this.title,
      moduleId: moduleId,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      totalSteps: totalSteps ?? this.totalSteps,
      completedSteps: completedSteps ?? this.completedSteps,
      isLocked: isLocked ?? this.isLocked,
      iconLabel: iconLabel ?? this.iconLabel,
      status: status ?? this.status,
    );
  }

  /// Placeholder lesson list matching the mockup's learning path.
  static List<LessonModel> placeholderLessons() {
    return const [
      LessonModel(
        id: '2.1',
        title: 'What is a Variable?',
        moduleId: '2',
        moduleTitle: 'Linear Equations',
        totalSteps: 5,
        completedSteps: 1,
        iconLabel: 'x',
        status: LessonStatus.inProgress,
      ),
      LessonModel(
        id: '2.2',
        title: 'Using Variables',
        moduleId: '2',
        moduleTitle: 'Linear Equations',
        totalSteps: 5,
        completedSteps: 0,
        iconLabel: 'x + 3',
        status: LessonStatus.notStarted,
      ),
      LessonModel(
        id: '2.3',
        title: 'One-Step Equations',
        moduleId: '2',
        moduleTitle: 'Linear Equations',
        totalSteps: 5,
        completedSteps: 0,
        iconLabel: 'x+4=10',
        status: LessonStatus.notStarted,
      ),
      LessonModel(
        id: '2.4',
        title: 'Two-Step Equations',
        moduleId: '2',
        moduleTitle: 'Linear Equations',
        totalSteps: 5,
        completedSteps: 0,
        isLocked: true,
        iconLabel: '2x-3=11',
        status: LessonStatus.locked,
      ),
      LessonModel(
        id: '2.5',
        title: 'Word Problems',
        moduleId: '2',
        moduleTitle: 'Linear Equations',
        totalSteps: 5,
        completedSteps: 0,
        isLocked: true,
        iconLabel: '?',
        status: LessonStatus.locked,
      ),
    ];
  }

  /// Returns the current in-progress lesson, or the first not-started one.
  static LessonModel? currentLesson(List<LessonModel> lessons) {
    return lessons.cast<LessonModel?>().firstWhere(
          (l) => l!.status == LessonStatus.inProgress,
          orElse: () => lessons.cast<LessonModel?>().firstWhere(
                (l) => l!.status == LessonStatus.notStarted,
                orElse: () => null,
              ),
        );
  }
}
