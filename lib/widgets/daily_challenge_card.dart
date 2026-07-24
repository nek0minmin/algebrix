import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/widgets/xp_badge.dart';

/// Daily challenge widget for dashboard.
class DailyChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final double progress;
  final String progressText;
  final int xpReward;
  final VoidCallback? onTap;

  const DailyChallengeCard({
    super.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.progressText,
    required this.xpReward,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.subtitle1,
                    ),
                    const SizedBox(width: 8),
                    const Text('🔥'),
                    const Spacer(),
                    XpBadge(amount: xpReward),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTextStyles.body2,
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
                          backgroundColor: AppColors.lightMint,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.mint,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
