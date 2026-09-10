import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/mastery_provider.dart';
import 'package:algebrix/models/concept_mastery_model.dart';
import 'package:algebrix/screens/review/concept_practice_launcher.dart';
import 'package:algebrix/services/quiz_review_repository.dart';
import 'package:algebrix/widgets/review/concept_mastery_tile.dart';
import 'package:algebrix/widgets/xy_mascot.dart';

/// How well each concept is holding up, grouped into bands.
///
/// Rewritten from two ranked lists ("least mastered" / "most mastered") that
/// were the same set in opposite orders, so a concept appeared in both. Bands
/// are disjoint: every scored concept sits in exactly one.
class MasteryTab extends StatelessWidget {
  const MasteryTab({super.key});

  /// What each band means, in the learner's words.
  static String _bandExplanation(MasteryBand band) => switch (band) {
        MasteryBand.needsWork => 'Under half right. Start here.',
        MasteryBand.shaky => 'Getting there, but not reliable yet.',
        MasteryBand.solid => 'Mostly right. Keep it warm.',
        MasteryBand.mastered => 'You have this one down.',
        MasteryBand.notAssessed => '',
      };

  @override
  Widget build(BuildContext context) {
    final mastery = context.watch<MasteryProvider>();

    if (mastery.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pink),
      );
    }

    final summary = mastery.summary;
    if (!summary.hasData) return const _NoMasteryData();

    final bands = mastery.conceptsByBand;

    return RefreshIndicator(
      color: AppColors.pink,
      onRefresh: mastery.reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _SummaryCard(summary: summary),
          const SizedBox(height: 22),

          for (final entry in bands.entries) ...[
            _BandSection(
              band: entry.key,
              explanation: _bandExplanation(entry.key),
              concepts: entry.value,
            ),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 4),
          _FootNote(
            'A concept you have never been quizzed on is left out entirely — '
            'no score is different from a low score.',
          ),
        ],
      ),
    );
  }
}

// ── Summary ─────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final MasterySummary summary;

  @override
  Widget build(BuildContext context) {
    final accuracy = summary.overallAccuracy;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              XyMascot(asset: AppAssets.xyInsight, size: 62),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accuracy == null
                          ? 'Scored on ${summary.assessedCount} '
                              '${summary.assessedCount == 1 ? 'concept' : 'concepts'}'
                          : 'You are getting ${accuracy.round()}% right',
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Across ${summary.assessedCount} '
                      '${summary.assessedCount == 1 ? 'concept' : 'concepts'} '
                      'you have been scored on.',
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // The single most important thing this page never said: where the
          // numbers come from, and how far back they reach.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.lightPurple.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_rounded,
                  size: 16,
                  color: AppColors.purple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Based on your last $kMaxRetainedAttemptsPerModule quiz '
                    'attempts in each module, plus any lesson answers you have '
                    'missed. Older attempts are not counted.',
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'To practice',
                  value: '${summary.needsReviewCount}',
                  color: AppColors.pink,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.divider),
              Expanded(
                child: _SummaryStat(
                  label: 'Mistakes to fix',
                  value: '${summary.openMistakeCount}',
                  color: AppColors.purple,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.divider),
              Expanded(
                child: _SummaryStat(
                  label: 'Mastered',
                  value: '${summary.masteredCount}',
                  color: AppColors.mint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: GoogleFonts.nunito(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bands ───────────────────────────────────────────────────────────────────

class _BandSection extends StatelessWidget {
  const _BandSection({
    required this.band,
    required this.explanation,
    required this.concepts,
  });

  final MasteryBand band;
  final String explanation;
  final List<ConceptMastery> concepts;

  @override
  Widget build(BuildContext context) {
    final colors = masteryBandColors(band);
    final accent =
        colors.accent == AppColors.yellow ? const Color(0xFF9A6B00) : colors.accent;

    return Column(
      key: Key('mastery-band-${band.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${band.label} (${concepts.length})',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  Text(
                    explanation,
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final concept in concepts) ...[
          ConceptMasteryTile(
            concept: concept,
            onTap: () => openConceptPractice(
              context,
              lessonId: concept.lessonId,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FootNote extends StatelessWidget {
  const _FootNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.nunito(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: AppColors.subtitle,
        height: 1.4,
      ),
    );
  }
}

class _NoMasteryData extends StatelessWidget {
  const _NoMasteryData();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            XyMascot(asset: AppAssets.xyQuestion, size: 128),
            const SizedBox(height: 20),
            Text(
              'No mastery data yet',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Finish a module quiz or a lesson and Xy will start tracking '
              'which concepts you have down and which need another look.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
