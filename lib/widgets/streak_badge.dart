import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';

/// Streak display widget.
class StreakBadge extends StatelessWidget {
  final int streakDays;
  final bool showSubtitle;

  const StreakBadge({
    super.key,
    required this.streakDays,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🔥',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              '$streakDays days',
              style: AppTextStyles.heading3,
            ),
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            'Keep it up!',
            style: AppTextStyles.subtitle2,
          ),
        ],
      ],
    );
  }
}
