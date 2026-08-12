import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/models/lesson_content_model.dart';

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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in widget.data.categories)
                      ChoiceChip(
                        label: Text(category.label),
                        selected: _assignments[item.id] == category.id,
                        onSelected: enabled
                            ? (_) => _select(item, category.id)
                            : null,
                        selectedColor: AppColors.extraLightPink,
                        side: BorderSide(
                          color: _assignments[item.id] == category.id
                              ? AppColors.pink
                              : AppColors.border,
                        ),
                        labelStyle: AppTextStyles.body2.copyWith(
                          color: _assignments[item.id] == category.id
                              ? AppColors.darkPink
                              : AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                        showCheckmark: false,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
