import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/core/providers/quiz_provider.dart';
import 'package:algebrix/screens/practice/quest_map_screen.dart';
import 'package:algebrix/screens/quiz/quiz_hub_screen.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/core/animations/app_page_route.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:algebrix/widgets/xy_mascot.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Practice Arena Screen with 3 Interactive Options.
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const RootPageHeader(
              title: 'Practice Arena',
              subtitle: 'Master algebra concepts through interactive challenges.',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode 1: Explore Algebria — Interactive Quest Map
                    Builder(
                      builder: (context) {
                        final questProvider = context.watch<QuestMapProvider>();
                        final questStars = questProvider.activeLandStars;
                        final landName = questProvider.activeLand?.name ?? 'Balands';

                        return _ExploreAlgebriaHeroCard(
                          key: const Key('practice-mode-balance-scale'),
                          starsEarned: questStars,
                          maxStars: 30,
                          landName: landName,
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageRoute(
                                child: const QuestMapScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Mode 2: AI Module Quiz
                    Builder(
                      builder: (context) {
                        final quizProvider = context.watch<QuizProvider>();
                        final analytics = quizProvider.analytics;

                        return _ModuleQuizHeroCard(
                          key: const Key('practice-mode-quiz'),
                          quizzesPassed: analytics.totalQuizzesPassed,
                          totalQuizzes: 3,
                          accuracy: analytics.overallAccuracyPercentage,
                          masteryLevel: analytics.masteryLevel,
                          onTap: () {
                            Navigator.push(
                              context,
                              AppPageRoute(child: const QuizHubScreen()),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Explore Algebria Rich Adventure Hero Card
// =============================================================================

class _ExploreAlgebriaHeroCard extends StatelessWidget {
  const _ExploreAlgebriaHeroCard({
    super.key,
    required this.starsEarned,
    required this.maxStars,
    required this.landName,
    required this.onTap,
  });

  final int starsEarned;
  final int maxStars;
  final String landName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      shrinkFactor: 0.97,
      enableHaptics: true,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.pink.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Adventure Cover Image with Overlay Badges
            SizedBox(
              height: 165,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    AppAssets.algebria,
                    fit: BoxFit.cover,
                  ),
                  // Subtle bottom gradient fade
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Top-Left Category Pill
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'QUEST MAP',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.pink,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore Algebria',
                              style: GoogleFonts.nunito(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Interactive Puzzles • $landName',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.pink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Right-most Star Count Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFF9E6).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFE082)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              AppAssets.star,
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$starsEarned/$maxStars',
                              style: GoogleFonts.nunito(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Journey through mysterious lands with Xy! Solve tactile balance scale puzzles, unlock new worlds, and master algebra basics.',
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Call To Action Strip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF69B4),
                          Color(0xFFFF4081),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pink.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start Quest',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
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

// =============================================================================
// AI Module Quiz Hero Card
// =============================================================================

/// The quiz entry point, built to sit alongside the Explore Algebria card
/// rather than under it.
///
/// Same shape as that card — cover band with a category pill, then a titled
/// content section with live progress and a CTA — but keyed to purple so the
/// two modes stay distinguishable at a glance.
class _ModuleQuizHeroCard extends StatelessWidget {
  const _ModuleQuizHeroCard({
    super.key,
    required this.quizzesPassed,
    required this.totalQuizzes,
    required this.accuracy,
    required this.masteryLevel,
    required this.onTap,
  });

  final int quizzesPassed;
  final int totalQuizzes;
  final double accuracy;
  final String masteryLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress =
        totalQuizzes == 0 ? 0.0 : (quizzesPassed / totalQuizzes).clamp(0.0, 1.0);

    return BouncyPressable(
      shrinkFactor: 0.97,
      enableHaptics: true,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.45),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover band — mascot on a soft gradient instead of a photo.
            SizedBox(
              height: 148,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.lightPurple,
                          AppColors.extraLightPink,
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: XyMascot(asset: AppAssets.xyQuiz, size: 126),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _CoverPill(
                      label: 'AI POWERED',
                      color: AppColors.purple,
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _CoverPill(
                      label: masteryLevel.toUpperCase(),
                      color: AppColors.darkPink,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Module Quiz',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '10 Progressive Questions • Per Module',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Live progress, so the card says something even before
                  // it is tapped.
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$quizzesPassed of $totalQuizzes quizzes passed',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: AppColors.divider,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  AppColors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.lightPurple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${accuracy.round()}%',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Overall accuracy',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.nunito(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.subtitle,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.purple, AppColors.darkPink],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Open Quiz Hub',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
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

/// Rounded pill used over a hero cover band.
class _CoverPill extends StatelessWidget {
  const _CoverPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
