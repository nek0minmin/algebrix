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
    final accent = widget.accentColor;
    final expr = widget.expression.trim();

    // Check expression mode
    final isComparison = expr.contains(' • ') || expr.contains('   •   ');
    final isStepFlow = expr.contains(' → ') || expr.contains('  →  ');

    String badgeLabel = 'EXPRESSION';
    IconData badgeIcon = Icons.functions_rounded;

    if (isComparison) {
      badgeLabel = 'COMPARISON';
      badgeIcon = Icons.compare_arrows_rounded;
    } else if (isStepFlow) {
      badgeLabel = 'STEP-BY-STEP';
      badgeIcon = Icons.timeline_rounded;
    } else if (expr.contains('=')) {
      badgeLabel = 'EQUATION';
      badgeIcon = Icons.drag_handle_rounded;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header Strip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 14, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          badgeLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: accent,
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

            // Main Math Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: isComparison
                  ? _buildComparisonContent(context, expr, accent)
                  : isStepFlow
                      ? _buildStepFlowContent(context, expr, accent)
                      : _buildHeroFormulaContent(context, expr, accent),
            ),

            // Integrated Annotation Footer
            if (widget.annotation != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(19),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: accent.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.annotation!,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
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
    Color accent,
  ) {
    final parts = expr.split(RegExp(r'\s*•\s*'));
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: isNarrow ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.extraLightPink.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: _buildTokenizedMath(
                  parts[i].trim(),
                  fontSize: 18,
                  accent: accent,
                ),
              ),
              if (i < parts.length - 1)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStepFlowContent(
    BuildContext context,
    String expr,
    Color accent,
  ) {
    final steps = expr.split(RegExp(r'\s*→\s*'));
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: i == steps.length - 1
                      ? AppColors.lightMint
                      : AppColors.extraLightPink.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i == steps.length - 1
                        ? AppColors.mint.withValues(alpha: 0.6)
                        : accent.withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                ),
                child: _buildTokenizedMath(
                  steps[i].trim(),
                  fontSize: isNarrow ? 16 : 18,
                  accent: accent,
                ),
              ),
              if (i < steps.length - 1)
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: accent.withValues(alpha: 0.7),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeroFormulaContent(
    BuildContext context,
    String expr,
    Color accent,
  ) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: _buildTokenizedMath(
            expr,
            fontSize: 24,
            accent: accent,
          ),
        ),
      ),
    );
  }

  Widget _buildTokenizedMath(
    String text, {
    required double fontSize,
    required Color accent,
  }) {
    final spans = <InlineSpan>[];
    // Regular expression to match variables (x, y, a, b, n), operators (+, −, -, ×, ÷, =, ≠), exponents (², ³, etc.)
    final regex = RegExp(
      r'([a-zA-Z][²³⁴]?|[0-9]+|[+\−\-\×\*\/\=\≠\(\)\,\:\?]|\band\b|\bwhen\b|\bIf\b|\bthen\b|\bvs\b|\s+)',
    );

    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
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
              fontWeight: FontWeight.w700,
              color: AppColors.text,
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
              fontSize: fontSize * 0.78,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else if (RegExp(r'^[xyzabcnXYZABCN][²³⁴]?$').hasMatch(token)) {
        // Variable token (vivid pink / brand accent)
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: AppColors.pink,
            ),
          ),
        );
      } else if (RegExp(r'^[+\−\-\×\*\/\=\≠]$').hasMatch(token)) {
        // Operator token
        spans.add(
          TextSpan(
            text: ' $token ',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.purple,
            ),
          ),
        );
      } else {
        // Numbers and brackets
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
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
            fontWeight: FontWeight.w700,
            color: AppColors.text,
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
