import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';

class XySpeechBubble extends StatefulWidget {
  final String message;
  final String xyAsset;
  final Color bubbleColor;
  final double xySize;
  final bool showMascot;

  const XySpeechBubble({
    super.key,
    required this.message,
    this.xyAsset = AppAssets.xyExplaining,
    this.bubbleColor = AppColors.extraLightPink,
    this.xySize = 80.0,
    this.showMascot = true,
  });

  @override
  State<XySpeechBubble> createState() => _XySpeechBubbleState();
}

class _XySpeechBubbleState extends State<XySpeechBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showMascot) ...[
              Image.asset(
                widget.xyAsset,
                width: widget.xySize,
                height: widget.xySize,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (widget.showMascot)
                    Positioned(
                      left: -8,
                      top: 20,
                      child: CustomPaint(
                        painter: _BubbleTailPainter(color: widget.bubbleColor),
                        size: const Size(8, 12),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.bubbleColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(widget.message, style: AppTextStyles.body1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;

  _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      color != oldDelegate.color;
}
