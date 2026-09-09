import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';

/// One answer option, marked as the correct answer and/or the learner's pick.
///
/// Shared by the quiz attempt review and the lesson mistake list so a wrong
/// answer looks the same wherever it is revisited.
///
/// Colour is never the only signal: each state also carries an icon and a text
/// tag, so the review stays readable without colour vision.
class ReviewedOptionRow extends StatelessWidget {
  const ReviewedOptionRow({
    super.key,
    required this.text,
    required this.isCorrectAnswer,
    required this.isLearnerAnswer,
  });

  final String text;
  final bool isCorrectAnswer;
  final bool isLearnerAnswer;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color background;
    final IconData? marker;
    final Color markerColor;
    final String? tag;

    if (isCorrectAnswer) {
      borderColor = AppColors.mint;
      background = AppColors.lightMint.withValues(alpha: 0.6);
      marker = Icons.check_circle_rounded;
      markerColor = AppColors.mint;
      tag = isLearnerAnswer ? 'Your answer · Correct' : 'Correct answer';
    } else if (isLearnerAnswer) {
      borderColor = AppColors.pink;
      background = AppColors.extraLightPink;
      marker = Icons.cancel_rounded;
      markerColor = AppColors.pink;
      tag = 'Your answer';
    } else {
      borderColor = AppColors.border;
      background = AppColors.card;
      marker = null;
      markerColor = AppColors.subtitle;
      tag = null;
    }

    return Semantics(
      label: tag == null ? text : '$text, $tag',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: marker == null ? 1.2 : 1.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              marker ?? Icons.radio_button_unchecked_rounded,
              size: 17,
              color: marker == null ? AppColors.border : markerColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight:
                          marker == null ? FontWeight.w600 : FontWeight.w800,
                      color: marker == null
                          ? AppColors.textSecondary
                          : AppColors.text,
                      height: 1.35,
                    ),
                  ),
                  if (tag != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      tag,
                      style: GoogleFonts.nunito(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: markerColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Why" callout shown under a reviewed question.
class ReviewExplanationBox extends StatelessWidget {
  const ReviewExplanationBox({super.key, required this.explanation});

  final String explanation;

  @override
  Widget build(BuildContext context) {
    if (explanation.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightPurple.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                size: 15,
                color: AppColors.purple,
              ),
              const SizedBox(width: 6),
              Text(
                'Why',
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            explanation,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
