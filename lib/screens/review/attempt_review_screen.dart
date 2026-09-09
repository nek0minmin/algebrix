import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/models/quiz_attempt_review_model.dart';
import 'package:algebrix/screens/review/review_date_format.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/review/reviewed_answer_card.dart';
import 'package:algebrix/widgets/xy_mascot.dart';

/// Question-by-question review of one archived quiz attempt.
///
/// Defaults to the missed questions — the mistake log is the point — with a
/// filter to see everything. Purely a read view: no answering, no re-scoring.
class AttemptReviewScreen extends StatefulWidget {
  const AttemptReviewScreen({super.key, required this.attempt});

  final QuizAttemptReview attempt;

  @override
  State<AttemptReviewScreen> createState() => _AttemptReviewScreenState();
}

class _AttemptReviewScreenState extends State<AttemptReviewScreen> {
  late bool _showMissedOnly;

  @override
  void initState() {
    super.initState();
    // Open on the mistakes when there are any; otherwise there is nothing to
    // filter down to and "All" is the only useful view.
    _showMissedOnly = widget.attempt.missedCount > 0;
  }

  @override
  Widget build(BuildContext context) {
    final attempt = widget.attempt;

    // Keep original question numbering even when the list is filtered, so a
    // learner can line a review up against the quiz they took.
    final numbered = <({int number, ReviewedQuestion question})>[
      for (var i = 0; i < attempt.items.length; i++)
        (number: i + 1, question: attempt.items[i]),
    ];
    final visible = _showMissedOnly
        ? numbered.where((entry) => entry.question.isMissed).toList()
        : numbered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AlgebrixAppBar(
        title: attempt.moduleTitle,
        subtitle: formatReviewTimestamp(attempt.takenAt),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _AttemptSummaryHeader(attempt: attempt),
            const SizedBox(height: 18),
            if (attempt.missedCount > 0)
              _FilterToggle(
                showMissedOnly: _showMissedOnly,
                missedCount: attempt.missedCount,
                totalCount: attempt.items.length,
                onChanged: (value) =>
                    setState(() => _showMissedOnly = value),
              ),
            if (attempt.missedCount > 0) const SizedBox(height: 18),
            if (visible.isEmpty)
              const _NothingToShow()
            else
              for (final entry in visible) ...[
                _ReviewQuestionCard(
                  number: entry.number,
                  question: entry.question,
                ),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }
}

// ── Summary header ──────────────────────────────────────────────────────────

class _AttemptSummaryHeader extends StatelessWidget {
  const _AttemptSummaryHeader({required this.attempt});

  final QuizAttemptReview attempt;

  @override
  Widget build(BuildContext context) {
    final isPerfect = attempt.isPerfect;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          XyMascot(
            asset: isPerfect ? AppAssets.xyHappy : AppAssets.xyExplaining,
            size: 66,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${attempt.score} / ${attempt.totalQuestions} correct',
                  style: GoogleFonts.nunito(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPerfect
                      ? 'A clean sweep — nothing to fix here.'
                      : '${attempt.missedCount} question'
                          '${attempt.missedCount == 1 ? '' : 's'} to look over '
                          'again.',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
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

// ── Filter ──────────────────────────────────────────────────────────────────

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({
    required this.showMissedOnly,
    required this.missedCount,
    required this.totalCount,
    required this.onChanged,
  });

  final bool showMissedOnly;
  final int missedCount;
  final int totalCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            key: const Key('attempt-review-filter-missed'),
            label: 'Missed ($missedCount)',
            icon: Icons.flag_rounded,
            isActive: showMissedOnly,
            activeColor: AppColors.pink,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FilterChip(
            key: const Key('attempt-review-filter-all'),
            label: 'All ($totalCount)',
            icon: Icons.list_rounded,
            isActive: !showMissedOnly,
            activeColor: AppColors.purple,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: BouncyPressable(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.14)
                : AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive ? activeColor : AppColors.border,
              width: isActive ? 2 : 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isActive ? activeColor : AppColors.subtitle,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                    color: isActive ? activeColor : AppColors.subtitle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NothingToShow extends StatelessWidget {
  const _NothingToShow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          XyMascot(asset: AppAssets.xyHappy, size: 110),
          const SizedBox(height: 16),
          Text(
            'Nothing to review here',
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Question card ───────────────────────────────────────────────────────────

class _ReviewQuestionCard extends StatelessWidget {
  const _ReviewQuestionCard({required this.number, required this.question});

  final int number;
  final ReviewedQuestion question;

  @override
  Widget build(BuildContext context) {
    final isCorrect = question.isCorrect;
    final accent = isCorrect ? AppColors.mint : AppColors.pink;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: number, verdict, topic
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isCorrect
                          ? const Color(0xFF1B7F72)
                          : AppColors.darkPink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 16,
                          color: accent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          question.wasAnswered
                              ? (isCorrect ? 'Correct' : 'Missed')
                              : 'Not answered',
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: isCorrect
                                ? const Color(0xFF1B7F72)
                                : AppColors.darkPink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${question.subLessonTitle}  ·  '
                      '${question.difficultyLabel}',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            question.question,
            style: GoogleFonts.nunito(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          for (var i = 0; i < question.options.length; i++) ...[
            ReviewedOptionRow(
              text: question.options[i],
              isCorrectAnswer: i == question.correctIndex,
              isLearnerAnswer: i == question.selectedIndex,
            ),
            if (i < question.options.length - 1) const SizedBox(height: 8),
          ],

          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 14),
            ReviewExplanationBox(explanation: question.explanation),
          ],
        ],
      ),
    );
  }
}
