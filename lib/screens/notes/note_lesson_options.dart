import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';

class NoteLessonOption {
  const NoteLessonOption({
    required this.moduleId,
    required this.lessonId,
    required this.label,
  });

  final String moduleId;
  final String lessonId;
  final String label;
}

final List<NoteLessonOption> noteLessonOptions = List.unmodifiable([
  ...module1.lessons.asMap().entries.map(
    (entry) => NoteLessonOption(
      moduleId: module1.id,
      lessonId: entry.value.lessonId,
      label: '1.${entry.key + 1} • ${entry.value.title}',
    ),
  ),
  ...module2.lessons.asMap().entries.map(
    (entry) => NoteLessonOption(
      moduleId: module2.id,
      lessonId: entry.value.lessonId,
      label: '2.${entry.key + 1} • ${entry.value.title}',
    ),
  ),
]);

NoteLessonOption? noteLessonOptionFor(String lessonId) {
  for (final option in noteLessonOptions) {
    if (option.lessonId == lessonId) return option;
  }
  return null;
}

String noteLessonLabel(String lessonId) =>
    noteLessonOptionFor(lessonId)?.label ?? 'Algebra Foundations';
