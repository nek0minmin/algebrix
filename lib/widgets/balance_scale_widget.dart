import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/models/equation_model.dart';
import 'package:algebrix/widgets/manipulative_item_widget.dart';
import 'package:algebrix/widgets/draggable_action_chip.dart';

/// Interactive animated balance scale widget supporting Drag & Drop on Left Pan, Right Pan, and Center Fulcrum.
class BalanceScaleWidget extends StatelessWidget {
  final EquationModel equation;
  final Function(DragChipData data)? onDropOnLeftPan;
  final Function(DragChipData data)? onDropOnRightPan;
  final Function(DragChipData data)? onDropOnCenterFulcrum;

  const BalanceScaleWidget({
    super.key,
    required this.equation,
    this.onDropOnLeftPan,
    this.onDropOnRightPan,
    this.onDropOnCenterFulcrum,
  });

  @override
  Widget build(BuildContext context) {
    final tiltAngle = equation.tiltAngle;

    return Container(
      height: 260,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // ── Layer 1: Fulcrum Stand Base (Center Triangle - DragTarget for BOTH sides) ──
          Positioned(
            bottom: 6,
            child: DragTarget<DragChipData>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                onDropOnCenterFulcrum?.call(details.data);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovered = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? AppColors.lightPink.withValues(alpha: 0.8)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isHovered
                        ? Border.all(color: AppColors.pink, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isHovered)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2.0),
                          child: Text(
                            'Drop here for BOTH sides!',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkPink,
                            ),
                          ),
                        ),
                      CustomPaint(
                        size: const Size(55, 65),
                        painter: _FulcrumPainter(isHovered: isHovered),
                      ),
                      Container(
                        width: 100,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Layer 2: Rotating Beam + Self-Leveling Pans ───────────────────
          Positioned(
            top: 38,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: tiltAngle),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, currentAngle, child) {
                return Transform.rotate(
                  angle: currentAngle,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Horizontal Beam Bar
                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.72,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.purple,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Center Pivot Node Dot
                      const Center(
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 5,
                            backgroundColor: AppColors.darkPink,
                          ),
                        ),
                      ),

                      // Left Pan (DragTarget for Left Side Only)
                      Positioned(
                        left: 8,
                        top: 0,
                        child: Transform.rotate(
                          angle: -currentAngle,
                          alignment: Alignment.topCenter,
                          child: DragTarget<DragChipData>(
                            onWillAcceptWithDetails: (details) => true,
                            onAcceptWithDetails: (details) {
                              onDropOnLeftPan?.call(details.data);
                            },
                            builder: (context, candidateData, rejectedData) {
                              final isHovered = candidateData.isNotEmpty;
                              return _ScalePan(
                                variablesCount: equation.leftVariables,
                                unitsCount: equation.leftUnits,
                                label: 'Left Side',
                                isHovered: isHovered,
                              );
                            },
                          ),
                        ),
                      ),

                      // Right Pan (DragTarget for Right Side Only)
                      Positioned(
                        right: 8,
                        top: 0,
                        child: Transform.rotate(
                          angle: -currentAngle,
                          alignment: Alignment.topCenter,
                          child: DragTarget<DragChipData>(
                            onWillAcceptWithDetails: (details) => true,
                            onAcceptWithDetails: (details) {
                              onDropOnRightPan?.call(details.data);
                            },
                            builder: (context, candidateData, rejectedData) {
                              final isHovered = candidateData.isNotEmpty;
                              return _ScalePan(
                                variablesCount: equation.rightVariables,
                                unitsCount: equation.rightUnits,
                                label: 'Right Side',
                                isHovered: isHovered,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Hanging scale pan housing variable tiles and unit cubes.
class _ScalePan extends StatelessWidget {
  final int variablesCount;
  final int unitsCount;
  final String label;
  final bool isHovered;

  const _ScalePan({
    required this.variablesCount,
    required this.unitsCount,
    required this.label,
    this.isHovered = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = variablesCount + unitsCount;
    final isCompact = totalCount > 5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hanging Strings
        CustomPaint(
          size: const Size(110, 28),
          painter: _StringsPainter(),
        ),

        // Pan Plate Container
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 140,
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isHovered
                ? AppColors.lightMint
                : AppColors.extraLightPink,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(18),
              top: Radius.circular(8),
            ),
            border: Border.all(
              color: isHovered ? AppColors.mint : AppColors.purple.withValues(alpha: 0.4),
              width: isHovered ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isHovered ? AppColors.mint : AppColors.purple).withValues(alpha: 0.18),
                blurRadius: isHovered ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHovered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Drop on $label!',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F7263),
                    ),
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: isCompact ? 1 : 2,
                runSpacing: isCompact ? 1 : 2,
                children: [
                  // Variable Blocks (X)
                  ...List.generate(
                    variablesCount,
                    (index) => ManipulativeItemWidget.variable(
                      key: ValueKey('var_${label}_$index'),
                      isCompact: isCompact,
                    ),
                  ),
                  // Unit Blocks (1)
                  ...List.generate(
                    unitsCount,
                    (index) => ManipulativeItemWidget.unit(
                      key: ValueKey('unit_${label}_$index'),
                      isCompact: isCompact,
                    ),
                  ),
                  if (variablesCount == 0 && unitsCount == 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Empty',
                        style: TextStyle(
                          color: AppColors.subtitle,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the triangular fulcrum base stand.
class _FulcrumPainter extends CustomPainter {
  final bool isHovered;

  _FulcrumPainter({this.isHovered = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isHovered ? AppColors.darkPink : AppColors.purple
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // Inner highlight
    final accentPaint = Paint()
      ..color = isHovered ? AppColors.lightPink : AppColors.lightPurple
      ..style = PaintingStyle.fill;

    final accentPath = Path()
      ..moveTo(size.width / 2, 16)
      ..lineTo(size.width * 0.8, size.height - 8)
      ..lineTo(size.width * 0.2, size.height - 8)
      ..close();

    canvas.drawPath(accentPath, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for the hanging scale pan strings.
class _StringsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width / 2, 0), Offset(10, size.height), paint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width - 10, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
