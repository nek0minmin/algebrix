import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/services/sound_service.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// Graphs an inequality on a number line, one decision at a time.
///
/// Three stages, in the order the maths actually works:
///   1. tap the boundary value
///   2. decide whether it is included (○ / ●)
///   3. paint the range, by dragging along the line or tapping a direction
///
/// Each stage only unlocks once the previous one is set, so the learner cannot
/// arrive at a right-looking graph without making all three calls.
class NumberLineActivity extends StatefulWidget {
  const NumberLineActivity({
    super.key,
    required this.data,
    required this.onAnswered,
    this.enabled = true,
  });

  final NumberLineActivityData data;
  final Future<void> Function(bool isCorrect) onAnswered;
  final bool enabled;

  @override
  State<NumberLineActivity> createState() => _NumberLineActivityState();
}

class _NumberLineActivityState extends State<NumberLineActivity> {
  int? _boundary;
  NumberLineBoundary? _marker;
  NumberLineDirection? _direction;
  bool _submitting = false;
  bool _submitted = false;

  bool get _interactive =>
      widget.enabled && !_submitting && !_submitted;

  void _selectBoundary(int value) {
    if (!_interactive) return;
    SoundService.playTileSelect();
    setState(() {
      _boundary = value;
      // Re-placing the boundary invalidates the later choices, so the learner
      // re-confirms them rather than inheriting a stale graph.
      _marker = null;
      _direction = null;
    });
  }

  void _selectMarker(NumberLineBoundary marker) {
    if (!_interactive || _boundary == null) return;
    SoundService.playTileSelect();
    setState(() => _marker = marker);
    _maybeSubmit();
  }

  void _selectDirection(NumberLineDirection direction) {
    if (!_interactive || _marker == null) return;
    SoundService.playTileDrop();
    setState(() => _direction = direction);
    _maybeSubmit();
  }

  Future<void> _maybeSubmit() async {
    if (_boundary == null || _marker == null || _direction == null) return;
    if (_submitting || _submitted) return;

    final data = widget.data;
    final isCorrect = _boundary == data.correctBoundary &&
        _marker == data.correctMarker &&
        _direction == data.correctDirection;

    setState(() => _submitting = true);
    try {
      await widget.onAnswered(isCorrect);
      if (mounted && isCorrect) setState(() => _submitted = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The inequality stays on screen the whole time; the graph is a
        // translation of it, not a separate puzzle.
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.lightPurple.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              data.inequality,
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.purple,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        _StagePrompt(
          index: 1,
          label: data.boundaryPrompt,
          isActive: _boundary == null,
          isDone: _boundary != null,
        ),
        const SizedBox(height: 10),

        _NumberLine(
          key: const Key('number-line'),
          data: data,
          boundary: _boundary,
          marker: _marker,
          direction: _direction,
          onTapValue: _selectBoundary,
          onDrag: _marker == null ? null : _selectDirection,
        ),
        const SizedBox(height: 18),

        if (_boundary != null) ...[
          _StagePrompt(
            index: 2,
            label: data.markerPrompt,
            isActive: _marker == null,
            isDone: _marker != null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ChoiceTile(
                  itemKey: const Key('number-line-open'),
                  glyph: '○',
                  label: 'Not included',
                  isSelected: _marker == NumberLineBoundary.open,
                  onTap: () => _selectMarker(NumberLineBoundary.open),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceTile(
                  itemKey: const Key('number-line-closed'),
                  glyph: '●',
                  label: 'Included',
                  isSelected: _marker == NumberLineBoundary.closed,
                  onTap: () => _selectMarker(NumberLineBoundary.closed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],

        if (_marker != null) ...[
          _StagePrompt(
            index: 3,
            label: data.directionPrompt,
            isActive: _direction == null,
            isDone: _direction != null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ChoiceTile(
                  itemKey: const Key('number-line-left'),
                  glyph: '◀',
                  label: 'Smaller',
                  isSelected: _direction == NumberLineDirection.left,
                  onTap: () => _selectDirection(NumberLineDirection.left),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChoiceTile(
                  itemKey: const Key('number-line-right'),
                  glyph: '▶',
                  label: 'Bigger',
                  isSelected: _direction == NumberLineDirection.right,
                  onTap: () => _selectDirection(NumberLineDirection.right),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You can also swipe along the line.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Number line ─────────────────────────────────────────────────────────────

class _NumberLine extends StatelessWidget {
  const _NumberLine({
    super.key,
    required this.data,
    required this.boundary,
    required this.marker,
    required this.direction,
    required this.onTapValue,
    required this.onDrag,
  });

  final NumberLineActivityData data;
  final int? boundary;
  final NumberLineBoundary? marker;
  final NumberLineDirection? direction;
  final ValueChanged<int> onTapValue;
  final ValueChanged<NumberLineDirection>? onDrag;

  @override
  Widget build(BuildContext context) {
    final ticks = data.ticks;

    return GestureDetector(
      // Dragging paints the range, which is what the graph means physically.
      onHorizontalDragEnd: onDrag == null
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity == 0) return;
              onDrag!(
                velocity > 0
                    ? NumberLineDirection.right
                    : NumberLineDirection.left,
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                SizedBox(
                  height: 46,
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 46),
                    painter: _NumberLinePainter(
                      tickCount: ticks.length,
                      boundaryIndex:
                          boundary == null ? null : ticks.indexOf(boundary!),
                      marker: marker,
                      direction: direction,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final value in ticks)
                      Expanded(
                        child: _TickLabel(
                          value: value,
                          isBoundary: value == boundary,
                          onTap: () => onTapValue(value),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TickLabel extends StatelessWidget {
  const _TickLabel({
    required this.value,
    required this.isBoundary,
    required this.onTap,
  });

  final int value;
  final bool isBoundary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isBoundary,
      label: 'Set boundary at $value',
      child: GestureDetector(
        key: Key('number-line-tick-$value'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 34,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$value',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: isBoundary ? FontWeight.w900 : FontWeight.w700,
                  color: isBoundary ? AppColors.darkPink : AppColors.subtitle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberLinePainter extends CustomPainter {
  _NumberLinePainter({
    required this.tickCount,
    required this.boundaryIndex,
    required this.marker,
    required this.direction,
  });

  final int tickCount;
  final int? boundaryIndex;
  final NumberLineBoundary? marker;
  final NumberLineDirection? direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (tickCount <= 1) return;

    final centreY = size.height / 2;
    final slot = size.width / tickCount;
    double xFor(int index) => slot * index + slot / 2;

    final axis = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(slot / 2, centreY),
      Offset(size.width - slot / 2, centreY),
      axis,
    );

    final tick = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < tickCount; i++) {
      final x = xFor(i);
      canvas.drawLine(Offset(x, centreY - 6), Offset(x, centreY + 6), tick);
    }

    if (boundaryIndex == null || boundaryIndex! < 0) return;
    final boundaryX = xFor(boundaryIndex!);

    // Shaded range, drawn under the boundary marker.
    if (direction != null) {
      final range = Paint()
        ..color = AppColors.mint
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      final endX = direction == NumberLineDirection.right
          ? size.width - 2
          : 2.0;
      canvas.drawLine(Offset(boundaryX, centreY), Offset(endX, centreY), range);
      _drawArrowHead(canvas, Offset(endX, centreY), direction!, range);
    }

    // Boundary marker on top.
    final markerCentre = Offset(boundaryX, centreY);
    if (marker == NumberLineBoundary.closed) {
      canvas.drawCircle(
        markerCentre,
        9,
        Paint()..color = AppColors.darkPink,
      );
    } else {
      canvas.drawCircle(
        markerCentre,
        9,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        markerCentre,
        9,
        Paint()
          ..color = AppColors.darkPink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    NumberLineDirection direction,
    Paint paint,
  ) {
    final sign = direction == NumberLineDirection.right ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + sign * 11, tip.dy - 7)
      ..lineTo(tip.dx + sign * 11, tip.dy + 7)
      ..close();
    canvas.drawPath(path, Paint()..color = paint.color);
  }

  @override
  bool shouldRepaint(_NumberLinePainter oldDelegate) =>
      oldDelegate.boundaryIndex != boundaryIndex ||
      oldDelegate.marker != marker ||
      oldDelegate.direction != direction ||
      oldDelegate.tickCount != tickCount;
}

// ── Shared bits ─────────────────────────────────────────────────────────────

class _StagePrompt extends StatelessWidget {
  const _StagePrompt({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  final int index;
  final String label;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final accent = isDone
        ? AppColors.mint
        : (isActive ? AppColors.pink : AppColors.subtitle);

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 1.4),
          ),
          child: Center(
            child: isDone
                ? Icon(Icons.check_rounded, size: 13, color: accent)
                : Text(
                    '$index',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: isActive ? AppColors.text : AppColors.subtitle,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.itemKey,
    required this.glyph,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Key itemKey;
  final String glyph;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: BouncyPressable(
        key: itemKey,
        enableSound: false,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.extraLightPink : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.pink : AppColors.border,
              width: isSelected ? 2 : 1.4,
            ),
          ),
          child: Column(
            children: [
              Text(
                glyph,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppColors.darkPink : AppColors.subtitle,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.darkPink : AppColors.subtitle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
