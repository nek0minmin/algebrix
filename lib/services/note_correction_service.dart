import 'package:algebrix/models/note_correction_model.dart';
import 'package:algebrix/services/ai_tutor_service.dart';

/// Finds the exact words, calculations, and mathematical steps in a study note
/// that Xy's feedback says are wrong.
///
/// Xy explains what went wrong in feedback ("to solve 2x - 8 = 0, divide by 2,
/// not 4, giving x = 4"), and this service locates the exact offending text
/// (e.g. "x = 2", "dividing it by 4", or "commutative") so the editor can
/// highlight it in place and offer one-tap corrections.
class NoteCorrectionService {
  const NoteCorrectionService();

  /// Groups of algebra terms that are easy to confuse with one another.
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
  static final RegExp _rejectionPattern = RegExp(
    r"\b(?:not|instead of|rather than|isn't|wasn't|never)\b[^.!?;]{0,40}",
    caseSensitive: false,
  );

  /// Builds the correction list for a note from Xy's feedback.
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

    // ── 1. Structured AI Corrections ──────────────────────────────────────────
    // When the LLM explicitly returns `{original, replacement, why}` items.
    for (final aiCorr in feedback.corrections) {
      final orig = aiCorr.original.trim();
      final repl = aiCorr.replacement.trim();
      if (orig.isEmpty || repl.isEmpty || orig.toLowerCase() == repl.toLowerCase()) {
        continue;
      }

      for (final target in NoteCorrectionTarget.values) {
        final text = target == NoteCorrectionTarget.title ? title : body;
        final ranges = _findSnippetRanges(text, orig);
        for (final range in ranges) {
          if (_hasOverlap(corrections, target, range.$1, range.$2)) continue;

          final matchedText = text.substring(range.$1, range.$2);
          corrections.add(
            NoteCorrection(
              id: 'c${sequence++}',
              target: target,
              start: range.$1,
              end: range.$2,
              original: matchedText,
              suggestions: [repl],
              why: aiCorr.why ?? 'Xy suggests replacing this with "$repl".',
            ),
          );
        }
      }
    }

    // ── 2. Equation & Operation Mistake Heuristics ────────────────────────────
    // Fallback detecting mathematical miscalculations & equation steps.
    final eqCorrections = _detectEquationMistakes(
      title: title,
      body: body,
      haystack: haystack,
      existing: corrections,
      startSequence: sequence,
    );
    corrections.addAll(eqCorrections);
    sequence += eqCorrections.length;

    // ── 3. Confusable Vocabulary Term Groups ──────────────────────────────────
    for (final group in confusableGroups) {
      final rejected = _rejectedTerms(haystack, group);
      if (rejected.isEmpty) continue;

      final replacements = group
          .where((term) => !rejected.contains(term) && _mentions(haystack, term))
          .toList();
      if (replacements.isEmpty) continue;

      for (final wrongTerm in rejected) {
        for (final target in NoteCorrectionTarget.values) {
          final text = target == NoteCorrectionTarget.title ? title : body;

          for (final range in _findWord(text, wrongTerm)) {
            if (_hasOverlap(corrections, target, range.$1, range.$2)) continue;

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
                why: 'Xy says this should be the ${replacements.first} one.',
              ),
            );
          }
        }
      }
    }

    corrections.sort((a, b) {
      if (a.target != b.target) {
        return a.target == NoteCorrectionTarget.title ? -1 : 1;
      }
      return a.start.compareTo(b.start);
    });

    return List.unmodifiable(corrections);
  }

  /// Detects mathematical value mismatches (e.g. student wrote x = 2 when solution is x = 4,
  /// or student wrote "dividing it by 4" when the step is "divide by 2").
  List<NoteCorrection> _detectEquationMistakes({
    required String title,
    required String body,
    required String haystack,
    required List<NoteCorrection> existing,
    required int startSequence,
  }) {
    final results = <NoteCorrection>[];
    var seq = startSequence;

    // Pattern A: Variable solution mismatch
    // Look for correct solution statement in feedback: "solution is x = 4", "gives x = 4", etc.
    final solPatterns = [
      RegExp(r'\b(?:solution is|answer is|correct solution is|gives|giving|result is|equals|is)\s+([a-z]\s*=\s*-?\d+(?:\.\d+)?)', caseSensitive: false),
      RegExp(r'\*\*([a-z]\s*=\s*-?\d+(?:\.\d+)?)\*\*', caseSensitive: false),
    ];

    for (final pattern in solPatterns) {
      for (final match in pattern.allMatches(haystack)) {
        final rawEquation = match.group(1);
        if (rawEquation == null) continue;
        final parts = rawEquation.split('=');
        if (parts.length != 2) continue;

        final variable = parts[0].trim();
        final correctVal = parts[1].trim();

        // Check if student's title or body has variable = <different_val>
        for (final target in NoteCorrectionTarget.values) {
          final text = target == NoteCorrectionTarget.title ? title : body;
          final noteSolRegex = RegExp(
            r'\b' + RegExp.escape(variable) + r'\s*=\s*(-?\d+(?:\.\d+)?)\b',
            caseSensitive: false,
          );

          for (final noteMatch in noteSolRegex.allMatches(text)) {
            final studentVal = noteMatch.group(1)?.trim();
            if (studentVal != null && studentVal != correctVal) {
              final start = noteMatch.start;
              final end = noteMatch.end;
              if (_hasOverlap(existing, target, start, end) ||
                  _hasOverlap(results, target, start, end)) {
                continue;
              }

              results.add(
                NoteCorrection(
                  id: 'c${seq++}',
                  target: target,
                  start: start,
                  end: end,
                  original: text.substring(start, end),
                  suggestions: ['$variable = $correctVal'],
                  why: 'Xy says the correct solution is $variable = $correctVal.',
                ),
              );
            }
          }
        }
      }
    }

    // Pattern B: Operation number mismatch
    // E.g., feedback says "divide by 2" or "divide by the coefficient of x (2)", but student note has "dividing it by 4" or "divide by 4".
    final opRegex = RegExp(
      r'\b(divide|multiply|add|subtract)(?:[^\d\n.!?;]{0,35}?)\b\(?(-?\d+)\)?\b',
      caseSensitive: false,
    );

    for (final match in opRegex.allMatches(haystack)) {
      final op = match.group(1)?.toLowerCase();
      final correctNum = match.group(2);
      if (op == null || correctNum == null) continue;

      for (final target in NoteCorrectionTarget.values) {
        final text = target == NoteCorrectionTarget.title ? title : body;
        final noteOpRegex = RegExp(
          r'\b(' + op + r'[a-z]*(?:\s+it|\s+both sides)?\s+by)\s+(-?\d+)\b',
          caseSensitive: false,
        );

        for (final noteMatch in noteOpRegex.allMatches(text)) {
          final studentNum = noteMatch.group(2);
          if (studentNum != null && studentNum != correctNum) {
            final start = noteMatch.start;
            final end = noteMatch.end;
            if (_hasOverlap(existing, target, start, end) ||
                _hasOverlap(results, target, start, end)) {
              continue;
            }

            final prefix = noteMatch.group(1) ?? '$op by';
            results.add(
              NoteCorrection(
                id: 'c${seq++}',
                target: target,
                start: start,
                end: end,
                original: text.substring(start, end),
                suggestions: ['$prefix $correctNum'],
                why: 'Xy says to $op by $correctNum, not $studentNum.',
              ),
            );
          }
        }
      }
    }

    // Pattern C: Explicit number rejection
    // E.g., feedback says "which is 2, not 4" or "(2), not 4" or "divide by 2, not 4"
    final rejNumRegex = RegExp(
      r'\(?(\d+)\)?[,\s]+(?:not|instead of)\s+\(?(\d+)\)?',
      caseSensitive: false,
    );

    for (final match in rejNumRegex.allMatches(haystack)) {
      final correctNum = match.group(1);
      final wrongNum = match.group(2);
      if (correctNum == null || wrongNum == null || correctNum == wrongNum) {
        continue;
      }

      for (final target in NoteCorrectionTarget.values) {
        final text = target == NoteCorrectionTarget.title ? title : body;
        final pattern = RegExp(
          r'\b(?:by|with|to|into)\s+(' + RegExp.escape(wrongNum) + r')\b',
          caseSensitive: false,
        );

        for (final noteMatch in pattern.allMatches(text)) {
          final start = noteMatch.start;
          final end = noteMatch.end;
          if (_hasOverlap(existing, target, start, end) ||
              _hasOverlap(results, target, start, end)) {
            continue;
          }

          final wholeSnippet = text.substring(start, end);
          final replacement = wholeSnippet.replaceFirst(wrongNum, correctNum);

          results.add(
            NoteCorrection(
              id: 'c${seq++}',
              target: target,
              start: start,
              end: end,
              original: wholeSnippet,
              suggestions: [replacement],
              why: 'Xy says to use $correctNum instead of $wrongNum.',
            ),
          );
        }
      }
    }

    return results;
  }

  bool _hasOverlap(List<NoteCorrection> list, NoteCorrectionTarget target, int start, int end) {
    return list.any((c) => c.target == target && !(c.end <= start || c.start >= end));
  }

  /// Locates exact or whitespace-tolerant occurrences of [snippet] in [text].
  List<(int, int)> _findSnippetRanges(String text, String snippet) {
    if (snippet.isEmpty || text.isEmpty) return const [];
    final lowerText = text.toLowerCase();
    final lowerSnippet = snippet.toLowerCase().trim();

    final ranges = <(int, int)>[];
    var start = 0;
    while (start < lowerText.length) {
      final idx = lowerText.indexOf(lowerSnippet, start);
      if (idx == -1) break;
      ranges.add((idx, idx + lowerSnippet.length));
      start = idx + lowerSnippet.length;
    }

    if (ranges.isNotEmpty) return ranges;

    // Whitespace tolerant match around math operators (e.g. "x=2" vs "x = 2")
    try {
      final escaped = RegExp.escape(lowerSnippet).replaceAll(r'\ ', r'\s*');
      final regex = RegExp(escaped, caseSensitive: false);
      for (final match in regex.allMatches(text)) {
        ranges.add((match.start, match.end));
      }
    } catch (_) {}

    return ranges;
  }

  /// Terms from [group] that the feedback explicitly rejects.
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

  /// Matches the capitalisation of the word being replaced.
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
