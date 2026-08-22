import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/screens/practice/balance_scale_screen.dart';
import 'package:algebrix/screens/quiz/module_quiz_screen.dart';
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
                      icon: Icons.psychology_rounded,
                      title: 'AI Module Quiz',
                      subtitle: '15 Progressive Questions',
                      description:
                          'Test your mastery across all module lessons with dynamic, AI-generated multiple choice and true/false questions.',
                      isPrimary: false,
                      badgeText: 'AI POWERED',
                      onTap: () => _showModuleSelectionSheet(context),
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

  void _showModuleSelectionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Select Module Quiz',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a module to generate 15 progressive quiz questions.',
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Module 1 Option
              _buildModuleQuizOptionTile(
                ctx,
                module: module1,
                icon: Icons.foundation_rounded,
                accentColor: AppColors.pink,
                surfaceColor: AppColors.extraLightPink,
              ),
              const SizedBox(height: 12),

              // Module 2 Option
              _buildModuleQuizOptionTile(
                ctx,
                module: module2,
                icon: Icons.auto_awesome_rounded,
                accentColor: AppColors.purple,
                surfaceColor: AppColors.lightPurple,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModuleQuizOptionTile(
    BuildContext context, {
    required ModuleContent module,
    required IconData icon,
    required Color accentColor,
    required Color surfaceColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ModuleQuizScreen(module: module),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${module.lessons.length} Sub-lessons • 15 Questions',
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_fill_rounded,
                color: accentColor,
                size: 28,
              ),
            ],
          ),
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
