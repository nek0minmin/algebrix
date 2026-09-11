import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/services/sound_service.dart';

/// A sandbox for `y = mx + b`.
///
/// Two sliders, one live line. Drag the slope up and the line gets steeper;
/// drag it through zero and it flattens, then falls. Change the intercept and
/// the whole line slides without changing its tilt.
///
/// There is no wrong answer to punish — a goal is either met yet or not, and
/// the learner keeps moving the sliders until it is.
class LineLabActivity extends StatefulWidget {
  const LineLabActivity({
    super.key,
    required this.data,
    required this.onAnswered,
    this.enabled = true,
  });

  final LineLabActivityData data;
  final Future<void> Function(bool isCorrect) onAnswered;
  final bool enabled;

  @override
  State<LineLabActivity> createState() => _LineLabActivityState();
}

class _LineLabActivityState extends State<LineLabActivity> {
  late int _slope = widget.data.startSlope;
  late int _intercept = widget.data.startIntercept;
  bool _solved = false;
  bool _submitting = false;

  bool get _interactive => widget.enabled && !_submitting && !_solved;

  bool get _goalMet => widget.data.isSatisfiedBy(_slope, _intercept);

  Future<void> _change({int? slope, int? intercept}) async {
    if (!_interactive) return;

    setState(() {
      if (slope != null) _slope = slope;
      if (intercept != null) _intercept = intercept;
    });
    SoundService.playTileSelect();

    // An open-ended lab has nothing to satisfy; the learner confirms it.
    if (widget.data.isOpenEnded || !_goalMet) return;
    await _submit();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onAnswered(true);
      if (mounted) setState(() => _solved = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _equation {
    final slopePart = switch (_slope) {
      0 => '',
      1 => 'x',
      -1 => '−x',
      _ => '${_slope < 0 ? '−' : ''}${_slope.abs()}x',
    };

    final interceptPart =
        _intercept < 0 ? '−${_intercept.abs()}' : '$_intercept';

    if (_slope == 0) return 'y = $interceptPart';
    if (_intercept == 0) return 'y = $slopePart';
    final sign = _intercept < 0 ? '−' : '+';
    return 'y = $slopePart $sign ${_intercept.abs()}';
  }

  String get _shapeDescription {
    if (_slope == 0) return 'A flat line — y never changes.';
    if (_slope > 0) return 'Rising: up $_slope for every 1 across.';
    return 'Falling: down ${_slope.abs()} for every 1 across.';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

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
            data.goal,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.purple,
            ),
          ),
        ),
        const SizedBox(height: 14),

        _LinePlane(slope: _slope, intercept: _intercept),
        const SizedBox(height: 12),

        // The equation the sliders currently describe.
        Center(
          key: const Key('line-lab-equation'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: _solved ? AppColors.lightMint : AppColors.extraLightPink,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _solved ? AppColors.mint : AppColors.lightPink,
              ),
            ),
            child: Text(
              _equation,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _solved ? const Color(0xFF12695E) : AppColors.darkPink,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _shapeDescription,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 14),

        _IntSlider(
          sliderKey: const Key('line-lab-slope'),
          label: 'Slope  m',
          value: _slope,
          min: data.minSlope,
          max: data.maxSlope,
          accent: AppColors.pink,
          enabled: _interactive,
          onChanged: (value) => _change(slope: value),
        ),
        const SizedBox(height: 10),
        _IntSlider(
          sliderKey: const Key('line-lab-intercept'),
          label: 'Intercept  b',
          value: _intercept,
          min: data.minIntercept,
          max: data.maxIntercept,
          accent: AppColors.purple,
          enabled: _interactive,
          onChanged: (value) => _change(intercept: value),
        ),

        if (data.hint != null && !_solved) ...[
          const SizedBox(height: 12),
          Text(
            data.hint!,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
        ],

        // Pure-play steps have nothing to check, so the learner says when they
        // are done exploring.
        if (data.isOpenEnded && !_solved) ...[
          const SizedBox(height: 14),
          FilledButton(
            key: const Key('line-lab-done'),
            onPressed: _interactive ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mint,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'I have explored enough',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _IntSlider extends StatelessWidget {
  const _IntSlider({
    required this.sliderKey,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.accent,
    required this.enabled,
    required this.onChanged,
  });

  final Key sliderKey;
  final String label;
  final int value;
  final int min;
  final int max;
  final Color accent;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                value < 0 ? '−${value.abs()}' : '$value',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            inactiveTrackColor: accent.withValues(alpha: 0.18),
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.15),
            trackHeight: 5,
          ),
          child: Slider(
            key: sliderKey,
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: '$value',
            onChanged:
                enabled ? (raw) => onChanged(raw.round()) : null,
          ),
        ),
      ],
    );
  }
}

/// The live plane. Fixed −6..6 window so the line moves against a stable grid
/// rather than the grid rescaling under it.
class _LinePlane extends StatelessWidget {
  const _LinePlane({required this.slope, required this.intercept});

  final int slope;
  final int intercept;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _LinePainter(slope: slope, intercept: intercept),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.slope, required this.intercept});

  final int slope;
  final int intercept;

  static const int _range = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / (_range * 2);

    Offset toScreen(double x, double y) => Offset(
          (x + _range) * unit,
          // Screen y grows downward; maths y grows upward.
          (_range - y) * unit,
        );

    final grid = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (var i = -_range; i <= _range; i++) {
      canvas.drawLine(
        toScreen(i.toDouble(), -_range.toDouble()),
        toScreen(i.toDouble(), _range.toDouble()),
        grid,
      );
      canvas.drawLine(
        toScreen(-_range.toDouble(), i.toDouble()),
        toScreen(_range.toDouble(), i.toDouble()),
        grid,
      );
    }

    final axis = Paint()
      ..color = AppColors.subtitle
      ..strokeWidth = 2;
    canvas.drawLine(toScreen(-_range.toDouble(), 0), toScreen(_range.toDouble(), 0), axis);
    canvas.drawLine(toScreen(0, -_range.toDouble()), toScreen(0, _range.toDouble()), axis);

    // Clip so a steep line stops at the edge instead of painting over the card.
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final line = Paint()
      ..color = AppColors.pink
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final span = _range.toDouble();
    canvas.drawLine(
      toScreen(-span, slope * -span + intercept),
      toScreen(span, slope * span + intercept),
      line,
    );

    // The y-intercept, marked because it is the thing b controls.
    if (intercept.abs() <= _range) {
      final dot = toScreen(0, intercept.toDouble());
      canvas.drawCircle(dot, 6, Paint()..color = AppColors.purple);
      canvas.drawCircle(
        dot,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.slope != slope || old.intercept != intercept;
}
