import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/secondary_button.dart';
import 'package:flutter/material.dart';

/// Modal dialog presenting side-by-side [Keep Original] vs [Use Suggestion] comparison.
class AiSuggestionDialog extends StatelessWidget {
  final String originalText;
  final String suggestedText;

  const AiSuggestionDialog({
    super.key,
    required this.originalText,
    required this.suggestedText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.extraLightPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.pink,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '✨ Improve My Understanding',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Algebrix structured your note for clarity. Your original note stays yours unless you choose to accept!',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 500;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _NotePreviewBox(
                              title: 'Original Note',
                              content: originalText,
                              badgeColor: AppColors.subtitle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _NotePreviewBox(
                              title: '✨ AI Suggestion',
                              content: suggestedText,
                              badgeColor: AppColors.pink,
                              isHighlighted: true,
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _NotePreviewBox(
                          title: 'Original Note',
                          content: originalText,
                          badgeColor: AppColors.subtitle,
                        ),
                        const SizedBox(height: 14),
                        _NotePreviewBox(
                          title: '✨ AI Suggestion',
                          content: suggestedText,
                          badgeColor: AppColors.pink,
                          isHighlighted: true,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Keep Original',
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Use Suggestion',
                        icon: Icons.check_rounded,
                        onPressed: () => Navigator.of(context).pop(true),
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

class _NotePreviewBox extends StatelessWidget {
  final String title;
  final String content;
  final Color badgeColor;
  final bool isHighlighted;

  const _NotePreviewBox({
    required this.title,
    required this.content,
    required this.badgeColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.extraLightPink.withValues(alpha: 0.5) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? AppColors.lightPink : AppColors.border,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            content.isEmpty ? '(Empty note)' : content,
            style: AppTextStyles.body2.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
