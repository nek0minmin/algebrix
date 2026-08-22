import 'dart:math' as math;
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/balance_scale_provider.dart';
import 'package:algebrix/services/math_api_service.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/xy_mascot.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
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

class BalanceScaleScreen extends StatefulWidget {
  const BalanceScaleScreen({super.key});

  @override
  State<BalanceScaleScreen> createState() => _BalanceScaleScreenState();
}

class _BalanceScaleScreenState extends State<BalanceScaleScreen> {
  String? _lastPresentedProblemId;
  bool _dialogOpen = false;

  void _checkAndShowModal(BalanceScaleProvider provider) {
    final problem = provider.currentProblem;
    if (problem == null) return;

    if (provider.isSolved &&
        _lastPresentedProblemId != problem.id &&
        !_dialogOpen) {
      _lastPresentedProblemId = problem.id;
      _dialogOpen = true;

      // Small satisfying delay for the physical scale to level out
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => ChangeNotifierProvider.value(
            value: provider,
            child: _ReasoningAndCelebrationDialog(
              problem: problem,
              onDismissAndNext: () {
                _dialogOpen = false;
                Navigator.of(dialogCtx).pop();
                provider.initNewProblem();
              },
            ),
          ),
        ).then((_) {
          _dialogOpen = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BalanceScaleProvider>();
    final problem = provider.currentProblem;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowModal(provider);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const SecondaryPageAppBar(
        title: 'Balance Scale',
        supportingText: 'Isolate x by dragging operations onto the scale.',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Xy Companion & Target Equation Header
              if (problem != null) ...[
                _EquationAndMascotHeader(
                  problem: problem,
                  moveCount: provider.moveCount,
                  optimalMoves: provider.optimalMoves,
                  isSolved: provider.isSolved,
                  onReset: () {
                    _lastPresentedProblemId = null;
                    provider.resetCurrentProblem();
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Drag & Tap Instructions Banner
              _DragInstructionsBanner(),
              const SizedBox(height: 18),

              // Authentic Physical Tilting Scale with Pans & Center Drop
              _AnimatedBalanceScale(
                leftExpr: provider.leftExpr,
                rightExpr: provider.rightExpr,
                isSolved: provider.isSolved,
                isLoading: provider.isLoading,
                onApply: (op, val, targetSide) =>
                    provider.applyOperation(op, val, targetSide: targetSide),
              ),
              const SizedBox(height: 24),

              // Tactile Colored Number Block Chips (Consistently 8 tiles in 2x4 Grid)
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

              // Fallback action button if solved and dialog was closed
              if (provider.isSolved && !_dialogOpen) ...[
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Next Equation →',
                  onPressed: () {
                    _lastPresentedProblemId = null;
                    provider.initNewProblem();
                  },
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Equation & Xy Mascot Header ────────────────────────────────────────────

class _EquationAndMascotHeader extends StatelessWidget {
  const _EquationAndMascotHeader({
    required this.problem,
    required this.moveCount,
    required this.optimalMoves,
    required this.isSolved,
    required this.onReset,
  });

  final BalanceScaleProblem problem;
  final int moveCount;
  final int optimalMoves;
  final bool isSolved;
  final VoidCallback onReset;

  String _resolveMascotAsset() {
    if (isSolved) return AppAssets.xyHappy;
    if (moveCount > optimalMoves + 1) return AppAssets.xyExplaining;
    return AppAssets.xyPractice;
  }

  String _resolveSpeechPrompt() {
    if (isSolved) return 'Awesome! You balanced and isolated x! 🎉';
    if (moveCount == 0) return 'Keep both sides balanced! Isolate x step-by-step.';
    if (moveCount <= optimalMoves) return 'Great move! What operation will isolate x next?';
    return 'Tip: Try eliminating the constant term first!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isSolved
              ? AppColors.mint
              : AppColors.pink.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSolved ? AppColors.mint : AppColors.pink)
                .withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Prominent Xy Mascot
              XyMascot(
                asset: _resolveMascotAsset(),
                size: 88,
                shadowBlur: 5.0,
                shadowOpacity: 0.2,
              ),
              const SizedBox(width: 14),

              // Target Equation Details & Top Actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: "Solve for x" Badge (Left) + Retry Button (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.extraLightPink,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Solve for x',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkPink,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        // Reset/Retry Button on Top Right
                        BouncyPressable(
                          shrinkFactor: 0.88,
                          enableHaptics: true,
                          onTap: onReset,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.extraLightPink,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.pink.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: AppColors.pink,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Equation + Moves Counter Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            problem.equation,
                            style: GoogleFonts.nunito(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Moves Counter Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: moveCount <= optimalMoves
                                ? AppColors.lightMint
                                : (moveCount <= optimalMoves + 2
                                    ? AppColors.lightYellow
                                    : AppColors.extraLightPink),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$moveCount/$optimalMoves moves',
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: moveCount <= optimalMoves
                                  ? AppColors.mint
                                  : (moveCount <= optimalMoves + 2
                                      ? const Color(0xFFB8860B)
                                      : AppColors.pink),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Companion Guide Dialogue
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppColors.pink,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _resolveSpeechPrompt(),
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightPurple,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.touch_app_rounded,
            color: AppColors.purple,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Drag a number block onto the Center (both sides) or a single Pan. Tap any block to apply to both sides!',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                height: 1.35,
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
      _wobbleController.forward(from: 0);
    }
  }

  void _updateTilt() {
    final leftWeight = _estimateWeight(widget.leftExpr);
    final rightWeight = _estimateWeight(widget.rightExpr);
    final diff = rightWeight - leftWeight;
    const maxDelta = 30.0;
    final oldTilt = _targetTilt;
    _targetTilt = (diff / maxDelta).clamp(-1.0, 1.0) * 0.12; // ~7° max

    if (widget.isSolved) _targetTilt = 0.0;

    _tiltAnimation = Tween<double>(begin: oldTilt, end: _targetTilt).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeOutBack),
    );
    _tiltController.forward(from: 0);
  }

  double _estimateWeight(String expr) {
    final numVal = double.tryParse(expr.trim());
    if (numVal != null) return numVal;

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
            ? math.sin(_wobbleAnimation.value * math.pi * 3) *
                3 *
                (1 - _wobbleAnimation.value)
            : 0.0;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.isSolved
                  ? AppColors.mint
                  : AppColors.border.withValues(alpha: 0.9),
              width: widget.isSolved ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSolved
                    ? AppColors.mint.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Center Drop Target (Apply to BOTH Sides)
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? AppColors.lightMint
                          : (widget.isSolved
                              ? AppColors.lightMint.withValues(alpha: 0.5)
                              : AppColors.background),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isHovered
                            ? AppColors.mint
                            : (widget.isSolved
                                ? AppColors.mint
                                : AppColors.border),
                        width: isHovered ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        if (isHovered)
                          BoxShadow(
                            color: AppColors.mint.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isHovered
                              ? Icons.check_circle_rounded
                              : (widget.isSolved
                                  ? Icons.verified_rounded
                                  : Icons.balance_rounded),
                          color: isHovered || widget.isSolved
                              ? AppColors.mint
                              : AppColors.pink,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isHovered
                                ? 'Release to apply to BOTH sides! 🎯'
                                : (widget.isSolved
                                    ? '⚖️ EQUATION BALANCED & SOLVED!'
                                    : '🎯 Drop here → Apply to BOTH sides'),
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: isHovered || widget.isSolved
                                  ? const Color(0xFF0F7263)
                                  : AppColors.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 2. Physical Balance Scale Mechanism (Fulcrum + Beam + Suspension + Pans)
              Transform.translate(
                offset: Offset(0, wobbleOffset),
                child: _PhysicalScaleStructure(
                  tiltAngle: _tiltAnimation.value,
                  leftExpr: widget.leftExpr,
                  rightExpr: widget.rightExpr,
                  isSolved: widget.isSolved,
                  isLoading: widget.isLoading,
                  onApply: widget.onApply,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Physical Scale Structure with Beam, Pivot, Chains & Pans ───────────────

class _PhysicalScaleStructure extends StatelessWidget {
  const _PhysicalScaleStructure({
    required this.tiltAngle,
    required this.leftExpr,
    required this.rightExpr,
    required this.isSolved,
    required this.isLoading,
    required this.onApply,
  });

  final double tiltAngle;
  final String leftExpr;
  final String rightExpr;
  final bool isSolved;
  final bool isLoading;
  final Function(String op, num val, String targetSide) onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Transform.rotate(
          angle: tiltAngle,
          alignment: Alignment.center,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Weighing Pan
              Expanded(
                child: DragTarget<ScaleOp>(
                  onWillAcceptWithDetails: (d) => !isLoading && !isSolved,
                  onAcceptWithDetails: (d) {
                    onApply(d.data.op, d.data.value, 'left');
                  },
                  builder: (ctx, candidateData, rejectedData) {
                    final isHovered = candidateData.isNotEmpty;
                    return _ScalePanDish(
                      expression: leftExpr,
                      isLeft: true,
                      isSolved: isSolved,
                      isHovered: isHovered,
                    );
                  },
                ),
              ),

              // Central Fulcrum & Level Needle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            isSolved ? AppColors.mint : AppColors.pink,
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSolved ? AppColors.mint : AppColors.darkPink,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    CustomPaint(
                      size: const Size(44, 38),
                      painter: _FulcrumPainter(
                        color: isSolved ? AppColors.mint : AppColors.pink,
                      ),
                    ),
                    Container(
                      height: 10,
                      width: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3E50),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right Weighing Pan
              Expanded(
                child: DragTarget<ScaleOp>(
                  onWillAcceptWithDetails: (d) => !isLoading && !isSolved,
                  onAcceptWithDetails: (d) {
                    onApply(d.data.op, d.data.value, 'right');
                  },
                  builder: (ctx, candidateData, rejectedData) {
                    final isHovered = candidateData.isNotEmpty;
                    return _ScalePanDish(
                      expression: rightExpr,
                      isLeft: false,
                      isSolved: isSolved,
                      isHovered: isHovered,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Scale Pan Dish (Physical Bowl/Tray) ─────────────────────────────────────

class _ScalePanDish extends StatelessWidget {
  const _ScalePanDish({
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
    final themeColor = isSolved
        ? AppColors.mint
        : (isHovered ? AppColors.pink : AppColors.text);

    return Column(
      children: [
        CustomPaint(
          size: const Size(80, 24),
          painter: _SuspensionChainsPainter(
            color: isSolved
                ? AppColors.mint
                : (isHovered ? AppColors.pink : const Color(0xFF9E9E9E)),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: isHovered
                ? AppColors.extraLightPink
                : (isSolved
                    ? AppColors.lightMint.withValues(alpha: 0.7)
                    : Colors.white),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: Radius.circular(28),
            ),
            border: Border.all(
              color: isHovered
                  ? AppColors.pink
                  : (isSolved ? AppColors.mint : AppColors.border),
              width: isHovered ? 2.5 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? AppColors.pink.withValues(alpha: 0.22)
                    : (isSolved
                        ? AppColors.mint.withValues(alpha: 0.16)
                        : Colors.black.withValues(alpha: 0.05)),
                blurRadius: isHovered ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isHovered
                      ? AppColors.pink
                      : (isSolved
                          ? AppColors.mint
                          : AppColors.background),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isHovered
                      ? (isLeft ? '↓ DROP ON LEFT' : '↓ DROP ON RIGHT')
                      : (isLeft ? 'LEFT PAN' : 'RIGHT PAN'),
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: isHovered || isSolved
                        ? Colors.white
                        : AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSolved
                      ? Colors.white
                      : (isHovered
                          ? Colors.white
                          : AppColors.background),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeColor.withValues(alpha: 0.25),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    expression.isEmpty ? '?' : expression,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isSolved
                          ? const Color(0xFF0F7263)
                          : (isHovered ? AppColors.darkPink : AppColors.text),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Suspension Chains Painter ───────────────────────────────────────────────

class _SuspensionChainsPainter extends CustomPainter {
  final Color color;

  _SuspensionChainsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;

    canvas.drawLine(
      Offset(centerX, 0),
      Offset(size.width * 0.15, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(centerX, 0),
      Offset(size.width * 0.85, size.height),
      paint,
    );

    final hookPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, 2), 3.5, hookPaint);
  }

  @override
  bool shouldRepaint(covariant _SuspensionChainsPainter oldDelegate) =>
      oldDelegate.color != color;
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

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.6), 4, dotPaint);
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

    final options = chips.take(8).toList();
    final row1 = options.length >= 4 ? options.sublist(0, 4) : options;
    final row2 = options.length >= 8 ? options.sublist(4, 8) : <ScaleOp>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Number Blocks',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Drag or Tap',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.purple,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.pink),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final availableWidth = constraints.maxWidth;
              final tileWidth =
                  ((availableWidth - (3 * spacing)) / 4).floorToDouble();
              final tileHeight = (tileWidth * 1.06).clamp(64.0, 86.0);
              final fontSize = (tileWidth * 0.31).clamp(16.0, 24.0);
              final iconSize = (tileWidth * 0.25).clamp(14.0, 20.0);

              return Column(
                children: [
                  // Row 1 (Top 4 options)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: row1.map((scaleOp) {
                      return SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: _DraggableNumberBlock(
                          scaleOp: scaleOp,
                          isSolved: isSolved,
                          tileWidth: tileWidth,
                          tileHeight: tileHeight,
                          fontSize: fontSize,
                          iconSize: iconSize,
                          onTap: () =>
                              onApply(scaleOp.op, scaleOp.value, 'both'),
                        ),
                      );
                    }).toList(),
                  ),
                  if (row2.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    // Row 2 (Bottom 4 options)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: row2.map((scaleOp) {
                        return SizedBox(
                          width: tileWidth,
                          height: tileHeight,
                          child: _DraggableNumberBlock(
                            scaleOp: scaleOp,
                            isSolved: isSolved,
                            tileWidth: tileWidth,
                            tileHeight: tileHeight,
                            fontSize: fontSize,
                            iconSize: iconSize,
                            onTap: () =>
                                onApply(scaleOp.op, scaleOp.value, 'both'),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              );
            },
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
    required this.tileWidth,
    required this.tileHeight,
    required this.fontSize,
    required this.iconSize,
    required this.onTap,
  });

  final ScaleOp scaleOp;
  final bool isSolved;
  final double tileWidth;
  final double tileHeight;
  final double fontSize;
  final double iconSize;
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
    _bobController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 1800 + (widget.scaleOp.value.toInt() * 100) % 600,
      ),
    );

    _bobAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTesting =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
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
        child: _NumberBlockWidget(
          scaleOp: widget.scaleOp,
          isDragging: false,
          tileWidth: widget.tileWidth,
          tileHeight: widget.tileHeight,
          fontSize: widget.fontSize,
          iconSize: widget.iconSize,
        ),
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
                  scaleOp: widget.scaleOp,
                  isDragging: true,
                  tileWidth: widget.tileWidth,
                  tileHeight: widget.tileHeight,
                  fontSize: widget.fontSize,
                  iconSize: widget.iconSize,
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _NumberBlockWidget(
                scaleOp: widget.scaleOp,
                isDragging: false,
                tileWidth: widget.tileWidth,
                tileHeight: widget.tileHeight,
                fontSize: widget.fontSize,
                iconSize: widget.iconSize,
              ),
            ),
            child: BouncyPressable(
              shrinkFactor: 0.93,
              enableHaptics: true,
              onTap: widget.onTap,
              child: _NumberBlockWidget(
                scaleOp: widget.scaleOp,
                isDragging: false,
                tileWidth: widget.tileWidth,
                tileHeight: widget.tileHeight,
                fontSize: widget.fontSize,
                iconSize: widget.iconSize,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Number Block Widget ─────────────────────────────────────────────────────

class _NumberBlockWidget extends StatelessWidget {
  const _NumberBlockWidget({
    required this.scaleOp,
    required this.isDragging,
    required this.tileWidth,
    required this.tileHeight,
    required this.fontSize,
    required this.iconSize,
  });

  final ScaleOp scaleOp;
  final bool isDragging;
  final double tileWidth;
  final double tileHeight;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tileWidth,
      height: tileHeight,
      decoration: BoxDecoration(
        color: isDragging ? scaleOp.lightColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDragging
              ? scaleOp.color
              : scaleOp.color.withValues(alpha: 0.45),
          width: isDragging ? 2.5 : 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDragging
                ? scaleOp.color.withValues(alpha: 0.35)
                : scaleOp.color.withValues(alpha: 0.1),
            blurRadius: isDragging ? 16 : 8,
            offset: Offset(0, isDragging ? 8 : 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            scaleOp.icon,
            size: iconSize,
            color: scaleOp.color,
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              scaleOp.value.toString().replaceAll('.0', ''),
              style: GoogleFonts.nunito(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(scaleOp.color),
              const SizedBox(width: 2.5),
              _dot(scaleOp.color),
              const SizedBox(width: 2.5),
              _dot(scaleOp.color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 3.5,
      height: 3.5,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.45),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
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
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _lightColorForOp(step.operationText.substring(0, 1)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              step.operationText,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: _colorForOp(step.operationText.substring(0, 1)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${step.leftAfter} = ${step.rightAfter}',
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Combined Reasoning & Celebration Pop-up Dialog ──────────────────────────

class _ReasoningAndCelebrationDialog extends StatefulWidget {
  const _ReasoningAndCelebrationDialog({
    required this.problem,
    required this.onDismissAndNext,
  });

  final BalanceScaleProblem problem;
  final VoidCallback onDismissAndNext;

  @override
  State<_ReasoningAndCelebrationDialog> createState() =>
      _ReasoningAndCelebrationDialogState();
}

class _ReasoningAndCelebrationDialogState
    extends State<_ReasoningAndCelebrationDialog>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  bool _showError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  late List<AnimationController> _starControllers;
  late List<Animation<double>> _starAnimations;

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
  }

  void _triggerStars(int starRating) {
    for (int i = 0; i < starRating; i++) {
      Future.delayed(Duration(milliseconds: 150 + (i * 180)), () {
        if (mounted) _starControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    for (final c in _starControllers) {
      c.dispose();
    }
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
    } else {
      _triggerStars(provider.starRating);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BalanceScaleProvider>();
    final isCelebration = !provider.showReasoningCheck;

    if (isCelebration && !_starControllers[0].isAnimating && !_starControllers[0].isCompleted) {
      _triggerStars(provider.starRating);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: isCelebration
            ? _buildCelebrationView(provider)
            : _buildReasoningView(provider),
      ),
    );
  }

  Widget _buildReasoningView(BalanceScaleProvider provider) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = _shakeController.isAnimating
            ? math.sin(_shakeAnimation.value * math.pi * 4) *
                6 *
                (1 - _shakeAnimation.value)
            : 0.0;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mascot + Header
            Row(
              children: [
                XyMascot(
                  asset: _showError
                      ? AppAssets.xyExplaining
                      : AppAssets.xyQuestion,
                  size: 68,
                  shadowBlur: 4.0,
                  shadowOpacity: 0.2,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reasoning Check 🧠',
                        style: GoogleFonts.nunito(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'WHY does this solution work?',
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Reasoning options
            ...widget.problem.reasoningOptions.asMap().entries.map((entry) {
              final idx = entry.key;
              final text = entry.value;
              final isSelected = _selectedIndex == idx;
              final isWrong = isSelected && _showError;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BouncyPressable(
                  shrinkFactor: 0.97,
                  enableHaptics: true,
                  onTap: () => _onOptionTap(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isWrong
                          ? AppColors.error.withValues(alpha: 0.06)
                          : (isSelected
                              ? AppColors.lightPurple
                              : AppColors.background),
                      borderRadius: BorderRadius.circular(18),
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
                          width: 26,
                          height: 26,
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
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: isWrong
                                  ? AppColors.error
                                  : (isSelected
                                      ? AppColors.purple
                                      : AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: GoogleFonts.nunito(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (isWrong)
                          const Icon(
                            Icons.close_rounded,
                            color: AppColors.error,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationView(BalanceScaleProvider provider) {
    final starLabels = ['Completed!', 'Great Job! 🎉', 'Great Job! 🎉', 'Perfect! ⭐'];
    final label = starLabels[provider.starRating.clamp(0, 3)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.pink, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mascot with celebration aura
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.extraLightPink,
              shape: BoxShape.circle,
            ),
            child: XyMascot(
              asset: AppAssets.xyHappy,
              size: 96,
              shadowBlur: 5.0,
              shadowOpacity: 0.2,
            ),
          ),
          const SizedBox(height: 14),

          // Star Capsule Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFE082),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final earned = i < provider.starRating;
                return AnimatedBuilder(
                  animation: _starAnimations[i],
                  builder: (ctx, child) {
                    return Transform.scale(
                      scale: earned ? _starAnimations[i].value : 0.65,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          earned
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 38,
                          color: earned
                              ? const Color(0xFFFFB300)
                              : const Color(0xFFBDBDBD),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Subtitle
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: AppColors.pink,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Solved in ${provider.moveCount} moves • ${provider.optimalMoves} optimal',
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Rewards Pods
          Row(
            children: [
              // XP Pod
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.mint.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.mint,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${provider.xpEarned} XP',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F7263),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.reasoningPassed) ...[
                const SizedBox(width: 10),
                // Reasoning Pod
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.lightPurple,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🧠', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Reasoning ✓',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.purple,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Next Equation Button
          PrimaryButton(
            label: 'Next Equation →',
            onPressed: widget.onDismissAndNext,
          ),
        ],
      ),
    );
  }
}
