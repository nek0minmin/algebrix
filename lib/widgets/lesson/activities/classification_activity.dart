import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// Interactive math classification activity with centered math labels and tactile option pills.
class ClassificationActivity extends StatefulWidget {
  const ClassificationActivity({
    super.key,
    required this.data,
    required this.onAnswered,
    this.enabled = true,
  });

  final ClassificationActivityData data;
  final Future<void> Function(bool isCorrect) onAnswered;
  final bool enabled;

  @override
  State<ClassificationActivity> createState() => _ClassificationActivityState();
}

class _ClassificationActivityState extends State<ClassificationActivity> {
  final Map<String, String> _assignments = {};
  bool _submitting = false;

  Future<void> _select(ClassificationItem item, String categoryId) async {
    if (!widget.enabled || _submitting) return;
    setState(() => _assignments[item.id] = categoryId);
    if (_assignments.length != widget.data.items.length) return;

    final isCorrect = widget.data.items.every(
      (candidate) => _assignments[candidate.id] == candidate.categoryId,
    );
    setState(() => _submitting = true);
    try {
      await widget.onAnswered(isCorrect);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !_submitting;

    return Column(
      children: [
        for (final item in widget.data.items) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.8),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Centered Math Expression
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Centered Option Pills
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    for (final category in widget.data.categories)
                      _ClassificationPill(
                        key: ValueKey('classification-pill-${item.id}-${category.id}'),
                        label: category.label,
                        isSelected: _assignments[item.id] == category.id,
                        enabled: enabled,
                        onTap: () => _select(item, category.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Modern tactile option pill with spring physics and high-contrast selected state.
class _ClassificationPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _ClassificationPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      shrinkFactor: 0.94,
      enableHaptics: true,
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pink : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.pink : AppColors.border,
            width: isSelected ? 2 : 1.4,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.pink.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
