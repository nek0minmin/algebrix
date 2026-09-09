import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/mastery_provider.dart';
import 'package:algebrix/models/concept_mastery_model.dart';
import 'package:algebrix/screens/review/concept_practice_launcher.dart';
import 'package:algebrix/widgets/review/concept_mastery_tile.dart';
import 'package:algebrix/widgets/xy_mascot.dart';

/// Mastery analytics: which concepts are strongest, which are weakest, and
/// which need reviewing — each row linking into the lesson behind it.
class MasteryTab extends StatefulWidget {
  const MasteryTab({super.key});

  @override
  State<MasteryTab> createState() => _MasteryTabState();
}

class _MasteryTabState extends State<MasteryTab> {
  /// How many concepts each list shows before "show all".
  static const int _collapsedCount = 5;

  bool _showAllStrong = false;
  bool _showAllWeak = false;

  @override
  Widget build(BuildContext context) {
    final mastery = context.watch<MasteryProvider>();

    if (mastery.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pink),
      );
    }

    final summary = mastery.summary;

    if (!summary.hasData) {
      return const _NoMasteryData();
    }

    final weakest = mastery.weakestFirst;
    final strongest = mastery.strongestFirst;
    final needsReview = mastery.needsReview;

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
          const SizedBox(height: 24),

          if (needsReview.isNotEmpty) ...[
            const _SectionHeading(
              title: 'Needs reviewing',
              subtitle: 'Due for practice right now',
              icon: Icons.flag_rounded,
              color: AppColors.pink,
            ),
            const SizedBox(height: 12),
            for (final concept in needsReview.take(_collapsedCount)) ...[
              ConceptMasteryTile(
                concept: concept,
                showDueBadge: true,
                onTap: () => openConceptPractice(
                  context,
                  lessonId: concept.lessonId,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (needsReview.length > _collapsedCount)
              Text(
                '+ ${needsReview.length - _collapsedCount} more in the '
                'Practice tab',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.subtitle,
                ),
              ),
            const SizedBox(height: 24),
          ],

          const _SectionHeading(
            title: 'Least mastered',
            subtitle: 'Lowest quiz accuracy and open mistakes first',
            icon: Icons.trending_down_rounded,
            color: AppColors.yellow,
          ),
          const SizedBox(height: 12),
          _ConceptList(
            key: const Key('mastery-weakest-list'),
            concepts: weakest,
            showAll: _showAllWeak,
            collapsedCount: _collapsedCount,
            onToggle: () => setState(() => _showAllWeak = !_showAllWeak),
          ),
          const SizedBox(height: 24),

          const _SectionHeading(
            title: 'Most mastered',
            subtitle: 'Your strongest concepts',
            icon: Icons.trending_up_rounded,
            color: AppColors.mint,
          ),
          const SizedBox(height: 12),
          _ConceptList(
            key: const Key('mastery-strongest-list'),
            concepts: strongest,
            showAll: _showAllStrong,
            collapsedCount: _collapsedCount,
            onToggle: () => setState(() => _showAllStrong = !_showAllStrong),
          ),

          const SizedBox(height: 20),
          Text(
            'Concepts you have not been quizzed on yet are left out — no '
            'evidence is different from weak evidence.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
              height: 1.4,
            ),
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
        children: [
          Row(
            children: [
              XyMascot(asset: AppAssets.xyInsight, size: 66),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.masteredCount} of ${summary.assessedCount} '
                      'concepts mastered',
                      style: GoogleFonts.nunito(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      accuracy == null
                          ? 'Take a module quiz to start scoring concepts.'
                          : 'Overall quiz accuracy ${accuracy.round()}%',
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.masteredFraction.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mint),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Need review',
                  value: '${summary.needsReviewCount}',
                  color: AppColors.pink,
                ),
              ),
              Container(width: 1, height: 34, color: AppColors.divider),
              Expanded(
                child: _SummaryStat(
                  label: 'Due now',
                  value: '${summary.dueNowCount}',
                  color: AppColors.yellow,
                ),
              ),
              Container(width: 1, height: 34, color: AppColors.divider),
              Expanded(
                child: _SummaryStat(
                  label: 'Open mistakes',
                  value: '${summary.openMistakeCount}',
                  color: AppColors.purple,
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
            color: color == AppColors.yellow
                ? const Color(0xFF9A6B00)
                : color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.subtitle,
          ),
        ),
      ],
    );
  }
}

// ── Sections ────────────────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: color == AppColors.yellow ? const Color(0xFF9A6B00) : color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              Text(
                subtitle,
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
    );
  }
}

class _ConceptList extends StatelessWidget {
  const _ConceptList({
    super.key,
    required this.concepts,
    required this.showAll,
    required this.collapsedCount,
    required this.onToggle,
  });

  final List<ConceptMastery> concepts;
  final bool showAll;
  final int collapsedCount;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final visible = showAll ? concepts : concepts.take(collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final concept in visible) ...[
          ConceptMasteryTile(
            concept: concept,
            onTap: () => openConceptPractice(
              context,
              lessonId: concept.lessonId,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (concepts.length > collapsedCount)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: AppColors.darkPink,
              ),
              child: Text(
                showAll
                    ? 'Show less'
                    : 'Show all ${concepts.length}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
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
