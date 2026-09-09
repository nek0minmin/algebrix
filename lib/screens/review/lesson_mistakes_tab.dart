import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/mastery_provider.dart';
import 'package:algebrix/data/lesson_catalog.dart';
import 'package:algebrix/models/lesson_mistake_model.dart';
import 'package:algebrix/screens/review/concept_practice_launcher.dart';
import 'package:algebrix/screens/review/review_date_format.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:algebrix/widgets/review/reviewed_answer_card.dart';
import 'package:algebrix/widgets/xy_mascot.dart';

/// Lesson answers the learner got wrong and has not since corrected.
///
/// The lesson-side counterpart to the quiz attempt log: same rendering, same
/// "what you picked vs. what was right", plus a tap straight back to the step.
class LessonMistakesTab extends StatelessWidget {
  const LessonMistakesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final mastery = context.watch<MasteryProvider>();

    if (mastery.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pink),
      );
    }

    final mistakes = mastery.openLessonMistakes;

    if (mistakes.isEmpty) {
      return const _NoLessonMistakes();
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
          Text(
            '${mistakes.length} lesson answer'
            '${mistakes.length == 1 ? '' : 's'} still open',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'These close automatically once you answer the step correctly.',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 18),
          for (final mistake in mistakes) ...[
            _LessonMistakeCard(mistake: mistake),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _LessonMistakeCard extends StatelessWidget {
  const _LessonMistakeCard({required this.mistake});

  final LessonMistake mistake;

  @override
  Widget build(BuildContext context) {
    final lessonLabel = LessonCatalog.lessonLabel(mistake.lessonId);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.pink.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lessonLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkPink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last missed ${formatReviewTimestamp(mistake.lastMissedAt)}',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              if (mistake.isRepeated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightYellow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.yellow.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    'Missed ${mistake.missCount}×',
                    style: GoogleFonts.nunito(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF9A6B00),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),

          Text(
            mistake.question,
            style: GoogleFonts.nunito(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 13),

          for (var i = 0; i < mistake.options.length; i++) ...[
            ReviewedOptionRow(
              text: mistake.options[i],
              isCorrectAnswer: i == mistake.correctIndex,
              isLearnerAnswer: i == mistake.selectedIndex,
            ),
            if (i < mistake.options.length - 1) const SizedBox(height: 8),
          ],

          if (mistake.explanation.isNotEmpty) ...[
            const SizedBox(height: 13),
            ReviewExplanationBox(explanation: mistake.explanation),
          ],

          const SizedBox(height: 15),
          Semantics(
            button: true,
            label: 'Practise this step again',
            child: BouncyPressable(
              key: Key('lesson-mistake-practise-${mistake.id}'),
              onTap: () => openConceptPractice(
                context,
                lessonId: mistake.lessonId,
                stepId: mistake.stepId,
              ),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.extraLightPink,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.pink, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.replay_rounded,
                      size: 17,
                      color: AppColors.darkPink,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Practise this step',
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkPink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoLessonMistakes extends StatelessWidget {
  const _NoLessonMistakes();

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
              'No open lesson mistakes',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Anything you get wrong inside a lesson lands here until you go '
              'back and answer it correctly.',
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
