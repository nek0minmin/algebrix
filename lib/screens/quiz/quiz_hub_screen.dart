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
import 'package:algebrix/data/module3_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/module_quiz_progress_model.dart';
import 'package:algebrix/screens/lessons/module_overview_screen.dart';
import 'package:algebrix/screens/quiz/module_quiz_screen.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/xy_mascot.dart';

/// Dedicated Quiz Hub & Mastery Screen featuring rich Xy hero artwork (xy-quiz.png),
/// aggregated performance analytics with expandable per-quiz breakdown (play/fail counts),
/// and module quiz progression without heavy gray buttons.
class QuizHubScreen extends StatelessWidget {
  const QuizHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final lessonProvider = context.watch<LessonProvider>();
    final analytics = quizProvider.analytics;

    final m1Progress = quizProvider.getQuizProgress('module1');
    final m2Progress = quizProvider.getQuizProgress('module2');
    final m3Progress = quizProvider.getQuizProgress('module3');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. Top Navigation Bar with Back Button ────────────────
                  Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Back',
                        child: IconButton(
                          key: const Key('quiz-hub-back-button'),
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            minimumSize: const Size.square(44),
                            maximumSize: const Size.square(44),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppColors.extraLightPink,
                            foregroundColor: AppColors.darkPink,
                            side: const BorderSide(color: AppColors.lightPink),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Quizzes & Mastery',
                        style: GoogleFonts.nunito(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── 2. Hero Mascot Banner Card (xy-quiz.png) ──────────────
                  _QuizHeroBannerCard(),
                  const SizedBox(height: 20),

                  // ── 3. Performance Analytics Dashboard (Expandable) ───────
                  _AnalyticsSummaryCard(
                    analytics: analytics,
                    moduleProgresses: [
                      _QuizBreakdownItem(
                        moduleNumber: 1,
                        title: module1.title,
                        progress: m1Progress,
                        isUnlocked: quizProvider.isQuizUnlocked('module1', lessonProvider),
                      ),
                      _QuizBreakdownItem(
                        moduleNumber: 2,
                        title: module2.title,
                        progress: m2Progress,
                        isUnlocked: quizProvider.isQuizUnlocked('module2', lessonProvider),
                      ),
                      _QuizBreakdownItem(
                        moduleNumber: 3,
                        title: module3.title,
                        progress: m3Progress,
                        isUnlocked: quizProvider.isQuizUnlocked('module3', lessonProvider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── 4. Section Header ─────────────────────────────────────
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
                          color: AppColors.extraLightPink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '60% to pass',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkPink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── 5. Module 1 Quiz Card ─────────────────────────────────
                  _ModuleQuizHubCard(
                    module: module1,
                    moduleNumber: 1,
                    accentColor: AppColors.pink,
                    isUnlocked: quizProvider.isQuizUnlocked('module1', lessonProvider),
                    progress: m1Progress,
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

                  // ── 6. Module 2 Quiz Card ─────────────────────────────────
                  _ModuleQuizHubCard(
                    module: module2,
                    moduleNumber: 2,
                    accentColor: AppColors.purple,
                    isUnlocked: quizProvider.isQuizUnlocked('module2', lessonProvider),
                    progress: m2Progress,
                    completedLessons: lessonProvider.completedLessonsInModule('module2'),
                    totalLessons: module2.lessons.length,
                    unlockRequirement: !quizProvider.isModuleUnlocked('module2')
                        ? 'Score at least 60% on Module 1 Quiz'
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

                  // ── 7. Module 3 Quiz Card ─────────────────────────────────
                  _ModuleQuizHubCard(
                    module: module3,
                    moduleNumber: 3,
                    accentColor: AppColors.mint,
                    isUnlocked: quizProvider.isQuizUnlocked('module3', lessonProvider),
                    progress: m3Progress,
                    completedLessons: lessonProvider.completedLessonsInModule('module3'),
                    totalLessons: module3.lessons.length,
                    unlockRequirement: !quizProvider.isModuleUnlocked('module3')
                        ? 'Score at least 60% on Module 2 Quiz'
                        : 'Complete all 8 Module 3 lessons',
                    onStart: () {
                      Navigator.of(context).push(
                        AppPageRoute(
                          child: ModuleQuizScreen(module: module3),
                        ),
                      );
                    },
                    onGoToLessons: () {
                      if (!quizProvider.isModuleUnlocked('module3')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pass the Module 2 Quiz first with at least 60% to unlock Module 3!'),
                            backgroundColor: AppColors.mint,
                          ),
                        );
                        return;
                      }
                      lessonProvider.startModule(module3);
                      Navigator.of(context).push(
                        AppPageRoute(
                          child: const ModuleOverviewScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── 8. Future Module Quizzes (Locked Previews) ────────────
                  _LockedFutureQuizCard(
                    moduleNumber: 4,
                    title: 'Inequalities Quiz',
                    prerequisite: 'Pass Module 3 Quiz (at least 60%)',
                    accentColor: AppColors.yellow,
                  ),
                  const SizedBox(height: 12),
                  _LockedFutureQuizCard(
                    moduleNumber: 5,
                    title: 'Linear Relationships Quiz',
                    prerequisite: 'Pass Module 4 Quiz (at least 60%)',
                    accentColor: AppColors.info,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizBreakdownItem {
  final int moduleNumber;
  final String title;
  final ModuleQuizProgress progress;
  final bool isUnlocked;

  const _QuizBreakdownItem({
    required this.moduleNumber,
    required this.title,
    required this.progress,
    required this.isUnlocked,
  });
}

/// Hero Banner featuring prominent Xy Quiz illustration
class _QuizHeroBannerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.extraLightPink,
            AppColors.lightPurple.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lightPink, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.lightPink),
                    ),
                    child: Text(
                      'ALGEBRA MASTERY',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkPink,
                        letterSpacing: 1.0,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Challenge\nYour Mind',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Earn stars, test your understanding, and unlock new worlds!',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Large Xy Quiz Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              AppAssets.xyQuiz,
              height: 125,
              width: 125,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const XyMascot(
                asset: AppAssets.xyQuestion,
                size: 110,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero Analytics Overview Card with expandable per-quiz breakdown
class _AnalyticsSummaryCard extends StatefulWidget {
  final QuizAnalyticsSummary analytics;
  final List<_QuizBreakdownItem> moduleProgresses;

  const _AnalyticsSummaryCard({
    required this.analytics,
    this.moduleProgresses = const [],
  });

  @override
  State<_AnalyticsSummaryCard> createState() => _AnalyticsSummaryCardState();
}

class _AnalyticsSummaryCardState extends State<_AnalyticsSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final rawAccuracy = widget.analytics.overallAccuracyPercentage;
    final accuracy = rawAccuracy.clamp(0.0, 100.0);
    final passedCount = widget.analytics.totalQuizzesPassed;
    final attempts = widget.analytics.totalAttempts;
    final fails = widget.analytics.totalFails;
    final mastery = widget.analytics.masteryLevel;

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
                size: 68,
                shadowBlur: 4,
                shadowOpacity: 0.15,
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
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lightPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        mastery,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.purple,
                        ),
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
                  value: '$passedCount / 3',
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

          // ── Expandable Analytics Breakdown Toggle ────────────────────────
          const SizedBox(height: 14),
          BouncyPressable(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isExpanded ? AppColors.extraLightPink : AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isExpanded ? AppColors.lightPink : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 18,
                    color: _isExpanded ? AppColors.darkPink : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isExpanded ? 'Hide Detailed Breakdown' : 'View Detailed Breakdown',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _isExpanded ? AppColors.darkPink : AppColors.text,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: _isExpanded ? AppColors.darkPink : AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Per-Quiz Breakdown Content ──────────────────────────
          if (_isExpanded) ...[
            const SizedBox(height: 14),
            // Overall play / fail pills
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryPill(
                    icon: Icons.sports_esports_rounded,
                    label: 'Total Plays',
                    count: '$attempts',
                    color: AppColors.purple,
                  ),
                  Container(width: 1, height: 20, color: AppColors.divider),
                  _SummaryPill(
                    icon: Icons.check_circle_rounded,
                    label: 'Passes',
                    count: '$passedCount',
                    color: AppColors.mint,
                  ),
                  Container(width: 1, height: 20, color: AppColors.divider),
                  _SummaryPill(
                    icon: Icons.replay_rounded,
                    label: 'Retries / Fails',
                    count: '$fails',
                    color: AppColors.pink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Per Quiz List
            ...widget.moduleProgresses.map((item) {
              final p = item.progress;
              final hasAttempted = p.hasAttempted;
              final isPassed = p.passed;
              final bestPercent = p.bestPercentage.round().clamp(0, 100);
              final displayScore = p.displayHighScore;
              final totalQ = p.totalQuestions;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPassed ? AppColors.mint.withValues(alpha: 0.5) : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top row: Module Pill on left, Status badge on right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightPurple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Module ${item.moduleNumber}',
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                        if (isPassed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.lightMint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Passed ($bestPercent%)',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F7263),
                              ),
                            ),
                          )
                        else if (hasAttempted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.extraLightPink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Retried ($bestPercent%)',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.darkPink,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.isUnlocked ? 'Ready' : 'Locked',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // 2. Dedicated Full-Width Title Row
                    Text(
                      item.title,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (hasAttempted)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MiniStat(
                            label: 'Best Score',
                            value: '$displayScore / $totalQ ($bestPercent%)',
                            icon: Icons.star_rounded,
                            iconColor: AppColors.yellow,
                          ),
                          _MiniStat(
                            label: 'Play Count',
                            value: '${p.playCount} attempts',
                            icon: Icons.play_arrow_rounded,
                            iconColor: AppColors.purple,
                          ),
                          _MiniStat(
                            label: 'Fail Count',
                            value: '${p.failCount} retries',
                            icon: Icons.replay_rounded,
                            iconColor: AppColors.pink,
                          ),
                        ],
                      )
                    else
                      Text(
                        item.isUnlocked
                            ? 'Not taken yet. Ready to start!'
                            : 'Locked. Complete previous lessons to unlock.',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;

  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
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
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Interactive Module Quiz Card (No heavy gray button on locked state)
class _ModuleQuizHubCard extends StatelessWidget {
  final ModuleContent module;
  final int moduleNumber;
  final Color accentColor;
  final bool isUnlocked;
  final ModuleQuizProgress progress;
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
    final hasPassed = progress.passed;
    final displayScore = progress.displayHighScore;
    final bestPercent = progress.bestPercentage.clamp(0.0, 100.0);
    final attempts = progress.attemptsCount;
    final totalQ = progress.totalQuestions;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.extraLightPink : AppColors.divider,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUnlocked ? Icons.psychology_rounded : Icons.lock_outline_rounded,
                  color: isUnlocked ? AppColors.pink : AppColors.subtitle,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MODULE $moduleNumber QUIZ',
                      style: GoogleFonts.nunito(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: isUnlocked ? AppColors.darkPink : AppColors.subtitle,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      module.title,
                      style: GoogleFonts.nunito(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: isUnlocked ? AppColors.text : AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              if (hasPassed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 13),
                      const SizedBox(width: 3.5),
                      Text(
                        '${bestPercent.round()}%',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F7263),
                        ),
                      ),
                    ],
                  ),
                )
              else if (isUnlocked && attempts > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel_rounded, color: AppColors.error, size: 13),
                      const SizedBox(width: 3.5),
                      Text(
                        '${bestPercent.round()}%',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.extraLightPink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Ready',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkPink,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 11, color: AppColors.subtitle),
                      const SizedBox(width: 3.5),
                      Text(
                        'Locked',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // High Score & Attempts Info for unlocked quizzes
          if (isUnlocked && attempts > 0) ...[
            Row(
              children: [
                Text(
                  'Best: $displayScore / $totalQ (${bestPercent.round()}%)',
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                Text(
                  '$attempts ${attempts == 1 ? 'attempt' : 'attempts'}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // ── Action or Lock Status ─────────────────────────────────────────
          if (isUnlocked)
            PrimaryButton(
              label: hasPassed ? 'Retake Quiz' : (attempts > 0 ? 'Try Again' : 'Start 10-Item Quiz'),
              backgroundColor: AppColors.pink,
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
            )
          else ...[
            // Clean lock requirement container (NO heavy gray button)
            BouncyPressable(
              onTap: onGoToLessons,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.extraLightPink.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightPink.withValues(alpha: 0.8)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: AppColors.pink,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unlockRequirement,
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            'Tap to view lessons ($completedLessons/$totalLessons)',
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.pink,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      opacity: 0.65,
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
