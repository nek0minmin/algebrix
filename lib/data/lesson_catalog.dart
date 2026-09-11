import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';
import 'package:algebrix/data/module3_content.dart';
import 'package:algebrix/data/module4_content.dart';
import 'package:algebrix/data/module5_content.dart';
import 'package:algebrix/data/module6_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// Single ordered registry of every shipped module and lesson.
///
/// Lookups elsewhere used chained `moduleId == 'module1' ? ... : ...`
/// expressions; the mastery module needs id-to-lesson resolution in several
/// places, so it lives here once.
class LessonCatalog {
  LessonCatalog._();

  /// Modules in learning order.
  static final List<ModuleContent> modules = List.unmodifiable([
    module1,
    module2,
    module3,
    module4,
    module5,
    module6,
  ]);

  /// Every lesson across every module, in learning order.
  static final List<LessonContent> lessons = List.unmodifiable([
    for (final module in modules) ...module.lessons,
  ]);

  static final Map<String, ModuleContent> _modulesById = {
    for (final module in modules) module.id: module,
  };

  static final Map<String, LessonContent> _lessonsById = {
    for (final lesson in lessons) lesson.lessonId: lesson,
  };

  /// 1-based module position, e.g. `module2` -> 2.
  static final Map<String, int> _moduleNumbers = {
    for (var i = 0; i < modules.length; i++) modules[i].id: i + 1,
  };

  /// 1-based lesson position within its own module.
  static final Map<String, int> _lessonNumbers = {
    for (final module in modules)
      for (var i = 0; i < module.lessons.length; i++)
        module.lessons[i].lessonId: i + 1,
  };

  /// Total lessons across all shipped modules.
  static int get totalLessons => lessons.length;

  static ModuleContent? moduleById(String? moduleId) =>
      moduleId == null ? null : _modulesById[moduleId];

  static LessonContent? lessonById(String? lessonId) =>
      lessonId == null ? null : _lessonsById[lessonId];

  /// The module a lesson belongs to, resolved from the lesson itself.
  static ModuleContent? moduleForLesson(String lessonId) {
    final lesson = lessonById(lessonId);
    if (lesson == null) return null;
    return moduleById(lesson.moduleId);
  }

  static int moduleNumber(String moduleId) => _moduleNumbers[moduleId] ?? 0;

  static int lessonNumber(String lessonId) => _lessonNumbers[lessonId] ?? 0;

  /// Short positional label, e.g. "2.3".
  static String lessonNumberLabel(String lessonId) {
    final lesson = lessonById(lessonId);
    if (lesson == null) return '';
    return '${moduleNumber(lesson.moduleId)}.${lessonNumber(lessonId)}';
  }

  /// Display label, e.g. "2.3 · Distributive Property".
  static String lessonLabel(String lessonId) {
    final lesson = lessonById(lessonId);
    if (lesson == null) return 'Algebra';
    return '${lessonNumberLabel(lessonId)} · ${lesson.title}';
  }

  /// Index of the step with [stepId] inside [lessonId], or null when absent.
  static int? stepIndexOf(String lessonId, String stepId) {
    final lesson = lessonById(lessonId);
    if (lesson == null) return null;
    final index = lesson.steps.indexWhere((step) => step.id == stepId);
    return index < 0 ? null : index;
  }

  /// The first step of [lessonId] that asks the learner a question.
  ///
  /// Used to drop a learner straight into practice rather than at the intro
  /// when they open a concept from the review list.
  static int? firstAnswerStepIndex(String lessonId) {
    final lesson = lessonById(lessonId);
    if (lesson == null) return null;
    final index = lesson.steps.indexWhere(
      (step) => step.isAnswerStep || step.choices != null || step.activity != null,
    );
    return index < 0 ? null : index;
  }
}
