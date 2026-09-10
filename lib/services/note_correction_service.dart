import 'package:algebrix/models/note_correction_model.dart';
import 'package:algebrix/services/ai_tutor_service.dart';

/// Finds the exact words in a study note that Xy's feedback says are wrong.
///
/// Xy already tells the learner *that* something is wrong ("the rule you used
/// is the distributive property, not the commutative property"), but the note
/// itself gives no clue *where*. This locates the offending word so the editor
/// can highlight it and offer the fix in place.
///
/// Detection is deliberately conservative: a wrong highlight on a correct word
/// is worse than no highlight at all, so a term is only flagged when the
/// feedback explicitly rejects it.
class NoteCorrectionService {
  const NoteCorrectionService();

  /// Groups of algebra terms that are easy to confuse with one another.
  ///
  /// A correction is only ever offered between members of the same group, so
  /// the app cannot suggest replacing "coefficient" with "denominator".
  static const List<List<String>> confusableGroups = [
    ['commutative', 'associative', 'distributive', 'identity', 'inverse'],
    ['coefficient', 'constant', 'variable', 'term', 'exponent'],
    ['expression', 'equation', 'inequality'],
    ['numerator', 'denominator'],
    ['multiply', 'divide', 'add', 'subtract'],
    ['factor', 'expand', 'simplify', 'evaluate'],
    ['sum', 'difference', 'product', 'quotient'],
  ];

  /// A rejection cue plus the short window of words that follows it.
  ///
  /// Greedy within the window on purpose: a lazy match stops at the first word
  /// ("not the"), which never reaches the term being rejected. The window stops
  /// at sentence punctuation so a rejection cannot leak into the next clause.
  static final RegExp _rejectionPattern = RegExp(
    r"\b(?:not|instead of|rather than|isn't|wasn't|never)\b[^.!?;]{0,40}",
    caseSensitive: false,
  );

  /// Builds the correction list for a note from Xy's feedback.
  ///
  /// [aiCorrections] carries structured `{original, replacement, why}` entries
  /// when the model returns them; the term-group scan below is the fallback
  /// that works when it does not.
  List<NoteCorrection> detect({
    required String title,
    required String body,
    AiFeedbackResult? feedback,
  }) {
    if (feedback == null) return const [];

    final haystack =
        '${feedback.title} ${feedback.message} ${feedback.whyItWorks ?? ''} '
                '${feedback.keyConcept ?? ''} ${feedback.steps.join(' ')}'
            .toLowerCase();
    if (haystack.trim().isEmpty) return const [];

    final corrections = <NoteCorrection>[];
    var sequence = 0;

    for (final group in confusableGroups) {
      final rejected = _rejectedTerms(haystack, group);
      if (rejected.isEmpty) continue;

      // Anything from the same group the feedback mentions but does not
      // reject is a candidate replacement.
      final replacements = group
          .where((term) => !rejected.contains(term) && _mentions(haystack, term))
          .toList();
      if (replacements.isEmpty) continue;

      for (final wrongTerm in rejected) {
        for (final target in NoteCorrectionTarget.values) {
          final text = target == NoteCorrectionTarget.title ? title : body;

          for (final range in _findWord(text, wrongTerm)) {
            corrections.add(
              NoteCorrection(
                id: 'c${sequence++}',
                target: target,
                start: range.$1,
                end: range.$2,
                original: text.substring(range.$1, range.$2),
                suggestions: _casedLike(
                  text.substring(range.$1, range.$2),
                  replacements,
                ),
                why: 'Xy says this should be the '
                    '${replacements.first} one.',
              ),
            );
          }
        }
      }
    }

    return List.unmodifiable(corrections);
  }

  /// Terms from [group] that the feedback explicitly rejects.
  ///
  /// Only the term nearest each rejection cue is taken. "…the distributive
  /// property, not the commutative property" must reject *commutative* alone —
  /// scanning the whole clause would reject both and leave nothing to suggest.
  Set<String> _rejectedTerms(String haystack, List<String> group) {
    final rejected = <String>{};

    for (final match in _rejectionPattern.allMatches(haystack)) {
      final clause = match.group(0) ?? '';

      String? nearest;
      var nearestIndex = clause.length;

      for (final term in group) {
        final termMatch =
            RegExp('\\b${RegExp.escape(term)}\\b', caseSensitive: false)
                .firstMatch(clause);
        if (termMatch != null && termMatch.start < nearestIndex) {
          nearest = term;
          nearestIndex = termMatch.start;
        }
      }

      if (nearest != null) rejected.add(nearest);
    }

    return rejected;
  }

  bool _mentions(String haystack, String term) =>
      RegExp('\\b${RegExp.escape(term)}\\b', caseSensitive: false)
          .hasMatch(haystack);

  /// Every whole-word occurrence of [word] in [text], as (start, end) pairs.
  List<(int, int)> _findWord(String text, String word) {
    final pattern = RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
    return [
      for (final match in pattern.allMatches(text)) (match.start, match.end),
    ];
  }

  /// Matches the capitalisation of the word being replaced, so swapping
  /// "Commutative" does not leave a lowercase word mid-sentence.
  List<String> _casedLike(String original, List<String> replacements) {
    final isCapitalised = original.isNotEmpty &&
        original[0] == original[0].toUpperCase() &&
        original[0] != original[0].toLowerCase();

    if (!isCapitalised) return List.unmodifiable(replacements);

    return List.unmodifiable([
      for (final value in replacements)
        value.isEmpty
            ? value
            : '${value[0].toUpperCase()}${value.substring(1)}',
    ]);
  }
}
