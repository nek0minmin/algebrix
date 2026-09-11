import 'package:flutter/foundation.dart';

/// The comparison in a territory rule.
enum InequalitySign {
  greater('>'),
  greaterOrEqual('≥'),
  less('<'),
  lessOrEqual('≤');

  const InequalitySign(this.symbol);

  final String symbol;

  /// `>` and `<` exclude the line itself, so the barrier is dashed.
  bool get includesBoundary =>
      this == InequalitySign.greaterOrEqual || this == InequalitySign.lessOrEqual;

  /// Solutions sit above the line for `>` and `≥`.
  bool get solutionIsAbove =>
      this == InequalitySign.greater || this == InequalitySign.greaterOrEqual;
}

/// Whether the barrier itself belongs to the territory.
enum BoundaryStyle { dashed, solid }

/// Which side of the barrier holds the solutions.
enum TerritorySide { above, below }

/// One stage of the Claim the Region loop.
///
/// Levels declare only the stages they use, so the mechanics unlock as the
/// learner moves deeper into Boundaria rather than arriving all at once.
enum BoundariaPhase {
  /// Turn a rule like `2x + y > 4` into `y > −2x + 4` first.
  rearrange,

  /// Tap the y-intercept to drop the first beacon.
  plotIntercept,

  /// Walk the slope to place the second beacon.
  buildSlope,

  /// Dashed barrier or solid barrier.
  chooseBoundary,

  /// Send the scout to a test point and see whether the rule holds there.
  scout,

  /// Claim the side that satisfies the rule.
  claim,

  /// Level 9 only: pick the map that follows the rule.
  inspectMaps,
}

/// Which of the three stars a mistake costs.
///
/// Boundaria scores what the learner understood rather than how many mistakes
/// they made, so each star belongs to one idea.
enum BoundariaStar {
  /// Slope, intercept, and the points that build the line.
  boundary,

  /// Solid or dashed.
  border,

  /// The side that holds the solutions.
  region,
}

/// One of the four maps offered in the Broken Map level.
class BoundariaMapOption {
  const BoundariaMapOption({
    required this.id,
    required this.label,
    required this.intercept,
    required this.style,
    required this.side,
    required this.flaw,
  });

  final String id;
  final String label;

  final int intercept;
  final BoundaryStyle style;
  final TerritorySide side;

  /// What this map gets wrong, or null when it is the correct one.
  ///
  /// Doubles as the star the learner loses by choosing it, which is what makes
  /// a wrong pick diagnostic instead of merely wrong.
  final BoundariaStar? flaw;

  bool get isCorrect => flaw == null;
}

/// A single Boundaria level.
///
/// Every rule is stored already solved for y, plus the form the learner is
/// shown. Levels 7, 8 and 10 differ between the two, which is the whole point
/// of their rearrange stage.
@immutable
class BoundariaProblem {
  const BoundariaProblem({
    required this.levelNumber,
    required this.title,
    required this.landmark,
    required this.displayedRule,
    required this.sign,
    required this.riseOverRun,
    required this.intercept,
    required this.phases,
    required this.introDialogue,
    required this.hintDialogue,
    this.rearrangeOptions = const [],
    this.correctRearrangeIndex = 0,
    this.suggestedScoutPoint,
    this.scoutPointIsFixed = false,
    this.mapOptions = const [],
    this.gridRange = 6,
  });

  final int levelNumber;
  final String title;

  /// Where this level sits in Boundaria, shown on the level card.
  final String landmark;

  /// The rule exactly as the learner first sees it, e.g. `2x + y > 4`.
  final String displayedRule;

  /// The comparison after solving for y.
  final InequalitySign sign;

  /// Slope as rise over run, so a half-step slope stays exact.
  final ({int rise, int run}) riseOverRun;

  /// The y-intercept after solving for y.
  final int intercept;

  /// The stages this level runs, in order.
  final List<BoundariaPhase> phases;

  final String introDialogue;
  final String hintDialogue;

  /// Choices for the rearrange stage, as displayed strings.
  final List<String> rearrangeOptions;
  final int correctRearrangeIndex;

  /// Where the scout starts, when the level places it for the learner.
  final ({int x, int y})? suggestedScoutPoint;

  /// True when the learner may not move the scout (level 5 teaches the idea).
  final bool scoutPointIsFixed;

  /// The four maps offered by the Broken Map level.
  final List<BoundariaMapOption> mapOptions;

  /// The grid runs from −[gridRange] to +[gridRange] on both axes.
  final int gridRange;

  // ---------------------------------------------------------------------------
  // Derived truth
  // ---------------------------------------------------------------------------

  /// The rule solved for y, e.g. `y > −2x + 4`.
  String get solvedRule {
    final slopePart = switch (riseOverRun) {
      (rise: 0, run: _) => '',
      (rise: final r, run: 1) when r == 1 => 'x',
      (rise: final r, run: 1) when r == -1 => '−x',
      (rise: final r, run: 1) => '${r < 0 ? '−' : ''}${r.abs()}x',
      (rise: final r, run: final n) =>
        '${r < 0 ? '−' : ''}${r.abs()}/${n}x',
    };

    if (slopePart.isEmpty) return 'y ${sign.symbol} ${_signed(intercept)}';
    if (intercept == 0) return 'y ${sign.symbol} $slopePart';
    final joiner = intercept < 0 ? '−' : '+';
    return 'y ${sign.symbol} $slopePart $joiner ${intercept.abs()}';
  }

  /// True when the displayed rule is not already solved for y.
  bool get needsRearranging => phases.contains(BoundariaPhase.rearrange);

  BoundaryStyle get correctStyle =>
      sign.includesBoundary ? BoundaryStyle.solid : BoundaryStyle.dashed;

  TerritorySide get correctSide =>
      sign.solutionIsAbove ? TerritorySide.above : TerritorySide.below;

  /// The second beacon, one slope step right of the intercept.
  ({int x, int y}) get slopeStepPoint =>
      (x: riseOverRun.run, y: intercept + riseOverRun.rise);

  /// Whether ([x], [y]) sits exactly on the barrier.
  ///
  /// Compared in whole numbers by scaling through the run, so a half-step
  /// slope never drifts the way a double would.
  bool isOnBoundary(int x, int y) =>
      y * riseOverRun.run == riseOverRun.rise * x + intercept * riseOverRun.run;

  /// Whether ([x], [y]) satisfies the rule.
  ///
  /// The run is always positive in the shipped levels, so scaling both sides by
  /// it cannot flip the comparison.
  bool satisfies(int x, int y) {
    assert(riseOverRun.run > 0, 'run must stay positive to preserve the sign');
    final left = y * riseOverRun.run;
    final right = riseOverRun.rise * x + intercept * riseOverRun.run;

    return switch (sign) {
      InequalitySign.greater => left > right,
      InequalitySign.greaterOrEqual => left >= right,
      InequalitySign.less => left < right,
      InequalitySign.lessOrEqual => left <= right,
    };
  }

  /// The substitution the scout shows in its speech bubble, e.g. `0 > −2`.
  String scoutWorking(int x, int y) {
    final rhsScaled = riseOverRun.rise * x + intercept * riseOverRun.run;
    final rhs = rhsScaled / riseOverRun.run;
    final rhsLabel = rhs == rhs.roundToDouble()
        ? '${rhs.round()}'
        : rhs.toStringAsFixed(1);
    return '${_signed(y)} ${sign.symbol} ${rhsLabel.replaceAll('-', '−')}';
  }

  /// Renders a number with the typographic minus the rest of the app uses, so
  /// a rule never mixes `-1` and `−1` on the same screen.
  static String _signed(int value) =>
      value < 0 ? '−${value.abs()}' : '$value';

  /// The side ([x], [y]) sits on, or null when it is on the barrier itself.
  TerritorySide? sideOf(int x, int y) {
    if (isOnBoundary(x, y)) return null;
    final left = y * riseOverRun.run;
    final right = riseOverRun.rise * x + intercept * riseOverRun.run;
    return left > right ? TerritorySide.above : TerritorySide.below;
  }
}
