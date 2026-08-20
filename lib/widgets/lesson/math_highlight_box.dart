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

class _MathHighlightBoxState extends State<MathHighlightBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
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
    final expr = widget.expression.trim();

    // Check expression mode
    final isComparison = expr.contains(' • ') || expr.contains('   •   ');
    final isStepFlow = expr.contains(' → ') || expr.contains('  →  ');

    String badgeLabel = 'EXPRESSION';
    IconData badgeIcon = Icons.functions_rounded;
    Color badgeColor = AppColors.pink;
    Color badgeBg = AppColors.extraLightPink;

    if (isComparison) {
      badgeLabel = 'COMPARISON';
      badgeIcon = Icons.compare_arrows_rounded;
      badgeColor = AppColors.pink;
      badgeBg = AppColors.extraLightPink;
    } else if (isStepFlow) {
      badgeLabel = 'STEP-BY-STEP';
      badgeIcon = Icons.timeline_rounded;
      badgeColor = AppColors.pink;
      badgeBg = AppColors.extraLightPink;
    } else if (expr.contains('=')) {
      badgeLabel = 'EQUATION';
      badgeIcon = Icons.drag_handle_rounded;
      badgeColor = AppColors.pink;
      badgeBg = AppColors.extraLightPink;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 14, color: badgeColor),
                        const SizedBox(width: 6),
                        Text(
                          badgeLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Math Content Area (All soft gray, clean, no inner pink boxes)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: isComparison
                  ? _buildComparisonContent(context, expr)
                  : isStepFlow
                      ? _buildStepFlowContent(context, expr)
                      : _buildHeroFormulaContent(context, expr),
            ),

            // Vibrant Pink Footer for Tips with Crisp White Text
            if (widget.annotation != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(19),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lightbulb_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.annotation!,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonContent(
    BuildContext context,
    String expr,
  ) {
    final parts = expr.split(RegExp(r'\s*•\s*'));
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              _buildTokenizedMath(
                parts[i].trim(),
                fontSize: 22,
              ),
              if (i < parts.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.subtitle,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepFlowContent(
    BuildContext context,
    String expr,
  ) {
    final steps = expr.split(RegExp(r'\s*→\s*'));
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              _buildTokenizedMath(
                steps[i].trim(),
                fontSize: 22,
              ),
              if (i < steps.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.subtitle,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroFormulaContent(
    BuildContext context,
    String expr,
  ) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: _buildTokenizedMath(
            expr,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTokenizedMath(
    String text, {
    required double fontSize,
  }) {
    final spans = <InlineSpan>[];

    // Accurate tokenizer: match keywords, symbols, variables & numbers
    final regex = RegExp(
      r'(\band\b|\bwhen\b|\bIf\b|\bthen\b|\bvs\b|[a-zA-Z][²³⁴]?|[0-9]+|[+\−\-\×\*\/\=\≠\(\)\,\:\?]|\s+)',
      caseSensitive: false,
    );

    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      );
    }

    var lastEnd = 0;
    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, m.start),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }

      final token = m.group(0)!;
      final lower = token.toLowerCase();

      if (lower == 'and' ||
          lower == 'when' ||
          lower == 'if' ||
          lower == 'then' ||
          lower == 'vs') {
        spans.add(
          TextSpan(
            text: ' $token ',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize * 0.85,
              fontWeight: FontWeight.w600,
              color: AppColors.subtitle,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else {
        // Everything in uniform soft dark gray
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        );
      }

      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }
}
