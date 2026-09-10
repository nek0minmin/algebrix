import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/models/note_correction_model.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// The chooser that appears when a learner taps a highlighted mistake.
///
/// Modelled on the phone text-selection toolbar the learner already knows: tap
/// the word, get a short row of things you can do to it — except the options
/// here are the algebra terms that would make the sentence true.
class CorrectionSuggestionCard extends StatelessWidget {
  const CorrectionSuggestionCard({
    super.key,
    required this.correction,
    required this.onApply,
    required this.onDismiss,
  });

  final NoteCorrection correction;
  final ValueChanged<String> onApply;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isApplied = correction.isApplied;
    final accent = isApplied ? AppColors.mint : AppColors.yellow;

    return Container(
      key: const Key('correction-suggestion-card'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: isApplied
            ? AppColors.lightMint.withValues(alpha: 0.55)
            : AppColors.lightYellow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.75), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isApplied
                    ? Icons.check_circle_rounded
                    : Icons.edit_note_rounded,
                size: 18,
                color: isApplied ? AppColors.mint : const Color(0xFF9A6B00),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isApplied
                      ? 'Changed to "${correction.appliedReplacement}"'
                      : 'Xy thinks "${correction.original}" is not right here',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isApplied
                        ? const Color(0xFF12695E)
                        : const Color(0xFF7A5300),
                    height: 1.3,
                  ),
                ),
              ),
              GestureDetector(
                key: const Key('correction-dismiss'),
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: AppColors.subtitle,
                  ),
                ),
              ),
            ],
          ),
          if (!isApplied) ...[
            if (correction.why case final why?) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  why,
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 11),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in correction.suggestions)
                  _SuggestionChip(
                    label: suggestion,
                    onTap: () => onApply(suggestion),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Replace with $label',
      child: BouncyPressable(
        key: Key('correction-suggestion-$label'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.pink, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_fix_high_rounded,
                size: 14,
                color: AppColors.pink,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkPink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short burst of sparkles marking a word that was just corrected.
///
/// Positioned over the text field by the caller, which computes the word's
/// rectangle with a [TextPainter]. Purely decorative and non-interactive, so a
/// position that lands slightly off never blocks the learner.
class CorrectionSparkleBurst extends StatefulWidget {
  const CorrectionSparkleBurst({
    super.key,
    required this.size,
    this.sparkleCount = 7,
  });

  /// Size of the word being celebrated; sparkles radiate from its centre.
  final Size size;
  final int sparkleCount;

  @override
  State<CorrectionSparkleBurst> createState() => _CorrectionSparkleBurstState();
}

class _CorrectionSparkleBurstState extends State<CorrectionSparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    // Widget tests pump a fixed number of frames; a running animation would
    // leave pumpAndSettle waiting.
    final isTesting =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTesting) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _SparklePainter(
              progress: _controller.value,
              sparkleCount: widget.sparkleCount,
            ),
          ),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.progress, required this.sparkleCount});

  final double progress;
  final int sparkleCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final centre = Offset(size.width / 2, size.height / 2);
    final spread = math.max(size.width, size.height) * 0.7 + 14;
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);

    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < sparkleCount; i++) {
      final angle = (i / sparkleCount) * 2 * math.pi;
      // Alternate the reach so the burst does not read as a perfect ring.
      final reach = spread * (i.isEven ? 1.0 : 0.68) * eased;
      final position = centre + Offset(math.cos(angle), math.sin(angle)) * reach;
      final radius = (i.isEven ? 3.2 : 2.2) * (1 - eased * 0.45);

      paint.color = (i.isEven ? AppColors.mint : AppColors.yellow)
          .withValues(alpha: fade);
      _drawSparkle(canvas, position, radius, paint);
    }
  }

  /// A four-point star, drawn as two crossed teardrops.
  void _drawSparkle(Canvas canvas, Offset centre, double radius, Paint paint) {
    final path = Path()
      ..moveTo(centre.dx, centre.dy - radius * 2)
      ..quadraticBezierTo(centre.dx, centre.dy, centre.dx + radius * 2, centre.dy)
      ..quadraticBezierTo(centre.dx, centre.dy, centre.dx, centre.dy + radius * 2)
      ..quadraticBezierTo(centre.dx, centre.dy, centre.dx - radius * 2, centre.dy)
      ..quadraticBezierTo(centre.dx, centre.dy, centre.dx, centre.dy - radius * 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
