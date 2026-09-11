import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 5.3 — Understanding Linear Relationships
final m5Lesson3 = LessonContent(
  lessonId: 'm5_l3',
  title: 'Understanding Linear Relationships',
  moduleId: 'module5',
  moduleTitle: 'Linear Relationships',
  objective:
      'Recognise a constant rate of change, and see why it produces a '
      'straight line.',
  xyAsset: AppAssets.xyLessons,
  steps: [
    LessonStep(
      id: 'm5_l3_s01',
      type: LessonStepType.intro,
      title: 'Look at This Pattern',
      bodyText: 'Same jump, every single time.',
      xyDialogue:
          'When x is 0, 1, 2, 3 the y values run 1, 3, 5, 7. Each step of x '
          'adds **2** to y. Every time.',
      xyAsset: AppAssets.xyIdea,
      buttonLabel: 'Why does that matter?',
    ),
    LessonStep(
      id: 'm5_l3_s02',
      type: LessonStepType.content,
      title: 'Constant Change',
      bodyText:
          'Follow the y values: **1 → 3 → 5 → 7**.\n\n'
          'Each change is **+2**, then **+2**, then **+2**.\n\n'
          'A relationship with a **constant rate of change** is called a '
          '**linear relationship**.',
      mathExpression: '+2   +2   +2',
      mathAnnotation: 'The word linear is a clue about what it looks like.',
    ),
    LessonStep(
      id: 'm5_l3_s03',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Connect the Pattern',
      xyDialogue:
          'Plot **(0, 0)**, **(1, 2)**, **(2, 4)** and **(3, 6)** and watch '
          'what shape they make.',
      activity: const CoordinatePlaneActivityData(
        targets: [
          GridPoint(0, 0),
          GridPoint(1, 2),
          GridPoint(2, 4),
          GridPoint(3, 6),
        ],
        minX: -1,
        maxX: 5,
        minY: -1,
        maxY: 7,
        prompt: 'Plot all four points',
        connectWhenComplete: true,
      ),
      explanation:
          'A straight line. **A constant rate of change always produces one** '
          '— that is where the word *linear* comes from.',
      incorrectExplanation:
          'Work along the table one pair at a time: (0, 0), (1, 2), (2, 4), (3, 6).',
    ),
    LessonStep(
      id: 'm5_l3_s04',
      type: LessonStepType.content,
      title: 'Is It Linear?',
      bodyText:
          'Table A has y values **3, 5, 7, 9** — the changes are **+2, +2, +2**. '
          'Linear.\n\n'
          'Table B has y values **1, 4, 9, 16** — the changes are **+3, +5, +7**. '
          'Not linear.',
      bulletPoints: ['+2 ✓', '+2 ✓', '+2 ✓'],
      mathExpression: 'constant change → linear',
      mathAnnotation: 'If the jump changes size, the graph will curve.',
    ),
    LessonStep(
      id: 'm5_l3_s05',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Linear or Not?',
      question: 'Sort each pattern of y values.',
      xyDialogue: 'Check how much y changes each time x goes up by 1.',
      activity: const ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'linear', label: 'Linear'),
          ActivityCategory(id: 'not', label: 'Not linear'),
        ],
        items: [
          ClassificationItem(id: 'a', label: '2, 5, 8, 11', categoryId: 'linear'),
          ClassificationItem(id: 'b', label: '1, 4, 9, 16', categoryId: 'not'),
          ClassificationItem(id: 'c', label: '10, 7, 4, 1', categoryId: 'linear'),
          ClassificationItem(id: 'd', label: '2, 4, 8, 16', categoryId: 'not'),
        ],
      ),
      explanation:
          '**2, 5, 8, 11** rises by 3 each time and **10, 7, 4, 1** falls by 3 '
          'each time — both constant, so both linear. Doubling is not.',
      incorrectExplanation:
          'A falling pattern can still be linear, as long as it falls by the '
          'same amount every step.',
    ),
    LessonStep(
      id: 'm5_l3_s06',
      type: LessonStepType.content,
      title: 'Relationships Are Everywhere',
      bodyText:
          'A game gives **50 coins** for every challenge you finish.\n\n'
          '• 1 challenge → 50 coins\n'
          '• 2 challenges → 100 coins\n'
          '• 3 challenges → 150 coins\n\n'
          'Each extra challenge adds the same **+50**, so the relationship is '
          '**linear**.',
      mathExpression: '+50 per challenge',
      mathAnnotation: 'A constant rate in real life is a straight line on a graph.',
    ),
    LessonStep(
      id: 'm5_l3_s07',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Spot the Rate',
      question:
          'A table shows y going **4, 9, 14, 19** as x goes 0, 1, 2, 3. Is it '
          'linear, and what is the rate?',
      choices: const [
        ChoiceOption(label: 'Linear, rate +5', isCorrect: true),
        ChoiceOption(label: 'Linear, rate +4'),
        ChoiceOption(label: 'Not linear'),
      ],
      correctChoiceIndex: 0,
      explanation:
          'Each step adds **5**, and it never changes, so it is linear with a '
          'rate of **+5**.',
      incorrectExplanation:
          'Subtract each y from the next: 9 − 4, 14 − 9, 19 − 14. Are they the same?',
    ),
    LessonStep(
      id: 'm5_l3_s08',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'A **constant rate of change** is what makes a relationship linear — '
          'and what makes its graph straight.',
      xyDialogue:
          'You have a rate and a starting value. Next we turn them into an '
          'equation.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 5.3',
    ),
  ],
);
