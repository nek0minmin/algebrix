import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/services/sound_service.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// Fill an area model for a polynomial product.
///
/// Tap a cell, then tap the tile that belongs in it. Every cell is one pair of
/// terms multiplied, which is the whole point: the learner can see that each
/// piece of the first bracket meets each piece of the second, before FOIL is
/// ever named.
class AreaModelActivity extends StatefulWidget {
  const AreaModelActivity({
    super.key,
    required this.data,
    required this.onAnswered,
    this.enabled = true,
  });

  final AreaModelActivityData data;
  final Future<void> Function(bool isCorrect) onAnswered;
  final bool enabled;

  @override
  State<AreaModelActivity> createState() => _AreaModelActivityState();
}

class _AreaModelActivityState extends State<AreaModelActivity> {
  late final List<String?> _filled =
      List<String?>.filled(widget.data.cells.length, null);
  int? _activeCell;
  bool _submitting = false;
  bool _solved = false;

  bool get _interactive => widget.enabled && !_submitting && !_solved;

  void _selectCell(int index) {
    if (!_interactive) return;
    SoundService.playTileSelect();
    setState(() {
      // Tapping a filled cell clears it, so a wrong tile is easy to undo.
      if (_filled[index] != null) {
        _filled[index] = null;
        _activeCell = index;
        return;
      }
      _activeCell = _activeCell == index ? null : index;
    });
  }

  Future<void> _placeTile(String value) async {
    if (!_interactive) return;

    // With no cell chosen, drop the tile into the first empty one.
    final target = _activeCell ?? _filled.indexWhere((cell) => cell == null);
    if (target < 0) return;

    SoundService.playTileDrop();
    setState(() {
      _filled[target] = value;
      _activeCell = null;
    });

    if (_filled.any((cell) => cell == null)) return;
    await _submit();
  }

  Future<void> _submit() async {
    var isCorrect = true;
    for (var i = 0; i < widget.data.cells.length; i++) {
      if (_filled[i] != widget.data.cells[i]) {
        isCorrect = false;
        break;
      }
    }

    setState(() => _submitting = true);
    try {
      await widget.onAnswered(isCorrect);
      if (mounted && isCorrect) setState(() => _solved = true);
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
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.lightPurple.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              data.expression,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.purple,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        _Grid(
          data: data,
          filled: _filled,
          activeCell: _activeCell,
          onCellTap: _selectCell,
        ),
        const SizedBox(height: 16),

        if (_solved)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lightMint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.mint),
            ),
            child: Center(
              child: Text(
                data.result,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF12695E),
                ),
              ),
            ),
          )
        else ...[
          Text(
            'Tap a box, then tap the piece that belongs in it.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in data.choices)
                _Tile(
                  label: choice,
                  used: _filled.contains(choice),
                  onTap: () => _placeTile(choice),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.data,
    required this.filled,
    required this.activeCell,
    required this.onCellTap,
  });

  final AreaModelActivityData data;
  final List<String?> filled;
  final int? activeCell;
  final ValueChanged<int> onCellTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Column headers, offset by the row-header column.
        Row(
          children: [
            const SizedBox(width: 44),
            for (final label in data.topLabels)
              Expanded(child: _Header(label: label)),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < data.rows; row++) ...[
          Row(
            children: [
              // Matches _Cell's height so the row label lines up with its row.
              // Stretching instead would demand an unbounded height inside a
              // scrolling lesson step.
              SizedBox(
                width: 44,
                height: 58,
                child: _Header(label: data.sideLabels[row]),
              ),
              for (var col = 0; col < data.columns; col++)
                Expanded(
                  child: _Cell(
                    index: row * data.columns + col,
                    value: filled[row * data.columns + col],
                    isActive: activeCell == row * data.columns + col,
                    onTap: onCellTap,
                  ),
                ),
            ],
          ),
          if (row < data.rows - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.darkPink,
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.index,
    required this.value,
    required this.isActive,
    required this.onTap,
  });

  final int index;
  final String? value;
  final bool isActive;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final filled = value != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        key: Key('area-cell-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.lightMint : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? AppColors.pink
                  : (filled ? AppColors.mint : AppColors.border),
              width: isActive ? 2.5 : 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value ?? '?',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: filled ? const Color(0xFF12695E) : AppColors.subtitle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.used,
    required this.onTap,
  });

  final String label;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Place $label',
      child: BouncyPressable(
        key: Key('area-tile-$label'),
        enableSound: false,
        onTap: onTap,
        child: Opacity(
          opacity: used ? 0.4 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.pink, width: 1.5),
            ),
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.darkPink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
