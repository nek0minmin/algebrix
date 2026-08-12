enum LessonStepType {
  intro, // Xy introduction with mascot image + body text
  content, // Educational content with explanation
  xySays, // Xy mascot tip/insight bubble
  interactive, // Interactive activity (mystery box, choices)
  quiz, // Multiple choice quiz question
  summary, // Lesson completion summary
  activity, // Typed interactive learning activity
}

sealed class LessonActivityData {
  const LessonActivityData();
}

class ActivityCategory {
  final String id;
  final String label;
  const ActivityCategory({required this.id, required this.label});
}

class ClassificationItem {
  final String id;
  final String label;
  final String categoryId;
  const ClassificationItem({
    required this.id,
    required this.label,
    required this.categoryId,
  });
}

class ClassificationActivityData extends LessonActivityData {
  final List<ActivityCategory> categories;
  final List<ClassificationItem> items;
  const ClassificationActivityData({
    required this.categories,
    required this.items,
  });
}

class TermToken {
  final String id;
  final String label;
  final bool isTerm;
  const TermToken({
    required this.id,
    required this.label,
    required this.isTerm,
  });
}

class TermSelectionActivityData extends LessonActivityData {
  final List<TermToken> tokens;
  const TermSelectionActivityData({required this.tokens});
}

class OrderingItem {
  final String id;
  final String label;
  const OrderingItem({required this.id, required this.label});
}

class OrderingActivityData extends LessonActivityData {
  final List<OrderingItem> items;
  final List<String> correctOrderIds;
  const OrderingActivityData({
    required this.items,
    required this.correctOrderIds,
  });
}

class ChoiceOption {
  final String label;
  final String? emoji;
  final bool isCorrect;
  const ChoiceOption({required this.label, this.emoji, this.isCorrect = false});
}

class LessonStep {
  final String id;
  final LessonStepType type;
  final String? title;
  final String? xyDialogue;
  final String? xyAsset;
  final String? bodyText;
  final String? mathExpression;
  final String? mathAnnotation;
  final List<String>? bulletPoints;
  final String? question;
  final List<ChoiceOption>? choices;
  final int? correctChoiceIndex;
  final String? explanation;
  final String? incorrectExplanation;
  final String? buttonLabel;
  final bool isAnswerStep;
  final LessonActivityData? activity;

  const LessonStep({
    required this.id,
    required this.type,
    this.title,
    this.xyDialogue,
    this.xyAsset,
    this.bodyText,
    this.mathExpression,
    this.mathAnnotation,
    this.bulletPoints,
    this.question,
    this.choices,
    this.correctChoiceIndex,
    this.explanation,
    this.incorrectExplanation,
    this.buttonLabel,
    this.isAnswerStep = false,
    this.activity,
  });
}

class LessonContent {
  final String lessonId;
  final String title;
  final String moduleId;
  final String moduleTitle;
  final String objective;
  final String xyAsset;
  final List<LessonStep> steps;

  const LessonContent({
    required this.lessonId,
    required this.title,
    required this.moduleId,
    required this.moduleTitle,
    required this.objective,
    required this.xyAsset,
    required this.steps,
  });

  int get totalSteps => steps.length;
}

class ModuleContent {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String? xyDialogue;
  final String? xyAsset;
  final String? buttonLabel;
  final List<LessonContent> lessons;

  const ModuleContent({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.xyDialogue,
    this.xyAsset,
    this.buttonLabel,
    required this.lessons,
  });
}
