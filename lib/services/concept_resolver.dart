import 'package:algebrix/data/lesson_catalog.dart';
import 'package:algebrix/screens/notes/note_lesson_options.dart';

/// Maps a free-text concept label onto a real lesson.
///
/// Module quizzes are AI-generated, so each question carries a
/// `subLessonTitle` like "Combining like terms" rather than a lesson id.
/// Aggregating mastery per concept, and linking a weak concept back to the
/// lesson that teaches it, both need that string resolved to an `m2_l2`.
///
/// Scoring reuses the per-lesson keyword lists already maintained for study
/// notes, so there is one place to teach the app new vocabulary.
class ConceptResolver {
  const ConceptResolver();

  /// Below this the match is treated as too weak to trust, and the question is
  /// counted toward overall accuracy but not attributed to any lesson.
  static const int minimumScore = 4;

  /// Resolves [conceptLabel] to a lesson id, or null when nothing matches
  /// confidently.
  ///
  /// [moduleId] narrows the search to one module when known — a quiz always
  /// knows which module it came from, which removes most cross-module
  /// ambiguity (e.g. "expressions" appears in both Module 1 and Module 2).
  String? resolveLessonId(String? conceptLabel, {String? moduleId}) {
    if (conceptLabel == null) return null;

    final needle = _normalize(conceptLabel);
    if (needle.isEmpty) return null;

    String? bestLessonId;
    var bestScore = 0;

    for (final option in noteLessonOptions) {
      if (moduleId != null && option.moduleId != moduleId) continue;

      final score = _score(needle, option);
      if (score > bestScore) {
        bestScore = score;
        bestLessonId = option.lessonId;
      }
    }

    // Nothing in the stated module matched; the label may name a prerequisite
    // concept taught earlier, so widen the search before giving up.
    if (bestScore < minimumScore && moduleId != null) {
      for (final option in noteLessonOptions) {
        final score = _score(needle, option);
        if (score > bestScore) {
          bestScore = score;
          bestLessonId = option.lessonId;
        }
      }
    }

    return bestScore >= minimumScore ? bestLessonId : null;
  }

  int _score(String needle, NoteLessonOption option) {
    var score = 0;

    final title = _normalize(option.title);
    final titleStem = _singularize(title);

    if (title.isNotEmpty && _containsPhrase(needle, title)) {
      score += 10;
    } else if (titleStem.isNotEmpty && _containsPhrase(needle, titleStem)) {
      score += 8;
    }

    for (final keyword in option.keywords) {
      final normalized = _normalize(keyword);
      if (normalized.isEmpty) continue;
      if (_containsPhrase(needle, normalized)) {
        // Longer keywords are far more specific: "combining like terms" should
        // outweigh a bare "terms".
        score += normalized.length > 12
            ? 8
            : normalized.length > 5
                ? 4
                : 2;
      }
    }

    return score;
  }

  /// Compiled patterns, keyed by phrase.
  ///
  /// Mastery recomputes across every lesson and every retained question, so the
  /// same few dozen phrases are matched repeatedly.
  static final Map<String, RegExp> _phrasePatterns = {};

  /// Whether [haystack] contains [phrase] as whole words.
  ///
  /// Substring matching is not safe here: "watermelon" contains "term", which
  /// would attribute an off-topic question to the Terms lesson. A trailing
  /// optional "s" keeps simple plurals matching.
  bool _containsPhrase(String haystack, String phrase) {
    if (phrase.isEmpty) return false;

    final pattern = _phrasePatterns.putIfAbsent(
      phrase,
      () => RegExp('\\b${RegExp.escape(phrase)}s?\\b'),
    );
    return pattern.hasMatch(haystack);
  }

  String _normalize(String raw) => raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _singularize(String value) =>
      value.endsWith('s') ? value.substring(0, value.length - 1) : value;

  /// Human label for a resolved lesson, e.g. "2.3 · Distributive Property".
  static String labelFor(String lessonId) =>
      LessonCatalog.lessonLabel(lessonId);
}
