import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_assets.dart';

class XySpeechBubble extends StatefulWidget {
  final String message;
  final String xyAsset;
  final Color bubbleColor;
  final double xySize;
  final bool showMascot;
  final Widget? leadingIcon;

  const XySpeechBubble({
    super.key,
    required this.message,
    this.xyAsset = AppAssets.xyInsight,
    this.bubbleColor = Colors.white,
    this.xySize = 64.0,
    this.showMascot = true,
    this.leadingIcon,
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
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.showMascot) ...[
              Image.asset(
                widget.xyAsset,
                width: widget.xySize,
                height: widget.xySize,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: widget.bubbleColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    widget.leadingIcon ??
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.lightYellow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: AppColors.yellow,
                            size: 18,
                          ),
                        ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormattedDialogue(widget.message),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedDialogue(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*.*?\*\*|\*.*?\*)');
    var lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 0.35,
              height: 1.45,
            ),
          ),
        );
      }

      final raw = match.group(0)!;
      final clean = raw.replaceAll('*', '');
      spans.add(
        TextSpan(
          text: clean,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppColors.pink,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.35,
            height: 1.45,
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.35,
            height: 1.45,
          ),
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }
}
