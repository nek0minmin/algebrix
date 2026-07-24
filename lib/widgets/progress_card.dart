import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';

/// Compact progress display.
class ProgressCard extends StatelessWidget {
  final int level;
  final double progress;
  final String xpText;
  final String levelTitle;

  const ProgressCard({
    super.key,
    required this.level,
    required this.progress,
    required this.xpText,
    required this.levelTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius: 40.0,
          lineWidth: 6.0,
          percent: progress.clamp(0.0, 1.0),
          center: Text(
            '$level',
            style: AppTextStyles.heading3.copyWith(color: AppColors.pink),
          ),
          progressColor: AppColors.pink,
          backgroundColor: AppColors.extraLightPink,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 12),
        Text(
          levelTitle,
          style: AppTextStyles.subtitle1,
        ),
        const SizedBox(height: 4),
        Text(
          xpText,
          style: AppTextStyles.subtitle2,
        ),
      ],
    );
  }
}
