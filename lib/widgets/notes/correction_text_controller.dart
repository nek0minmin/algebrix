import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/models/note_correction_model.dart';

/// A [TextEditingController] that paints Xy's corrections behind the text.
///
/// Pending corrections get a yellow highlighter; once the learner accepts a
/// suggestion the same span turns teal, so a note visibly shows what was fixed.
///
/// Nothing else about the field changes — typing, selection, validation, and
/// saving all behave exactly as before. A highlight simply stops being drawn as
/// soon as the text under it no longer matches what was flagged.
class CorrectionTextEditingController extends TextEditingController {
  CorrectionTextEditingController({super.text});

  List<NoteCorrection> _corrections = const [];

  /// Corrections belonging to this field.
  List<NoteCorrection> get corrections => _corrections;

  set corrections(List<NoteCorrection> value) {
    _corrections = List.unmodifiable(value);
    notifyListeners();
  }

  /// Corrections whose text is still exactly where it was flagged.
  List<NoteCorrection> get liveCorrections {
    final live = _corrections.where((c) => c.matches(text)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return live;
  }

  /// The pending correction under [offset], if any.
  NoteCorrection? correctionAt(int offset) {
    for (final correction in liveCorrections) {
      if (correction.containsOffset(offset)) return correction;
    }
    return null;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final live = liveCorrections;
    if (live.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final children = <TextSpan>[];
    var cursor = 0;

    for (final correction in live) {
      // Overlapping or out-of-order spans would corrupt the run; skip rather
      // than render the text twice.
      if (correction.start < cursor) continue;

      if (correction.start > cursor) {
        children.add(
          TextSpan(text: text.substring(cursor, correction.start), style: style),
        );
      }

      children.add(
        TextSpan(
          text: text.substring(correction.start, correction.end),
          style: (style ?? const TextStyle()).copyWith(
            backgroundColor: correction.isApplied
                ? AppColors.mint.withValues(alpha: 0.38)
                : AppColors.yellow.withValues(alpha: 0.45),
            fontWeight: FontWeight.w800,
            color: correction.isApplied
                ? const Color(0xFF12695E)
                : const Color(0xFF7A5300),
          ),
        ),
      );

      cursor = correction.end;
    }

    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor), style: style));
    }

    return TextSpan(style: style, children: children);
  }
}
