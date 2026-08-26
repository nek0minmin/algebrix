/// Data models for Pairadise — The Land of Relationships (Systems of Equations).
///
/// Each [PairadiseProblem] defines a level's equations, solution pair,
/// candidate values/pairs, and scoring parameters.
library;

/// The gameplay mechanic used for a specific level.
///
/// Mechanics evolve across levels to progressively teach systems of equations:
/// - [discovery]: Drag values into x/y slots and test pairs (L1–2)
/// - [elimination]: Cross out impossible candidate pairs (L3–4)
/// - [substitution]: Drag an expression onto a variable to substitute (L5–7)
/// - [cancelation]: Stack equations and cancel matching terms (L8–9)
/// - [freeChoice]: Player chooses their own solving strategy (L10)
enum PairadiseMechanic {
  discovery,
  elimination,
  substitution,
  cancelation,
  freeChoice,
}

/// A candidate pair for elimination-type levels.
class CandidatePair {
  const CandidatePair({required this.x, required this.y});

  final int x;
  final int y;

  @override
  String toString() => '($x, $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandidatePair && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Problem definition for a single Pairadise level.
///
/// Contains two equation clues, the solution pair, candidate values or pairs
/// (depending on the mechanic), scoring parameters, and reasoning check data.
class PairadiseProblem {
  const PairadiseProblem({
    required this.id,
    required this.levelNumber,
    required this.mechanic,
    required this.clue1,
    required this.clue2,
    required this.solutionX,
    required this.solutionY,
    this.candidateValues = const [],
    this.candidatePairs = const [],
    required this.optimalMoves,
    this.hasReasoningCheckpoint = false,
    this.reasoningQuestion,
    this.reasoningOptions = const [],
    this.correctReasoningIndex = 0,
    required this.introDialogue,
    required this.hintDialogue,
  });

  /// Unique identifier for this problem.
  final String id;

  /// Level number within Pairadise (1–10).
  final int levelNumber;

  /// The gameplay mechanic used for this level.
  final PairadiseMechanic mechanic;

  /// First equation clue, e.g. "x + y = 10".
  final String clue1;

  /// Second equation clue, e.g. "x - y = 2".
  final String clue2;

  /// The correct x value of the mystery pair.
  final int solutionX;

  /// The correct y value of the mystery pair.
  final int solutionY;

  /// Candidate values available to drag into x/y slots (Discovery mechanic).
  final List<int> candidateValues;

  /// Candidate pairs to eliminate from (Elimination mechanic).
  final List<CandidatePair> candidatePairs;

  /// Minimum number of moves to solve optimally.
  final int optimalMoves;

  /// Whether this specific level features a conceptual reasoning checkpoint.
  final bool hasReasoningCheckpoint;

  /// The question prompt for reasoning checkpoint levels.
  final String? reasoningQuestion;

  /// Reasoning explanation options shown for checkpoint levels.
  final List<String> reasoningOptions;

  /// Index of the correct reasoning option.
  final int correctReasoningIndex;

  /// Mascot intro dialogue when the level starts.
  final String introDialogue;

  /// Hint dialogue shown when the player is stuck.
  final String hintDialogue;

  /// Whether the assigned values match the solution.
  bool checkSolution(int x, int y) => x == solutionX && y == solutionY;

  /// Whether the given values satisfy clue 1.
  ///
  /// Evaluates the clue equation with the provided x and y values.
  /// Returns null if the clue format is not recognized.
  bool? evaluateClue1(int x, int y) => _evaluateClue(clue1, x, y);

  /// Whether the given values satisfy clue 2.
  bool? evaluateClue2(int x, int y) => _evaluateClue(clue2, x, y);

  /// Simple expression evaluator for clue equations.
  ///
  /// Supports formats like "x + y = N", "x - y = N", "Ax + By = N",
  /// "y = x + N", etc. Returns null for unrecognized formats.
  static bool? _evaluateClue(String clue, int x, int y) {
    final normalized = clue.replaceAll(' ', '');

    // Split on '='
    final eqParts = normalized.split('=');
    if (eqParts.length != 2) return null;

    final leftVal = _evaluateExpression(eqParts[0], x, y);
    final rightVal = _evaluateExpression(eqParts[1], x, y);

    if (leftVal == null || rightVal == null) return null;
    return leftVal == rightVal;
  }

  /// Evaluates a simple algebraic expression with x and y substitution.
  ///
  /// Handles: numbers, x, y, Ax, By, and +/- combinations of these.
  static int? _evaluateExpression(String expr, int x, int y) {
    if (expr.isEmpty) return null;

    // Try pure number
    final asNumber = int.tryParse(expr);
    if (asNumber != null) return asNumber;

    // Parse term-by-term: split into signed terms
    // Insert '+' before '-' to split, but handle leading '-'
    final termBuffer = StringBuffer();
    final terms = <String>[];

    for (int i = 0; i < expr.length; i++) {
      final ch = expr[i];
      if ((ch == '+' || ch == '-') && i > 0) {
        terms.add(termBuffer.toString());
        termBuffer.clear();
      }
      termBuffer.write(ch);
    }
    if (termBuffer.isNotEmpty) terms.add(termBuffer.toString());

    int result = 0;
    for (final term in terms) {
      final val = _evaluateTerm(term, x, y);
      if (val == null) return null;
      result += val;
    }
    return result;
  }

  /// Evaluates a single term like "3x", "-2y", "x", "y", "5", "-7".
  static int? _evaluateTerm(String term, int x, int y) {
    if (term.isEmpty) return null;

    // Pure number
    final asNumber = int.tryParse(term);
    if (asNumber != null) return asNumber;

    // Contains 'x'
    if (term.contains('x')) {
      final coeff = term.replaceAll('x', '');
      if (coeff.isEmpty || coeff == '+') return x;
      if (coeff == '-') return -x;
      final c = int.tryParse(coeff);
      return c != null ? c * x : null;
    }

    // Contains 'y'
    if (term.contains('y')) {
      final coeff = term.replaceAll('y', '');
      if (coeff.isEmpty || coeff == '+') return y;
      if (coeff == '-') return -y;
      final c = int.tryParse(coeff);
      return c != null ? c * y : null;
    }

    return null;
  }
}
