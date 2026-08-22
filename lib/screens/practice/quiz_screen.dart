import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/models/equation_model.dart';
import 'package:algebrix/services/equation_generator_service.dart';
import 'package:algebrix/services/ai_service.dart';
import 'package:algebrix/widgets/balance_scale_widget.dart';
import 'package:algebrix/widgets/draggable_action_chip.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/page_headers.dart';

/// Minimalist Balance Scale Screen supporting Drag & Drop on Left Pan, Right Pan, or Center Pivot.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final EquationGeneratorService _generator = EquationGeneratorService();
  final AiService _aiService = AiService();

  DifficultyLevel _currentLevel = DifficultyLevel.level1OneStep;
  late EquationModel _equation;
  late List<ActionOptionData> _paletteOptions;
  int _movesUsed = 0;
  static const int _targetMovesMax = 2;

  String _xyMessage = "";

  @override
  void initState() {
    super.initState();
    _loadNextEquation();
  }

  void _loadNextEquation() {
    setState(() {
      _equation = _generator.generateEquation(_currentLevel);
      _paletteOptions = _generator.generateActionPaletteOptions(_equation);
      _movesUsed = 0;
      _updateXyAdvice();
    });
  }

  void _updateXyAdvice() {
    final advice = _aiService.generateXyAdvice(equation: _equation);
    setState(() => _xyMessage = advice);
  }

  void _handleDropOnCenter(DragChipData data) {
    if (_equation.isSolved) return;

    final val = data.value;
    final isDivision = data.isDivision;

    setState(() {
      _movesUsed++;
      if (isDivision) {
        final div = val.abs();
        if (div > 1) {
          _equation = _equation.copyWith(
            leftVariables: (_equation.leftVariables ~/ div).clamp(1, 10),
            leftUnits: _equation.leftUnits ~/ div,
            rightVariables: _equation.rightVariables ~/ div,
            rightUnits: _equation.rightUnits ~/ div,
          );
        }
      } else {
        final newLeftUnits = (_equation.leftUnits + val).clamp(0, 30);
        final newRightUnits = (_equation.rightUnits + val).clamp(0, 30);
        _equation = _equation.copyWith(
          leftUnits: newLeftUnits,
          rightUnits: newRightUnits,
        );
      }
      _updateXyAdvice();
    });
  }

  void _handleDropOnLeft(DragChipData data) {
    if (_equation.isSolved) return;

    final val = data.value;
    setState(() {
      _movesUsed++;
      final newLeftUnits = (_equation.leftUnits + val).clamp(0, 30);
      _equation = _equation.copyWith(leftUnits: newLeftUnits);
      _updateXyAdvice();
    });
  }

  void _handleDropOnRight(DragChipData data) {
    if (_equation.isSolved) return;

    final val = data.value;
    setState(() {
      _movesUsed++;
      final newRightUnits = (_equation.rightUnits + val).clamp(0, 30);
      _equation = _equation.copyWith(rightUnits: newRightUnits);
      _updateXyAdvice();
    });
  }

  void _changeLevel(DifficultyLevel level) {
    setState(() {
      _currentLevel = level;
      _loadNextEquation();
    });
  }

  int get _starRating {
    if (_movesUsed <= 2) return 3;
    if (_movesUsed <= 4) return 2;
    return 1;
  }

  String _getLevelName(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.level1OneStep:
        return 'x + 3 = 9';
      case DifficultyLevel.level2OneStep:
        return 'x + 4 = 10';
      case DifficultyLevel.level3OneStep:
        return 'x + 2 = 7';
      case DifficultyLevel.level4TwoStep:
        return '2x + 2 = 8';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSolved = _equation.isSolved;
    final isBalanced = _equation.isBalanced;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RootPageHeader(
            title: 'Practice',
            subtitle: 'Solve one step at a time.',
            mascotAsset: AppAssets.xyQuestion,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Clean Header ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Solve: ',
                          style: AppTextStyles.subtitle1.copyWith(fontSize: 15),
                        ),
                        Text(
                          _equation.equationText,
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.darkPink,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSolved
                            ? AppColors.lightMint
                            : (isBalanced
                                  ? AppColors.lightYellow
                                  : AppColors.extraLightPink),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSolved
                              ? AppColors.success
                              : (isBalanced
                                    ? AppColors.yellow
                                    : AppColors.darkPink),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        isSolved
                            ? 'x = ${_equation.targetXValue} 🎉'
                            : (isBalanced ? 'Balanced ✨' : 'Tilted ⚖️'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSolved
                              ? AppColors.success
                              : (isBalanced
                                    ? const Color(0xFFB78103)
                                    : AppColors.darkPink),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── Minimal Level Filter Bar ──────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: DifficultyLevel.values.map((level) {
                      final isSelected = level == _currentLevel;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(_getLevelName(level)),
                          selected: isSelected,
                          onSelected: (_) => _changeLevel(level),
                          selectedColor: AppColors.pink,
                          backgroundColor: AppColors.extraLightPink,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Interactive Drag & Drop Balance Scale Visualizer ───────────────
                BalanceScaleWidget(
                  equation: _equation,
                  onDropOnCenterFulcrum: _handleDropOnCenter,
                  onDropOnLeftPan: _handleDropOnLeft,
                  onDropOnRightPan: _handleDropOnRight,
                ),
                const SizedBox(height: 8),

                // ── Victory Card when Solved ───────────────────────────────────────
                if (isSolved) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightMint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.success, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '✨ YOU DISCOVERED X = ${_equation.targetXValue} ✨',
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 20,
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Solved in $_movesUsed moves! (${'⭐' * _starRating})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F7263),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Next problem',
                    onPressed: _loadNextEquation,
                  ),
                ] else ...[
                  _PracticeHint(message: _xyMessage, isBalanced: isBalanced),
                  const SizedBox(height: 10),

                  // ── Clean 5-Item Action Chips Palette ───────────────────────────
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _paletteOptions.map((opt) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: DraggableActionChip(
                              value: opt.value,
                              label: opt.label,
                              isDivision: opt.isDivision,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: TextButton.icon(
                      onPressed: _loadNextEquation,
                      icon: const Icon(
                        Icons.refresh,
                        size: 16,
                        color: AppColors.purple,
                      ),
                      label: Text(
                        'Reset Scale (Moves: $_movesUsed / $_targetMovesMax)',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeHint extends StatelessWidget {
  const _PracticeHint({required this.message, required this.isBalanced});

  final String message;
  final bool isBalanced;

  @override
  Widget build(BuildContext context) {
    final accent = isBalanced ? AppColors.mint : AppColors.purple;
    final surface = isBalanced ? AppColors.lightMint : AppColors.lightPurple;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
            child: Icon(
              isBalanced
                  ? Icons.balance_rounded
                  : Icons.tips_and_updates_outlined,
              color: accent,
              size: 21,
              semanticLabel: isBalanced ? 'Balance hint' : 'Practice hint',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
