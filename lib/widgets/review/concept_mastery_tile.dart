import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/models/concept_mastery_model.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// Palette for a mastery band.
///
/// Every band also carries a written label wherever this is used, so the colour
/// reinforces the reading rather than carrying it alone.
({Color accent, Color background}) masteryBandColors(MasteryBand band) {
  return switch (band) {
    MasteryBand.mastered => (
        accent: AppColors.mint,
        background: AppColors.lightMint,
      ),
    MasteryBand.solid => (
        accent: AppColors.purple,
        background: AppColors.lightPurple,
      ),
    MasteryBand.shaky => (
        accent: AppColors.yellow,
        background: AppColors.lightYellow,
      ),
    MasteryBand.needsWork => (
        accent: AppColors.pink,
        background: AppColors.extraLightPink,
      ),
    MasteryBand.notAssessed => (
        accent: AppColors.subtitle,
        background: AppColors.divider,
      ),
  };
}

/// Small pill showing a mastery band by name and colour.
class MasteryBandChip extends StatelessWidget {
  const MasteryBandChip({super.key, required this.band, this.compact = false});

  final MasteryBand band;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = masteryBandColors(band);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.accent.withValues(alpha: 0.55)),
      ),
      child: Text(
        band.label,
        style: GoogleFonts.nunito(
          fontSize: compact ? 9.5 : 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
          color: colors.accent == AppColors.yellow
              ? const Color(0xFF9A6B00)
              : colors.accent,
        ),
      ),
    );
  }
}

/// One concept in a mastery or practice list.
///
/// Tapping opens the lesson behind it — that link is what makes the analytics
/// actionable rather than merely informative.
class ConceptMasteryTile extends StatelessWidget {
  const ConceptMasteryTile({
    super.key,
    required this.concept,
    required this.onTap,
    this.showDueBadge = false,
    this.trailing,
  });

  final ConceptMastery concept;
  final VoidCallback onTap;

  /// Shows the spaced-review state (due now / strength) instead of staying
  /// purely descriptive. Used in the practice queue.
  final bool showDueBadge;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = masteryBandColors(concept.band);
    final accuracy = concept.quizAccuracy;

    return Semantics(
      button: true,
      label:
          '${concept.lessonTitle}, ${concept.band.label}. Tap to practice.',
      child: BouncyPressable(
        key: Key('concept-tile-${concept.lessonId}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accuracy dial, or a dash when never quizzed.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    accuracy == null ? '—' : '${accuracy.round()}%',
                    style: GoogleFonts.nunito(
                      fontSize: accuracy == null ? 16 : 13,
                      fontWeight: FontWeight.w900,
                      color: colors.accent == AppColors.yellow
                          ? const Color(0xFF9A6B00)
                          : colors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${concept.lessonNumberLabel} · ${concept.lessonTitle}',
                      style: GoogleFonts.nunito(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // In the practice queue every concept is already due, so
                    // the useful thing to show is *why* it is there. In the
                    // mastery list the useful thing is the quiz record.
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        MasteryBandChip(band: concept.band, compact: true),
                        if (showDueBadge)
                          _MetaText(concept.practiceReason, emphasis: true)
                        else ...[
                          if (concept.quizSummary case final summary?)
                            _MetaText(summary),
                          if (concept.openMisses > 0)
                            _MetaText(
                              concept.openMisses == 1
                                  ? '1 mistake to fix'
                                  : '${concept.openMisses} mistakes to fix',
                              emphasis: true,
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.subtitle,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text, {this.emphasis = false});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: emphasis ? FontWeight.w900 : FontWeight.w700,
        color: emphasis ? AppColors.darkPink : AppColors.subtitle,
      ),
    );
  }
}
