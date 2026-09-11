import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/services/sound_service.dart';

/// Algebra tiles: polynomials as physical pieces.
///
/// The learner sets the rectangle's two sides, and the workspace lays out the
/// tiles those sides produce — one `x²` square, a row and column of `x` strips,
/// and a block of units. When the rectangle matches the target, the sides and
/// the area are the factorisation and the expansion of the same thing.
///
/// BUILD starts from the factors and asks what the rectangle holds.
/// FACTOR starts from the trinomial and asks what sides make it.
/// Same workspace, read in the two directions 6.4 and 6.5 teach.
class AlgebraTilesActivity extends StatefulWidget {
  const AlgebraTilesActivity({
    super.key,
    required this.data,
    required this.onAnswered,
    this.enabled = true,
  });

  final AlgebraTilesActivityData data;
  final Future<void> Function(bool isCorrect) onAnswered;
  final bool enabled;

  @override
  State<AlgebraTilesActivity> createState() => _AlgebraTilesActivityState();
}

class _AlgebraTilesActivityState extends State<AlgebraTilesActivity> {
  int _width = 0;
  int _height = 0;
  bool _solved = false;
  bool _submitting = false;
  bool _checkedOnce = false;

  bool get _interactive => widget.enabled && !_submitting && !_solved;

  /// Sides match the target either way round — a rectangle does not care which
  /// side you call the width.
  bool get _isCorrect {
    final p = widget.data.factorP;
    final q = widget.data.factorQ;
    return (_width == p && _height == q) || (_width == q && _height == p);
  }

  void _adjust({int? width, int? height}) {
    if (!_interactive) return;
    final max = widget.data.maxSide;

    setState(() {
      if (width != null) _width = width.clamp(0, max);
      if (height != null) _height = height.clamp(0, max);
      _checkedOnce = false;
    });
    SoundService.playTileSelect();
  }

  Future<void> _check() async {
    if (!_interactive) return;

    final correct = _isCorrect;
    setState(() {
      _submitting = true;
      _checkedOnce = true;
    });
    SoundService.playTileDrop();

    try {
      await widget.onAnswered(correct);
      if (mounted && correct) setState(() => _solved = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final xCount = _width + _height;
    final unitCount = _width * _height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.lightPurple.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                data.mode == AlgebraTilesMode.build ? 'BUILD' : 'FACTOR',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.purple,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.prompt,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _TileRectangle(width: _width, height: _height, solved: _solved),
        const SizedBox(height: 12),

        _TileTally(
          squares: 1,
          strips: xCount,
          units: unitCount,
        ),
        const SizedBox(height: 14),

        _SideStepper(
          stepperKey: 'width',
          label: 'Across',
          value: _width,
          max: data.maxSide,
          accent: AppColors.pink,
          enabled: _interactive,
          onChanged: (value) => _adjust(width: value),
        ),
        const SizedBox(height: 8),
        _SideStepper(
          stepperKey: 'height',
          label: 'Down',
          value: _height,
          max: data.maxSide,
          accent: AppColors.purple,
          enabled: _interactive,
          onChanged: (value) => _adjust(height: value),
        ),
        const SizedBox(height: 14),

        if (_solved)
          Container(
            key: const Key('tiles-result'),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.lightMint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.mint),
            ),
            child: Column(
              children: [
                Text(
                  data.factoredLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF12695E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '=  ${data.expandedLabel}',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF12695E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The sides and the area describe the same rectangle.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else ...[
          FilledButton(
            key: const Key('tiles-check'),
            onPressed: _interactive ? _check : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.pink,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Check the rectangle',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          if (_checkedOnce && !_isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              'Not this one — adjust a side and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.subtitle,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// The workspace itself: one x² square, x strips along two edges, units in the
/// corner. Laid out as a real rectangle so the sides are visible lengths.
class _TileRectangle extends StatelessWidget {
  const _TileRectangle({
    required this.width,
    required this.height,
    required this.solved,
  });

  final int width;
  final int height;
  final bool solved;

  static const double _squareSide = 54;
  static const double _unitSide = 18;
  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: solved ? AppColors.lightMint.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: solved ? AppColors.mint : AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: the x² square, then one x strip per unit of width.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Tile(
                  label: 'x²',
                  width: _squareSide,
                  height: _squareSide,
                  color: AppColors.lightPurple,
                  border: AppColors.purple,
                ),
                for (var i = 0; i < width; i++) ...[
                  const SizedBox(width: _gap),
                  _Tile(
                    label: 'x',
                    width: _unitSide,
                    height: _squareSide,
                    color: AppColors.extraLightPink,
                    border: AppColors.pink,
                  ),
                ],
              ],
            ),
            // Then one row per unit of height: an x strip, then the units.
            for (var row = 0; row < height; row++) ...[
              const SizedBox(height: _gap),
              Row(
                children: [
                  _Tile(
                    label: 'x',
                    width: _squareSide,
                    height: _unitSide,
                    color: AppColors.extraLightPink,
                    border: AppColors.pink,
                  ),
                  for (var col = 0; col < width; col++) ...[
                    const SizedBox(width: _gap),
                    _Tile(
                      label: '',
                      width: _unitSide,
                      height: _unitSide,
                      color: AppColors.lightYellow,
                      border: AppColors.yellow,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.width,
    required this.height,
    required this.color,
    required this.border,
  });

  final String label;
  final double width;
  final double height;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border, width: 1.4),
      ),
      child: label.isEmpty
          ? null
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ),
    );
  }
}

/// Reads the workspace back as an expression, so the picture and the algebra
/// stay side by side while the learner adjusts.
class _TileTally extends StatelessWidget {
  const _TileTally({
    required this.squares,
    required this.strips,
    required this.units,
  });

  final int squares;
  final int strips;
  final int units;

  @override
  Widget build(BuildContext context) {
    final middle = strips == 1 ? 'x' : '${strips}x';

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _TallyChip(
              label: '$squares × x²',
              color: AppColors.purple,
              background: AppColors.lightPurple,
            ),
            _TallyChip(
              label: '$strips × x',
              color: AppColors.darkPink,
              background: AppColors.extraLightPink,
            ),
            _TallyChip(
              label: '$units × 1',
              color: const Color(0xFF8A6A12),
              background: AppColors.lightYellow,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          key: const Key('tiles-expression'),
          strips == 0 && units == 0 ? 'x²' : 'x² + $middle + $units',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _TallyChip extends StatelessWidget {
  const _TallyChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _SideStepper extends StatelessWidget {
  const _SideStepper({
    required this.stepperKey,
    required this.label,
    required this.value,
    required this.max,
    required this.accent,
    required this.enabled,
    required this.onChanged,
  });

  final String stepperKey;
  final String label;
  final int value;
  final int max;
  final Color accent;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label:  x + $value',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        _StepButton(
          buttonKey: Key('tiles-$stepperKey-minus'),
          icon: Icons.remove_rounded,
          accent: accent,
          enabled: enabled && value > 0,
          onTap: () => onChanged(value - 1),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(
            '$value',
            key: Key('tiles-$stepperKey-value'),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _StepButton(
          buttonKey: Key('tiles-$stepperKey-plus'),
          icon: Icons.add_rounded,
          accent: accent,
          enabled: enabled && value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.buttonKey,
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final Key buttonKey;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled ? accent.withValues(alpha: 0.12) : AppColors.divider,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? accent : AppColors.navInactive,
        ),
      ),
    );
  }
}
