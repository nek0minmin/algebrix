import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/equation_model.dart';
import 'package:algebrix/services/equation_generator_service.dart';
import 'package:algebrix/services/ai_service.dart';
import 'package:algebrix/widgets/balance_scale_widget.dart';
import 'package:algebrix/widgets/xy_dialog.dart';
import 'package:algebrix/widgets/primary_button.dart';

/// Anti-Spamming Conceptual Balance Scale Screen with Strategic Moves & Reflection Checkpoint.
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
  int _moves = 0;
  String _xyMessage = "";
  
  // Anti-spamming reflection state
  ReflectionQuestion? _currentReflection;
  int? _selectedReflectionIndex;
  bool _showReflectionModal = false;
  bool _isReflectionPassed = false;

  @override
  void initState() {
    super.initState();
    _loadNextEquation();
  }

  void _loadNextEquation() {
    setState(() {
      _equation = _generator.generateEquation(_currentLevel);
      _moves = 0;
      _showReflectionModal = false;
      _selectedReflectionIndex = null;
      _isReflectionPassed = false;
      _currentReflection = null;
      _updateXyAdvice();
    });
  }

  void _updateXyAdvice() {
    final advice = _aiService.generateXyAdvice(equation: _equation);
    setState(() => _xyMessage = advice);

    if (_equation.isSolved && !_isReflectionPassed && _currentReflection == null) {
      _currentReflection = _aiService.generateReflectionQuestion(_equation);
      _showReflectionModal = true;
    }
  }

  void _applyStrategicOperation({required int deltaUnits, required int divisor}) {
    if (_equation.isSolved) return;

    setState(() {
      _moves++;
      if (divisor > 1) {
        _equation = _equation.copyWith(
          leftVariables: (_equation.leftVariables ~/ divisor).clamp(1, 10),
          leftUnits: _equation.leftUnits ~/ divisor,
          rightVariables: _equation.rightVariables ~/ divisor,
          rightUnits: _equation.rightUnits ~/ divisor,
        );
      } else if (deltaUnits != 0) {
        final newLeftUnits = (_equation.leftUnits + deltaUnits).clamp(0, 30);
        final newRightUnits = (_equation.rightUnits + deltaUnits).clamp(0, 30);
        _equation = _equation.copyWith(
          leftUnits: newLeftUnits,
          rightUnits: newRightUnits,
        );
      }
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
    if (_moves <= 2) return 3;
    if (_moves <= 4) return 2;
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
        return '2x + 2 = 8 (2-Step)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSolved = _equation.isSolved;
    final isBalanced = _equation.isBalanced;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Bar: Mode & Move Efficiency Meter ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conceptual Balance',
                    style: AppTextStyles.heading3.copyWith(fontSize: 18),
                  ),
                  Text(
                    'Strategic Moves: $_moves  (${'⭐' * _starRating})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _moves <= 2 ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightYellow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.yellow, width: 1.2),
                ),
                child: Row(
                  children: const [
                    Text('🔥', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 4),
                    Text(
                      '12 Streak',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Level Selector Chips ──────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DifficultyLevel.values.map((level) {
                final isSelected = level == _currentLevel;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    label: Text(_getLevelName(level)),
                    selected: isSelected,
                    onSelected: (_) => _changeLevel(level),
                    selectedColor: AppColors.pink,
                    backgroundColor: AppColors.extraLightPink,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSelected ? AppColors.darkPink : AppColors.lightPink,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // ── Target Goal Banner ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              gradient: AppColors.splashGradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSolved ? AppColors.success : (isBalanced ? AppColors.lightPink : AppColors.error),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🔍 ', style: TextStyle(fontSize: 16)),
                    Text(
                      'Solve: ',
                      style: AppTextStyles.subtitle2.copyWith(fontSize: 13),
                    ),
                    Text(
                      _equation.equationText,
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.darkPink,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSolved
                        ? AppColors.lightMint
                        : (isBalanced ? AppColors.lightYellow : AppColors.extraLightPink),
                    borderRadius: BorderRadius.circular(10),
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
                          : (isBalanced ? const Color(0xFFB78103) : AppColors.darkPink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Interactive Balance Scale Visualizer ───────────────────────────
          BalanceScaleWidget(equation: _equation),
          const SizedBox(height: 10),

          // ── Mascot Xy Advice Card ──────────────────────────────────────────
          XyDialog(
            message: _xyMessage,
            xyAsset: isSolved
                ? AppAssets.xyHappy
                : isBalanced
                    ? AppAssets.xyPointing
                    : AppAssets.xyExplaining,
          ),
          const SizedBox(height: 12),

          // ── anti-spamming Reflection Challenge Modal (When scale is solved) ──
          if (_showReflectionModal && _currentReflection != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightPurple,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.purple, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('💡 ', style: TextStyle(fontSize: 16)),
                      Text(
                        'Conceptual Checkpoint: Why did it work?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A349C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentReflection!.question,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_currentReflection!.options.length, (idx) {
                    final isSelected = _selectedReflectionIndex == idx;
                    final isCorrect = idx == _currentReflection!.correctIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedReflectionIndex = idx;
                            if (isCorrect) {
                              _isReflectionPassed = true;
                            }
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isCorrect ? AppColors.lightMint : AppColors.extraLightPink)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? (isCorrect ? AppColors.success : AppColors.error)
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            _currentReflection!.options[idx],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? (isCorrect ? AppColors.success : AppColors.error)
                                  : AppColors.text,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_isReflectionPassed) ...[
                    const SizedBox(height: 6),
                    Text(
                      '✅ Correct! ${_currentReflection!.explanation}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Strategic Operation Selector Buttons (No raw +1/-1 button spam!) ──
          if (!isSolved) ...[
            Text(
              'Select Strategic Operation on BOTH sides:',
              style: AppTextStyles.heading3.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 6),

            Column(
              children: [
                // Strategy 1: Subtract units
                if (_equation.leftUnits > 0)
                  _StrategyCardButton(
                    label: '➖ Subtract ${_equation.leftUnits} from BOTH sides',
                    subtext: 'Isolates X by eliminating unit blocks on the left',
                    color: AppColors.pink,
                    onPressed: () => _applyStrategicOperation(
                      deltaUnits: -_equation.leftUnits,
                      divisor: 1,
                    ),
                  ),

                // Strategy 2: Divide by coefficient (if 2X or 3X)
                if (_equation.leftVariables > 1 && _equation.leftUnits == 0)
                  _StrategyCardButton(
                    label: '➗ Divide BOTH sides by ${_equation.leftVariables}',
                    subtext: 'Scales ${_equation.leftVariables}X down to 1 single X',
                    color: AppColors.purple,
                    onPressed: () => _applyStrategicOperation(
                      deltaUnits: 0,
                      divisor: _equation.leftVariables,
                    ),
                  ),

                // Distractor 1: Add units (Incorrect strategic direction)
                _StrategyCardButton(
                  label: '➕ Add ${_equation.initialLeftUnits} to BOTH sides',
                  subtext: 'Adds more weight to both scale pans',
                  color: AppColors.lightMint,
                  textColor: const Color(0xFF0F7263),
                  onPressed: () => _applyStrategicOperation(
                    deltaUnits: _equation.initialLeftUnits,
                    divisor: 1,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // ── Victory & Reset Controls ─────────────────────────────────────
          if (isSolved && _isReflectionPassed)
            PrimaryButton(
              label: 'Claim +15 XP (${'⭐' * _starRating}) & Next Problem',
              onPressed: _loadNextEquation,
            )
          else if (!isSolved)
            OutlinedButton(
              onPressed: _loadNextEquation,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                side: const BorderSide(color: AppColors.purple, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Reset Strategy (Moves: $_moves)',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.purple,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Full strategic operation selection card button.
class _StrategyCardButton extends StatelessWidget {
  final String label;
  final String subtext;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _StrategyCardButton({
    required this.label,
    required this.subtext,
    required this.color,
    this.textColor = Colors.white,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: textColor),
          ],
        ),
      ),
    );
  }
}
