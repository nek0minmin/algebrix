import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';

class NoteLessonOption {
  const NoteLessonOption({
    required this.moduleId,
    required this.moduleName,
    required this.lessonId,
    required this.label,
    required this.title,
    required this.lessonNumber,
    this.keywords = const [],
  });

  final String moduleId;
  final String moduleName;
  final String lessonId;
  final String label;
  final String title;
  final String lessonNumber;
  final List<String> keywords;
}

final List<NoteLessonOption> noteLessonOptions = List.unmodifiable([
  ...module1.lessons.asMap().entries.map(
    (entry) => NoteLessonOption(
      moduleId: module1.id,
      moduleName: 'Module 1: ${module1.title}',
      lessonId: entry.value.lessonId,
      lessonNumber: '1.${entry.key + 1}',
      title: entry.value.title,
      label: '1.${entry.key + 1} • ${entry.value.title}',
      keywords: _keywordsFor(entry.value.lessonId),
    ),
  ),
  ...module2.lessons.asMap().entries.map(
    (entry) => NoteLessonOption(
      moduleId: module2.id,
      moduleName: 'Module 2: ${module2.title}',
      lessonId: entry.value.lessonId,
      lessonNumber: '2.${entry.key + 1}',
      title: entry.value.title,
      label: '2.${entry.key + 1} • ${entry.value.title}',
      keywords: _keywordsFor(entry.value.lessonId),
    ),
  ),
]);

List<String> _keywordsFor(String lessonId) {
  return switch (lessonId) {
    'm1_l1' => const ['variable', 'variables', 'container', 'placeholder', 'unknown value', 'unknowns', 'letter in math'],
    'm1_l2' => const ['constant', 'constants', 'fixed value', 'standalone number', 'fixed number', 'unchanging'],
    'm1_l3' => const ['terms', 'separated by plus', 'separated by minus', 'monomial'],
    'm1_l4' => const ['expression', 'expressions', 'algebraic expression', 'math phrase', 'combine operations', 'no equal sign'],
    'm1_l5' => const ['coefficient', 'coefficients', 'number in front', 'multiplier', 'attached to variable'],
    'm1_l6' => const ['order of operations', 'pemdas', 'parentheses first', 'precedence', 'operation order', 'bodmas'],
    'm2_l1' => const ['like terms', 'like term', 'same variable and exponent', 'matching terms'],
    'm2_l2' => const ['combining like terms', 'combine like terms', 'combine terms', 'simplifying expressions', 'add like terms'],
    'm2_l3' => const ['distributive property', 'distribute', 'expanding parentheses', 'multiply across', 'expand brackets'],
    'm2_l4' => const ['factoring', 'factor', 'greatest common factor', 'gcf', 'pulling out common', 'reverse distributive'],
    'm2_l5' => const ['multiplying expressions', 'foil', 'binomial multiplication', 'product of expressions', 'multiply binomials'],
    'm2_l6' => const ['dividing expressions', 'divide expressions', 'cancel terms', 'quotient of expressions'],
    'm2_l7' => const ['algebraic fraction', 'algebraic fractions', 'rational expression', 'fraction simplification', 'numerator', 'denominator'],
    _ => const [],
  };
}

NoteLessonOption? noteLessonOptionFor(String lessonId) {
  for (final option in noteLessonOptions) {
    if (option.lessonId == lessonId) return option;
  }
  return null;
}

String noteLessonLabel(String lessonId) =>
    noteLessonOptionFor(lessonId)?.label ?? 'Algebra Foundations';

/// Determines the best-matching lesson based on the student's note content,
/// title, and AI synthesized feedback concepts.
NoteLessonOption? detectBestFittingLesson({
  required String title,
  required String content,
  String? keyConcept,
  String? aiTitle,
  String? aiMessage,
}) {
  final combinedText = '$title $content ${keyConcept ?? ''} ${aiTitle ?? ''} ${aiMessage ?? ''}'
      .toLowerCase();

  NoteLessonOption? bestOption;
  int bestScore = 0;

  for (final option in noteLessonOptions) {
    int score = 0;

    final lowerTitle = option.title.toLowerCase();
    final singularStem = lowerTitle.endsWith('s')
        ? lowerTitle.substring(0, lowerTitle.length - 1)
        : lowerTitle;

    // Direct title/stem match
    if (combinedText.contains(lowerTitle) || combinedText.contains(singularStem)) {
      score += 6;
    }

    // Title words in note title (highest priority)
    final lowerNoteTitle = title.toLowerCase();
    if (lowerNoteTitle.contains(lowerTitle) || lowerNoteTitle.contains(singularStem)) {
      score += 8;
    }

    // Key concept match from AI
    if (keyConcept != null && keyConcept.toLowerCase().contains(singularStem)) {
      score += 10;
    }

    // Keyword matching
    for (final kw in option.keywords) {
      if (combinedText.contains(kw)) {
        score += kw.length > 5 ? 4 : 2;
      }
    }

    if (score > bestScore) {
      bestScore = score;
      bestOption = option;
    }
  }

  if (bestScore >= 4) {
    return bestOption;
  }

  return null;
}
