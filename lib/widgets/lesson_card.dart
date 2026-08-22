import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// Continue Learning card for the dashboard with tactile spring press.
class LessonCard extends StatelessWidget {
  final String lessonTitle;
  final String moduleTitle;
  final double progress;
  final String progressText;
  final VoidCallback? onTap;

  const LessonCard({
    super.key,
    required this.lessonTitle,
    required this.moduleTitle,
    required this.progress,
    required this.progressText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      shrinkFactor: 0.97,
      enableHaptics: true,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moduleTitle,
                        style: AppTextStyles.subtitle2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lessonTitle,
                        style: AppTextStyles.subtitle1,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.subtitle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  progressText,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.extraLightPink,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.pink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
