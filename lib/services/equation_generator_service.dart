import 'dart:math';
import 'package:algebrix/models/equation_model.dart';

enum DifficultyLevel {
  level1OneStep,    // Solve: x + 3 = 9
  level2OneStep,    // Solve: x + 4 = 10
  level3OneStep,    // Solve: x + 2 = 7
  level4TwoStep,    // Solve: 2x + 2 = 8 (Requires Division)
}

/// Generates progressive "Solve for X" balance scale equations.
class EquationGeneratorService {
  final Random _random = Random();

  EquationModel generateEquation(DifficultyLevel level) {
    final id = 'eq_${DateTime.now().millisecondsSinceEpoch}';

    switch (level) {
      case DifficultyLevel.level1OneStep:
        final a = 3;
        final targetX = 6;
        final b = targetX + a; // 9

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
        final a = _random.nextInt(3) + 2; // 2, 3, 4
        final targetX = _random.nextInt(4) + 4; // 4..7
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
        final a = _random.nextInt(4) + 1; // 1..4
        final targetX = _random.nextInt(5) + 3; // 3..7
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
        final b = (coeffX * targetX) + a; // 8

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
}
