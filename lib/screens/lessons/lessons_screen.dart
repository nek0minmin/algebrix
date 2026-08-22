import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/screens/lessons/module_overview_screen.dart';
import 'package:algebrix/screens/lessons/lesson_screen.dart';
import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/data/module2_content.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/core/animations/app_page_route.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// Learning Path screen — replaces the placeholder "Coming Soon" Lessons tab.
/// Shows available modules with progress indicators and lock states.
class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allLessons = [...module1.lessons, ...module2.lessons];
    final filteredLessons = _searchQuery.isEmpty
        ? <LessonContent>[]
        : allLessons.where((l) {
            return l.title.toLowerCase().contains(_searchQuery) ||
                l.objective.toLowerCase().contains(_searchQuery);
          }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RootPageHeader(
            title: 'Your Lessons',
            subtitle: 'Let’s learn together!',
            searchPlaceholder: 'Search Lessons',
            onSearchChanged: (q) => setState(() => _searchQuery = q.trim().toLowerCase()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                if (_searchQuery.isNotEmpty) ...[
                  if (filteredLessons.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'No lessons found matching "$_searchQuery"',
                          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    for (final lesson in filteredLessons) ...[
                      _FilteredLessonCard(lesson: lesson),
                      const SizedBox(height: 12),
                    ],
                ] else ...[
                  // Module 1 — Algebra Foundations (Active)
                _ModuleCard(
                  module: module1,
                  moduleNumber: 1,
                  accentColor: AppColors.pink,
                  isLocked: false,
                  onTap: () {
                    final lessonProvider = context.read<LessonProvider>();
                    lessonProvider.startModule(module1);
                    Navigator.of(context).push(
                      AppPageRoute(
                        child: const ModuleOverviewScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Module 2 — Working with Expressions (Active)
                _ModuleCard(
                  module: module2,
                  moduleNumber: 2,
                  accentColor: AppColors.purple,
                  isLocked: false,
                  onTap: () {
                    final lessonProvider = context.read<LessonProvider>();
                    lessonProvider.startModule(module2);
                    Navigator.of(context).push(
                      AppPageRoute(
                        child: const ModuleOverviewScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Module 3 — Solving Equations (Locked)
                _LockedModuleCard(
                  title: 'Solving Equations',
                  description: 'One-step, two-step, and multi-step equations.',
                  moduleNumber: 3,
                  icon: '⚖️',
                  accentColor: AppColors.mint,
                ),

                const SizedBox(height: 16),

                // Module 4 — Inequalities (Locked)
                _LockedModuleCard(
                  title: 'Inequalities',
                  description: 'One-step, two-step, and graphing inequalities.',
                  moduleNumber: 4,
                  icon: '📊',
                  accentColor: AppColors.yellow,
                ),

                const SizedBox(height: 16),

                // Module 5 — Linear Relationships (Locked)
                _LockedModuleCard(
                  title: 'Linear Relationships',
                  description:
                      'Coordinate plane, slope, linear equations, and graphing.',
                  moduleNumber: 5,
                  icon: '📈',
                  accentColor: AppColors.info,
                ),

                const SizedBox(height: 16),

                // Module 6 — Polynomials (Locked)
                _LockedModuleCard(
                  title: 'Polynomials',
                  description:
                      'Adding, subtracting, multiplying, and factoring.',
                  moduleNumber: 6,
                  icon: '🔢',
                  accentColor: AppColors.error,
                ),

                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
}

/// Active module card with progress and tap-to-open.
class _ModuleCard extends StatelessWidget {
  final ModuleContent module;
  final int moduleNumber;
  final Color accentColor;
  final bool isLocked;
  final VoidCallback? onTap;

  const _ModuleCard({
    required this.module,
    required this.moduleNumber,
    required this.accentColor,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lessonProvider = context.watch<LessonProvider>();
    final completedCount = module.lessons
        .where((l) => lessonProvider.isLessonCompleted(l.lessonId))
        .length;
    final totalCount = module.lessons.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return BouncyPressable(
      shrinkFactor: 0.97,
      enableHaptics: true,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Module header row
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.functions_rounded,
                    color: accentColor,
                    size: 26,
                    semanticLabel: 'Algebra module',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MODULE $moduleNumber',
                        style: AppTextStyles.caption.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        module.title,
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Description
            Text(
              '${module.lessons.length} lessons • ${module.lessons.take(3).map((l) => l.title).join(", ")}, and more',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completedCount of $totalCount lessons completed',
              style: AppTextStyles.caption.copyWith(color: AppColors.subtitle),
            ),
          ],
        ),
      ),
    );
  }
}

/// Locked module card with greyed-out lock indicator.
class _LockedModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final int moduleNumber;
  final String icon;
  final Color accentColor;

  const _LockedModuleCard({
    required this.title,
    required this.description,
    required this.moduleNumber,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MODULE $moduleNumber',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.subtitle,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: AppTextStyles.subtitle1.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock_rounded, size: 22, color: AppColors.subtitle),
          ],
        ),
      ),
    );
  }
}

class _FilteredLessonCard extends StatelessWidget {
  final LessonContent lesson;

  const _FilteredLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final lessonProvider = context.watch<LessonProvider>();
    final isCompleted = lessonProvider.isLessonCompleted(lesson.lessonId);

    return BouncyPressable(
      shrinkFactor: 0.97,
      enableHaptics: true,
      onTap: () {
        final parentModule = module1.lessons.any((l) => l.lessonId == lesson.lessonId)
            ? module1
            : module2;
        lessonProvider.startModule(parentModule);
        lessonProvider.startLesson(lesson);
        Navigator.of(context).push(
          AppPageRoute(
            child: const LessonScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.lightMint : AppColors.extraLightPink,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.menu_book_rounded,
                color: isCompleted ? AppColors.mint : AppColors.pink,
                size: 22,
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
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lesson.objective,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
