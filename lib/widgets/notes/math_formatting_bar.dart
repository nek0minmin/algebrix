import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A math chip model representing a quick-insert symbol or structure.
class MathSymbolChip {
  const MathSymbolChip({
    required this.label,
    required this.insertText,
    this.cursorOffsetFromEnd = 0,
    this.tooltip,
    this.isExponent = false,
    this.category,
  });

  final String label;
  final String insertText;
  final int cursorOffsetFromEnd;
  final String? tooltip;
  final bool isExponent;
  final MathPaletteCategory? category;
}

/// Category grouping for the expandable math palette.
enum MathPaletteCategory {
  exponents('Exponents', Icons.superscript_rounded, AppColors.pink, AppColors.extraLightPink),
  variables('Variables', Icons.font_download_rounded, AppColors.purple, AppColors.lightPurple),
  operators('Operators', Icons.calculate_outlined, AppColors.mint, AppColors.lightMint);

  const MathPaletteCategory(
    this.title,
    this.icon,
    this.accentColor,
    this.lightColor,
  );

  final String title;
  final IconData icon;
  final Color accentColor;
  final Color lightColor;
}

/// A tactile horizontal toolbar with compact square chips for exponents, variables,
/// and operators, with a centered and balanced category mini-palette.
class MathFormattingBar extends StatefulWidget {
  const MathFormattingBar({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  State<MathFormattingBar> createState() => _MathFormattingBarState();
}

class _MathFormattingBarState extends State<MathFormattingBar>
    with SingleTickerProviderStateMixin {
  bool _isPaletteExpanded = false;
  MathPaletteCategory _selectedCategory = MathPaletteCategory.exponents;

  // ── Quick Bar 6 High-Frequency Chips ──────────────────────────────────────
  static const List<MathSymbolChip> _quickChips = [
    MathSymbolChip(
      label: 'x²',
      insertText: 'x²',
      tooltip: 'x squared',
      isExponent: true,
      category: MathPaletteCategory.exponents,
    ),
    MathSymbolChip(
      label: 'y²',
      insertText: 'y²',
      tooltip: 'y squared',
      isExponent: true,
      category: MathPaletteCategory.exponents,
    ),
    MathSymbolChip(
      label: 'x',
      insertText: 'x',
      tooltip: 'Variable x',
      category: MathPaletteCategory.variables,
    ),
    MathSymbolChip(
      label: 'y',
      insertText: 'y',
      tooltip: 'Variable y',
      category: MathPaletteCategory.variables,
    ),
    MathSymbolChip(
      label: '+',
      insertText: ' + ',
      tooltip: 'Plus',
      category: MathPaletteCategory.operators,
    ),
    MathSymbolChip(
      label: '=',
      insertText: ' = ',
      tooltip: 'Equals',
      category: MathPaletteCategory.operators,
    ),
  ];

  // ── Categorized Palette Chips (Small Square Tiles) ─────────────────────────
  static const Map<MathPaletteCategory, List<MathSymbolChip>> _categoryChips = {
    MathPaletteCategory.exponents: [
      MathSymbolChip(label: 'x²', insertText: 'x²', tooltip: 'x squared', isExponent: true),
      MathSymbolChip(label: 'y²', insertText: 'y²', tooltip: 'y squared', isExponent: true),
      MathSymbolChip(label: 'x³', insertText: 'x³', tooltip: 'x cubed', isExponent: true),
      MathSymbolChip(label: 'xⁿ', insertText: 'xⁿ', tooltip: 'x to the n', isExponent: true),
      MathSymbolChip(label: '²', insertText: '²', tooltip: 'Exponent 2', isExponent: true),
      MathSymbolChip(label: '³', insertText: '³', tooltip: 'Exponent 3', isExponent: true),
      MathSymbolChip(label: 'ⁿ', insertText: 'ⁿ', tooltip: 'Exponent n', isExponent: true),
      MathSymbolChip(label: '()²', insertText: '()²', cursorOffsetFromEnd: 2, tooltip: 'Squared group', isExponent: true),
    ],
    MathPaletteCategory.variables: [
      MathSymbolChip(label: 'x', insertText: 'x'),
      MathSymbolChip(label: 'y', insertText: 'y'),
      MathSymbolChip(label: 'z', insertText: 'z'),
      MathSymbolChip(label: 'a', insertText: 'a'),
      MathSymbolChip(label: 'b', insertText: 'b'),
      MathSymbolChip(label: 'c', insertText: 'c'),
      MathSymbolChip(label: 'n', insertText: 'n'),
    ],
    MathPaletteCategory.operators: [
      MathSymbolChip(label: '=', insertText: ' = '),
      MathSymbolChip(label: '+', insertText: ' + '),
      MathSymbolChip(label: '−', insertText: ' − '),
      MathSymbolChip(label: '×', insertText: ' × '),
      MathSymbolChip(label: '÷', insertText: ' ÷ '),
      MathSymbolChip(label: '±', insertText: ' ± '),
      MathSymbolChip(label: '≠', insertText: ' ≠ '),
      MathSymbolChip(label: '≤', insertText: ' ≤ '),
      MathSymbolChip(label: '≥', insertText: ' ≥ '),
      MathSymbolChip(label: '≈', insertText: ' ≈ '),
      MathSymbolChip(label: '<', insertText: ' < '),
      MathSymbolChip(label: '>', insertText: ' > '),
    ],
  };

  void _insertChip(MathSymbolChip chip) {
    if (!widget.enabled) return;

    final controller = widget.controller;
    final value = controller.value;
    final selection = value.selection;
    final text = value.text;

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final hasSelection = selection.isValid && start != end;

    String replacement = chip.insertText;
    int cursorOffset = chip.cursorOffsetFromEnd;

    // Smart exponent wrap/append if user has highlighted text
    if (hasSelection) {
      final selectedText = text.substring(start, end);
      if (chip.isExponent) {
        if (chip.label == '²' || chip.label == '³' || chip.label == 'ⁿ') {
          replacement = '$selectedText${chip.label}';
          cursorOffset = 0;
        } else if (chip.label == '()²') {
          replacement = '($selectedText)²';
          cursorOffset = 0;
        }
      }
    }

    final newText = text.replaceRange(start, end, replacement);
    final nextCursor = (start + replacement.length - cursorOffset).clamp(0, newText.length);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: nextCursor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isPaletteExpanded
              ? AppColors.pink.withValues(alpha: 0.5)
              : AppColors.border,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Quick-Access Bar (Horizontal Scroll) ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Math icon header badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.extraLightPink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.functions_rounded,
                        color: AppColors.darkPink,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MATH',
                        style: GoogleFonts.nunito(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkPink,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Horizontal scrollable quick chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _quickChips.map((chip) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _MathChipButton(
                            chip: chip,
                            enabled: widget.enabled,
                            onTap: () => _insertChip(chip),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Expand / Collapse Palette Toggle Button (More / Less)
                BouncyPressable(
                  shrinkFactor: 0.9,
                  enableHaptics: true,
                  onTap: () {
                    setState(() {
                      _isPaletteExpanded = !_isPaletteExpanded;
                    });
                  },
                  child: Container(
                    key: const Key('math-palette-toggle-button'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isPaletteExpanded
                          ? AppColors.pink
                          : AppColors.lightPurple,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isPaletteExpanded
                            ? AppColors.pink
                            : AppColors.purple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPaletteExpanded
                              ? Icons.expand_less_rounded
                              : Icons.grid_view_rounded,
                          size: 14,
                          color: _isPaletteExpanded
                              ? Colors.white
                              : AppColors.purple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isPaletteExpanded ? 'Less' : 'More',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _isPaletteExpanded
                                ? Colors.white
                                : AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Expandable Categorized Mini-Palette (Centered Small Squares) ───
          if (_isPaletteExpanded) ...[
            const Divider(color: AppColors.divider, height: 1),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(17),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Category Tabs (Exponents, Variables, Operators) - Centered
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: MathPaletteCategory.values.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: BouncyPressable(
                            shrinkFactor: 0.94,
                            enableHaptics: true,
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                            },
                            child: Container(
                              key: Key('math-cat-${cat.name}'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cat.accentColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? cat.accentColor
                                      : AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    cat.icon,
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : cat.accentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat.title,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Symmetrical Centered Small Squares Grid for Current Category
                  Center(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: (_categoryChips[_selectedCategory] ?? [])
                          .map((chip) {
                        return _MathChipButton(
                          chip: chip,
                          enabled: widget.enabled,
                          accentColor: _selectedCategory.accentColor,
                          lightColor: _selectedCategory.lightColor,
                          onTap: () => _insertChip(chip),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// An individual tactile math chip button rendered strictly as a compact small square.
class _MathChipButton extends StatelessWidget {
  const _MathChipButton({
    required this.chip,
    required this.enabled,
    required this.onTap,
    this.accentColor,
    this.lightColor,
  });

  final MathSymbolChip chip;
  final bool enabled;
  final VoidCallback onTap;
  final Color? accentColor;
  final Color? lightColor;

  @override
  Widget build(BuildContext context) {
    final effectiveCategory = chip.category ?? (chip.isExponent ? MathPaletteCategory.exponents : MathPaletteCategory.variables);
    final effectiveAccent = accentColor ?? effectiveCategory.accentColor;
    final effectiveLight = lightColor ?? effectiveCategory.lightColor;

    return BouncyPressable(
      shrinkFactor: 0.9,
      enableHaptics: true,
      onTap: enabled ? onTap : null,
      child: Tooltip(
        message: chip.tooltip ?? chip.label,
        child: SizedBox(
          width: 44,
          height: 42,
          child: Container(
            key: Key('math-chip-${chip.label.trim()}'),
            decoration: BoxDecoration(
              color: effectiveLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: effectiveAccent.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              chip.label,
              style: GoogleFonts.nunito(
                fontSize: chip.isExponent ? 14.5 : 14,
                fontWeight: FontWeight.w900,
                color: effectiveAccent,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
