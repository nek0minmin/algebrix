import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';

enum ManipulativeType { variable, unit }

/// Visual representation of algebraic manipulatives (Variable Tile X or Unit Cube +1).
class ManipulativeItemWidget extends StatelessWidget {
  final ManipulativeType type;
  final String label;
  final bool isCompact;

  const ManipulativeItemWidget({
    super.key,
    required this.type,
    this.label = '1',
    this.isCompact = false,
  });

  factory ManipulativeItemWidget.variable({Key? key, bool isCompact = false}) {
    return ManipulativeItemWidget(
      key: key,
      type: ManipulativeType.variable,
      label: 'X',
      isCompact: isCompact,
    );
  }

  factory ManipulativeItemWidget.unit({Key? key, String label = '1', bool isCompact = false}) {
    return ManipulativeItemWidget(
      key: key,
      type: ManipulativeType.unit,
      label: label,
      isCompact: isCompact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVariable = type == ManipulativeType.variable;
    final itemWidth = isCompact
        ? (isVariable ? 34.0 : 24.0)
        : (isVariable ? 42.0 : 30.0);
    final itemHeight = itemWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      width: itemWidth,
      height: itemHeight,
      margin: EdgeInsets.all(isCompact ? 2.0 : 3.0),
      decoration: BoxDecoration(
        gradient: isVariable
            ? AppColors.primaryGradient
            : const LinearGradient(
                colors: [AppColors.mint, Color(0xFF48C9B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(isVariable ? (isCompact ? 9 : 12) : (isCompact ? 6 : 8)),
        boxShadow: [
          BoxShadow(
            color: (isVariable ? AppColors.pink : AppColors.mint).withValues(alpha: 0.35),
            blurRadius: isCompact ? 4 : 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: isCompact ? 1.0 : 1.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isVariable ? (isCompact ? 16 : 19) : (isCompact ? 12 : 14),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 1.5),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
