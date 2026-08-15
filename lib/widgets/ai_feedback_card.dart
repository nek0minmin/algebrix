import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/services/ai_tutor_service.dart';
import 'package:flutter/material.dart';

/// Interactive AI Feedback Card featuring Xy mascot and Socratic guidance chips.
class AiFeedbackCard extends StatelessWidget {
  final AiFeedbackResult feedback;
  final ValueChanged<String>? onChipSelected;
  final VoidCallback? onClose;

  const AiFeedbackCard({
    super.key,
    required this.feedback,
    this.onChipSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: feedback.isCorrect
              ? AppColors.lightPink
              : AppColors.warning.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                AppAssets.xyDefault,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.title,
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: feedback.isCorrect
                            ? AppColors.text
                            : AppColors.darkPink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feedback.message,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.text,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClose,
                  color: AppColors.subtitle,
                ),
            ],
          ),
          if (feedback.whyItWorks != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.extraLightPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.pink,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Why it works: ${feedback.whyItWorks}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.darkPink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (feedback.promptForStudent != null) ...[
            const SizedBox(height: 12),
            Text(
              feedback.promptForStudent!,
              style: AppTextStyles.subtitle2.copyWith(
                color: AppColors.pink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (feedback.suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: feedback.suggestions.map((chipText) {
                return ActionChip(
                  label: Text(chipText),
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.darkPink,
                    fontWeight: FontWeight.w800,
                  ),
                  backgroundColor: AppColors.extraLightPink,
                  side: const BorderSide(color: AppColors.lightPink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () => onChipSelected?.call(chipText),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Powered by ${feedback.providerUsed}',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: AppColors.subtitle.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
