/// Represents an equation balance scale problem where the student isolates X to discover its value.
class EquationModel {
  final String id;
  final String equationText; // e.g. "x + 3 = 9"
  final int initialLeftVariables;
  final int initialLeftUnits;
  final int initialRightVariables;
  final int initialRightUnits;
  final int targetXValue; // Solution e.g. 6

  int leftVariables;
  int leftUnits;
  int rightVariables;
  int rightUnits;

  EquationModel({
    required this.id,
    required this.equationText,
    required this.initialLeftVariables,
    required this.initialLeftUnits,
    required this.initialRightVariables,
    required this.initialRightUnits,
    required this.targetXValue,
    required this.leftVariables,
    required this.leftUnits,
    required this.rightVariables,
    required this.rightUnits,
  });

  /// Total numerical weight on left pan assuming X = targetXValue
  int get leftWeight => (leftVariables * targetXValue) + leftUnits;

  /// Total numerical weight on right pan assuming X = targetXValue
  int get rightWeight => (rightVariables * targetXValue) + rightUnits;

  /// Difference (Right - Left weight). 0 = level, >0 = right down, <0 = left down
  int get weightDifference => rightWeight - leftWeight;

  /// Scale is balanced when left weight equals right weight
  bool get isBalanced => weightDifference == 0;

  /// X is isolated when left has 1 X and 0 units (or right has 1 X and 0 units)
  bool get isXIsolated {
    return (leftVariables == 1 && leftUnits == 0 && rightVariables == 0) ||
           (rightVariables == 1 && rightUnits == 0 && leftVariables == 0);
  }

  /// Problem is SOLVED when X is isolated AND scale is balanced!
  bool get isSolved => isBalanced && isXIsolated;

  /// Scale tilt angle in radians (-0.22 to +0.22 radians => ~12.5 degrees tilt for obvious visibility!)
  double get tiltAngle {
    if (weightDifference == 0) return 0.0;
    // Visibly tilt left or right depending on weight difference
    final diff = weightDifference.clamp(-5, 5);
    return (diff * 0.045);
  }

  EquationModel copyWith({
    int? leftVariables,
    int? leftUnits,
    int? rightVariables,
    int? rightUnits,
  }) {
    return EquationModel(
      id: id,
      equationText: equationText,
      initialLeftVariables: initialLeftVariables,
      initialLeftUnits: initialLeftUnits,
      initialRightVariables: initialRightVariables,
      initialRightUnits: initialRightUnits,
      targetXValue: targetXValue,
      leftVariables: leftVariables ?? this.leftVariables,
      leftUnits: leftUnits ?? this.leftUnits,
      rightVariables: rightVariables ?? this.rightVariables,
      rightUnits: rightUnits ?? this.rightUnits,
    );
  }

  factory EquationModel.sampleTwoStep() {
    return EquationModel(
      id: 'eq_two_step',
      equationText: '2x + 2 = 8',
      initialLeftVariables: 2,
      initialLeftUnits: 2,
      initialRightVariables: 0,
      initialRightUnits: 8,
      targetXValue: 3,
      leftVariables: 2,
      leftUnits: 2,
      rightVariables: 0,
      rightUnits: 8,
    );
  }
}
