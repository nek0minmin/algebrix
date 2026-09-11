import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 5.7 — Module 5 Challenge: Line Quest
///
/// Mirrors the Module 3 Challenge: ten mixed items that pull from every lesson
/// in the module rather than drilling one skill.
final m5Lesson7 = LessonContent(
  lessonId: 'm5_l7',
  title: 'Module 5 Challenge',
  moduleId: 'module5',
  moduleTitle: 'Linear Relationships',
  objective:
      'Prove mastery of linear relationships across ten mixed challenges '
      'spanning plotting, slope, equations and graphs.',
  xyAsset: AppAssets.xyHappy,
  steps: [
    LessonStep(
      id: 'm5_l7_s01',
      type: LessonStepType.intro,
      title: 'Line Quest',
      bodyText: 'The Ultimate Linear Challenge',
      xyDialogue:
          'Everything from this module, mixed together. Ten challenges stand '
          'between you and the title of **Line Reader**.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Start Challenge →',
    ),
    LessonStep(
      id: 'm5_l7_s02',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 1: Read the Pair',
      question: 'Where does the point **(−2, 3)** sit?',
      choices: const [
        ChoiceOption(label: '2 left and 3 up', isCorrect: true),
        ChoiceOption(label: '2 right and 3 up'),
        ChoiceOption(label: '3 left and 2 up'),
        ChoiceOption(label: '2 down and 3 left'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'x comes first. A negative x means left, and a positive y means up.',
      incorrectExplanation:
          'Read the first number as horizontal movement. Negative goes left.',
    ),
    LessonStep(
      id: 'm5_l7_s03',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Challenge 2: Plot It',
      xyDialogue: 'Put **(−2, 3)** on the grid.',
      activity: const CoordinatePlaneActivityData(
        targets: [GridPoint(-2, 3)],
        minX: -4,
        maxX: 4,
        minY: -2,
        maxY: 4,
        prompt: 'Plot the point (−2, 3)',
      ),
      explanation: 'Two steps left along x, three steps up along y.',
      incorrectExplanation:
          'Start at the origin. Move along the x-axis first, then up.',
    ),
    LessonStep(
      id: 'm5_l7_s04',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 3: Find the Slope',
      question:
          'A line passes through **(1, 2)** and **(3, 8)**. What is its slope?',
      choices: const [
        ChoiceOption(label: '3', isCorrect: true),
        ChoiceOption(label: '2'),
        ChoiceOption(label: '6'),
        ChoiceOption(label: '1/3'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'Rise over run: y climbs `8 − 2 = 6` while x runs `3 − 1 = 2`, and '
          '`6 ÷ 2 = 3`.',
      incorrectExplanation:
          'Take the change in y over the change in x, not the change in y alone.',
    ),
    LessonStep(
      id: 'm5_l7_s05',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 4: Linear or Not?',
      question:
          'As x goes **1, 2, 3**, a table\'s y goes **4, 8, 16**. Is the '
          'relationship linear?',
      choices: const [
        ChoiceOption(label: 'No — the steps are 4 then 8', isCorrect: true),
        ChoiceOption(label: 'Yes — y keeps going up'),
        ChoiceOption(label: 'Yes — the slope is 4'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'Linear means the **same** step every time. Here y doubles instead, '
          'so the graph curves.',
      incorrectExplanation:
          'Rising is not enough. Compare each step: is it always the same size?',
    ),
    LessonStep(
      id: 'm5_l7_s06',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Challenge 5: Build the Equation',
      question:
          '"A tank holds 3 litres and fills 2 litres per minute." Put the '
          'equation in order.',
      xyDialogue: 'Rate first, starting amount last.',
      activity: const OrderingActivityData(
        items: [
          OrderingItem(id: 'rate', label: '2x  (litres per minute)'),
          OrderingItem(id: 'plus', label: '+'),
          OrderingItem(id: 'start', label: '3  (litres to begin)'),
        ],
        correctOrderIds: ['rate', 'plus', 'start'],
      ),
      explanation:
          '**y = 2x + 3**. The rate rides with x; the starting amount is added on.',
      incorrectExplanation:
          'Which number changes with time, and which one was there at minute 0?',
    ),
    LessonStep(
      id: 'm5_l7_s07',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 6: Spot the Intercept',
      question: 'Where does **y = −3x + 7** cross the y-axis?',
      choices: const [
        ChoiceOption(label: '7', isCorrect: true),
        ChoiceOption(label: '−3'),
        ChoiceOption(label: '−7'),
        ChoiceOption(label: '3'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'At the y-axis, x is 0, so `y = −3(0) + 7 = 7`. The **b** in '
          '`y = mx + b` is the intercept.',
      incorrectExplanation:
          'The number attached to x is the slope. The lone number is the intercept.',
    ),
    LessonStep(
      id: 'm5_l7_s08',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 7: Evaluate',
      question: 'For **y = 4x − 5**, what is y when **x = 3**?',
      choices: const [
        ChoiceOption(label: '7', isCorrect: true),
        ChoiceOption(label: '17'),
        ChoiceOption(label: '2'),
        ChoiceOption(label: '−2'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation: 'Substitute: `4 × 3 = 12`, then `12 − 5 = 7`.',
      incorrectExplanation:
          'Multiply before subtracting — the order of operations still applies.',
    ),
    LessonStep(
      id: 'm5_l7_s09',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Challenge 8: Graph the Line',
      xyDialogue: 'Plot **y = 2x − 1** at x = 0, 1 and 2.',
      activity: const CoordinatePlaneActivityData(
        targets: [GridPoint(0, -1), GridPoint(1, 1), GridPoint(2, 3)],
        minX: -1,
        maxX: 3,
        minY: -2,
        maxY: 4,
        prompt: 'Plot three points on y = 2x − 1',
        connectWhenComplete: true,
      ),
      explanation:
          'Start at the intercept **−1**, then climb 2 for every 1 across.',
      incorrectExplanation:
          'At x = 0 the answer is just b. Then add the slope for each step right.',
    ),
    LessonStep(
      id: 'm5_l7_s10',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 9: Read the Story',
      question:
          'A graph of savings per week follows **y = 15x + 40**. What does the '
          '**15** mean?',
      choices: const [
        ChoiceOption(label: 'They save 15 each week', isCorrect: true),
        ChoiceOption(label: 'They started with 15'),
        ChoiceOption(label: 'They saved 15 in total'),
        ChoiceOption(label: 'It takes 15 weeks'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'The slope is a **rate**: 15 saved per week. The 40 is what they '
          'started with.',
      incorrectExplanation:
          'Which number rides with x? That one describes change over time.',
    ),
    LessonStep(
      id: 'm5_l7_s11',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 10: Catch the Error',
      question:
          'A learner says **y = −2x + 6** rises from left to right. What went '
          'wrong?',
      choices: const [
        ChoiceOption(
          label: 'A negative slope falls, not rises',
          isCorrect: true,
        ),
        ChoiceOption(label: 'The +6 makes it fall'),
        ChoiceOption(label: 'Nothing — it does rise'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'A negative slope means y **drops** as x grows. The **+6** only sets '
          'where the line starts.',
      incorrectExplanation:
          'Look at the sign on the slope, not the intercept.',
    ),
    LessonStep(
      id: 'm5_l7_s12',
      type: LessonStepType.summary,
      title: 'Challenge Complete',
      bodyText:
          'You can move between a **story**, a **table**, an **equation** and a '
          '**graph** in any direction.',
      xyDialogue:
          'One more stop before the quiz — and this one has no right answers at all.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete the Challenge',
    ),
  ],
);
