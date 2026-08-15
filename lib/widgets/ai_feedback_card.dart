import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/services/ai_tutor_service.dart';
import 'package:flutter/material.dart';

/// Interactive AI Feedback Card featuring Xy mascot, step-by-step guidance, and bold math emphasis.
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
          // Header Row: Xy Mascot & Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                AppAssets.xyDefault,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
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
                    FormattedMathText(
                      text: feedback.message,
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

          // Step-by-Step Bulleted List (Reduces cognitive load!)
          if (feedback.steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: feedback.steps.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final stepText = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.extraLightPink,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$index',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.darkPink,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FormattedMathText(
                            text: stepText,
                            style: AppTextStyles.body2.copyWith(
                              fontSize: 13,
                              height: 1.35,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Punchy 1-line Why It Works Pill
          if (feedback.whyItWorks != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.extraLightPink,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightPink, width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.pink,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormattedMathText(
                      text: 'Rule: ${feedback.whyItWorks!}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.darkPink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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
                fontWeight: FontWeight.w900,
              ),
            ),
          ],

          if (feedback.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
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

/// Helper widget that parses markdown **bold** tags and highlights numbers / math expressions.
class FormattedMathText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const FormattedMathText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;

      if (i % 2 == 1) {
        // Bold emphasized math expression or number
        spans.add(
          TextSpan(
            text: part,
            style: style.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.darkPink,
            ),
          ),
        );
      } else {
        // Regular text segment - parse remaining numbers for subtle bolding
        spans.addAll(_parseNumbersInText(part, style));
      }
    }

    return RichText(text: TextSpan(children: spans, style: style));
  }

  List<TextSpan> _parseNumbersInText(String input, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final regExp = RegExp(r'(\d+[\d\.\+\-\*\/\=x]*|\b\d+\b)');
    var lastIndex = 0;

    for (final match in regExp.allMatches(input)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: input.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < input.length) {
      spans.add(TextSpan(text: input.substring(lastIndex)));
    }

    return spans;
  }
}

