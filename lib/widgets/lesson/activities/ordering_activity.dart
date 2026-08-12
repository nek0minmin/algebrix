import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/models/lesson_content_model.dart';

class OrderingActivity extends StatefulWidget {
  const OrderingActivity({
    super.key,
    required this.data,
    required this.onAnswered,
    this.enabled = true,
  });

  final OrderingActivityData data;
  final Future<void> Function(bool isCorrect) onAnswered;
  final bool enabled;

  @override
  State<OrderingActivity> createState() => _OrderingActivityState();
}

class _OrderingActivityState extends State<OrderingActivity> {
  final List<String> _selectedIds = [];
  bool _submitting = false;

  Future<void> _select(OrderingItem item) async {
    if (!widget.enabled || _submitting || _selectedIds.contains(item.id)) {
      return;
    }
    setState(() => _selectedIds.add(item.id));
    if (_selectedIds.length != widget.data.items.length) return;

    final isCorrect =
        widget.data.correctOrderIds.length == _selectedIds.length &&
        List.generate(
          _selectedIds.length,
          (index) => _selectedIds[index] == widget.data.correctOrderIds[index],
        ).every((matches) => matches);
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in widget.data.items) ...[
          OutlinedButton(
            key: ValueKey('ordering-item-${item.id}'),
            onPressed: enabled && !_selectedIds.contains(item.id)
                ? () => _select(item)
                : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              alignment: Alignment.centerLeft,
              side: BorderSide(
                color: _selectedIds.contains(item.id)
                    ? AppColors.pink
                    : AppColors.border,
              ),
              backgroundColor: _selectedIds.contains(item.id)
                  ? AppColors.extraLightPink
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedIds.contains(item.id)
                        ? AppColors.pink
                        : AppColors.divider,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _selectedIds.contains(item.id)
                        ? '${_selectedIds.indexOf(item.id) + 1}'
                        : '–',
                    style: AppTextStyles.caption.copyWith(
                      color: _selectedIds.contains(item.id)
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_selectedIds.isNotEmpty) ...[
          TextButton.icon(
            onPressed: enabled ? () => setState(_selectedIds.clear) : null,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset order'),
          ),
        ],
      ],
    );
  }
}
