import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 5.2 — Discovering Slope
///
/// Rise and run come first; the formula arrives only at the end, as a faster
/// way to compute an idea the learner has already walked out on a grid.
final m5Lesson2 = LessonContent(
  lessonId: 'm5_l2',
  title: 'Discovering Slope',
  moduleId: 'module5',
  moduleTitle: 'Linear Relationships',
  objective:
      'Understand slope as a rate of change, recognise positive, negative, '
      'zero and undefined slopes, and only then meet the formula.',
  xyAsset: AppAssets.xyInsight,
  steps: [
    LessonStep(
      id: 'm5_l2_s01',
      type: LessonStepType.intro,
      title: 'Points Can Tell a Story',
      bodyText: 'Watch two values change together.',
      xyDialogue:
          'Look at **(1, 2)**, **(2, 4)**, **(3, 6)**. Every time x goes up by '
          '**1**, y goes up by **2**. That pattern has a name.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Name it',
    ),
    LessonStep(
      id: 'm5_l2_s02',
      type: LessonStepType.content,
      title: 'Meet the Slope',
      bodyText:
          'A steady relationship like **x +1 → y +2** has a constant **rate of '
          'change**.\n\nWe call that rate the **slope**.\n\nSlope tells us how '
          'much **y** changes when **x** changes.',
      mathExpression: 'slope = rise ÷ run',
      mathAnnotation: 'Change in y, over change in x.',
    ),
    LessonStep(
      id: 'm5_l2_s03',
      type: LessonStepType.content,
      title: 'Rise and Run',
      bodyText:
          'Think of slope as movement.\n\n'
          '• **Rise** — how far up or down you moved\n'
          '• **Run** — how far left or right you moved\n\n'
          'Slope compares the two.',
      mathExpression: 'rise / run',
      mathAnnotation: 'Vertical change measured against horizontal change.',
    ),
    LessonStep(
      id: 'm5_l2_s04',
      type: LessonStepType.content,
      title: 'Walk the Line',
      bodyText:
          'From **(1, 2)** to **(3, 6)**:\n\n'
          '• x goes 1 → 3, so **run = +2**\n'
          '• y goes 2 → 6, so **rise = +4**\n\n'
          'That gives `4 ÷ 2`.',
      mathExpression: 'slope = 2',
      mathAnnotation: 'For every 1 step right, the line climbs 2.',
    ),
    LessonStep(
      id: 'm5_l2_s05',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Slope Steps',
      xyDialogue:
          'Plot **(1, 1)** and **(4, 3)**, then count the run and the rise '
          'between them.',
      activity: const CoordinatePlaneActivityData(
        targets: [GridPoint(1, 1), GridPoint(4, 3)],
        minX: -1,
        maxX: 5,
        minY: -1,
        maxY: 5,
        prompt: 'Plot (1, 1) and (4, 3)',
      ),
      explanation:
          'From (1, 1) to (4, 3) the **run is 3** and the **rise is 2**, so '
          'the slope is `2/3`.',
      incorrectExplanation:
          'Place both points first: (1, 1) then (4, 3). Across first, then up.',
    ),
    LessonStep(
      id: 'm5_l2_s06',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Read the Steps',
      question:
          'Between those two points the run was **3** and the rise was **2**. '
          'What is the slope?',
      choices: const [
        ChoiceOption(label: '3/2'),
        ChoiceOption(label: '2/3', isCorrect: true),
        ChoiceOption(label: '5'),
        ChoiceOption(label: '1'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'Slope is **rise over run**, so the rise goes on top: `2/3`.',
      incorrectExplanation:
          'Rise goes on top, run underneath. Rise was 2 and run was 3.',
    ),
    LessonStep(
      id: 'm5_l2_s07',
      type: LessonStepType.content,
      title: 'Four Kinds of Slope',
      bodyText:
          'Read every line from **left to right**.\n\n'
          '• Rising → **positive** slope\n'
          '• Falling → **negative** slope\n'
          '• Flat → **zero** slope, because the rise is 0\n'
          '• Straight up → **undefined**, because the run is 0',
      mathExpression: 'run = 0  →  undefined',
      mathAnnotation:
          'A vertical line would need division by zero, which is not allowed.',
    ),
    LessonStep(
      id: 'm5_l2_s08',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Slope Sorter',
      question: 'Sort each line by the kind of slope it has.',
      xyDialogue: 'Always read from left to right.',
      activity: const ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'pos', label: 'Positive'),
          ActivityCategory(id: 'neg', label: 'Negative'),
          ActivityCategory(id: 'zero', label: 'Zero'),
          ActivityCategory(id: 'undef', label: 'Undefined'),
        ],
        items: [
          ClassificationItem(id: 'up', label: 'Rises left to right', categoryId: 'pos'),
          ClassificationItem(id: 'down', label: 'Falls left to right', categoryId: 'neg'),
          ClassificationItem(id: 'flat', label: 'Perfectly flat', categoryId: 'zero'),
          ClassificationItem(id: 'vert', label: 'Straight up and down', categoryId: 'undef'),
        ],
      ),
      explanation:
          'A flat line has **no rise**, so its slope is 0. A vertical line has '
          '**no run**, so its slope is undefined.',
      incorrectExplanation:
          'Zero and undefined are easy to swap. Flat means rise = 0; vertical '
          'means run = 0, and dividing by 0 is not allowed.',
    ),
    LessonStep(
      id: 'm5_l2_s09',
      type: LessonStepType.content,
      title: 'Meet the Formula',
      bodyText:
          'Now that you know what slope **means**, we can write it down.\n\n'
          'Given **(x₁, y₁)** and **(x₂, y₂)**:\n\n'
          '`m = (y₂ − y₁) ÷ (x₂ − x₁)`\n\n'
          'That is just **change in y over change in x** — rise over run.',
      mathExpression: 'm = (y₂ − y₁) / (x₂ − x₁)',
      mathAnnotation:
          'The formula did not create the idea. It just calculates it faster.',
    ),
    LessonStep(
      id: 'm5_l2_s10',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Use the Formula',
      question:
          'Find the slope between **(2, 1)** and **(5, 7)**.',
      choices: const [
        ChoiceOption(label: '2', isCorrect: true),
        ChoiceOption(label: '3'),
        ChoiceOption(label: '1/2'),
        ChoiceOption(label: '6'),
      ],
      correctChoiceIndex: 0,
      explanation:
          '`(7 − 1) ÷ (5 − 2)` = `6 ÷ 3` = **2**. Up 2 for every 1 across.',
      incorrectExplanation:
          'Subtract the y values for the rise, the x values for the run, then '
          'divide rise by run.',
    ),
    LessonStep(
      id: 'm5_l2_s11',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'Slope is a **rate of change** — how fast y moves as x moves.',
      xyDialogue:
          'You walked it out before you calculated it. That is the order that '
          'makes it stick.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 5.2',
    ),
  ],
);
