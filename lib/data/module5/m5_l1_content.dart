import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 5.1 — Exploring the Coordinate Plane
final m5Lesson1 = LessonContent(
  lessonId: 'm5_l1',
  title: 'Exploring the Coordinate Plane',
  moduleId: 'module5',
  moduleTitle: 'Linear Relationships',
  objective:
      'Understand the x-axis, y-axis, origin, quadrants, and ordered pairs, '
      'and how coordinates describe an exact location.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm5_l1_s01',
      type: LessonStepType.intro,
      title: 'Algebra Has a Map',
      bodyText: 'Give numbers a place to live.',
      xyDialogue:
          'You have worked with numbers and variables. But what if we want to '
          '**see** where values are? Meet the **coordinate plane**.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Open the map',
    ),
    LessonStep(
      id: 'm5_l1_s02',
      type: LessonStepType.content,
      title: 'Meet the Axes',
      bodyText:
          'The plane is built from two number lines.\n\n'
          '• The **x-axis** runs sideways\n'
          '• The **y-axis** runs up and down\n\n'
          'They cross at **(0, 0)**, called the **origin**.',
      mathExpression: '(0, 0)',
      mathAnnotation: 'Every journey on the plane starts here.',
    ),
    LessonStep(
      id: 'm5_l1_s03',
      type: LessonStepType.content,
      title: 'Ordered Pairs',
      bodyText:
          'A location is written as **(x, y)** — an **ordered pair**.\n\n'
          'For **(3, 2)**:\n\n'
          '• **x = 3** → move 3 spaces right\n'
          '• **y = 2** → move 2 spaces up',
      mathExpression: '(3, 2)',
      mathAnnotation: 'Across first, then up or down.',
    ),
    LessonStep(
      id: 'm5_l1_s04',
      type: LessonStepType.xySays,
      xyDialogue:
          'My memory trick: **across first, then up**. The x-axis moves '
          'sideways, the y-axis moves up and down.',
      xyAsset: AppAssets.xyIdea,
    ),
    LessonStep(
      id: 'm5_l1_s05',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Why Does Order Matter?',
      question:
          'Are **(2, 4)** and **(4, 2)** the same point?',
      choices: const [
        ChoiceOption(label: 'Yes, same two numbers'),
        ChoiceOption(label: 'No, different places', isCorrect: true),
      ],
      correctChoiceIndex: 1,
      explanation:
          'Right. **(2, 4)** goes 2 across and 4 up. **(4, 2)** goes 4 across '
          'and 2 up. Different spots entirely.',
      incorrectExplanation:
          'The numbers match, but their jobs do not. The first is always x.',
    ),
    LessonStep(
      id: 'm5_l1_s06',
      type: LessonStepType.content,
      title: 'Negative Coordinates',
      bodyText:
          'For **(−3, 2)**:\n\n'
          '• **x = −3** → move 3 spaces **left**\n'
          '• **y = 2** → move 2 spaces **up**\n\n'
          'A negative simply sends you the opposite way.',
      mathExpression: '(−3, 2)',
      mathAnnotation: 'Left and down are just negative directions.',
    ),
    LessonStep(
      id: 'm5_l1_s07',
      type: LessonStepType.content,
      title: 'The Four Quadrants',
      bodyText:
          'The axes cut the plane into four regions.\n\n'
          '• **Quadrant I** — (+, +)\n'
          '• **Quadrant II** — (−, +)\n'
          '• **Quadrant III** — (−, −)\n'
          '• **Quadrant IV** — (+, −)\n\n'
          'A point sitting **on** an axis is not inside any quadrant.',
      mathExpression: 'I   II   III   IV',
      mathAnnotation: 'They are numbered anticlockwise from the top right.',
    ),
    LessonStep(
      id: 'm5_l1_s08',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Coordinate Hunt',
      xyDialogue: 'Find **(3, 2)**. Across first, then up.',
      activity: const CoordinatePlaneActivityData(
        targets: [GridPoint(3, 2)],
        prompt: 'Plot (3, 2)',
      ),
      explanation: 'Found it. 3 across, 2 up.',
      incorrectExplanation:
          'Count 3 along the x-axis first, then 2 up. The first number is always x.',
    ),
    LessonStep(
      id: 'm5_l1_s09',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Into the Negatives',
      xyDialogue: 'Now try **(−2, 4)**. Which way does a negative x send you?',
      activity: const CoordinatePlaneActivityData(
        targets: [GridPoint(-2, 4)],
        prompt: 'Plot (−2, 4)',
      ),
      explanation:
          'Exactly — 2 to the **left** because x is negative, then 4 up.',
      incorrectExplanation:
          'A negative x means go left of the origin, not right.',
    ),
    LessonStep(
      id: 'm5_l1_s10',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Where Am I?',
      question:
          'A point sits 4 spaces right of the origin and 2 spaces **down**. '
          'What are its coordinates?',
      choices: const [
        ChoiceOption(label: '(4, 2)'),
        ChoiceOption(label: '(4, −2)', isCorrect: true),
        ChoiceOption(label: '(−2, 4)'),
        ChoiceOption(label: '(−4, 2)'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'Right — 4 right is **x = 4**, and down makes **y = −2**.',
      incorrectExplanation:
          'Right is a positive x. Down is a negative y. Put them in order.',
    ),
    LessonStep(
      id: 'm5_l1_s11',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'Coordinates turn **locations into numbers** — and numbers back into '
          'locations.',
      xyDialogue:
          'Next we will look at what happens when points start following a '
          'pattern.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 5.1',
    ),
  ],
);
