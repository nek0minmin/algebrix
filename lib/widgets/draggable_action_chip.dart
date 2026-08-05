import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';

/// Strongly-typed payload data passed during drag and drop operations.
class DragChipData {
  final int value;
  final bool isDivision;
  final String label;

  const DragChipData({
    required this.value,
    this.isDivision = false,
    required this.label,
  });
}

/// Draggable action chip representing an algebraic operation (e.g. -3, +3, ÷2).
class DraggableActionChip extends StatelessWidget {
  final int value;
  final String label;
  final bool isDivision;

  const DraggableActionChip({
    super.key,
    required this.value,
    required this.label,
    this.isDivision = false,
  });

  @override
  Widget build(BuildContext context) {
    final payload = DragChipData(
      value: value,
      isDivision: isDivision,
      label: label,
    );

    final chipWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: isDivision
            ? const LinearGradient(
                colors: [AppColors.purple, Color(0xFF8B64FF)],
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.drag_indicator, color: Colors.white70, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    return Draggable<DragChipData>(
      data: payload,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.15,
          child: chipWidget,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: chipWidget,
      ),
      child: chipWidget,
    );
  }
}
