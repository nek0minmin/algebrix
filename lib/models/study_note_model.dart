/// An account-owned study note linked to one Algebrix lesson.
///
/// Instances are immutable. Supabase is responsible for generating [id],
/// [createdAt], and [updatedAt].
class StudyNote {
  const StudyNote({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.lessonId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.aiFeedbackTitle,
    this.aiFeedbackMessage,
    this.aiFeedbackSteps,
    this.aiFeedbackWhyItWorks,
    this.aiFeedbackProvider,
  });

  final String id;
  final String userId;
  final String moduleId;
  final String lessonId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? aiFeedbackTitle;
  final String? aiFeedbackMessage;
  final List<String>? aiFeedbackSteps;
  final String? aiFeedbackWhyItWorks;
  final String? aiFeedbackProvider;

  factory StudyNote.fromJson(Map<String, dynamic> json) {
    return StudyNote(
      id: _readString(json, 'id'),
      userId: _readString(json, 'user_id'),
      moduleId: _readString(json, 'module_id'),
      lessonId: _readString(json, 'lesson_id'),
      title: _readString(json, 'title'),
      content: _readString(json, 'content'),
      createdAt: _readDateTime(json, 'created_at'),
      updatedAt: _readDateTime(json, 'updated_at'),
      aiFeedbackTitle: json['ai_feedback_title'] as String?,
      aiFeedbackMessage: json['ai_feedback_message'] as String?,
      aiFeedbackSteps: (json['ai_feedback_steps'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      aiFeedbackWhyItWorks: json['ai_feedback_why_it_works'] as String?,
      aiFeedbackProvider: json['ai_feedback_provider'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'module_id': moduleId,
      'lesson_id': lessonId,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (aiFeedbackTitle != null) 'ai_feedback_title': aiFeedbackTitle,
      if (aiFeedbackMessage != null) 'ai_feedback_message': aiFeedbackMessage,
      if (aiFeedbackSteps != null) 'ai_feedback_steps': aiFeedbackSteps,
      if (aiFeedbackWhyItWorks != null) 'ai_feedback_why_it_works': aiFeedbackWhyItWorks,
      if (aiFeedbackProvider != null) 'ai_feedback_provider': aiFeedbackProvider,
    };
  }

  StudyNote copyWith({
    String? id,
    String? userId,
    String? moduleId,
    String? lessonId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? aiFeedbackTitle,
    String? aiFeedbackMessage,
    List<String>? aiFeedbackSteps,
    String? aiFeedbackWhyItWorks,
    String? aiFeedbackProvider,
  }) {
    return StudyNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moduleId: moduleId ?? this.moduleId,
      lessonId: lessonId ?? this.lessonId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiFeedbackTitle: aiFeedbackTitle ?? this.aiFeedbackTitle,
      aiFeedbackMessage: aiFeedbackMessage ?? this.aiFeedbackMessage,
      aiFeedbackSteps: aiFeedbackSteps ?? this.aiFeedbackSteps,
      aiFeedbackWhyItWorks: aiFeedbackWhyItWorks ?? this.aiFeedbackWhyItWorks,
      aiFeedbackProvider: aiFeedbackProvider ?? this.aiFeedbackProvider,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StudyNote &&
            other.id == id &&
            other.userId == userId &&
            other.moduleId == moduleId &&
            other.lessonId == lessonId &&
            other.title == title &&
            other.content == content &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    moduleId,
    lessonId,
    title,
    content,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'StudyNote(id: $id, moduleId: $moduleId, lessonId: $lessonId, '
      'title: $title)';

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException(
        'Study note field "$key" must be a non-empty string.',
      );
    }
    return value;
  }

  static DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Study note field "$key" must be a timestamp.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException(
        'Study note field "$key" is not a valid timestamp.',
      );
    }
    return parsed;
  }
}
