import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';

/// Parses the lightweight markup used throughout lesson content.
///
/// Two markers are supported, and both are always *consumed* — a learner must
/// never see a raw `*` or backtick on screen:
///
///   `**bold**`  → brand-pink emphasis
///   `` `code` `` → a purple math pill
///
/// This exists because the same markup was previously parsed in three
/// different places and ignored in three others, so `**not**` rendered as
/// literal asterisks on some steps and — worse — as a pink multiplication sign
/// on question text, where `*` was being tokenised as an operator.
List<InlineSpan> buildLessonSpans(
  String text, {
  required TextStyle base,
  required TextStyle emphasis,
  double codeFontSize = 13.5,
}) {
  final spans = <InlineSpan>[];
  final boldParts = text.split('**');

  for (var i = 0; i < boldParts.length; i++) {
    final part = boldParts[i];
    if (part.isEmpty) continue;

    // Odd indices sit between a pair of ** markers.
    if (i.isOdd) {
      spans.add(TextSpan(text: part, style: emphasis));
      continue;
    }

    final codeParts = part.split('`');
    for (var c = 0; c < codeParts.length; c++) {
      final chunk = codeParts[c];
      if (chunk.isEmpty) continue;

      if (c.isOdd) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lightPurple,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                chunk,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: codeFontSize,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purple,
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: chunk, style: base));
      }
    }
  }

  // A string of pure markers would otherwise render as nothing at all.
  if (spans.isEmpty) spans.add(TextSpan(text: text, style: base));

  return spans;
}

/// Renders lesson copy with `**bold**` and `` `code` `` markup resolved.
class LessonRichText extends StatelessWidget {
  const LessonRichText(
    this.text, {
    super.key,
    required this.base,
    required this.emphasis,
    this.textAlign = TextAlign.center,
    this.codeFontSize = 13.5,
  });

  final String text;
  final TextStyle base;
  final TextStyle emphasis;
  final TextAlign textAlign;
  final double codeFontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: buildLessonSpans(
          text,
          base: base,
          emphasis: emphasis,
          codeFontSize: codeFontSize,
        ),
      ),
      textAlign: textAlign,
    );
  }
}
