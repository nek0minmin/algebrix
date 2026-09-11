import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 5.4 — Building Linear Equations
///
/// y = mx + b arrives as something the learner assembles from a rate and a
/// starting value, not as a formula handed down.
final m5Lesson4 = LessonContent(
  lessonId: 'm5_l4',
  title: 'Building Linear Equations',
  moduleId: 'module5',
  moduleTitle: 'Linear Relationships',
  objective:
      'Build y = mx + b from a rate of change and a starting value, and say '
      'what each part means.',
  xyAsset: AppAssets.xySitPencil,
  steps: [
    LessonStep(
      id: 'm5_l4_s01',
      type: LessonStepType.intro,
      title: 'Can We Describe the Pattern?',
      bodyText: 'A rate, plus a place to start.',
      xyDialogue:
          'Our table climbs by **2** each step, so the slope is **m = 2**. But '
          'look at what happens when **x = 0**…',
      xyAsset: AppAssets.xyQuestion,
      buttonLabel: 'Show me',
    ),
    LessonStep(
      id: 'm5_l4_s02',
      type: LessonStepType.content,
      title: 'Meet the Starting Value',
      bodyText:
          'In our table, when **x = 0** we already have **y = 1**.\n\n'
          'The line crosses the y-axis at **1**. That value is the '
          '**y-intercept**, and we call it **b**.',
      mathExpression: 'b = 1',
      mathAnnotation: 'The value of y before x has done anything.',
    ),
    LessonStep(
      id: 'm5_l4_s03',
      type: LessonStepType.content,
      title: 'Put Them Together',
      bodyText:
          'We have a rate and a start:\n\n'
          '• slope **m = 2**\n'
          '• starting value **b = 1**\n\n'
          'Slot them into `y = mx + b`.',
      mathExpression: 'y = 2x + 1',
      mathAnnotation: 'One equation now describes the whole relationship.',
    ),
    LessonStep(
      id: 'm5_l4_s04',
      type: LessonStepType.xySays,
      xyDialogue:
          '`y = mx + b` is not really a formula. It is a sentence: **start at b, '
          'then repeat the change m**.',
      xyAsset: AppAssets.xyInsight,
    ),
    LessonStep(
      id: 'm5_l4_s05',
      type: LessonStepType.content,
      title: 'What Each Piece Means',
      bodyText:
          'Take **y = 2x + 1** apart:\n\n'
          '• **2** is the slope — how quickly y changes\n'
          '• **1** is the y-intercept — where things begin when x = 0',
      mathExpression: 'y = mx + b',
      mathAnnotation: 'Starting value, plus repeated change.',
    ),
    LessonStep(
      id: 'm5_l4_s06',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Read the Equation',
      question:
          'In **y = 3x + 2**, what does the **2** tell you?',
      choices: const [
        ChoiceOption(label: 'y when x is 0', isCorrect: true),
        ChoiceOption(label: 'How fast y grows'),
        ChoiceOption(label: 'The value of x'),
      ],
      correctChoiceIndex: 0,
      explanation:
          'Correct. Put x = 0 and you get **y = 2**, so the line starts at '
          '**(0, 2)**. The **3** is the rate.',
      incorrectExplanation:
          'The number attached to x is the rate. The lone number is the start.',
    ),
    LessonStep(
      id: 'm5_l4_s07',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Equation Builder',
      question:
          'You begin with **2 stars** and earn **3 stars per level**. Put the '
          'pieces in order to build the equation.',
      xyDialogue: 'Rate first, then the starting value.',
      activity: const OrderingActivityData(
        items: [
          OrderingItem(id: 'rate', label: '3x  (the rate)'),
          OrderingItem(id: 'plus', label: '+'),
          OrderingItem(id: 'start', label: '2  (the start)'),
        ],
        correctOrderIds: ['rate', 'plus', 'start'],
      ),
      explanation:
          'That builds **y = 3x + 2**. The **3** is stars per level, the **2** '
          'is what you had before level 1.',
      incorrectExplanation:
          'In `y = mx + b` the rate rides with x and comes first; the starting '
          'value is added on the end.',
    ),
    LessonStep(
      id: 'm5_l4_s08',
      type: LessonStepType.content,
      title: 'Build It From a Table',
      bodyText:
          'x runs 0, 1, 2, 3 and y runs **4, 6, 8, 10**.\n\n'
          '• The rate is **+2**, so **m = 2**\n'
          '• At x = 0, y is **4**, so **b = 4**',
      mathExpression: 'y = 2x + 4',
      mathAnnotation: 'Read the rate from the jumps, the start from x = 0.',
    ),
    LessonStep(
      id: 'm5_l4_s09',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Your Turn From a Table',
      question:
          'x runs 0, 1, 2, 3 and y runs **5, 9, 13, 17**. What is the equation?',
      choices: const [
        ChoiceOption(label: 'y = 5x + 4'),
        ChoiceOption(label: 'y = 4x + 5', isCorrect: true),
        ChoiceOption(label: 'y = 4x'),
        ChoiceOption(label: 'y = 9x + 5'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'Each step adds **4**, so m = 4. At x = 0 we have **5**, so b = 5. '
          'That gives **y = 4x + 5**.',
      incorrectExplanation:
          'The rate multiplies x. The value at x = 0 is added on. Do not swap them.',
    ),
    LessonStep(
      id: 'm5_l4_s10',
      type: LessonStepType.content,
      title: 'Change the Equation',
      bodyText:
          'Two dials control every straight line.\n\n'
          '• Change **m** and the line **rotates** — steeper, flatter, or '
          'tipping the other way\n'
          '• Change **b** and the line **slides** up or down without turning',
      mathExpression: 'y = mx + b',
      mathAnnotation: 'm turns the line. b moves it.',
    ),
    LessonStep(
      id: 'm5_l4_s11',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Which Dial?',
      question:
          'Going from **y = 2x + 1** to **y = 2x + 4**, what happened to the line?',
      choices: const [
        ChoiceOption(label: 'It got steeper'),
        ChoiceOption(label: 'It slid up', isCorrect: true),
        ChoiceOption(label: 'It flipped direction'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'The slope stayed at **2**, so the tilt is unchanged. Only **b** '
          'moved, sliding the whole line up.',
      incorrectExplanation:
          'Compare the number in front of x. If it did not change, the steepness '
          'did not change either.',
    ),
    LessonStep(
      id: 'm5_l4_s12',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          '**y = mx + b** is a description, not a spell: a starting value plus '
          'a repeated change.',
      xyDialogue: 'Now let us turn one of these into a picture.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 5.4',
    ),
  ],
);
