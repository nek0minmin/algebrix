import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/services/sound_service.dart';

/// Plot points by tapping the grid itself.
///
/// The readout under the plane updates as points land, so "3 across, 2 up"
/// and "(3, 2)" are visibly the same statement. Tapping a plotted point
/// removes it, which makes a wrong guess cheap to undo.
class CoordinatePlaneActivity extends StatefulWidget {
  const CoordinatePlaneActivity({
    super.key,
    required this.data,
    required this.onAnswered,
    this.enabled = true,
  });

  final CoordinatePlaneActivityData data;
  final Future<void> Function(bool isCorrect) onAnswered;
  final bool enabled;

  @override
  State<CoordinatePlaneActivity> createState() =>
      _CoordinatePlaneActivityState();
}

class _CoordinatePlaneActivityState extends State<CoordinatePlaneActivity> {
  final List<GridPoint> _plotted = [];
  bool _submitting = false;
  bool _solved = false;

  bool get _interactive => widget.enabled && !_submitting && !_solved;

  Future<void> _tap(GridPoint point) async {
    if (!_interactive) return;

    setState(() {
      if (_plotted.contains(point)) {
        _plotted.remove(point);
        SoundService.playClick();
        return;
      }
      if (_plotted.length >= widget.data.targets.length) return;
      _plotted.add(point);
      SoundService.playTileDrop();
    });

    if (_plotted.length != widget.data.targets.length) return;
    await _submit();
  }

  Future<void> _submit() async {
    final targets = widget.data.targets;
    final isCorrect = widget.data.orderMatters
        ? _sameInOrder(_plotted, targets)
        : _plotted.toSet().containsAll(targets) &&
              _plotted.length == targets.length;

    setState(() => _submitting = true);
    try {
      await widget.onAnswered(isCorrect);
      if (mounted && isCorrect) setState(() => _solved = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _sameInOrder(List<GridPoint> a, List<GridPoint> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final remaining = data.targets.length - _plotted.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.lightPurple.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            data.prompt,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.purple,
            ),
          ),
        ),
        const SizedBox(height: 14),

        _Plane(
          data: data,
          plotted: _plotted,
          onTap: _tap,
          showLine: _solved && data.connectWhenComplete,
        ),
        const SizedBox(height: 12),

        // Live readout: the coordinates the learner has actually placed.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_plotted.isEmpty)
              Text(
                remaining == 1
                    ? 'Tap one point on the grid'
                    : 'Tap $remaining points on the grid',
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.subtitle,
                ),
              )
            else
              for (final point in _plotted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.extraLightPink,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.lightPink),
                  ),
                  child: Text(
                    '$point',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkPink,
                    ),
                  ),
                ),
          ],
        ),
        if (_plotted.isNotEmpty && !_solved) ...[
          const SizedBox(height: 6),
          Text(
            'Tap a placed point to remove it.',
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

class _Plane extends StatelessWidget {
  const _Plane({
    required this.data,
    required this.plotted,
    required this.onTap,
    required this.showLine,
  });

  final CoordinatePlaneActivityData data;
  final List<GridPoint> plotted;
  final ValueChanged<GridPoint> onTap;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final xs = data.xTicks;
    final ys = data.yTicks.reversed.toList(); // y grows upward on screen

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      // A tall grid (11 rows in 5.6, say) would otherwise run far past the
      // bottom of a phone screen, so the height is capped and the plane
      // narrows to keep its squares square.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: AspectRatio(
            aspectRatio: xs.length / ys.length,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PlanePainter(
                          data: data,
                          plotted: plotted,
                          showLine: showLine,
                        ),
                      ),
                    ),
                    // A transparent tap target per lattice point.
                    Column(
                      children: [
                        for (final y in ys)
                          Expanded(
                            child: Row(
                              children: [
                                for (final x in xs)
                                  Expanded(
                                    child: GestureDetector(
                                      key: Key('grid-point-${x}_$y'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => onTap(GridPoint(x, y)),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanePainter extends CustomPainter {
  _PlanePainter({
    required this.data,
    required this.plotted,
    required this.showLine,
  });

  final CoordinatePlaneActivityData data;
  final List<GridPoint> plotted;
  final bool showLine;

  @override
  void paint(Canvas canvas, Size size) {
    final xs = data.xTicks;
    final ys = data.yTicks;
    if (xs.length < 2 || ys.length < 2) return;

    final cellW = size.width / xs.length;
    final cellH = size.height / ys.length;

    Offset centreOf(int x, int y) => Offset(
      (x - data.minX + 0.5) * cellW,
      // Screen y is inverted relative to maths y.
      (data.maxY - y + 0.5) * cellH,
    );

    final grid = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (var i = 0; i <= xs.length; i++) {
      canvas.drawLine(
        Offset(i * cellW, 0),
        Offset(i * cellW, size.height),
        grid,
      );
    }
    for (var i = 0; i <= ys.length; i++) {
      canvas.drawLine(
        Offset(0, i * cellH),
        Offset(size.width, i * cellH),
        grid,
      );
    }

    // Axes, drawn only when zero is on the board.
    final axis = Paint()
      ..color = AppColors.subtitle
      ..strokeWidth = 2;
    if (data.minY <= 0 && data.maxY >= 0) {
      final y = centreOf(data.minX, 0).dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axis);
    }
    if (data.minX <= 0 && data.maxX >= 0) {
      final x = centreOf(0, data.minY).dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), axis);
    }

    if (showLine && plotted.length >= 2) {
      final sorted = [...plotted]..sort((a, b) => a.x.compareTo(b.x));
      final line = Paint()
        ..color = AppColors.mint
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      for (var i = 1; i < sorted.length; i++) {
        canvas.drawLine(
          centreOf(sorted[i - 1].x, sorted[i - 1].y),
          centreOf(sorted[i].x, sorted[i].y),
          line,
        );
      }
    }

    for (final point in plotted) {
      final centre = centreOf(point.x, point.y);
      canvas.drawCircle(centre, 7, Paint()..color = AppColors.darkPink);
      canvas.drawCircle(
        centre,
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_PlanePainter old) =>
      old.plotted.length != plotted.length ||
      old.showLine != showLine ||
      !_sameList(old.plotted, plotted);

  bool _sameList(List<GridPoint> a, List<GridPoint> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
