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

  /// Circles only when every bullet is a bare symbol, e.g. the variables
  /// x, y, a, b, n. A list of worked values or phrases gets pills instead.
  bool get _useCircles =>
      widget.bulletPoints!.every((point) => point.trim().length <= 2);

  /// "COMMON VARIABLES" is only true when the bullets really are variables.
  String get _bulletsLabel => _useCircles ? 'COMMON VARIABLES' : 'EXAMPLES';

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
                    Image.asset(
                      widget.xyAsset!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
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
                _bulletsLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Circles shrink their gap so a row of variables stays on one
                  // line even at 320px; pills size to their text and wrap
                  // naturally, so a fixed gap is right for them.
                  var spacing = 8.0;
                  if (_useCircles) {
                    final chipSize =
                        MediaQuery.sizeOf(context).width < 340 ? 44.0 : 48.0;
                    final count = widget.bulletPoints!.length;
                    final gap = count > 1
                        ? (constraints.maxWidth - (chipSize * count)) /
                            (count - 1)
                        : 0.0;
                    spacing = gap.clamp(0.0, 12.0);
                  }

                  return Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: spacing,
                      runSpacing: 8,
                      children: [
                        for (final point in widget.bulletPoints!)
                          _BulletChip(point: point, asCircle: _useCircles),
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

/// One bullet from a content card.
///
/// Circles suit single-symbol lists like the variables x, y, n. Anything
/// longer gets a pill that sizes to its text — the old fixed 44px circle
/// shrank a phrase like "…and infinitely many more" until it was unreadable.
class _BulletChip extends StatelessWidget {
  const _BulletChip({required this.point, required this.asCircle});

  final String point;
  final bool asCircle;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      point,
      maxLines: asCircle ? 1 : 2,
      textAlign: TextAlign.center,
      style: AppTextStyles.subtitle1.copyWith(
        color: AppColors.pink,
        fontWeight: FontWeight.w900,
        fontSize: asCircle ? null : 14,
      ),
    );

    if (asCircle) {
      final chipSize = MediaQuery.sizeOf(context).width < 340 ? 44.0 : 48.0;
      return Container(
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
          child: FittedBox(fit: BoxFit.scaleDown, child: label),
        ),
      );
    }

    return Container(
      key: ValueKey('variable-chip-$point'),
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.extraLightPink,
        borderRadius: BorderRadius.circular(19),
      ),
      child: label,
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
