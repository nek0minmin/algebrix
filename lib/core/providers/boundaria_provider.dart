import 'package:flutter/foundation.dart';

import 'package:algebrix/models/boundaria_problem.dart';
import 'package:algebrix/services/boundaria_problem_service.dart';
import 'package:algebrix/services/sound_service.dart';

/// What the scout found at the point it was sent to.
enum ScoutVerdict {
  /// The rule held there, so the scout is standing in the solution.
  belongs,

  /// The rule failed there, so the other side holds the solution.
  doesNotBelong,

  /// The scout landed on the barrier, which settles nothing.
  onBorder,
}

/// State for one run through a Boundaria level.
///
/// The level drives the loop: it declares which stages it uses, and the
/// provider walks them in order. Nothing is hard-coded to a level number, so
/// adding a territory later means adding data, not branches.
class BoundariaProvider extends ChangeNotifier {
  BoundariaProvider({BoundariaProblemService? problemService})
      : _problemService = problemService ?? const BoundariaProblemService();

  final BoundariaProblemService _problemService;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  BoundariaProblem? _problem;
  int _phaseIndex = 0;
  bool _isSolved = false;

  ({int x, int y})? _interceptBeacon;
  ({int x, int y})? _slopeBeacon;
  BoundaryStyle? _chosenStyle;
  ({int x, int y})? _scoutPoint;
  ScoutVerdict? _scoutVerdict;
  TerritorySide? _claimedSide;
  String? _chosenMapId;

  /// Stars still intact. A mistake removes the star for the idea it belongs to.
  final Set<BoundariaStar> _starsHeld = {...BoundariaStar.values};

  /// Categories this level actually asks about; the rest are given.
  Set<BoundariaStar> _exercised = {};

  String? _feedback;
  bool _feedbackIsError = false;
  bool _hintVisible = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  BoundariaProblem? get problem => _problem;
  bool get isSolved => _isSolved;

  ({int x, int y})? get interceptBeacon => _interceptBeacon;
  ({int x, int y})? get slopeBeacon => _slopeBeacon;
  BoundaryStyle? get chosenStyle => _chosenStyle;
  ({int x, int y})? get scoutPoint => _scoutPoint;
  ScoutVerdict? get scoutVerdict => _scoutVerdict;
  TerritorySide? get claimedSide => _claimedSide;
  String? get chosenMapId => _chosenMapId;

  String? get feedback => _feedback;
  bool get feedbackIsError => _feedbackIsError;
  bool get hintVisible => _hintVisible;

  /// The stage the learner is on, or null once the territory is claimed.
  BoundariaPhase? get currentPhase {
    final problem = _problem;
    if (problem == null || _phaseIndex >= problem.phases.length) return null;
    return problem.phases[_phaseIndex];
  }

  /// Both beacons are down, so the barrier can be drawn.
  bool get hasBoundaryLine {
    final problem = _problem;
    if (problem == null) return false;
    // Levels that never ask for construction start with the border already up.
    if (!problem.phases.contains(BoundariaPhase.plotIntercept)) return true;
    return _interceptBeacon != null && _slopeBeacon != null;
  }

  /// Whether this level ever asks the learner about [star].
  bool isExercised(BoundariaStar star) => _exercised.contains(star);

  bool hasStar(BoundariaStar star) => _starsHeld.contains(star);

  int get starsEarned => _starsHeld.length;

  /// One line per star for the result screen.
  Map<BoundariaStar, bool> get starBreakdown => {
        for (final star in BoundariaStar.values) star: _starsHeld.contains(star),
      };

  /// How far through the loop the learner is, for the progress rail.
  int get completedPhaseCount => _phaseIndex;
  int get totalPhaseCount => _problem?.phases.length ?? 0;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Starts (or restarts) [levelNumber].
  void startLevel(int levelNumber) {
    final problem = _problemService.levelProblem(levelNumber);
    _problem = problem;
    _phaseIndex = 0;
    _isSolved = false;

    _interceptBeacon = null;
    _slopeBeacon = null;
    _chosenStyle = null;
    _scoutPoint = null;
    _scoutVerdict = null;
    _claimedSide = null;
    _chosenMapId = null;

    _starsHeld
      ..clear()
      ..addAll(BoundariaStar.values);
    _exercised = _exercisedStarsFor(problem);

    _feedback = null;
    _feedbackIsError = false;
    _hintVisible = false;

    // Level 5 places the scout for the learner; the lesson there is reading the
    // result, not choosing the point.
    if (problem.scoutPointIsFixed && problem.suggestedScoutPoint != null) {
      _scoutPoint = problem.suggestedScoutPoint;
    }

    notifyListeners();
  }

  void restart() {
    final level = _problem?.levelNumber;
    if (level != null) startLevel(level);
  }

  void toggleHint() {
    _hintVisible = !_hintVisible;
    notifyListeners();
  }

  /// Which stars a level can actually take away.
  ///
  /// A level that never asks the learner to build a line should not be able to
  /// cost them the Boundary star — those are reported as given rather than
  /// earned, so the breakdown never claims they did something they did not.
  static Set<BoundariaStar> _exercisedStarsFor(BoundariaProblem problem) {
    // The Broken Map asks about all three at once: one wrong map per idea.
    if (problem.phases.contains(BoundariaPhase.inspectMaps)) {
      return {...BoundariaStar.values};
    }

    final exercised = <BoundariaStar>{};
    for (final phase in problem.phases) {
      switch (phase) {
        case BoundariaPhase.rearrange:
        case BoundariaPhase.plotIntercept:
        case BoundariaPhase.buildSlope:
          exercised.add(BoundariaStar.boundary);
        case BoundariaPhase.chooseBoundary:
          exercised.add(BoundariaStar.border);
        case BoundariaPhase.scout:
        case BoundariaPhase.claim:
          exercised.add(BoundariaStar.region);
        case BoundariaPhase.inspectMaps:
          break;
      }
    }
    return exercised;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Picks the rule solved for y. Level 7, 8 and 10.
  bool chooseRearrangeOption(int index) {
    final problem = _problem;
    if (problem == null || currentPhase != BoundariaPhase.rearrange) return false;

    if (index != problem.correctRearrangeIndex) {
      _loseStar(BoundariaStar.boundary);
      _fail(
        problem.levelNumber == 8 || problem.levelNumber == 10
            ? 'Not quite. Dividing by a negative reverses the inequality.'
            : 'Not quite. Move the x term across without flipping the sign.',
      );
      return false;
    }

    _succeed('Solved for y: ${problem.solvedRule}');
    _advance();
    return true;
  }

  /// Drops a beacon. Serves both the intercept and the slope step.
  bool plotPoint(int x, int y) {
    final problem = _problem;
    if (problem == null) return false;

    switch (currentPhase) {
      case BoundariaPhase.plotIntercept:
        if (x != 0 || y != problem.intercept) {
          _loseStar(BoundariaStar.boundary);
          _fail(
            x != 0
                ? 'The anchor sits on the y-axis, where x is 0.'
                : 'That is not where this border crosses. Check the intercept.',
          );
          return false;
        }
        _interceptBeacon = (x: x, y: y);
        _succeed('Boundary anchor placed!');
        _advance();
        return true;

      case BoundariaPhase.buildSlope:
        final target = problem.slopeStepPoint;
        if (x != target.x || y != target.y) {
          _loseStar(BoundariaStar.boundary);
          final rise = problem.riseOverRun.rise;
          final run = problem.riseOverRun.run;
          _fail(
            'From the anchor, move $run right and '
            '${rise.abs()} ${rise < 0 ? 'down' : 'up'}.',
          );
          return false;
        }
        _slopeBeacon = (x: x, y: y);
        _succeed('The border stretches across Boundaria!');
        _advance();
        return true;

      default:
        return false;
    }
  }

  /// Dashed barrier or solid barrier.
  bool chooseStyle(BoundaryStyle style) {
    final problem = _problem;
    if (problem == null || currentPhase != BoundariaPhase.chooseBoundary) {
      return false;
    }

    _chosenStyle = style;
    if (style != problem.correctStyle) {
      _loseStar(BoundariaStar.border);
      _fail(
        problem.sign.includesBoundary
            ? 'This rule says "or equal to", so the border belongs to the '
                'territory. It should be solid.'
            : 'A plain ${problem.sign.symbol} leaves the border out, so it '
                'should be dashed.',
      );
      // The correct barrier goes up anyway, so the level can continue.
      _chosenStyle = problem.correctStyle;
      _advance();
      return false;
    }

    _succeed(
      style == BoundaryStyle.solid
          ? 'Solid barrier raised — the border belongs.'
          : 'Dashed barrier raised — the border is excluded.',
    );
    _advance();
    return true;
  }

  /// Sends the scout to a test point.
  ///
  /// Landing on the barrier is not a mistake — it is the lesson that a point on
  /// the line settles nothing — so it costs no star and the scout can move.
  ScoutVerdict sendScout(int x, int y) {
    final problem = _problem;
    if (problem == null || currentPhase != BoundariaPhase.scout) {
      return ScoutVerdict.onBorder;
    }

    _scoutPoint = (x: x, y: y);

    if (problem.isOnBoundary(x, y)) {
      _scoutVerdict = ScoutVerdict.onBorder;
      _feedback = 'Our scout landed on the border! Try a point inside one of '
          'the territories.';
      _feedbackIsError = false;
      SoundService.playClick();
      notifyListeners();
      return ScoutVerdict.onBorder;
    }

    final holds = problem.satisfies(x, y);
    _scoutVerdict =
        holds ? ScoutVerdict.belongs : ScoutVerdict.doesNotBelong;

    _feedback = holds
        ? '${problem.scoutWorking(x, y)} ✓ This location follows the rule!'
        : "${problem.scoutWorking(x, y)} ✗ This location doesn't belong. "
            'Check the other territory!';
    _feedbackIsError = false;
    SoundService.playCorrect();
    _advance();
    return _scoutVerdict!;
  }

  /// Claims a side as the solution territory.
  bool claimSide(TerritorySide side) {
    final problem = _problem;
    if (problem == null || currentPhase != BoundariaPhase.claim) return false;

    _claimedSide = side;
    if (side != problem.correctSide) {
      _loseStar(BoundariaStar.region);
      _fail(
        'That territory does not satisfy the rule. '
        '${problem.solvedRule} claims the side ${problem.correctSide == TerritorySide.above ? 'above' : 'below'} the border.',
      );
      _claimedSide = problem.correctSide;
      _finish();
      return false;
    }

    _succeed('Territory restored!');
    _finish();
    return true;
  }

  /// Picks one of the four maps in the Broken Map level.
  ///
  /// Each wrong map breaks exactly one idea, so the map chosen says which star
  /// to take — a far more useful signal than "wrong".
  bool chooseMap(String mapId) {
    final problem = _problem;
    if (problem == null || currentPhase != BoundariaPhase.inspectMaps) {
      return false;
    }

    final option = problem.mapOptions.firstWhere(
      (m) => m.id == mapId,
      orElse: () => problem.mapOptions.last,
    );
    _chosenMapId = mapId;

    if (!option.isCorrect) {
      _loseStar(option.flaw!);
      _fail(switch (option.flaw!) {
        BoundariaStar.boundary =>
          'Look again at where that border crosses the y-axis.',
        BoundariaStar.border =>
          'That map used the wrong kind of barrier for a rule with '
              '"or equal to".',
        BoundariaStar.region => 'That map claimed the wrong side.',
      });
      _finish();
      return false;
    }

    _succeed('That map follows the Territory Rule exactly.');
    _finish();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _advance() {
    final problem = _problem;
    if (problem == null) return;

    _phaseIndex++;
    if (_phaseIndex >= problem.phases.length) {
      _finish();
      return;
    }
    notifyListeners();
  }

  void _finish() {
    _phaseIndex = _problem?.phases.length ?? 0;
    _isSolved = true;
    notifyListeners();
  }

  void _loseStar(BoundariaStar star) => _starsHeld.remove(star);

  void _succeed(String message) {
    _feedback = message;
    _feedbackIsError = false;
    SoundService.playCorrect();
    notifyListeners();
  }

  void _fail(String message) {
    _feedback = message;
    _feedbackIsError = true;
    SoundService.playWrong();
    notifyListeners();
  }
}
