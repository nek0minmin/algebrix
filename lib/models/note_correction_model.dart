/// Which field of a study note a correction points at.
enum NoteCorrectionTarget { title, body }

/// A span of note text Xy believes is wrong, with the replacements it offers.
///
/// Offsets are into the raw field text. They are only ever trusted when
/// [matches] confirms the text at that range is still what was flagged — a
/// learner may keep typing after an analysis, and a stale highlight pointing at
/// the wrong word is worse than no highlight.
class NoteCorrection {
  const NoteCorrection({
    required this.id,
    required this.target,
    required this.start,
    required this.end,
    required this.original,
    required this.suggestions,
    this.why,
    this.appliedReplacement,
  });

  final String id;
  final NoteCorrectionTarget target;
  final int start;
  final int end;

  /// The text originally flagged, e.g. "commutative".
  final String original;

  /// Replacements offered to the learner, best first.
  final List<String> suggestions;

  /// One short line explaining the fix, shown above the choices.
  final String? why;

  /// The suggestion the learner picked, or null while still pending.
  final String? appliedReplacement;

  bool get isApplied => appliedReplacement != null;

  /// The text this correction currently expects to occupy its range.
  String get currentText => appliedReplacement ?? original;

  /// Whether [text] still contains this correction's word at its range.
  bool matches(String text) {
    if (start < 0 || end > text.length || start >= end) return false;
    return text.substring(start, end) == currentText;
  }

  bool containsOffset(int offset) => offset >= start && offset <= end;

  NoteCorrection copyWith({
    int? start,
    int? end,
    String? appliedReplacement,
  }) {
    return NoteCorrection(
      id: id,
      target: target,
      start: start ?? this.start,
      end: end ?? this.end,
      original: original,
      suggestions: suggestions,
      why: why,
      appliedReplacement: appliedReplacement ?? this.appliedReplacement,
    );
  }

  /// Shifts this correction by [delta] characters.
  ///
  /// Used when an earlier correction in the same field is applied and changes
  /// the text length, moving everything after it.
  NoteCorrection shifted(int delta) =>
      copyWith(start: start + delta, end: end + delta);
}

/// The result of applying one suggestion: the new field text plus the
/// correction list with every offset kept in step.
class NoteCorrectionApplyResult {
  const NoteCorrectionApplyResult({
    required this.text,
    required this.corrections,
    required this.applied,
  });

  final String text;
  final List<NoteCorrection> corrections;
  final NoteCorrection applied;
}

/// Applies [replacement] to [correction] within [text].
///
/// Returns the rewritten text and a correction list whose later entries have
/// been shifted by the length change, so the remaining highlights stay on the
/// words they were pointing at.
NoteCorrectionApplyResult applyNoteCorrection({
  required String text,
  required List<NoteCorrection> corrections,
  required NoteCorrection correction,
  required String replacement,
}) {
  if (!correction.matches(text)) {
    return NoteCorrectionApplyResult(
      text: text,
      corrections: corrections,
      applied: correction,
    );
  }

  final updatedText =
      text.replaceRange(correction.start, correction.end, replacement);
  final delta = replacement.length - (correction.end - correction.start);

  final applied = correction.copyWith(
    end: correction.start + replacement.length,
    appliedReplacement: replacement,
  );

  final updated = <NoteCorrection>[
    for (final entry in corrections)
      if (entry.id == correction.id)
        applied
      else if (entry.target == correction.target && entry.start >= correction.end)
        entry.shifted(delta)
      else
        entry,
  ];

  return NoteCorrectionApplyResult(
    text: updatedText,
    corrections: updated,
    applied: applied,
  );
}
