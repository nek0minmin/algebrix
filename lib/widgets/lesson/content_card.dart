import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';

class ContentCard extends StatefulWidget {
  final String? title;
  final String? body;
  final List<String>? bulletPoints;
  final Widget? child;
  final String? xyAsset;

  const ContentCard({
    super.key,
    this.title,
    this.body,
    this.bulletPoints,
    this.child,
    this.xyAsset,
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
      duration: const Duration(milliseconds: 500),
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
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (widget.xyAsset != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E2024),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: Image.asset(
                          widget.xyAsset!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (widget.body != null) ...[
              EmphasizedText(widget.body!),
              const SizedBox(height: 14),
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
              const SizedBox(height: 14),
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
    final defaultBase = baseStyle ??
        AppTextStyles.body1.copyWith(
          color: AppColors.textSecondary,
          height: 1.6,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        );
    final defaultHighlight = highlightStyle ??
        AppTextStyles.body1.copyWith(
          color: AppColors.pink,
          fontWeight: FontWeight.w800,
          height: 1.6,
          fontSize: 15,
        );

    final lines = text.split('\n');
    final children = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }

      final spans = _parseLineSpans(line, defaultBase, defaultHighlight);
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(TextSpan(children: spans)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  List<InlineSpan> _parseLineSpans(
    String line,
    TextStyle baseStyle,
    TextStyle highlightStyle,
  ) {
    final spans = <InlineSpan>[];
    final parts = line.split('**');

    for (var index = 0; index < parts.length; index++) {
      final part = parts[index];
      if (part.isEmpty) continue;

      if (index.isOdd) {
        // Highlighted bold text
        spans.add(TextSpan(text: part, style: highlightStyle));
      } else {
        // Parse code ticks `...` inside base parts
        final tickParts = part.split('`');
        for (var t = 0; t < tickParts.length; t++) {
          final tPart = tickParts[t];
          if (tPart.isEmpty) continue;

          if (t.isOdd) {
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightPurple,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tPart,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ),
            );
          } else {
            spans.add(TextSpan(text: tPart, style: baseStyle));
          }
        }
      }
    }

    return spans;
  }
}
