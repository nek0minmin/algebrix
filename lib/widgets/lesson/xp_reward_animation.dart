import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';

class XpRewardAnimation extends StatefulWidget {
  final int xpAmount;
  final VoidCallback? onComplete;

  const XpRewardAnimation({
    super.key,
    required this.xpAmount,
    this.onComplete,
  });

  @override
  State<XpRewardAnimation> createState() => _XpRewardAnimationState();
}

class _XpRewardAnimationState extends State<XpRewardAnimation> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 40),
    ]).animate(_scaleController);

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      await _fadeController.forward();
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${widget.xpAmount} XP',
                style: AppTextStyles.heading2.copyWith(color: AppColors.text),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.star_rounded,
                color: AppColors.yellow,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
