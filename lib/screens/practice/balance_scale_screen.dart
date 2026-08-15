import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/balance_scale_provider.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Data class representing a scale operation to drag or apply.
class ScaleOp {
  const ScaleOp({
    required this.op,
    required this.value,
    required this.label,
  });

  final String op;
  final num value;
  final String label;
}

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
        supportingText: 'Isolate x by dragging equal operations onto the scale.',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // API Status Indicator
              _ApiStatusBadge(providerUsed: provider.providerUsed),
              const SizedBox(height: 16),

              // Target Equation Banner
              if (problem != null) ...[
                Container(
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
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Goal: Solve for x',
                              style: AppTextStyles.subtitle2.copyWith(
                                color: AppColors.pink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                        onPressed: provider.resetCurrentProblem,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Drag & Drop Instructions Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.extraLightPink,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.pink.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, color: AppColors.pink, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Drag an operation chip onto the Center Fulcrum (both sides) or Left/Right Pans (single side), or tap directly!',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Visual Interactive Drag-Target Scale Canvas
              _VisualScaleWidget(
                leftExpr: provider.leftExpr,
                rightExpr: provider.rightExpr,
                isSolved: provider.isSolved,
                isLoading: provider.isLoading,
                onApply: (op, val, targetSide) =>
                    provider.applyOperation(op, val, targetSide: targetSide),
              ),
              const SizedBox(height: 24),

              // Draggable Chips Operation Palette
              _OperationPalette(
                isLoading: provider.isLoading,
                isSolved: provider.isSolved,
                onApply: (op, val, targetSide) =>
                    provider.applyOperation(op, val, targetSide: targetSide),
              ),
              const SizedBox(height: 24),

              // Step History Log
              if (provider.history.isNotEmpty) ...[
                Text(
                  'Steps Performed',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ...provider.history.map(
                  (step) => Container(
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.extraLightPink,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            step.operationText,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              color: AppColors.pink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${step.leftAfter} = ${step.rightAfter}',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          step.providerUsed.contains('MathJS') ? 'HTTP POST' : 'Offline',
                          style: AppTextStyles.body2.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Celebratory Win Banner if Solved
              if (provider.isSolved) ...[
                const SizedBox(height: 24),
                _CelebrationCard(
                  xp: provider.xpEarned,
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
          Text(
            'Powered by $providerUsed',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.pink,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualScaleWidget extends StatelessWidget {
  const _VisualScaleWidget({
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isSolved ? AppColors.pink : AppColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Center Fulcrum Drag Target (Applies to BOTH sides equal)
          DragTarget<ScaleOp>(
            onWillAcceptWithDetails: (details) => !isLoading && !isSolved,
            onAcceptWithDetails: (details) {
              onApply(details.data.op, details.data.value, 'both');
            },
            builder: (ctx, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isHovered
                      ? AppColors.extraLightPink
                      : AppColors.background.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHovered ? AppColors.pink : AppColors.border.withValues(alpha: 0.6),
                    width: isHovered ? 2.5 : 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isHovered ? Icons.add_circle_rounded : Icons.center_focus_strong_rounded,
                      color: isHovered ? AppColors.pink : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isHovered
                          ? 'RELEASE HERE TO APPLY TO BOTH SIDES! 🎯'
                          : '🎯 Drop here to apply to BOTH sides equally',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isHovered ? AppColors.pink : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Tilted Beam & Drag-Target Scale Pans
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Scale Pan Drag Target
              Expanded(
                child: DragTarget<ScaleOp>(
                  onWillAcceptWithDetails: (details) => !isLoading && !isSolved,
                  onAcceptWithDetails: (details) {
                    onApply(details.data.op, details.data.value, 'left');
                  },
                  builder: (ctx, candidateData, rejectedData) {
                    final isHovered = candidateData.isNotEmpty;
                    return _ScalePan(
                      expression: leftExpr,
                      isLeft: true,
                      isSolved: isSolved,
                      isHovered: isHovered,
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Fulcrum Triangle Centerpiece
              Column(
                children: [
                  const SizedBox(height: 24),
                  CustomPaint(
                    size: const Size(40, 36),
                    painter: _FulcrumPainter(),
                  ),
                  Container(
                    height: 8,
                    width: 60,
                    decoration: BoxDecoration(
                      color: AppColors.text,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Right Scale Pan Drag Target
              Expanded(
                child: DragTarget<ScaleOp>(
                  onWillAcceptWithDetails: (details) => !isLoading && !isSolved,
                  onAcceptWithDetails: (details) {
                    onApply(details.data.op, details.data.value, 'right');
                  },
                  builder: (ctx, candidateData, rejectedData) {
                    final isHovered = candidateData.isNotEmpty;
                    return _ScalePan(
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
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: isHovered
            ? AppColors.extraLightPink
            : (isSolved ? AppColors.extraLightPink : AppColors.background),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHovered
              ? AppColors.pink
              : (isSolved ? AppColors.pink : AppColors.border),
          width: isHovered ? 2.5 : 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isHovered
                ? (isLeft ? 'RELEASE ON LEFT' : 'RELEASE ON RIGHT')
                : (isLeft ? 'LEFT PAN' : 'RIGHT PAN'),
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isHovered ? AppColors.pink : AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              expression.isEmpty ? '?' : expression,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isSolved || isHovered ? AppColors.pink : AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FulcrumPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.pink
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OperationPalette extends StatelessWidget {
  const _OperationPalette({
    required this.isLoading,
    required this.isSolved,
    required this.onApply,
  });

  final bool isLoading;
  final bool isSolved;
  final Function(String op, num val, String targetSide) onApply;

  static const List<ScaleOp> _presetOps = [
    ScaleOp(op: '-', value: 6, label: '- 6'),
    ScaleOp(op: '-', value: 4, label: '- 4'),
    ScaleOp(op: '-', value: 8, label: '- 8'),
    ScaleOp(op: '+', value: 5, label: '+ 5'),
    ScaleOp(op: '/', value: 2, label: '÷ 2'),
    ScaleOp(op: '/', value: 3, label: '÷ 3'),
    ScaleOp(op: '/', value: 4, label: '÷ 4'),
    ScaleOp(op: '/', value: 5, label: '÷ 5'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Operation Weight Chips',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Drag or Tap',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.pink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.pink),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._presetOps.map(
                (scaleOp) => _DraggableOperationChip(
                  scaleOp: scaleOp,
                  isSolved: isSolved,
                  onTap: () => onApply(scaleOp.op, scaleOp.value, 'both'),
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 18, color: AppColors.pink),
                label: Text(
                  'Custom Operation',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: AppColors.pink,
                  ),
                ),
                backgroundColor: AppColors.extraLightPink,
                side: const BorderSide(color: AppColors.pink),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                onPressed: isSolved
                    ? null
                    : () => _showCustomOperationModal(context, onApply),
              ),
            ],
          ),
      ],
    );
  }

  void _showCustomOperationModal(
    BuildContext context,
    Function(String op, num val, String targetSide) onApply,
  ) {
    String selectedOp = '-';
    final controller = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Custom Scale Operation',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (ctx, setModalState) => Row(
                children: [
                  DropdownButton<String>(
                    value: selectedOp,
                    items: const [
                      DropdownMenuItem(value: '+', child: Text('+ (Add)')),
                      DropdownMenuItem(value: '-', child: Text('- (Subtract)')),
                      DropdownMenuItem(value: '*', child: Text('× (Multiply)')),
                      DropdownMenuItem(value: '/', child: Text('÷ (Divide)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedOp = val);
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Apply Operation',
              onPressed: () {
                final val = num.tryParse(controller.text.trim());
                if (val == null || val == 0) {
                  showAlgebrixSnackBar(context, message: 'Enter a valid number!', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                onApply(selectedOp, val, 'both');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DraggableOperationChip extends StatelessWidget {
  const _DraggableOperationChip({
    required this.scaleOp,
    required this.isSolved,
    required this.onTap,
  });

  final ScaleOp scaleOp;
  final bool isSolved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isSolved) {
      return _ChipWidget(label: scaleOp.label, isDragging: false);
    }

    return Draggable<ScaleOp>(
      data: scaleOp,
      feedback: Material(
        color: Colors.transparent,
        child: _ChipWidget(label: scaleOp.label, isDragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _ChipWidget(label: scaleOp.label, isDragging: false),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _ChipWidget(label: scaleOp.label, isDragging: false),
      ),
    );
  }
}

class _ChipWidget extends StatelessWidget {
  const _ChipWidget({required this.label, required this.isDragging});

  final String label;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDragging ? AppColors.extraLightPink : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDragging ? AppColors.pink : AppColors.border,
          width: isDragging ? 2 : 1.5,
        ),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: AppColors.pink.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.drag_indicator_rounded, size: 16, color: AppColors.pink),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({required this.xp, required this.onNext});

  final int xp;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.extraLightPink,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.pink, width: 2),
      ),
      child: Column(
        children: [
          Image.asset(
            AppAssets.xyDefault,
            width: 72,
            height: 72,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            'Equation Balanced! 🎉',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.pink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You isolated x and earned +$xp XP!',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Next Equation →',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
