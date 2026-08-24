import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/animations/app_page_route.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/core/providers/quiz_provider.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/screens/lessons/module_overview_screen.dart';
import 'package:algebrix/screens/quiz/module_quiz_screen.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/xy_mascot.dart';

/// Dedicated Quiz Hub & Analytics Screen displaying all module quizzes,
/// unlock status, high scores, accuracy statistics, and domain mastery breakdown.
class QuizHubScreen extends StatelessWidget {
  const QuizHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final lessonProvider = context.watch<LessonProvider>();
    final analytics = quizProvider.analytics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Quizzes & Mastery',
          style: GoogleFonts.nunito(
            color: AppColors.text,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Hero Analytics Dashboard Card ─────────────────────────────
            _AnalyticsSummaryCard(analytics: analytics),
            const SizedBox(height: 24),

            // ── 2. Section Header ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Module Quizzes',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '60% to pass',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── 3. Module 1 Quiz Card ─────────────────────────────────────────
            _ModuleQuizHubCard(
              module: module1,
              moduleNumber: 1,
              accentColor: AppColors.pink,
              isUnlocked: quizProvider.isQuizUnlocked('module1', lessonProvider),
              progress: quizProvider.getQuizProgress('module1'),
              completedLessons: lessonProvider.completedLessonsInModule('module1'),
              totalLessons: module1.lessons.length,
              unlockRequirement: 'Complete all 6 Module 1 lessons',
              onStart: () {
                Navigator.of(context).push(
                  AppPageRoute(
                    child: ModuleQuizScreen(module: module1),
                  ),
                );
              },
              onGoToLessons: () {
                lessonProvider.startModule(module1);
                Navigator.of(context).push(
                  AppPageRoute(
                    child: const ModuleOverviewScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── 4. Module 2 Quiz Card ─────────────────────────────────────────
            _ModuleQuizHubCard(
              module: module2,
              moduleNumber: 2,
              accentColor: AppColors.purple,
              isUnlocked: quizProvider.isQuizUnlocked('module2', lessonProvider),
              progress: quizProvider.getQuizProgress('module2'),
              completedLessons: lessonProvider.completedLessonsInModule('module2'),
              totalLessons: module2.lessons.length,
              unlockRequirement: !quizProvider.isModuleUnlocked('module2')
                  ? 'Score ≥60% on Module 1 Quiz'
                  : 'Complete all 7 Module 2 lessons',
              onStart: () {
                Navigator.of(context).push(
                  AppPageRoute(
                    child: ModuleQuizScreen(module: module2),
                  ),
                );
              },
              onGoToLessons: () {
                if (!quizProvider.isModuleUnlocked('module2')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pass the Module 1 Quiz first with at least 60% to unlock Module 2!'),
                      backgroundColor: AppColors.pink,
                    ),
                  );
                  return;
                }
                lessonProvider.startModule(module2);
                Navigator.of(context).push(
                  AppPageRoute(
                    child: const ModuleOverviewScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── 5. Future Module Quizzes (Locked Previews) ────────────────────
            _LockedFutureQuizCard(
              moduleNumber: 3,
              title: 'Solving Equations Quiz',
              prerequisite: 'Pass Module 2 Quiz (≥60%)',
              accentColor: AppColors.mint,
            ),
            const SizedBox(height: 12),
            _LockedFutureQuizCard(
              moduleNumber: 4,
              title: 'Inequalities Quiz',
              prerequisite: 'Pass Module 3 Quiz (≥60%)',
              accentColor: AppColors.yellow,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero Analytics Overview Card
class _AnalyticsSummaryCard extends StatelessWidget {
  final dynamic analytics;

  const _AnalyticsSummaryCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final accuracy = analytics.overallAccuracyPercentage as double;
    final passedCount = analytics.totalQuizzesPassed as int;
    final attempts = analytics.totalAttempts as int;
    final mastery = analytics.masteryLevel as String;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const XyMascot(
                asset: AppAssets.xyIdea,
                size: 54,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Performance',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      mastery,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Accuracy',
                  value: accuracy > 0 ? '${accuracy.round()}%' : '--',
                  icon: Icons.track_changes_rounded,
                  color: AppColors.mint,
                ),
              ),
              Container(width: 1, height: 38, color: AppColors.divider),
              Expanded(
                child: _MetricTile(
                  label: 'Quizzes Passed',
                  value: '$passedCount / 2',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.pink,
                ),
              ),
              Container(width: 1, height: 38, color: AppColors.divider),
              Expanded(
                child: _MetricTile(
                  label: 'Attempts',
                  value: attempts > 0 ? '$attempts' : '0',
                  icon: Icons.refresh_rounded,
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

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Interactive Module Quiz Card in the Quiz Hub
class _ModuleQuizHubCard extends StatelessWidget {
  final ModuleContent module;
  final int moduleNumber;
  final Color accentColor;
  final bool isUnlocked;
  final dynamic progress;
  final int completedLessons;
  final int totalLessons;
  final String unlockRequirement;
  final VoidCallback onStart;
  final VoidCallback onGoToLessons;

  const _ModuleQuizHubCard({
    required this.module,
    required this.moduleNumber,
    required this.accentColor,
    required this.isUnlocked,
    required this.progress,
    required this.completedLessons,
    required this.totalLessons,
    required this.unlockRequirement,
    required this.onStart,
    required this.onGoToLessons,
  });

  @override
  Widget build(BuildContext context) {
    final hasPassed = progress.passed as bool;
    final highScore = progress.highScore as int;
    final bestPercent = progress.bestPercentage as double;
    final attempts = progress.attemptsCount as int;
    final totalQ = progress.totalQuestions as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnlocked
              ? (hasPassed ? AppColors.mint : accentColor.withValues(alpha: 0.4))
              : AppColors.border,
          width: isUnlocked ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isUnlocked ? accentColor.withValues(alpha: 0.12) : AppColors.divider,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isUnlocked ? Icons.psychology_rounded : Icons.lock_outline_rounded,
                  color: isUnlocked ? accentColor : AppColors.subtitle,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MODULE $moduleNumber QUIZ',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      module.title,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              if (hasPassed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Passed (${bestPercent.round()}%)',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F7263),
                        ),
                      ),
                    ],
                  ),
                )
              else if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.extraLightPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attempts > 0 ? 'Needs Review (${bestPercent.round()}%)' : 'Ready to Take',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkPink,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Locked',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.subtitle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // High Score & Lesson Progress Info
          if (isUnlocked && attempts > 0) ...[
            Row(
              children: [
                Row(
                  children: List.generate(3, (index) {
                    final earned = index < progress.starRating;
                    return Icon(
                      earned ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 20,
                      color: earned ? AppColors.yellow : AppColors.border,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  'Best: $highScore / $totalQ (${bestPercent.round()}%)',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                Text(
                  '$attempts ${attempts == 1 ? 'attempt' : 'attempts'}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Unlock details
          if (!isUnlocked) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.subtitle),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      unlockRequirement,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Action Buttons
          if (isUnlocked)
            PrimaryButton(
              label: hasPassed ? 'Retake Quiz' : (attempts > 0 ? 'Try Again' : 'Start 10-Item Quiz'),
              backgroundColor: hasPassed ? AppColors.purple : AppColors.pink,
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
            )
          else
            PrimaryButton(
              label: 'Complete Lessons ($completedLessons/$totalLessons)',
              backgroundColor: AppColors.subtitle,
              icon: Icons.menu_book_rounded,
              onPressed: onGoToLessons,
            ),
        ],
      ),
    );
  }
}

/// Locked Future Module Card
class _LockedFutureQuizCard extends StatelessWidget {
  final int moduleNumber;
  final String title;
  final String prerequisite;
  final Color accentColor;

  const _LockedFutureQuizCard({
    required this.moduleNumber,
    required this.title,
    required this.prerequisite,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_rounded, size: 18, color: AppColors.subtitle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MODULE $moduleNumber QUIZ',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.subtitle,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    prerequisite,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
