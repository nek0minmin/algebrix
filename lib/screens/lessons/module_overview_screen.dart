import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/core/providers/quiz_provider.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/lesson/xy_speech_bubble.dart';
import 'package:algebrix/screens/lessons/lesson_screen.dart';
import 'package:algebrix/screens/quiz/module_quiz_screen.dart';
import 'package:algebrix/widgets/search_bar_widget.dart';
import 'package:algebrix/widgets/xy_mascot.dart';
import 'package:algebrix/core/animations/app_page_route.dart';
import 'package:algebrix/widgets/page_headers.dart';

/// Module Overview screen showing the module intro and lesson list with progressive unlocking.
class ModuleOverviewScreen extends StatefulWidget {
  const ModuleOverviewScreen({super.key});

  @override
  State<ModuleOverviewScreen> createState() => _ModuleOverviewScreenState();
}

class _ModuleOverviewScreenState extends State<ModuleOverviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _introSeen = false;
  int? _expandedLessonIndex;
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'completed', 'unlocked', 'locked'

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonProvider = context.watch<LessonProvider>();
    final module = lessonProvider.currentModule;

    if (module == null) {
      return const Scaffold(body: Center(child: Text('No module selected.')));
    }

    final appBar = AlgebrixAppBar(
      title: 'Module Overview',
      onBack: () => Navigator.of(context).pop(),
    );

    if (lessonProvider.isHydrating) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: appBar,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.pink),
              const SizedBox(height: 16),
              Text(
                'Loading your learning path…',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (lessonProvider.hydrationError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: appBar,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.error,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'We couldn’t load your progress.',
                  style: AppTextStyles.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  lessonProvider.hydrationError!,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Try again',
                  onPressed: lessonProvider.retryHydration,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Module Intro Card
              if (!_introSeen) ...[
                _ModuleIntroCard(
                  module: module,
                  onStart: () {
                    setState(() => _introSeen = true);
                  },
                ),
              ] else ...[
                // Dynamic Module Hero Header Banner
                _ModuleHeroHeaderBanner(
                  module: module,
                  completedCount: module.lessons
                      .where((l) => lessonProvider.isLessonCompleted(l.lessonId))
                      .length,
                ),

                const SizedBox(height: 16),

                // ⚡ AI Module Quiz Challenge Card
                _ModuleQuizPromoCard(
                  module: module,
                  onStartQuiz: () {
                    Navigator.push(
                      context,
                      AppPageRoute(
                        child: ModuleQuizScreen(module: module),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Search & Status Filter
                SearchBarWidget(
                  onChanged: (q) => setState(() => _searchQuery = q),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _LessonFilterChip(
                        label: 'All',
                        isSelected: _statusFilter == 'all',
                        onTap: () => setState(() => _statusFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _LessonFilterChip(
                        label: 'Completed',
                        isSelected: _statusFilter == 'completed',
                        onTap: () => setState(() => _statusFilter = 'completed'),
                      ),
                      const SizedBox(width: 8),
                      _LessonFilterChip(
                        label: 'Unlocked',
                        isSelected: _statusFilter == 'unlocked',
                        onTap: () => setState(() => _statusFilter = 'unlocked'),
                      ),
                      const SizedBox(width: 8),
                      _LessonFilterChip(
                        label: 'Locked',
                        isSelected: _statusFilter == 'locked',
                        onTap: () => setState(() => _statusFilter = 'locked'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Lesson List Header
                Text(
                  'Lessons',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),

                ...() {
                  final query = _searchQuery.trim().toLowerCase();
                  final filtered = module.lessons.where((lesson) {
                    final isCompleted = lessonProvider.isLessonCompleted(lesson.lessonId);
                    final isUnlocked = lessonProvider.isLessonUnlocked(lesson.lessonId, module.lessons) && lesson.steps.isNotEmpty;
                    final isLocked = !isUnlocked;

                    if (_statusFilter == 'completed' && !isCompleted) return false;
                    if (_statusFilter == 'unlocked' && !isUnlocked) return false;
                    if (_statusFilter == 'locked' && !isLocked) return false;

                    if (query.isNotEmpty) {
                      final titleMatch = lesson.title.toLowerCase().contains(query);
                      final descMatch = lesson.objective.toLowerCase().contains(query);
                      return titleMatch || descMatch;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No lessons match your search/filter.',
                            style: AppTextStyles.body2.copyWith(color: AppColors.subtitle),
                          ),
                        ),
                      ),
                    ];
                  }

                  return filtered.map((lesson) {
                    final index = module.lessons.indexOf(lesson);
                    final isCompleted = lessonProvider.isLessonCompleted(lesson.lessonId);
                    final isUnlocked = lessonProvider.isLessonUnlocked(lesson.lessonId, module.lessons);
                    final hasContent = lesson.steps.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LessonListItem(
                      lessonNumber: index + 1,
                      lesson: lesson,
                      isCompleted: isCompleted,
                      isUnlocked: isUnlocked && hasContent,
                      isExpanded: _expandedLessonIndex == index,
                      onExpansionChanged: () {
                        setState(() {
                          _expandedLessonIndex = _expandedLessonIndex == index
                              ? null
                              : index;
                        });
                      },
                      onTap:
                          (isUnlocked && hasContent && !lessonProvider.isBusy)
                          ? () async {
                              final opened = await lessonProvider.startLesson(
                                lesson,
                              );
                              if (!context.mounted) return;
                              if (!opened) {
                                final message = lessonProvider.errorMessage;
                                if (message != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$message Try again.'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                                return;
                              }
                              Navigator.of(context).push(
                                AppPageRoute(
                                  child: const LessonScreen(),
                                ),
                              );
                            }
                          : null,
                    ),
                  );
                }).toList();
              }(),

                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonFilterChip extends StatelessWidget {
  const _LessonFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: isSelected ? Colors.white : AppColors.text,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: AppColors.pink,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.pink : AppColors.border,
        ),
      ),
    );
  }
}

/// Module Intro Card — "Meet Xy" welcome screen.
class _ModuleIntroCard extends StatelessWidget {
  final ModuleContent module;
  final VoidCallback onStart;

  const _ModuleIntroCard({required this.module, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          XyMascot(
            asset: module.xyAsset ?? AppAssets.xyLessons,
            size: 120,
            shadowBlur: 6.0,
            shadowOpacity: 0.25,
          ),
          const SizedBox(height: 14),
          // Title
          Text(
            module.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),

          // Xy speech bubble
          if (module.xyDialogue != null)
            XySpeechBubble(
              message: module.xyDialogue!,
              xyAsset: module.xyAsset ?? AppAssets.xyLessons,
              xySize: 60,
              showMascot: false,
            ),
          const SizedBox(height: 16),

          // Body text
          Text(
            module.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // CTA Button
          PrimaryButton(
            label: module.buttonLabel ?? 'Explore Module 1',
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

/// Individual lesson item in the module overview list.
class _LessonListItem extends StatelessWidget {
  final int lessonNumber;
  final LessonContent lesson;
  final bool isCompleted;
  final bool isUnlocked;
  final bool isExpanded;
  final VoidCallback onExpansionChanged;
  final VoidCallback? onTap;

  const _LessonListItem({
    required this.lessonNumber,
    required this.lesson,
    required this.isCompleted,
    required this.isUnlocked,
    required this.isExpanded,
    required this.onExpansionChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isCompleted
        ? AppColors.mint
        : (isUnlocked ? AppColors.pink : AppColors.subtitle);

    return Semantics(
      button: true,
      expanded: isExpanded,
      label: 'Lesson $lessonNumber: ${lesson.title}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isUnlocked
              ? Colors.white
              : AppColors.divider.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? AppColors.mint.withValues(alpha: 0.4)
                : (isUnlocked
                      ? AppColors.pink.withValues(alpha: 0.2)
                      : AppColors.border),
            width: 1.2,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onExpansionChanged,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.lightMint
                            : (isUnlocked
                                  ? AppColors.extraLightPink
                                  : AppColors.divider),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.mint,
                                size: 22,
                              )
                            : (isUnlocked
                                  ? Text(
                                      '$lessonNumber',
                                      style: AppTextStyles.subtitle1.copyWith(
                                        color: AppColors.pink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.lock_rounded,
                                      color: AppColors.subtitle,
                                      size: 18,
                                    )),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: AppTextStyles.subtitle1.copyWith(
                              color: isUnlocked
                                  ? AppColors.text
                                  : AppColors.subtitle,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isExpanded
                                ? 'Lesson overview'
                                : 'Tap to preview this lesson',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: isExpanded
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 0, 10, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              isUnlocked
                                  ? lesson.objective
                                  : '${lesson.objective}  Coming soon.',
                              style: AppTextStyles.body2.copyWith(
                                color: isUnlocked
                                    ? AppColors.textSecondary
                                    : AppColors.subtitle,
                                height: 1.5,
                              ),
                            ),
                          ),
                          if (isUnlocked)
                            SizedBox.square(
                              dimension: 44,
                              child: IconButton(
                                tooltip: isCompleted
                                    ? 'Review lesson'
                                    : 'Open lesson',
                                onPressed: onTap,
                                icon: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                ),
                                color: isCompleted
                                    ? AppColors.mint
                                    : AppColors.pink,
                                style: IconButton.styleFrom(
                                  backgroundColor: isCompleted
                                      ? AppColors.lightMint
                                      : AppColors.extraLightPink,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleQuizPromoCard extends StatelessWidget {
  final ModuleContent module;
  final VoidCallback onStartQuiz;

  const _ModuleQuizPromoCard({
    required this.module,
    required this.onStartQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final lessonProvider = context.watch<LessonProvider>();
    final quizProvider = context.watch<QuizProvider>();

    final isUnlocked = quizProvider.isQuizUnlocked(module.id, lessonProvider);
    final quizProgress = quizProvider.getQuizProgress(module.id);
    final completedLessons = lessonProvider.completedLessonsInModule(module.id);
    final totalLessons = module.lessons.length;
    final hasPassed = quizProgress.passed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUnlocked
            ? onStartQuiz
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Complete all ${module.title} lessons ($completedLessons/$totalLessons) to unlock the Quiz!',
                    ),
                    backgroundColor: AppColors.pink,
                  ),
                );
              },
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: isUnlocked ? 1.0 : 0.7,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUnlocked
                    ? (hasPassed
                        ? AppColors.mint
                        : AppColors.purple.withValues(alpha: 0.4))
                    : AppColors.border,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isUnlocked
                      ? (hasPassed
                          ? AppColors.mint.withValues(alpha: 0.08)
                          : AppColors.purple.withValues(alpha: 0.08))
                      : AppColors.shadow,
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUnlocked ? AppColors.lightPurple : AppColors.divider,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnlocked
                        ? Icons.psychology_rounded
                        : Icons.lock_outline_rounded,
                    color: isUnlocked ? AppColors.purple : AppColors.subtitle,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'AI Module Quiz',
                              style: GoogleFonts.nunito(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (hasPassed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightMint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Passed (${quizProgress.formattedBestPercentage})',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F7263),
                                ),
                              ),
                            )
                          else if (isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.extraLightPink,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Ready to Take',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.darkPink,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Locked ($completedLessons/$totalLessons)',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.subtitle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUnlocked
                            ? '10 Dynamic Questions • Progressive Difficulty'
                            : 'Complete all $totalLessons lessons to unlock this quiz',
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
                  isUnlocked
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.lock_rounded,
                  size: 16,
                  color: isUnlocked ? AppColors.purple : AppColors.subtitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rich, engaging hero banner card for the module overview page.
class _ModuleHeroHeaderBanner extends StatelessWidget {
  final ModuleContent module;
  final int completedCount;

  const _ModuleHeroHeaderBanner({
    required this.module,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = module.lessons.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final isModule3 = module.id == 'module3';
    final isModule2 = module.id == 'module2';
    final accentColor = isModule3
        ? AppColors.mint
        : (isModule2 ? AppColors.purple : AppColors.pink);
    final moduleNum = isModule3 ? 3 : (isModule2 ? 2 : 1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          XyMascot(
            asset: module.xyAsset ?? AppAssets.xyLessons,
            size: 96,
            shadowBlur: 8.0,
            shadowOpacity: 0.22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    'MODULE $moduleNum',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  module.title,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completedCount of $totalCount lessons completed',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: accentColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
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

