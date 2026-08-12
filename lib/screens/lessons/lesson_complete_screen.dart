import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/secondary_button.dart';
import 'package:algebrix/screens/lessons/lesson_screen.dart';

/// Celebration screen shown after completing a lesson.
/// Displays XP earned, Xy happy mascot, and navigation options.
class LessonCompleteScreen extends StatefulWidget {
  const LessonCompleteScreen({super.key});

  @override
  State<LessonCompleteScreen> createState() => _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends State<LessonCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _confettiController;
  bool _isStartingNext = false;
  String? _navigationError;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Staggered animation sequence
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _confettiController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonProvider = context.watch<LessonProvider>();
    final lesson = lessonProvider.currentLesson;
    final module = lessonProvider.currentModule;
    final xpEarned = lessonProvider.sessionXp;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti-like particles
            ..._buildConfetti(),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mascot celebration
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Image.asset(
                        AppAssets.xyHappy,
                        width: 150,
                        height: 150,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Text(
                        'Lesson Complete! 🎉',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        lesson?.title ?? 'Great job!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // XP Earned Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.yellow.withValues(alpha: 0.15),
                              AppColors.lightYellow,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.yellow.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 8),
                            Text(
                              '+$xpEarned XP',
                              style: AppTextStyles.heading1.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Experience earned',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats row
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatChip(
                            icon: Icons.check_circle_rounded,
                            label: '${lesson?.totalSteps ?? 0} Steps',
                            color: AppColors.mint,
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.stars_rounded,
                            label: '$xpEarned XP',
                            color: AppColors.yellow,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Action buttons
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Check if there's a next lesson
                          if (_hasNextLesson(module, lesson))
                            PrimaryButton(
                              label: 'Next Lesson',
                              isLoading: _isStartingNext,
                              onPressed: () async {
                                await _startNextLesson(module, lesson);
                              },
                            ),
                          if (_navigationError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '$_navigationError Try again.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),
                          SecondaryButton(
                            label: 'Back to Module',
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
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

  bool _hasNextLesson(ModuleContent? module, LessonContent? currentLesson) {
    if (module == null || currentLesson == null) return false;
    final index = module.lessons.indexWhere(
      (l) => l.lessonId == currentLesson.lessonId,
    );
    return index >= 0 &&
        index < module.lessons.length - 1 &&
        module.lessons[index + 1].steps.isNotEmpty;
  }

  Future<void> _startNextLesson(
    ModuleContent? module,
    LessonContent? currentLesson,
  ) async {
    if (module == null || currentLesson == null) return;
    final index = module.lessons.indexWhere(
      (l) => l.lessonId == currentLesson.lessonId,
    );
    if (index >= 0 && index < module.lessons.length - 1) {
      final nextLesson = module.lessons[index + 1];
      final lessonProvider = context.read<LessonProvider>();
      setState(() {
        _isStartingNext = true;
        _navigationError = null;
      });
      final opened = await lessonProvider.startLesson(nextLesson);
      if (!mounted) return;
      setState(() => _isStartingNext = false);
      if (!opened) {
        setState(() {
          _navigationError =
              lessonProvider.errorMessage ?? 'Progress could not be saved.';
        });
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _NextLessonRedirect()),
      );
    }
  }

  List<Widget> _buildConfetti() {
    final colors = [
      AppColors.pink,
      AppColors.purple,
      AppColors.mint,
      AppColors.yellow,
    ];

    return List.generate(16, (i) {
      final random = i * 37 % 17;
      final left = (i * 23 % 100).toDouble() / 100;
      // delay is calculated but confetti timing is handled by controller
      final size = 8.0 + (random % 4) * 2;

      return AnimatedBuilder(
        animation: _confettiController,
        builder: (context, child) {
          final screenWidth = MediaQuery.of(context).size.width;
          return Positioned(
            left: left * screenWidth,
            top: -20 + (_confettiController.value * (300 + random * 20)),
            child: Opacity(
              opacity: (1 - _confettiController.value).clamp(0, 1),
              child: Transform.rotate(
                angle: _confettiController.value * 3.14 * (i % 2 == 0 ? 1 : -1),
                child: Container(
                  width: size,
                  height: size * 1.5,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

/// Helper widget to redirect to the LessonScreen for the next lesson.
class _NextLessonRedirect extends StatefulWidget {
  const _NextLessonRedirect();

  @override
  State<_NextLessonRedirect> createState() => _NextLessonRedirectState();
}

class _NextLessonRedirectState extends State<_NextLessonRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LessonScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator(color: AppColors.pink)),
    );
  }
}

/// Small stat chip widget for the celebration screen.
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.subtitle2.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
