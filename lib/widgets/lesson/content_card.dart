import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';

class ContentCard extends StatefulWidget {
  final String? title;
  final String? body;
  final List<String>? bulletPoints;
  final Widget? child;

  const ContentCard({
    super.key,
    this.title,
    this.body,
    this.bulletPoints,
    this.child,
  });

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
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
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.body != null) ...[
              EmphasizedText(widget.body!),
              const SizedBox(height: 16),
            ],
            if (widget.bulletPoints != null &&
                widget.bulletPoints!.isNotEmpty) ...[
              Text(
                'COMMON VARIABLES',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.sizeOf(context).width;
                  final chipSize = screenWidth < 340 ? 44.0 : 48.0;
                  final itemCount = widget.bulletPoints!.length;
                  final availableGap = itemCount > 1
                      ? (constraints.maxWidth - (chipSize * itemCount)) /
                            (itemCount - 1)
                      : 0.0;
                  final spacing = availableGap.clamp(0.0, 12.0);

                  return Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: spacing,
                      runSpacing: 8,
                      children: [
                        for (final point in widget.bulletPoints!)
                          Container(
                            key: ValueKey('variable-chip-$point'),
                            width: chipSize,
                            height: chipSize,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.extraLightPink,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  point,
                                  maxLines: 1,
                                  style: AppTextStyles.subtitle1.copyWith(
                                    color: AppColors.pink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

class EmphasizedText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextStyle? highlightStyle;

  const EmphasizedText(
    this.text, {
    super.key,
    this.baseStyle,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    final defaultBase = baseStyle ?? AppTextStyles.body1.copyWith(height: 1.6);
    final defaultHighlight = highlightStyle ??
        AppTextStyles.body1.copyWith(
          color: AppColors.pink,
          fontWeight: FontWeight.w800,
          height: 1.6,
        );

    for (var index = 0; index < parts.length; index++) {
      spans.add(
        TextSpan(
          text: parts[index],
          style: index.isOdd ? defaultHighlight : defaultBase,
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }
}
