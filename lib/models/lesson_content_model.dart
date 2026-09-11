enum LessonStepType {
  intro, // Xy introduction with mascot image + body text
  content, // Educational content with explanation
  xySays, // Xy mascot tip/insight bubble
  interactive, // Interactive activity (mystery box, choices)
  quiz, // Multiple choice quiz question
  summary, // Lesson completion summary
  activity, // Typed interactive learning activity
}

sealed class LessonActivityData {
  const LessonActivityData();
}

class ActivityCategory {
  final String id;
  final String label;
  const ActivityCategory({required this.id, required this.label});
}

class ClassificationItem {
  final String id;
  final String label;
  final String categoryId;
  const ClassificationItem({
    required this.id,
    required this.label,
    required this.categoryId,
  });
}

class ClassificationActivityData extends LessonActivityData {
  final List<ActivityCategory> categories;
  final List<ClassificationItem> items;
  const ClassificationActivityData({
    required this.categories,
    required this.items,
  });
}

class TermToken {
  final String id;
  final String label;
  final bool isTerm;
  const TermToken({
    required this.id,
    required this.label,
    required this.isTerm,
  });
}

class TermSelectionActivityData extends LessonActivityData {
  final List<TermToken> tokens;
  const TermSelectionActivityData({required this.tokens});
}

class OrderingItem {
  final String id;
  final String label;
  const OrderingItem({required this.id, required this.label});
}

class OrderingActivityData extends LessonActivityData {
  final List<OrderingItem> items;
  final List<String> correctOrderIds;
  const OrderingActivityData({
    required this.items,
    required this.correctOrderIds,
  });
}

/// Whether a graphed boundary value is part of the solution.
enum NumberLineBoundary {
  /// `<` or `>` — an open circle, boundary excluded.
  open,

  /// `≤` or `≥` — a filled circle, boundary included.
  closed,
}

/// Which way the shaded solution range runs from the boundary.
enum NumberLineDirection { left, right }

/// Graphing an inequality on a number line.
///
/// The learner does the three things a graph actually encodes, in order:
/// place the boundary, decide whether it is included, then paint the range.
/// Splitting it up is the point — it stops "open circle for `<`" being
/// memorised without understanding why.
class NumberLineActivityData extends LessonActivityData {
  const NumberLineActivityData({
    required this.inequality,
    required this.minValue,
    required this.maxValue,
    required this.correctBoundary,
    required this.correctMarker,
    required this.correctDirection,
    this.boundaryPrompt = 'Tap the boundary value',
    this.markerPrompt = 'Can x equal that value?',
    this.directionPrompt = 'Paint the values that belong',
  });

  /// The inequality being graphed, e.g. `x ≥ -2`.
  final String inequality;

  final int minValue;
  final int maxValue;

  final int correctBoundary;
  final NumberLineBoundary correctMarker;
  final NumberLineDirection correctDirection;

  final String boundaryPrompt;
  final String markerPrompt;
  final String directionPrompt;

  /// Tick values drawn on the line, inclusive of both ends.
  List<int> get ticks => [
        for (var value = minValue; value <= maxValue; value++) value,
      ];
}

/// A lattice point on a coordinate plane.
class GridPoint {
  const GridPoint(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is GridPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x, $y)';
}

/// Plotting points on a coordinate plane.
///
/// Covers the whole of Module 5's spatial work: dropping a single point,
/// walking a slope from one point to another, and laying down the points of a
/// line before connecting them. The learner taps real grid positions rather
/// than picking a coordinate from a list, so "3 across, 2 up" stays physical.
class CoordinatePlaneActivityData extends LessonActivityData {
  const CoordinatePlaneActivityData({
    required this.targets,
    this.minX = -5,
    this.maxX = 5,
    this.minY = -5,
    this.maxY = 5,
    this.prompt = 'Tap the grid to place your point',
    this.connectWhenComplete = false,
    this.orderMatters = false,
  });

  /// Every point that must be plotted for the activity to be correct.
  final List<GridPoint> targets;

  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  final String prompt;

  /// Draws a line through the plotted points once they are all placed —
  /// the moment a table of values becomes visibly straight.
  final bool connectWhenComplete;

  /// When true the learner must plot the targets in the listed order.
  final bool orderMatters;

  List<int> get xTicks => [for (var v = minX; v <= maxX; v++) v];
  List<int> get yTicks => [for (var v = minY; v <= maxY; v++) v];
}

/// Filling in an area model for a polynomial product.
///
/// Multiplication is taught as "every piece meets every piece" before FOIL is
/// named, so the grid is the concept and FOIL is the shortcut.
class AreaModelActivityData extends LessonActivityData {
  const AreaModelActivityData({
    required this.expression,
    required this.topLabels,
    required this.sideLabels,
    required this.cells,
    required this.choices,
    required this.result,
  });

  /// The product being expanded, e.g. `(x + 2)(x + 3)`.
  final String expression;

  /// Column headers, left to right.
  final List<String> topLabels;

  /// Row headers, top to bottom.
  final List<String> sideLabels;

  /// Correct cell contents in row-major order.
  final List<String> cells;

  /// Tiles offered to the learner, including plausible wrong ones.
  final List<String> choices;

  /// The combined result revealed once the grid is complete.
  final String result;

  int get rows => sideLabels.length;
  int get columns => topLabels.length;
}

/// A free exploration of `y = mx + b` driven by two sliders.
///
/// The learner is not being scored on a procedure here: they move m and b and
/// watch the line answer. Each step poses one discovery goal ("make the line
/// horizontal") that is satisfied the moment the line matches, so there is no
/// way to get it wrong — only to keep adjusting until it is right.
class LineLabActivityData extends LessonActivityData {
  const LineLabActivityData({
    required this.goal,
    this.hint,
    this.targetSlope,
    this.targetIntercept,
    this.startSlope = 1,
    this.startIntercept = 0,
    this.minSlope = -5,
    this.maxSlope = 5,
    this.minIntercept = -5,
    this.maxIntercept = 5,
  });

  /// The discovery prompt, e.g. "Can you make the line horizontal?".
  final String goal;

  /// Optional nudge shown under the sliders.
  final String? hint;

  /// The slope that satisfies [goal], or null when any slope will do.
  final int? targetSlope;

  /// The intercept that satisfies [goal], or null when any intercept will do.
  final int? targetIntercept;

  final int startSlope;
  final int startIntercept;

  final int minSlope;
  final int maxSlope;
  final int minIntercept;
  final int maxIntercept;

  /// Whether [slope] and [intercept] answer the goal.
  bool isSatisfiedBy(int slope, int intercept) {
    if (targetSlope != null && slope != targetSlope) return false;
    if (targetIntercept != null && intercept != targetIntercept) return false;
    return true;
  }

  /// A lab with no target is pure play; the learner marks it done themselves.
  bool get isOpenEnded => targetSlope == null && targetIntercept == null;
}

/// Which mode an algebra-tile workspace is in.
enum AlgebraTilesMode {
  /// Given the factors, lay out the tiles that fill the rectangle.
  build,

  /// Given the expanded expression, find the rectangle's sides.
  factor,
}

/// Building a quadratic out of physical algebra tiles.
///
/// `x²` is a large square, `x` a rectangle and `1` a unit square. Laying
/// `(x + p)(x + q)` out as a rectangle makes the expansion visible: the
/// rectangle's area is the trinomial and its sides are the factors. Factoring
/// is the same picture read the other way, which is exactly how 6.4 and 6.5
/// teach it.
class AlgebraTilesActivityData extends LessonActivityData {
  const AlgebraTilesActivityData({
    required this.mode,
    required this.prompt,
    required this.factorP,
    required this.factorQ,
    this.maxSide = 6,
  });

  final AlgebraTilesMode mode;

  /// What the learner is being asked for, in words.
  final String prompt;

  /// The rectangle is `(x + factorP)(x + factorQ)`.
  final int factorP;
  final int factorQ;

  /// Upper bound on either side's constant, which also bounds the tile counts.
  final int maxSide;

  /// Tiles in the finished rectangle.
  int get squareTiles => 1;
  int get xTiles => factorP + factorQ;
  int get unitTiles => factorP * factorQ;

  String get factoredLabel => '(x + $factorP)(x + $factorQ)';

  String get expandedLabel {
    final middle = xTiles == 1 ? 'x' : '${xTiles}x';
    return 'x² + $middle + $unitTiles';
  }
}

class ChoiceOption {
  final String label;
  final String? emoji;
  final bool isCorrect;
  const ChoiceOption({required this.label, this.emoji, this.isCorrect = false});
}

class LessonStep {
  final String id;
  final LessonStepType type;
  final String? title;
  final String? xyDialogue;
  final String? xyAsset;
  final String? bodyText;
  final String? mathExpression;
  final String? mathAnnotation;
  final List<String>? bulletPoints;
  final String? question;
  final List<ChoiceOption>? choices;
  final int? correctChoiceIndex;
  final String? explanation;
  final String? incorrectExplanation;
  final String? buttonLabel;
  final bool isAnswerStep;
  final LessonActivityData? activity;

  const LessonStep({
    required this.id,
    required this.type,
    this.title,
    this.xyDialogue,
    this.xyAsset,
    this.bodyText,
    this.mathExpression,
    this.mathAnnotation,
    this.bulletPoints,
    this.question,
    this.choices,
    this.correctChoiceIndex,
    this.explanation,
    this.incorrectExplanation,
    this.buttonLabel,
    this.isAnswerStep = false,
    this.activity,
  });
}

class LessonContent {
  final String lessonId;
  final String title;
  final String moduleId;
  final String moduleTitle;
  final String objective;
  final String xyAsset;
  final List<LessonStep> steps;

  const LessonContent({
    required this.lessonId,
    required this.title,
    required this.moduleId,
    required this.moduleTitle,
    required this.objective,
    required this.xyAsset,
    required this.steps,
  });

  int get totalSteps => steps.length;
}

class ModuleContent {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String? xyDialogue;
  final String? xyAsset;
  final String? buttonLabel;
  final List<LessonContent> lessons;

  const ModuleContent({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.xyDialogue,
    this.xyAsset,
    this.buttonLabel,
    required this.lessons,
  });
}
