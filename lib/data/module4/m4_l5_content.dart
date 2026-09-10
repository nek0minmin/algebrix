import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 4.5 — Graphing Inequalities
///
/// The signature lesson of Module 4. Every graphing activity splits into the
/// three decisions a graph actually encodes — boundary, inclusion, direction —
/// so the open/closed circle is understood rather than memorised.
final m4Lesson5 = LessonContent(
  lessonId: 'm4_l5',
  title: 'Graphing Inequalities',
  moduleId: 'module4',
  moduleTitle: 'Inequalities',
  objective:
      'Represent inequality solutions visually on a number line and interpret '
      'graphs as solution sets.',
  xyAsset: AppAssets.xyInsight,
  steps: [
    LessonStep(
      id: 'm4_l5_s01',
      type: LessonStepType.intro,
      title: 'How Do We Show Infinite Answers?',
      bodyText: 'You can\'t list them all. So draw them instead.',
      xyDialogue:
          '**x > 3** includes 4, 5, 10 — but also 3.1, 3.01, 3.001… There are '
          'infinitely many. Listing them is hopeless, so we **draw the range**.',
      xyAsset: AppAssets.xyQuestion,
      buttonLabel: 'Show me how',
    ),
    LessonStep(
      id: 'm4_l5_s02',
      type: LessonStepType.content,
      title: 'Meet the Boundary',
      bodyText:
          'In **x > 3**, the number **3** is the boundary.\n\nBut is 3 itself a '
          'solution? Test it:\n\n`3 > 3` ❌ false\n\nSo 3 is **not** included. We '
          'show that with an **open circle ○**.',
      mathExpression: '○  =  boundary NOT included',
      mathAnnotation: 'Hollow means "everything up to here, but not here".',
    ),
    LessonStep(
      id: 'm4_l5_s03',
      type: LessonStepType.content,
      title: 'Closed Circle',
      bodyText:
          'Now **x ≥ 3**. Is 3 allowed?\n\n`3 ≥ 3` ✓ true\n\nSo we fill it in — a '
          '**closed circle ●**.\n\n'
          '• **<** and **>** use an open **○**\n'
          '• **≤** and **≥** use a closed **●**',
      mathExpression: '●  =  boundary IS included',
      mathAnnotation: 'Test the boundary value. The circle follows the answer.',
    ),
    LessonStep(
      id: 'm4_l5_s04',
      type: LessonStepType.xySays,
      xyDialogue:
          'Don\'t memorise which symbol gets which circle. **Substitute the '
          'boundary** into the inequality. True means filled, false means hollow.',
      xyAsset: AppAssets.xyIdea,
    ),
    LessonStep(
      id: 'm4_l5_s05',
      type: LessonStepType.content,
      title: 'Which Direction?',
      bodyText:
          '**x > 3** needs every number greater than 3.\n\nOn a number line, '
          'greater numbers live to the **right →**\n\nAnd for **x ≤ 2**, smaller '
          'values live to the **left ←**',
      mathExpression: 'greater → right      smaller → left',
      mathAnnotation: 'The shaded arrow shows every value that works.',
    ),
    LessonStep(
      id: 'm4_l5_s06',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Paint the Range',
      xyDialogue:
          'Your turn. Place the boundary, decide if it counts, then paint the '
          'values that belong.',
      activity: const NumberLineActivityData(
        inequality: 'x ≥ −2',
        minValue: -5,
        maxValue: 3,
        correctBoundary: -2,
        correctMarker: NumberLineBoundary.closed,
        correctDirection: NumberLineDirection.right,
      ),
      explanation:
          'Range painted!Every point in that direction is a possible value '
          'of x — and **−2** is included because the symbol is ≥.',
      incorrectExplanation:
          'Check each decision: boundary at −2, can x equal −2 (yes, it\'s ≥), '
          'and does "greater" go left or right?',
    ),
    LessonStep(
      id: 'm4_l5_s07',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Graph Detective',
      question:
          'A graph has an **open circle at 2** with the shading running **left**. '
          'What inequality is it?',
      choices: const [
        ChoiceOption(label: 'x > 2'),
        ChoiceOption(label: 'x < 2', isCorrect: true),
        ChoiceOption(label: 'x ≤ 2'),
        ChoiceOption(label: 'x ≥ 2'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'Detective work complete. Open circle means 2 is excluded, and left '
          'means smaller — so **x < 2**.',
      incorrectExplanation:
          'Three clues: where is the boundary, is it filled in, and which way does '
          'the shading run? Open + left.',
    ),
    LessonStep(
      id: 'm4_l5_s08',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Build the Inequality',
      question:
          'A graph shows a **closed circle at 4** shading to the **right**. Build '
          'the matching inequality.',
      choices: const [
        ChoiceOption(label: 'x ≥ 4', isCorrect: true),
        ChoiceOption(label: 'x > 4'),
        ChoiceOption(label: 'x ≤ 4'),
        ChoiceOption(label: 'x < 4'),
      ],
      correctChoiceIndex: 0,
      explanation:
          'Yes — filled circle means 4 counts, right means greater. **x ≥ 4**.',
      incorrectExplanation:
          'A filled circle includes the boundary, so you need ≥ or ≤. Which '
          'direction is shaded?',
    ),
    LessonStep(
      id: 'm4_l5_s09',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Solve and Graph',
      question: 'Solve **2x + 4 > 10** first, then graph your answer.',
      xyDialogue: 'Subtract 4, divide by 2 — then draw what you found.',
      activity: const NumberLineActivityData(
        inequality: 'x > 3',
        minValue: -1,
        maxValue: 7,
        correctBoundary: 3,
        correctMarker: NumberLineBoundary.open,
        correctDirection: NumberLineDirection.right,
      ),
      explanation:
          '`2x + 4 > 10` → `2x > 6` → **x > 3**. Open circle, because 3 itself '
          'does not satisfy `3 > 3`.',
      incorrectExplanation:
          'The solution is x > 3. Since it is a plain >, the boundary is excluded.',
    ),
    LessonStep(
      id: 'm4_l5_s10',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Final Graphing Challenge',
      question:
          'Solve **−2x + 4 ≥ 10**, watch the negative, then graph the result.',
      xyDialogue: 'Everything you have learned this module, in one problem.',
      activity: const NumberLineActivityData(
        inequality: 'x ≤ −3',
        minValue: -6,
        maxValue: 2,
        correctBoundary: -3,
        correctMarker: NumberLineBoundary.closed,
        correctDirection: NumberLineDirection.left,
      ),
      explanation:
          '`−2x + 4 ≥ 10` → `−2x ≥ 6` → divide by −2 and **reverse**: **x ≤ −3**. '
          'Closed circle, shading left. You solved it, understood the boundary, '
          'and drew every possible solution.',
      incorrectExplanation:
          'Subtract 4 to get −2x ≥ 6, then divide by −2 — remember the sign '
          'reverses. That gives x ≤ −3.',
    ),
    LessonStep(
      id: 'm4_l5_s11',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'A graph is just three decisions: **where** the boundary is, **whether** '
          'it counts, and **which way** the answers run.',
      xyDialogue:
          'Equations lead to specific values. Inequalities let you explore whole '
          'ranges. You can read them both ways now.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 4.5',
    ),
  ],
);
