import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 5.6 — Reading Linear Graphs
///
/// The conceptual payoff of the module: slope and intercept stop being numbers
/// on a page and start meaning something about a real situation.
final m5Lesson6 = LessonContent(
  lessonId: 'm5_l6',
  title: 'Reading Linear Graphs',
  moduleId: 'module5',
  moduleTitle: 'Linear Relationships',
  objective:
      'Interpret slope and y-intercept in context, and connect a story, an '
      'equation and a graph as one relationship.',
  xyAsset: AppAssets.xyInsight,
  steps: [
    LessonStep(
      id: 'm5_l6_s01',
      type: LessonStepType.intro,
      title: 'A Graph Tells a Story',
      bodyText: 'Every point means something.',
      xyDialogue:
          'If x is **hours studied** and y is **questions finished**, then the '
          'point **(2, 20)** is a sentence: after 2 hours, 20 questions done.',
      xyAsset: AppAssets.xyQuestion,
      buttonLabel: 'Read it',
    ),
    LessonStep(
      id: 'm5_l6_s02',
      type: LessonStepType.content,
      title: 'What the Slope Tells Us',
      bodyText:
          'The line passes through **(1, 10)**, **(2, 20)**, **(3, 30)**.\n\n'
          'Every extra hour adds **10 questions**, so the slope is **10**.\n\n'
          'In context that reads as **10 questions per hour**.',
      mathExpression: 'slope = 10 per hour',
      mathAnnotation: 'Slope is not just a number. It is a rate.',
    ),
    LessonStep(
      id: 'm5_l6_s03',
      type: LessonStepType.content,
      title: 'What the Intercept Tells Us',
      bodyText:
          'Take **y = 10x + 5**.\n\nAt **x = 0** we already have **y = 5**.\n\n'
          'So the graph begins with **5 questions already done** — the '
          'y-intercept is the **starting amount**.',
      mathExpression: 'b = starting amount',
      mathAnnotation: 'Where the story begins, before any time has passed.',
    ),
    LessonStep(
      id: 'm5_l6_s04',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Graph Story',
      question:
          'A graph of coins over levels follows **y = 4x + 6**. How many coins '
          'did the player **start** with?',
      choices: const [
        ChoiceOption(label: '4'),
        ChoiceOption(label: '6', isCorrect: true),
        ChoiceOption(label: '10'),
        ChoiceOption(label: '0'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'At level 0 they had **6** coins. The **4** is what each level adds.',
      incorrectExplanation:
          'Starting amount means x = 0. Which part of the equation survives '
          'when x is 0?',
    ),
    LessonStep(
      id: 'm5_l6_s05',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'What Does This Point Mean?',
      question:
          'On that same coins-per-level graph, what does **(3, 18)** say?',
      choices: const [
        ChoiceOption(label: '3 coins at level 18'),
        ChoiceOption(label: '18 coins at level 3', isCorrect: true),
        ChoiceOption(label: '18 coins earned per level'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'x is the level and y is the coins, so **(3, 18)** means 18 coins at '
          'level 3. Check it: `4(3) + 6 = 18` ✓',
      incorrectExplanation:
          'The first number is always x — here that is the level.',
    ),
    LessonStep(
      id: 'm5_l6_s06',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Match the Story',
      question:
          '"You start with 5 coins and earn 2 every level." Put the pieces of '
          'its equation in order.',
      xyDialogue:
          'A story, an equation and a graph are three ways of saying one thing.',
      activity: const OrderingActivityData(
        items: [
          OrderingItem(id: 'rate', label: '2x  (earned per level)'),
          OrderingItem(id: 'plus', label: '+'),
          OrderingItem(id: 'start', label: '5  (coins to begin)'),
        ],
        correctOrderIds: ['rate', 'plus', 'start'],
      ),
      explanation:
          'That is **y = 2x + 5** — and its graph crosses the y-axis at 5 and '
          'climbs 2 per level. Same relationship, three ways.',
      incorrectExplanation:
          'The amount earned each level rides with x. The starting pile is added on.',
    ),
    LessonStep(
      id: 'm5_l6_s07',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Story to Graph',
      xyDialogue:
          'Graph that same story — **y = 2x + 5** — for levels 0, 1 and 2.',
      activity: const CoordinatePlaneActivityData(
        targets: [GridPoint(0, 5), GridPoint(1, 7), GridPoint(2, 9)],
        minX: -1,
        maxX: 4,
        minY: 0,
        maxY: 10,
        prompt: 'Plot the first three levels',
        connectWhenComplete: true,
      ),
      explanation:
          'Start at 5 coins, then climb 2 per level. The story, the equation '
          'and the line all agree.',
      incorrectExplanation:
          'At level 0 the player has 5 coins. Each level after that adds 2.',
    ),
    LessonStep(
      id: 'm5_l6_s08',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'A story, an equation and a graph are not three topics. They are '
          '**three ways of describing the same relationship**.',
      xyDialogue:
          'You can now go in any direction between them. That is the whole '
          'module in one sentence.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 5.6',
    ),
  ],
);
