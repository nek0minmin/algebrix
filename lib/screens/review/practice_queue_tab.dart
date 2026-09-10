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

/// The spaced-review queue: concepts that are due, weakest first.
///
/// A concept enters when it is missed, and leaves for 1 / 3 / 7 / 14 / 30 days
/// each time the learner reviews it successfully.
class PracticeQueueTab extends StatelessWidget {
  const PracticeQueueTab({super.key});

  @override
  Widget build(BuildContext context) {
    final mastery = context.watch<MasteryProvider>();
    final queue = mastery.needsReview;

    if (mastery.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pink),
      );
    }

    if (queue.isEmpty) {
      return _AllCaughtUp(
        hasAnyEvidence: mastery.summary.hasData,
      );
    }

    return RefreshIndicator(
      color: AppColors.pink,
      onRefresh: mastery.reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _QueueHeader(count: queue.length),
          const SizedBox(height: 18),
          for (final concept in queue) ...[
            ConceptMasteryTile(
              concept: concept,
              showDueBadge: true,
              onTap: () => _practice(context, concept),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          Text(
            'Reviewed concepts come back after 1, 3, 7, 14, then 30 days. '
            'Missing one brings it forward again.',
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

  Future<void> _practice(BuildContext context, ConceptMastery concept) async {
    final mastery = context.read<MasteryProvider>();

    // Land on the exact step behind an open mistake when there is one,
    // otherwise the lesson's first question.
    final openMistakes = mastery.mistakesForLesson(concept.lessonId);
    final stepId = openMistakes.isEmpty ? null : openMistakes.first.stepId;

    await openConceptPractice(
      context,
      lessonId: concept.lessonId,
      stepId: stepId,
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.extraLightPink,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.lightPink),
      ),
      child: Row(
        children: [
          XyMascot(asset: AppAssets.xyIdea, size: 64),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count concept${count == 1 ? '' : 's'} to practice',
                  style: GoogleFonts.nunito(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkPink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Start at the top — that is the one costing you the most '
                  'marks right now.',
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp({required this.hasAnyEvidence});

  final bool hasAnyEvidence;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            XyMascot(asset: AppAssets.xyHappy, size: 128),
            const SizedBox(height: 20),
            Text(
              hasAnyEvidence
                  ? 'Nothing due right now'
                  : 'No practice queue yet',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              hasAnyEvidence
                  ? 'Every concept you have struggled with is scheduled '
                      'further out. Xy will bring them back when it is time.'
                  : 'Take a module quiz or work through a lesson. Anything '
                      'you miss shows up here to practice.',
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
