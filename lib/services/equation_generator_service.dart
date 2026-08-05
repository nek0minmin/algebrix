import 'dart:math';
import 'package:algebrix/models/equation_model.dart';

enum DifficultyLevel {
  level1OneStep,    // Solve: x + 3 = 9
  level2OneStep,    // Solve: x + 4 = 10
  level3OneStep,    // Solve: x + 2 = 7
  level4TwoStep,    // Solve: 2x + 2 = 8
}

class ActionOptionData {
  final int value;
  final String label;
  final bool isDivision;

  const ActionOptionData({
    required this.value,
    required this.label,
    this.isDivision = false,
  });
}

class EquationGeneratorService {
  final Random _random = Random();

  EquationModel generateEquation(DifficultyLevel level) {
    final id = 'eq_${DateTime.now().millisecondsSinceEpoch}';

    switch (level) {
      case DifficultyLevel.level1OneStep:
        final a = 3;
        final targetX = 6;
        final b = targetX + a;

        return EquationModel(
          id: id,
          equationText: 'x + $a = $b',
          initialLeftVariables: 1,
          initialLeftUnits: a,
          initialRightVariables: 0,
          initialRightUnits: b,
          targetXValue: targetX,
          leftVariables: 1,
          leftUnits: a,
          rightVariables: 0,
          rightUnits: b,
        );

      case DifficultyLevel.level2OneStep:
        final a = 4;
        final targetX = 6;
        final b = targetX + a;

        return EquationModel(
          id: id,
          equationText: 'x + $a = $b',
          initialLeftVariables: 1,
          initialLeftUnits: a,
          initialRightVariables: 0,
          initialRightUnits: b,
          targetXValue: targetX,
          leftVariables: 1,
          leftUnits: a,
          rightVariables: 0,
          rightUnits: b,
        );

      case DifficultyLevel.level3OneStep:
        final a = 2;
        final targetX = 5;
        final b = targetX + a;

        return EquationModel(
          id: id,
          equationText: 'x + $a = $b',
          initialLeftVariables: 1,
          initialLeftUnits: a,
          initialRightVariables: 0,
          initialRightUnits: b,
          targetXValue: targetX,
          leftVariables: 1,
          leftUnits: a,
          rightVariables: 0,
          rightUnits: b,
        );

      case DifficultyLevel.level4TwoStep:
        final coeffX = 2;
        final a = 2;
        final targetX = 3;
        final b = (coeffX * targetX) + a;

        return EquationModel(
          id: id,
          equationText: '${coeffX}x + $a = $b',
          initialLeftVariables: coeffX,
          initialLeftUnits: a,
          initialRightVariables: 0,
          initialRightUnits: b,
          targetXValue: targetX,
          leftVariables: coeffX,
          leftUnits: a,
          rightVariables: 0,
          rightUnits: b,
        );
    }
  }

  /// Generate 5 clean, distinct options to keep the UI minimal & un-cluttered.
  List<ActionOptionData> generateActionPaletteOptions(EquationModel equation) {
    final targetSub = equation.initialLeftUnits;

    final options = <ActionOptionData>[
      ActionOptionData(value: -targetSub, label: '- $targetSub'), // Correct
      ActionOptionData(value: targetSub, label: '+ $targetSub'),  // Distractor
      const ActionOptionData(value: -1, label: '- 1'),
      const ActionOptionData(value: 1, label: '+ 1'),
    ];

    if (equation.leftVariables > 1) {
      options.add(ActionOptionData(
        value: equation.leftVariables,
        label: '÷ ${equation.leftVariables}',
        isDivision: true,
      ));
    } else {
      options.add(const ActionOptionData(value: -2, label: '- 2'));
    }

    options.shuffle(_random);
    return options;
  }
}
