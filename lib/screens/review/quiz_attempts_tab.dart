import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/animations/app_page_route.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/quiz_review_provider.dart';
import 'package:algebrix/models/quiz_attempt_review_model.dart';
import 'package:algebrix/screens/review/attempt_review_screen.dart';
import 'package:algebrix/screens/review/review_date_format.dart';
import 'package:algebrix/services/quiz_review_repository.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:algebrix/widgets/xy_mascot.dart';

/// The learner's retained quiz attempts, grouped by module.
///
/// Read-only: opening a past attempt never re-scores anything.
class QuizAttemptsTab extends StatelessWidget {
  const QuizAttemptsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<QuizReviewProvider>();
    final moduleIds = reviewProvider.moduleIdsWithAttempts;

    if (reviewProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pink),
      );
    }

    if (moduleIds.isEmpty) return const _EmptyReviewState();

    return RefreshIndicator(
      color: AppColors.pink,
      onRefresh: reviewProvider.reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _MistakeSummaryCard(
            totalMissed: reviewProvider.totalMissedCount,
            attemptCount: reviewProvider.attempts.length,
          ),
          const SizedBox(height: 24),
          for (final moduleId in moduleIds) ...[
            _ModuleReviewSection(
              moduleId: moduleId,
              attempts: reviewProvider.attemptsForModule(moduleId),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Only your $kMaxRetainedAttemptsPerModule most recent attempts '
            'per module are kept.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            XyMascot(asset: AppAssets.xyNotes, size: 128),
            const SizedBox(height: 22),
            Text(
              'No quizzes to review yet',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Finish a module quiz and Xy will keep your answers here so you '
              'can look back at what tripped you up.',
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

// ── Summary ─────────────────────────────────────────────────────────────────

class _MistakeSummaryCard extends StatelessWidget {
  const _MistakeSummaryCard({
    required this.totalMissed,
    required this.attemptCount,
  });

  final int totalMissed;
  final int attemptCount;

  @override
  Widget build(BuildContext context) {
    final isClean = totalMissed == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isClean ? AppColors.lightMint : AppColors.extraLightPink,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isClean ? AppColors.mint : AppColors.lightPink,
        ),
      ),
      child: Row(
        children: [
          XyMascot(
            asset: isClean ? AppAssets.xyHappy : AppAssets.xyIdea,
            size: 68,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isClean
                      ? 'Nothing missed. Nice work!'
                      : '$totalMissed question${totalMissed == 1 ? '' : 's'} to revisit',
                  style: GoogleFonts.nunito(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color:
                        isClean ? const Color(0xFF1B7F72) : AppColors.darkPink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Across your last $attemptCount '
                  'attempt${attemptCount == 1 ? '' : 's'}.',
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
    );
  }
}

// ── Module section ──────────────────────────────────────────────────────────

class _ModuleReviewSection extends StatelessWidget {
  const _ModuleReviewSection({
    required this.moduleId,
    required this.attempts,
  });

  final String moduleId;
  final List<QuizAttemptReview> attempts;

  Future<void> _handleClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Clear review history?',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        content: Text(
          'This removes the saved answers for this module. Your quiz scores '
          'and unlocks are not affected.',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Clear',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<QuizReviewProvider>();
    final success = await provider.clearModule(moduleId);

    if (!context.mounted) return;
    showAlgebrixSnackBar(
      context,
      message: success
          ? 'Review history cleared.'
          : provider.errorMessage ?? 'Could not clear your review history.',
      isError: !success,
      icon: success ? Icons.check_circle_rounded : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                attempts.first.moduleTitle,
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ),
            TextButton(
              key: Key('review-clear-$moduleId'),
              onPressed: () => _handleClear(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: AppColors.subtitle,
              ),
              child: Text(
                'Clear',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < attempts.length; i++) ...[
          _AttemptCard(
            attempt: attempts[i],
            // attempts arrive newest first
            label: i == 0 ? 'Latest attempt' : '${i + 1} attempts ago',
          ),
          if (i < attempts.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AttemptCard extends StatelessWidget {
  const _AttemptCard({required this.attempt, required this.label});

  final QuizAttemptReview attempt;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = attempt.passed ? AppColors.mint : AppColors.pink;

    return Semantics(
      button: true,
      label: '$label, scored ${attempt.score} out of ${attempt.totalQuestions}',
      child: BouncyPressable(
        key: Key('review-attempt-${attempt.id}'),
        onTap: () {
          Navigator.push(
            context,
            AppPageRoute(child: AttemptReviewScreen(attempt: attempt)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    '${attempt.percentage.round()}%',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: attempt.passed
                          ? const Color(0xFF1B7F72)
                          : AppColors.darkPink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.nunito(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${attempt.score}/${attempt.totalQuestions} correct  ·  '
                      '${formatReviewTimestamp(attempt.takenAt)}',
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.subtitle,
                      ),
                    ),
                    if (attempt.missedCount > 0) ...[
                      const SizedBox(height: 6),
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
                          '${attempt.missedCount} to review',
                          style: GoogleFonts.nunito(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF9A6B00),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
