import 'dart:math' as math;
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/balance_scale_provider.dart';
import 'package:algebrix/services/math_api_service.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Data class representing a draggable scale operation.
class ScaleOp {
  const ScaleOp({
    required this.op,
    required this.value,
    required this.label,
    required this.color,
    required this.lightColor,
    required this.icon,
  });

  final String op;
  final num value;
  final String label;
  final Color color;
  final Color lightColor;
  final IconData icon;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _colorForOp(String op) {
  switch (op) {
    case '-':
      return AppColors.pink;
    case '+':
      return AppColors.mint;
    case '/':
      return AppColors.purple;
    case '*':
      return AppColors.yellow;
    default:
      return AppColors.pink;
  }
}

Color _lightColorForOp(String op) {
  switch (op) {
    case '-':
      return AppColors.extraLightPink;
    case '+':
      return AppColors.lightMint;
    case '/':
      return AppColors.lightPurple;
    case '*':
      return AppColors.lightYellow;
    default:
      return AppColors.extraLightPink;
  }
}

IconData _iconForOp(String op) {
  switch (op) {
    case '-':
      return Icons.remove_rounded;
    case '+':
      return Icons.add_rounded;
    case '/':
      return Icons.percent_rounded;
    case '*':
      return Icons.close_rounded;
    default:
      return Icons.calculate_rounded;
  }
}

String _labelForOp(String op, num value) {
  final valStr = value.toString().replaceAll('.0', '');
  switch (op) {
    case '-':
      return '− $valStr';
    case '+':
      return '+ $valStr';
    case '/':
      return '÷ $valStr';
    case '*':
      return '× $valStr';
    default:
      return '$op $valStr';
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class BalanceScaleScreen extends StatelessWidget {
  const BalanceScaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BalanceScaleProvider>();
    final problem = provider.currentProblem;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SecondaryPageAppBar(
        title: 'Balance Scale',
        supportingText: 'Isolate x by dragging operations onto the scale.',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // API Status Badge
              _ApiStatusBadge(providerUsed: provider.providerUsed),
              const SizedBox(height: 14),

              // Equation Goal Banner
              if (problem != null) ...[
                _EquationBanner(
                  problem: problem,
                  moveCount: provider.moveCount,
                  optimalMoves: provider.optimalMoves,
                  onReset: provider.resetCurrentProblem,
                ),
                const SizedBox(height: 16),
              ],

              // Drag Instructions
              _DragInstructionsBanner(),
              const SizedBox(height: 16),

              // Animated Tilting Scale with Drag Targets
              _AnimatedBalanceScale(
                leftExpr: provider.leftExpr,
                rightExpr: provider.rightExpr,
                isSolved: provider.isSolved,
                isLoading: provider.isLoading,
                onApply: (op, val, targetSide) =>
                    provider.applyOperation(op, val, targetSide: targetSide),
              ),
              const SizedBox(height: 24),

              // Colored Number Block Chips
              _NumberBlockPalette(
                isLoading: provider.isLoading,
                isSolved: provider.isSolved,
                dynamicOps: provider.dynamicOps,
                onApply: (op, val, targetSide) =>
                    provider.applyOperation(op, val, targetSide: targetSide),
              ),
              const SizedBox(height: 20),

              // Step History
              if (provider.history.isNotEmpty) ...[
                Text(
                  'Steps (${provider.moveCount} move${provider.moveCount == 1 ? '' : 's'})',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...provider.history.asMap().entries.map(
                  (entry) => _StepHistoryCard(
                    index: entry.key + 1,
                    step: entry.value,
                  ),
                ),
              ],

              // Reasoning Check (appears after solving)
              if (provider.showReasoningCheck && problem != null) ...[
                const SizedBox(height: 24),
                _ReasoningCheckCard(problem: problem),
              ],

              // Celebration (appears after reasoning passed or skipped)
              if (provider.isSolved && !provider.showReasoningCheck) ...[
                const SizedBox(height: 24),
                _CelebrationCard(
                  xp: provider.xpEarned,
                  starRating: provider.starRating,
                  moveCount: provider.moveCount,
                  optimalMoves: provider.optimalMoves,
                  reasoningPassed: provider.reasoningPassed,
                  onNext: provider.initNewProblem,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── API Status Badge ────────────────────────────────────────────────────────

class _ApiStatusBadge extends StatelessWidget {
  const _ApiStatusBadge({required this.providerUsed});

  final String providerUsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.extraLightPink,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.pink.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Powered by $providerUsed',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.pink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Equation Banner ─────────────────────────────────────────────────────────

class _EquationBanner extends StatelessWidget {
  const _EquationBanner({
    required this.problem,
    required this.moveCount,
    required this.optimalMoves,
    required this.onReset,
  });

  final BalanceScaleProblem problem;
  final int moveCount;
  final int optimalMoves;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.pink.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.xyDefault,
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Solve for x',
                        style: AppTextStyles.subtitle2.copyWith(
                          color: AppColors.pink,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Moves Counter Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: moveCount <= optimalMoves
                            ? AppColors.lightMint
                            : (moveCount <= optimalMoves + 2
                                ? AppColors.lightYellow
                                : AppColors.extraLightPink),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$moveCount/$optimalMoves moves',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: moveCount <= optimalMoves
                              ? AppColors.mint
                              : (moveCount <= optimalMoves + 2
                                  ? const Color(0xFFD4A017)
                                  : AppColors.pink),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  problem.equation,
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.pink),
            tooltip: 'Reset Problem',
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

// ─── Drag Instructions ───────────────────────────────────────────────────────

class _DragInstructionsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightPurple,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_rounded, color: AppColors.purple, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Drag a number block onto the Center (both sides) or a single Pan. Tap to apply to both sides!',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Balance Scale ─────────────────────────────────────────────────

class _AnimatedBalanceScale extends StatefulWidget {
  const _AnimatedBalanceScale({
    required this.leftExpr,
    required this.rightExpr,
    required this.isSolved,
    required this.isLoading,
    required this.onApply,
  });

  final String leftExpr;
  final String rightExpr;
  final bool isSolved;
  final bool isLoading;
  final Function(String op, num val, String targetSide) onApply;

  @override
  State<_AnimatedBalanceScale> createState() => _AnimatedBalanceScaleState();
}

class _AnimatedBalanceScaleState extends State<_AnimatedBalanceScale>
    with TickerProviderStateMixin {
  late AnimationController _tiltController;
  late AnimationController _wobbleController;
  late Animation<double> _tiltAnimation;
  late Animation<double> _wobbleAnimation;
  double _targetTilt = 0.0;

  @override
  void initState() {
    super.initState();
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tiltAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeOutBack),
    );
    _wobbleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.elasticOut),
    );
    _updateTilt();
  }

  @override
  void didUpdateWidget(covariant _AnimatedBalanceScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leftExpr != widget.leftExpr ||
        oldWidget.rightExpr != widget.rightExpr) {
      _updateTilt();
      // Trigger wobble when expressions change
      _wobbleController.forward(from: 0);
    }
  }

  void _updateTilt() {
    final leftWeight = _estimateWeight(widget.leftExpr);
    final rightWeight = _estimateWeight(widget.rightExpr);
    final diff = rightWeight - leftWeight;
    final maxDelta = 30.0;
    final oldTilt = _targetTilt;
    _targetTilt = (diff / maxDelta).clamp(-1.0, 1.0) * 0.12; // ~7° max

    if (widget.isSolved) _targetTilt = 0.0;

    _tiltAnimation = Tween<double>(begin: oldTilt, end: _targetTilt).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeOutBack),
    );
    _tiltController.forward(from: 0);
  }

  double _estimateWeight(String expr) {
    // Try parsing as pure number first
    final numVal = double.tryParse(expr.trim());
    if (numVal != null) return numVal;

    // Extract numeric parts from expressions like "2x + 6"
    double weight = 0;
    final matches = RegExp(r'[\d]+\.?[\d]*').allMatches(expr);
    for (final m in matches) {
      weight += double.tryParse(m.group(0) ?? '0') ?? 0;
    }
    return weight;
  }

  @override
  void dispose() {
    _tiltController.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_tiltAnimation, _wobbleAnimation]),
      builder: (context, child) {
        final wobbleOffset = _wobbleController.isAnimating
            ? math.sin(_wobbleAnimation.value * math.pi * 3) * 3 *
                (1 - _wobbleAnimation.value)
            : 0.0;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.isSolved ? AppColors.mint : AppColors.border,
              width: widget.isSolved ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSolved
                    ? AppColors.mint.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Center Fulcrum Drop Target (BOTH sides)
              DragTarget<ScaleOp>(
                onWillAcceptWithDetails: (d) =>
                    !widget.isLoading && !widget.isSolved,
                onAcceptWithDetails: (d) {
                  widget.onApply(d.data.op, d.data.value, 'both');
                },
                builder: (ctx, candidateData, rejectedData) {
                  final isHovered = candidateData.isNotEmpty;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? AppColors.lightMint
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isHovered
                            ? AppColors.mint
                            : AppColors.border.withValues(alpha: 0.6),
                        width: isHovered ? 2.5 : 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isHovered
                              ? Icons.check_circle_rounded
                              : Icons.center_focus_strong_rounded,
                          color: isHovered
                              ? AppColors.mint
                              : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isHovered
                                ? 'Release to apply to BOTH sides! 🎯'
                                : '🎯 Drop here → Apply to BOTH sides',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: isHovered
                                  ? AppColors.mint
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Tilting Beam + Pans
              Transform.translate(
                offset: Offset(0, wobbleOffset),
                child: Transform.rotate(
                  angle: _tiltAnimation.value,
                  alignment: Alignment.center,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Pan Drop Target
                      Expanded(
                        child: DragTarget<ScaleOp>(
                          onWillAcceptWithDetails: (d) =>
                              !widget.isLoading && !widget.isSolved,
                          onAcceptWithDetails: (d) {
                            widget.onApply(
                                d.data.op, d.data.value, 'left');
                          },
                          builder: (ctx, candidateData, rejectedData) {
                            final isHovered = candidateData.isNotEmpty;
                            return _ScalePan(
                              expression: widget.leftExpr,
                              isLeft: true,
                              isSolved: widget.isSolved,
                              isHovered: isHovered,
                            );
                          },
                        ),
                      ),

                      // Fulcrum + Beam connector
                      Column(
                        children: [
                          const SizedBox(height: 6),
                          // Beam
                          Container(
                            width: 40,
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.isSolved
                                    ? [AppColors.mint, AppColors.mint]
                                    : [AppColors.text, AppColors.text],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          // Fulcrum triangle
                          CustomPaint(
                            size: const Size(36, 32),
                            painter: _FulcrumPainter(
                              color: widget.isSolved
                                  ? AppColors.mint
                                  : AppColors.pink,
                            ),
                          ),
                          Container(
                            height: 8,
                            width: 50,
                            decoration: BoxDecoration(
                              color: AppColors.text,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),

                      // Right Pan Drop Target
                      Expanded(
                        child: DragTarget<ScaleOp>(
                          onWillAcceptWithDetails: (d) =>
                              !widget.isLoading && !widget.isSolved,
                          onAcceptWithDetails: (d) {
                            widget.onApply(
                                d.data.op, d.data.value, 'right');
                          },
                          builder: (ctx, candidateData, rejectedData) {
                            final isHovered = candidateData.isNotEmpty;
                            return _ScalePan(
                              expression: widget.rightExpr,
                              isLeft: false,
                              isSolved: widget.isSolved,
                              isHovered: isHovered,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Scale Pan ──────────────────────────────────────────────────────────────

class _ScalePan extends StatelessWidget {
  const _ScalePan({
    required this.expression,
    required this.isLeft,
    required this.isSolved,
    required this.isHovered,
  });

  final String expression;
  final bool isLeft;
  final bool isSolved;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: isHovered
            ? _lightColorForOp('-')
            : (isSolved ? AppColors.lightMint : AppColors.background),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHovered
              ? AppColors.pink
              : (isSolved ? AppColors.mint : AppColors.border),
          width: isHovered ? 2.5 : 1.5,
        ),
        boxShadow: isHovered
            ? [
                BoxShadow(
                  color: AppColors.pink.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isHovered
                ? (isLeft ? '↓ LEFT ONLY' : '↓ RIGHT ONLY')
                : (isLeft ? 'LEFT' : 'RIGHT'),
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isHovered ? AppColors.pink : AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              expression.isEmpty ? '?' : expression,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isSolved
                    ? AppColors.mint
                    : (isHovered ? AppColors.pink : AppColors.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fulcrum Painter ─────────────────────────────────────────────────────────

class _FulcrumPainter extends CustomPainter {
  _FulcrumPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FulcrumPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─── Number Block Palette ────────────────────────────────────────────────────

class _NumberBlockPalette extends StatelessWidget {
  const _NumberBlockPalette({
    required this.isLoading,
    required this.isSolved,
    required this.dynamicOps,
    required this.onApply,
  });

  final bool isLoading;
  final bool isSolved;
  final List<Map<String, dynamic>> dynamicOps;
  final Function(String op, num val, String targetSide) onApply;

  @override
  Widget build(BuildContext context) {
    // Build ScaleOp list from dynamic ops
    final chips = dynamicOps.map((m) {
      final op = m['op'] as String;
      final value = m['value'] as num;
      return ScaleOp(
        op: op,
        value: value,
        label: _labelForOp(op, value),
        color: _colorForOp(op),
        lightColor: _lightColorForOp(op),
        icon: _iconForOp(op),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Number Blocks',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.lightPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Drag or Tap',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.purple,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.pink),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: chips
                .map(
                  (scaleOp) => _DraggableNumberBlock(
                    scaleOp: scaleOp,
                    isSolved: isSolved,
                    onTap: () => onApply(scaleOp.op, scaleOp.value, 'both'),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

// ─── Draggable Number Block ──────────────────────────────────────────────────

class _DraggableNumberBlock extends StatefulWidget {
  const _DraggableNumberBlock({
    required this.scaleOp,
    required this.isSolved,
    required this.onTap,
  });

  final ScaleOp scaleOp;
  final bool isSolved;
  final VoidCallback onTap;

  @override
  State<_DraggableNumberBlock> createState() => _DraggableNumberBlockState();
}

class _DraggableNumberBlockState extends State<_DraggableNumberBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _bobController;
  late Animation<double> _bobAnimation;

  @override
  void initState() {
    super.initState();
    // Subtle idle bobbing animation — each block has a different phase
    _bobController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800 + (widget.scaleOp.value.toInt() * 100) % 600),
    );

    _bobAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (TickerMode.of(context) && !isTesting) {
      if (!_bobController.isAnimating) {
        _bobController.repeat(reverse: true);
      }
    } else {
      _bobController.stop();
    }
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSolved) {
      return Opacity(
        opacity: 0.4,
        child: _NumberBlockWidget(scaleOp: widget.scaleOp, isDragging: false),
      );
    }

    return AnimatedBuilder(
      animation: _bobAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bobAnimation.value),
          child: Draggable<ScaleOp>(
            data: widget.scaleOp,
            feedback: Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: 1.15,
                child: _NumberBlockWidget(
                    scaleOp: widget.scaleOp, isDragging: true),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _NumberBlockWidget(
                  scaleOp: widget.scaleOp, isDragging: false),
            ),
            child: GestureDetector(
              onTap: widget.onTap,
              child: child,
            ),
          ),
        );
      },
      child: _NumberBlockWidget(scaleOp: widget.scaleOp, isDragging: false),
    );
  }
}

// ─── Number Block Widget ─────────────────────────────────────────────────────

class _NumberBlockWidget extends StatelessWidget {
  const _NumberBlockWidget({
    required this.scaleOp,
    required this.isDragging,
  });

  final ScaleOp scaleOp;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 72,
      decoration: BoxDecoration(
        color: isDragging ? scaleOp.lightColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDragging ? scaleOp.color : scaleOp.color.withValues(alpha: 0.4),
          width: isDragging ? 2.5 : 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDragging
                ? scaleOp.color.withValues(alpha: 0.35)
                : scaleOp.color.withValues(alpha: 0.08),
            blurRadius: isDragging ? 16 : 6,
            offset: Offset(0, isDragging ? 8 : 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Operation icon
          Icon(
            scaleOp.icon,
            size: 16,
            color: scaleOp.color,
          ),
          const SizedBox(height: 2),
          // Value
          Text(
            scaleOp.value.toString().replaceAll('.0', ''),
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          // Drag dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(scaleOp.color),
              const SizedBox(width: 3),
              _dot(scaleOp.color),
              const SizedBox(width: 3),
              _dot(scaleOp.color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── Step History Card ───────────────────────────────────────────────────────

class _StepHistoryCard extends StatelessWidget {
  const _StepHistoryCard({
    required this.index,
    required this.step,
  });

  final int index;
  final BalanceScaleStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Step number circle
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.extraLightPink,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.pink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Operation badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _lightColorForOp(step.operationText.substring(0, 1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              step.operationText,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _colorForOp(step.operationText.substring(0, 1)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${step.leftAfter} = ${step.rightAfter}',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            step.providerUsed.contains('MathJS') ? 'POST' : 'Local',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reasoning Check Card ────────────────────────────────────────────────────

class _ReasoningCheckCard extends StatefulWidget {
  const _ReasoningCheckCard({required this.problem});

  final BalanceScaleProblem problem;

  @override
  State<_ReasoningCheckCard> createState() => _ReasoningCheckCardState();
}

class _ReasoningCheckCardState extends State<_ReasoningCheckCard>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  bool _showError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onOptionTap(int index) {
    final provider = context.read<BalanceScaleProvider>();
    setState(() {
      _selectedIndex = index;
      _showError = false;
    });

    final isCorrect = provider.submitReasoningAnswer(index);
    if (!isCorrect) {
      setState(() => _showError = true);
      _shakeController.forward(from: 0);
      showAlgebrixSnackBar(
        context,
        message: 'Not quite! Think about what keeps the equation balanced. 🤔',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = _shakeController.isAnimating
            ? math.sin(_shakeAnimation.value * math.pi * 4) * 6 *
                (1 - _shakeAnimation.value)
            : 0.0;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Xy mascot + question header
            Row(
              children: [
                Image.asset(
                  AppAssets.xyExplaining,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reasoning Check 🧠',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'WHY does this solution work?',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Options
            ...widget.problem.reasoningOptions.asMap().entries.map((entry) {
              final idx = entry.key;
              final text = entry.value;
              final isSelected = _selectedIndex == idx;
              final isWrong = isSelected && _showError;

              return GestureDetector(
                onTap: () => _onOptionTap(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isWrong
                        ? AppColors.error.withValues(alpha: 0.06)
                        : (isSelected
                            ? AppColors.lightPurple
                            : AppColors.background),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isWrong
                          ? AppColors.error
                          : (isSelected ? AppColors.purple : AppColors.border),
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isWrong
                              ? AppColors.error.withValues(alpha: 0.1)
                              : (isSelected
                                  ? AppColors.purple.withValues(alpha: 0.15)
                                  : AppColors.border.withValues(alpha: 0.5)),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          String.fromCharCode(65 + idx),
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isWrong
                                ? AppColors.error
                                : (isSelected
                                    ? AppColors.purple
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (isWrong)
                        const Icon(Icons.close_rounded,
                            color: AppColors.error, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Celebration Card ────────────────────────────────────────────────────────

class _CelebrationCard extends StatefulWidget {
  const _CelebrationCard({
    required this.xp,
    required this.starRating,
    required this.moveCount,
    required this.optimalMoves,
    required this.reasoningPassed,
    required this.onNext,
  });

  final int xp;
  final int starRating;
  final int moveCount;
  final int optimalMoves;
  final bool reasoningPassed;
  final VoidCallback onNext;

  @override
  State<_CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<_CelebrationCard>
    with TickerProviderStateMixin {
  late List<AnimationController> _starControllers;
  late List<Animation<double>> _starAnimations;

  @override
  void initState() {
    super.initState();
    _starControllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _starAnimations = _starControllers.map((c) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: Curves.elasticOut),
      );
    }).toList();

    // Stagger star animations
    for (int i = 0; i < widget.starRating; i++) {
      Future.delayed(Duration(milliseconds: 200 + (i * 200)), () {
        if (mounted) _starControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _starControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final starLabels = ['Completed!', 'Great Job!', 'Great Job!', 'Perfect! ⭐'];
    final label = starLabels[widget.starRating.clamp(0, 3)];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.extraLightPink,
            AppColors.lightPurple.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.pink, width: 2),
      ),
      child: Column(
        children: [
          // Xy mascot
          Image.asset(
            AppAssets.xyHappy,
            width: 64,
            height: 64,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),

          // Stars row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final earned = i < widget.starRating;
              return AnimatedBuilder(
                animation: _starAnimations[i],
                builder: (ctx, child) {
                  return Transform.scale(
                    scale: earned ? _starAnimations[i].value : 0.6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        earned ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                        color: earned
                            ? AppColors.yellow
                            : AppColors.border,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 8),

          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.pink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Solved in ${widget.moveCount} move${widget.moveCount == 1 ? '' : 's'} (${widget.optimalMoves} optimal)',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+${widget.xp} XP',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.mint,
                ),
              ),
              if (widget.reasoningPassed) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🧠 Reasoning ✓',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.mint,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Next Equation →',
            onPressed: widget.onNext,
          ),
        ],
      ),
    );
  }
}
