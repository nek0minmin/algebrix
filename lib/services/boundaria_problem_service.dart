import 'package:algebrix/models/boundaria_problem.dart';

/// The ten territories of Boundaria.
///
/// The mechanics unlock in order: levels 1–2 only decide the barrier type and
/// the side, 3–4 add building the line, 5–6 add the scout, 7–8 add rearranging,
/// 9 tests whether a finished map can be read rather than followed, and 10 asks
/// for the whole loop with no guidance.
class BoundariaProblemService {
  const BoundariaProblemService();

  static const int levelCount = 10;

  BoundariaProblem levelProblem(int levelNumber) {
    final index = levelNumber.clamp(1, levelCount) - 1;
    return _levels[index];
  }

  List<BoundariaProblem> get allLevels => List.unmodifiable(_levels);

  static const List<BoundariaProblem> _levels = [
    // ── Boundary Gardens ────────────────────────────────────────────────────
    BoundariaProblem(
      levelNumber: 1,
      title: 'First Border',
      landmark: 'Boundary Gardens',
      displayedRule: 'y > 2',
      sign: InequalitySign.greater,
      riseOverRun: (rise: 0, run: 1),
      intercept: 2,
      phases: [BoundariaPhase.chooseBoundary, BoundariaPhase.claim],
      introDialogue:
          'A border already runs across these gardens. Two questions decide the '
          'territory: does the border itself belong, and which side does?',
      hintDialogue:
          'A plain > leaves the border out. And "greater than" points upward.',
    ),
    BoundariaProblem(
      levelNumber: 2,
      title: 'The Included Lands',
      landmark: 'Boundary Gardens',
      displayedRule: 'y ≤ −1',
      sign: InequalitySign.lessOrEqual,
      riseOverRun: (rise: 0, run: 1),
      intercept: -1,
      phases: [BoundariaPhase.chooseBoundary, BoundariaPhase.claim],
      introDialogue:
          'Look closely at this rule. That little line under the symbol changes '
          'who is allowed to stand on the border.',
      hintDialogue:
          'The line under ≤ means "or equal to", so the border counts. '
          '"Less than" points downward.',
    ),

    // ── Slope Hills ─────────────────────────────────────────────────────────
    BoundariaProblem(
      levelNumber: 3,
      title: 'The Rising Border',
      landmark: 'Slope Hills',
      displayedRule: 'y > x + 1',
      sign: InequalitySign.greater,
      riseOverRun: (rise: 1, run: 1),
      intercept: 1,
      phases: [
        BoundariaPhase.plotIntercept,
        BoundariaPhase.buildSlope,
        BoundariaPhase.chooseBoundary,
        BoundariaPhase.claim,
      ],
      introDialogue:
          'This border rises. Anchor it where it crosses the y-axis, then walk '
          'the slope to find a second point.',
      hintDialogue:
          'The +1 is where it crosses. A slope of 1 means one right, one up.',
    ),
    BoundariaProblem(
      levelNumber: 4,
      title: 'Border Architect',
      landmark: 'Slope Hills',
      displayedRule: 'y ≥ 2x − 2',
      sign: InequalitySign.greaterOrEqual,
      riseOverRun: (rise: 2, run: 1),
      intercept: -2,
      phases: [
        BoundariaPhase.plotIntercept,
        BoundariaPhase.buildSlope,
        BoundariaPhase.chooseBoundary,
        BoundariaPhase.claim,
      ],
      introDialogue:
          'No guidance this time. Read the slope and the intercept straight off '
          'the rule and build the border yourself.',
      hintDialogue:
          'The number in front of x is the slope; the number on its own is the '
          'intercept. Watch its sign.',
    ),

    // ── Scout's Observatory ─────────────────────────────────────────────────
    BoundariaProblem(
      levelNumber: 5,
      title: 'Meet the Scout',
      landmark: "Scout's Observatory",
      displayedRule: 'y < x + 3',
      sign: InequalitySign.less,
      riseOverRun: (rise: 1, run: 1),
      intercept: 3,
      phases: [BoundariaPhase.scout, BoundariaPhase.claim],
      suggestedScoutPoint: (x: 0, y: 0),
      scoutPointIsFixed: true,
      introDialogue:
          'The border is already built, but both sides are still under fog. We '
          'need to know which side follows the rule — let us test a location!',
      hintDialogue:
          'Put the numbers from the scout into the rule. If it comes out true, '
          'the scout is standing in the solution.',
    ),
    BoundariaProblem(
      levelNumber: 6,
      title: 'Choose Your Own Scout',
      landmark: "Scout's Observatory",
      displayedRule: 'y > −x + 2',
      sign: InequalitySign.greater,
      riseOverRun: (rise: -1, run: 1),
      intercept: 2,
      phases: [
        BoundariaPhase.plotIntercept,
        BoundariaPhase.buildSlope,
        BoundariaPhase.chooseBoundary,
        BoundariaPhase.scout,
        BoundariaPhase.claim,
      ],
      suggestedScoutPoint: (x: 0, y: 0),
      introDialogue:
          'This border falls as it travels right. Build it, then pick your own '
          'test location — anywhere that is not on the border itself.',
      hintDialogue:
          'A negative slope goes one right and one down. The origin is usually '
          'the easiest place to send a scout.',
    ),

    // ── Mist Territories ────────────────────────────────────────────────────
    BoundariaProblem(
      levelNumber: 7,
      title: 'Hidden Border',
      landmark: 'Mist Territories',
      displayedRule: '2x + y > 4',
      sign: InequalitySign.greater,
      riseOverRun: (rise: -2, run: 1),
      intercept: 4,
      phases: [
        BoundariaPhase.rearrange,
        BoundariaPhase.plotIntercept,
        BoundariaPhase.buildSlope,
        BoundariaPhase.chooseBoundary,
        BoundariaPhase.scout,
        BoundariaPhase.claim,
      ],
      rearrangeOptions: [
        'y > −2x + 4',
        'y > 2x + 4',
        'y > −2x − 4',
        'y < −2x + 4',
      ],
      correctRearrangeIndex: 0,
      suggestedScoutPoint: (x: 0, y: 0),
      introDialogue:
          'This rule is hiding its shape. Before we can build anything, y has to '
          'stand on its own.',
      hintDialogue:
          'Subtract 2x from both sides. Subtracting never flips the sign — only '
          'multiplying or dividing by a negative does.',
    ),
    BoundariaProblem(
      levelNumber: 8,
      title: 'The Reversed Rule',
      landmark: 'Mist Territories',
      displayedRule: '−y < 2x − 4',
      sign: InequalitySign.greater,
      riseOverRun: (rise: -2, run: 1),
      intercept: 4,
      phases: [
        BoundariaPhase.rearrange,
        BoundariaPhase.plotIntercept,
        BoundariaPhase.buildSlope,
        BoundariaPhase.chooseBoundary,
        BoundariaPhase.scout,
        BoundariaPhase.claim,
      ],
      rearrangeOptions: [
        'y > −2x + 4',
        'y < −2x + 4',
        'y > 2x − 4',
        'y < 2x − 4',
      ],
      correctRearrangeIndex: 0,
      suggestedScoutPoint: (x: 0, y: 0),
      introDialogue:
          'Careful here. Freeing y from that minus sign costs something, and the '
          'rule will not look the same afterwards.',
      hintDialogue:
          'Dividing both sides by −1 reverses the inequality, exactly as it did '
          'back in Module 4.',
    ),

    // ── Cartographer's Archive ──────────────────────────────────────────────
    BoundariaProblem(
      levelNumber: 9,
      title: 'Broken Map',
      landmark: "Cartographer's Archive",
      displayedRule: 'y ≥ ½x − 2',
      sign: InequalitySign.greaterOrEqual,
      riseOverRun: (rise: 1, run: 2),
      intercept: -2,
      phases: [BoundariaPhase.inspectMaps],
      mapOptions: [
        BoundariaMapOption(
          id: 'A',
          label: 'Map A',
          intercept: -2,
          style: BoundaryStyle.dashed,
          side: TerritorySide.above,
          flaw: BoundariaStar.border,
        ),
        BoundariaMapOption(
          id: 'B',
          label: 'Map B',
          intercept: 2,
          style: BoundaryStyle.solid,
          side: TerritorySide.above,
          flaw: BoundariaStar.boundary,
        ),
        BoundariaMapOption(
          id: 'C',
          label: 'Map C',
          intercept: -2,
          style: BoundaryStyle.solid,
          side: TerritorySide.below,
          flaw: BoundariaStar.region,
        ),
        BoundariaMapOption(
          id: 'D',
          label: 'Map D',
          intercept: -2,
          style: BoundaryStyle.solid,
          side: TerritorySide.above,
          flaw: null,
        ),
      ],
      introDialogue:
          'Four cartographers each drew this territory. Only one of them got it '
          'right. Read the whole map before you choose.',
      hintDialogue:
          'Check three things on every map: where it crosses, whether the border '
          'is solid, and which side is claimed.',
    ),

    // ── The Boundary Citadel ────────────────────────────────────────────────
    BoundariaProblem(
      levelNumber: 10,
      title: 'The Final Territory',
      landmark: 'The Boundary Citadel',
      displayedRule: '2x − y ≤ 4',
      sign: InequalitySign.greaterOrEqual,
      riseOverRun: (rise: 2, run: 1),
      intercept: -4,
      phases: [
        BoundariaPhase.rearrange,
        BoundariaPhase.plotIntercept,
        BoundariaPhase.buildSlope,
        BoundariaPhase.chooseBoundary,
        BoundariaPhase.scout,
        BoundariaPhase.claim,
      ],
      rearrangeOptions: [
        'y ≥ 2x − 4',
        'y ≤ 2x − 4',
        'y ≥ −2x + 4',
        'y ≤ −2x − 4',
      ],
      correctRearrangeIndex: 0,
      suggestedScoutPoint: (x: 0, y: 0),
      introDialogue:
          'The Citadel is dark, and everything you have learned in Boundaria is '
          'needed to light it. No hints unless you ask.',
      hintDialogue:
          'Move y to its own side, then divide by −1 and reverse. The border is '
          'solid because the rule includes "or equal to".',
      gridRange: 7,
    ),
  ];
}
