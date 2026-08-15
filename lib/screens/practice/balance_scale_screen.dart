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
        supportingText: 'Isolate x by applying equal operations to both sides.',
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
                const SizedBox(height: 24),
              ],

              // Visual Interactive Balance Scale
              _VisualScaleWidget(
                leftExpr: provider.leftExpr,
                rightExpr: provider.rightExpr,
                isSolved: provider.isSolved,
              ),
              const SizedBox(height: 28),

              // Operation Palette
              _OperationPalette(
                isLoading: provider.isLoading,
                isSolved: provider.isSolved,
                onApply: provider.applyOperation,
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
  });

  final String leftExpr;
  final String rightExpr;
  final bool isSolved;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Scale Base & Fulcrum Triangle
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Fulcrum Triangle
                CustomPaint(
                  size: const Size(44, 38),
                  painter: _FulcrumPainter(),
                ),
                Container(
                  height: 10,
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.text,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),

          // Tilted Beam & Scale Pans
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Beam
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: isSolved ? AppColors.pink : AppColors.text,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Scale Pan
                    _ScalePan(
                      expression: leftExpr,
                      isLeft: true,
                      isSolved: isSolved,
                    ),
                    // Right Scale Pan
                    _ScalePan(
                      expression: rightExpr,
                      isLeft: false,
                      isSolved: isSolved,
                    ),
                  ],
                ),
              ],
            ),
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
  });

  final String expression;
  final bool isLeft;
  final bool isSolved;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pan Hanger Lines
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 2, height: 28, color: AppColors.border),
            const SizedBox(width: 80),
            Container(width: 2, height: 28, color: AppColors.border),
          ],
        ),
        // Dish Pan
        Container(
          width: 110,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isSolved ? AppColors.extraLightPink : AppColors.background,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
              top: Radius.circular(8),
            ),
            border: Border.all(
              color: isSolved ? AppColors.pink : AppColors.border,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLeft ? 'LEFT PAN' : 'RIGHT PAN',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  expression.isEmpty ? '?' : expression,
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isSolved ? AppColors.pink : AppColors.text,
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
  final Function(String op, num val) onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perform Equal Operation on Both Sides',
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.w900,
          ),
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
              _ActionChip(
                label: '- 6',
                onPressed: isSolved ? null : () => onApply('-', 6),
              ),
              _ActionChip(
                label: '- 4',
                onPressed: isSolved ? null : () => onApply('-', 4),
              ),
              _ActionChip(
                label: '+ 5',
                onPressed: isSolved ? null : () => onApply('+', 5),
              ),
              _ActionChip(
                label: '÷ 2',
                onPressed: isSolved ? null : () => onApply('/', 2),
              ),
              _ActionChip(
                label: '÷ 3',
                onPressed: isSolved ? null : () => onApply('/', 3),
              ),
              _ActionChip(
                label: '÷ 4',
                onPressed: isSolved ? null : () => onApply('/', 4),
              ),
              _ActionChip(
                label: '÷ 5',
                onPressed: isSolved ? null : () => onApply('/', 5),
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
    Function(String op, num val) onApply,
  ) {
    String selectedOp = '-';
    final controller = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                onApply(selectedOp, val);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: AppColors.text,
        ),
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
