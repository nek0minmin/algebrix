import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/screens/practice/balance_scale_screen.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode 1: Balance Scale
                    _PracticeModeCard(
                      key: const Key('practice-mode-balance-scale'),
                      icon: Icons.scale_rounded,
                      title: 'Balance Scale',
                      subtitle: 'Find x through scale balancing',
                      description:
                          'Apply equal operations to both sides of the scale to isolate x step-by-step.',
                      isPrimary: true,
                      badgeText: 'FEATURED MODE',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BalanceScaleScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mode 2: Quiz
                    _PracticeModeCard(
                      key: const Key('practice-mode-quiz'),
                      icon: Icons.quiz_rounded,
                      title: 'Quiz Challenge',
                      subtitle: 'Test your knowledge',
                      description:
                          'Quick-fire multiple choice questions to reinforce key algebra definitions and rules.',
                      isPrimary: false,
                      badgeText: 'COMING SOON',
                      onTap: () {
                        showAlgebrixSnackBar(
                          context,
                          message: 'Quiz Challenge mode is coming soon!',
                          icon: Icons.access_time_rounded,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mode 3: Root Finder
                    _PracticeModeCard(
                      key: const Key('practice-mode-root-finder'),
                      icon: Icons.alt_route_rounded,
                      title: 'Root Finder',
                      subtitle: 'Find the roots of an equation',
                      description:
                          'Explore quadratic equations, factorizations, and graph parabola intercepts.',
                      isPrimary: false,
                      badgeText: 'COMING SOON',
                      onTap: () {
                        showAlgebrixSnackBar(
                          context,
                          message: 'Root Finder mode is coming soon!',
                          icon: Icons.access_time_rounded,
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

class _PracticeModeCard extends StatelessWidget {
  const _PracticeModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isPrimary,
    required this.badgeText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool isPrimary;
  final String badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPrimary ? AppColors.pink : AppColors.border,
              width: isPrimary ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isPrimary
                    ? AppColors.pink.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? AppColors.extraLightPink
                          : AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isPrimary ? AppColors.pink : AppColors.textSecondary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.pink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? AppColors.pink
                          : AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isPrimary ? Colors.white : AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isPrimary ? 'Launch Mode →' : 'Learn More →',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isPrimary ? AppColors.pink : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
