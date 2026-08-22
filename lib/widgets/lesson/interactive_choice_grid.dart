import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/models/lesson_content_model.dart';

class InteractiveChoiceGrid extends StatefulWidget {
  final List<ChoiceOption> choices;
  final FutureOr<void> Function(int index, bool isCorrect) onAnswered;
  final bool isAnswered;
  final bool isEnabled;

  const InteractiveChoiceGrid({
    super.key,
    required this.choices,
    required this.onAnswered,
    required this.isAnswered,
    this.isEnabled = true,
  });

  @override
  State<InteractiveChoiceGrid> createState() => _InteractiveChoiceGridState();
}

class _InteractiveChoiceGridState extends State<InteractiveChoiceGrid> {
  int? _selectedIndex;
  final Set<int> _incorrectSelections = {};
  bool _isSubmitting = false;

  Future<void> _handleChoice(int index, ChoiceOption choice) async {
    if (!widget.isEnabled || widget.isAnswered || _isSubmitting) return;
    setState(() {
      _selectedIndex = index;
      _isSubmitting = true;
      if (!choice.isCorrect) {
        _incorrectSelections.add(index);
      }
    });
    try {
      await widget.onAnswered(index, choice.isCorrect);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(widget.choices.length, (index) {
        final choice = widget.choices[index];
        final isSelected = _selectedIndex == index;

        return FractionallySizedBox(
          widthFactor: 0.48,
          child: _ChoiceItem(
            choice: choice,
            isAnswered: widget.isAnswered,
            isEnabled: widget.isEnabled && !_isSubmitting,
            isSelected: isSelected,
            isIncorrectSelection: _incorrectSelections.contains(index),
            onTap: () => unawaited(_handleChoice(index, choice)),
          ),
        );
      }),
    );
  }
}

class _ChoiceItem extends StatefulWidget {
  final ChoiceOption choice;
  final bool isAnswered;
  final bool isEnabled;
  final bool isSelected;
  final bool isIncorrectSelection;
  final VoidCallback onTap;

  const _ChoiceItem({
    required this.choice,
    required this.isAnswered,
    required this.isEnabled,
    required this.isSelected,
    required this.isIncorrectSelection,
    required this.onTap,
  });

  @override
  State<_ChoiceItem> createState() => _ChoiceItemState();
}

class _ChoiceItemState extends State<_ChoiceItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isAnswered) {
      HapticFeedback.selectionClick();
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isEnabled && !widget.isAnswered) _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    if (widget.isEnabled && !widget.isAnswered) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white;
    Color borderColor = AppColors.border;
    Widget? trailingIcon;
    double opacity = 1.0;

    if (widget.isIncorrectSelection) {
      bgColor = const Color(0xFFFFF1F2);
      borderColor = AppColors.error;
      trailingIcon = const Icon(
        Icons.cancel_rounded,
        color: AppColors.error,
        size: 20,
      );
    } else if (widget.isSelected && !widget.isAnswered) {
      bgColor = AppColors.extraLightPink;
      borderColor = AppColors.pink;
    } else if (widget.isAnswered) {
      if (widget.isSelected) {
        bgColor = AppColors.lightMint;
        borderColor = AppColors.mint;
        trailingIcon = const Icon(
          Icons.check_circle_rounded,
          color: AppColors.mint,
          size: 20,
        );
      } else {
        opacity = 0.6;
      }
    }

    final emojiText = widget.choice.emoji ?? '';

    return IgnorePointer(
      ignoring: !widget.isEnabled,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: widget.isEnabled ? opacity : opacity * 0.7,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (emojiText.isNotEmpty) ...[
                    Text(emojiText, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      widget.choice.label,
                      style: AppTextStyles.subtitle1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    trailingIcon,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
