import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';

class MathHighlightBox extends StatefulWidget {
  final String expression;
  final String? annotation;
  final Color accentColor;

  const MathHighlightBox({
    super.key,
    required this.expression,
    this.annotation,
    this.accentColor = AppColors.pink,
  });

  @override
  State<MathHighlightBox> createState() => _MathHighlightBoxState();
}

class _MathHighlightBoxState extends State<MathHighlightBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.extraLightPink,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: widget.accentColor,
              width: 4,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.expression,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.annotation != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.annotation!,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
