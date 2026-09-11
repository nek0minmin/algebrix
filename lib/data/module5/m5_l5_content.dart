import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 5.5 — Graphing Linear Equations
final m5Lesson5 = LessonContent(
  lessonId: 'm5_l5',
  title: 'Graphing Linear Equations',
  moduleId: 'module5',
  moduleTitle: 'Linear Relationships',
  objective:
      'Turn y = mx + b into a graph by starting at the intercept and stepping '
      'out the slope.',
  xyAsset: AppAssets.xyBalance,
  steps: [
    LessonStep(
      id: 'm5_l5_s01',
      type: LessonStepType.intro,
      title: 'Turn an Equation Into a Picture',
      bodyText: 'Two numbers are all you need.',
      xyDialogue:
          '**y = 2x + 1** hands you everything: **b = 1** says where to start, '
          '**m = 2** says how to move.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Draw it',
    ),
    LessonStep(
      id: 'm5_l5_s02',
      type: LessonStepType.content,
      title: 'Start With b',
      bodyText:
          'In **y = 2x + 1** the y-intercept is **b = 1**.\n\nSo the first '
          'point is **(0, 1)** — on the y-axis, one step up.',
      mathExpression: '(0, 1)',
      mathAnnotation: 'The intercept is always your first point.',
    ),
    LessonStep(
      id: 'm5_l5_s03',
      type: LessonStepType.content,
      title: 'Follow the Slope',
      bodyText:
          'The slope **m = 2** can be written as `2/1`.\n\nFrom **(0, 1)**:\n\n'
          '• run **+1** to the right\n'
          '• rise **+2** upward\n\n'
          'You land on **(1, 3)**. Repeat for **(2, 5)** and **(3, 7)**.',
      mathExpression: '(0,1) → (1,3) → (2,5)',
      mathAnnotation: 'Same move, over and over. That is what constant means.',
    ),
    LessonStep(
      id: 'm5_l5_s04',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Draw the Line',
      xyDialogue:
          'Graph **y = 2x + 1**. Start at the intercept, then step out the '
          'slope twice.',
      activity: const CoordinatePlaneActivityData(
        targets: [GridPoint(0, 1), GridPoint(1, 3), GridPoint(2, 5)],
        minX: -2,
        maxX: 4,
        minY: -1,
        maxY: 6,
        prompt: 'Plot (0, 1), then follow m = 2',
        connectWhenComplete: true,
      ),
      explanation:
          'Line created. Every point on it satisfies **y = 2x + 1**.',
      incorrectExplanation:
          'Start on the y-axis at 1. Then go 1 right and 2 up, twice.',
    ),
    LessonStep(
      id: 'm5_l5_s05',
      type: LessonStepType.content,
      title: 'Negative Slope',
      bodyText:
          'Graph **y = −2x + 3**.\n\nStart at **(0, 3)**. The slope `−2/1` '
          'means:\n\n'
          '• run **+1** right\n'
          '• rise **−2**, which is **down** 2\n\n'
          'That gives **(1, 1)**, then **(2, −1)**.',
      mathExpression: 'y = −2x + 3',
      mathAnnotation: 'A negative slope falls as you read left to right.',
    ),
    LessonStep(
      id: 'm5_l5_s06',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Graph a Falling Line',
      xyDialogue: 'Now graph **y = −2x + 3**. Watch the direction of the rise.',
      activity: const CoordinatePlaneActivityData(
        targets: [GridPoint(0, 3), GridPoint(1, 1), GridPoint(2, -1)],
        minX: -2,
        maxX: 4,
        minY: -3,
        maxY: 5,
        prompt: 'Plot (0, 3), then follow m = −2',
        connectWhenComplete: true,
      ),
      explanation:
          'The line falls from left to right — exactly what a negative slope '
          'looks like.',
      incorrectExplanation:
          'Start at (0, 3). A slope of −2 means 1 across and 2 **down** each time.',
    ),
    LessonStep(
      id: 'm5_l5_s07',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Fix the Graph',
      question:
          'Someone graphed **y = 2x + 1** but started their line at **(0, 2)**. '
          'What should be fixed?',
      choices: const [
        ChoiceOption(label: 'The slope is wrong'),
        ChoiceOption(label: 'It must cross at (0, 1)', isCorrect: true),
        ChoiceOption(label: 'Nothing, it is fine'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'In **y = 2x + 1** the intercept is **b = 1**, so the line has to '
          'cross the y-axis at **(0, 1)**, not (0, 2).',
      incorrectExplanation:
          'Check the lone number in the equation — that is where the line meets '
          'the y-axis.',
    ),
    LessonStep(
      id: 'm5_l5_s08',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'Graphing is two moves: **start at b**, then **step out m** as many '
          'times as you like.',
      xyDialogue:
          'You can build a graph from an equation now. Next: reading one '
          'backwards.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 5.5',
    ),
  ],
);
