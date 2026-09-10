import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 4.4 — Two-Step Inequalities
///
/// Goal: chain inverse operations correctly, and reverse the sign only at the
/// moment a negative multiply or divide actually happens.
final m4Lesson4 = LessonContent(
  lessonId: 'm4_l4',
  title: 'Two-Step Inequalities',
  moduleId: 'module4',
  moduleTitle: 'Inequalities',
  objective:
      'Solve inequalities requiring multiple inverse operations and correctly '
      'handle negative coefficients.',
  xyAsset: AppAssets.xySitPencil,
  steps: [
    LessonStep(
      id: 'm4_l4_s01',
      type: LessonStepType.intro,
      title: 'Two Steps Again',
      bodyText: 'Build forward. Solve backward.',
      xyDialogue:
          'Just like two-step equations: undo the operations in **reverse** '
          'order. Last thing done, first thing undone.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Let\'s go',
    ),
    LessonStep(
      id: 'm4_l4_s02',
      type: LessonStepType.content,
      title: 'Undo in Reverse',
      bodyText:
          'Solve **2x + 3 < 11**.\n\nFirst subtract **3**:\n\n`2x + 3 − 3 < 11 − 3`\n\n'
          'That leaves **2x < 8**. Now divide by **2**.',
      mathExpression: 'x < 4',
      mathAnnotation: 'Two moves, in the opposite order they were applied.',
    ),
    LessonStep(
      id: 'm4_l4_s03',
      type: LessonStepType.content,
      title: 'Retrace Your Steps',
      bodyText:
          'Think about how the expression was **built**:\n\n'
          '`x  →  × 2  →  + 3`\n\nSo to solve, retrace those steps backwards:\n\n'
          '`− 3  →  ÷ 2`',
      mathExpression: '2x + 3 < 11  →  2x < 8  →  x < 4',
      mathAnnotation: 'Build forward. Solve backward.',
    ),
    LessonStep(
      id: 'm4_l4_s04',
      type: LessonStepType.content,
      title: 'Now With a Negative',
      bodyText:
          'Solve **−2x + 3 ≤ 11**.\n\nFirst subtract **3**: `−2x ≤ 8`\n\n'
          'Now divide by **−2**. ⚠️ That is a negative — so **≤** becomes **≥**.',
      mathExpression: 'x ≥ −4',
      mathAnnotation: 'The flip happens at the division, not before it.',
    ),
    LessonStep(
      id: 'm4_l4_s05',
      type: LessonStepType.xySays,
      xyDialogue:
          'The most common slip: flipping **too early**. Subtracting a number '
          'never reverses the sign — only the negative multiply or divide does.',
      xyAsset: AppAssets.xyPointUp,
    ),
    LessonStep(
      id: 'm4_l4_s06',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Don\'t Flip Too Early',
      question:
          'Solving **−3x + 4 > 10**, you subtract 4 and get **−3x > 6**. Should '
          'the sign reverse at this point?',
      choices: const [
        ChoiceOption(label: 'Yes, there is a negative'),
        ChoiceOption(label: 'No, not yet', isCorrect: true),
        ChoiceOption(label: 'Only if x is negative'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'Correct. You only subtracted 4. The flip comes next, when you divide '
          'by **−3** — giving **x < −2**.',
      incorrectExplanation:
          'Subtracting 4 is not multiplying or dividing by a negative. Wait for '
          'the division step.',
    ),
    LessonStep(
      id: 'm4_l4_s07',
      type: LessonStepType.content,
      title: 'Does Our Solution Make Sense?',
      bodyText:
          'We found **x < −2**. Test **x = −3** in the original:\n\n'
          '`−3(−3) + 4 > 10`\n`9 + 4 > 10`\n`13 > 10` ✓',
      mathExpression: '13 > 10 ✓',
      mathAnnotation: 'So −3 really does belong to the solution set.',
    ),
    LessonStep(
      id: 'm4_l4_s08',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Operation Path',
      question: 'Build the path that isolates x in **3x + 6 ≤ 18**.',
      xyDialogue: 'Put the moves in the order you would actually do them.',
      activity: const OrderingActivityData(
        items: [
          OrderingItem(id: 'sub6', label: 'Subtract 6 from both sides'),
          OrderingItem(id: 'div3', label: 'Divide both sides by 3'),
        ],
        correctOrderIds: ['sub6', 'div3'],
      ),
      explanation:
          'That\'s the path: `3x + 6 ≤ 18` → `3x ≤ 12` → **x ≤ 4**.',
      incorrectExplanation:
          'Undo the addition before the multiplication — reverse of how it was built.',
    ),
    LessonStep(
      id: 'm4_l4_s09',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Negative Challenge',
      question:
          'Solve **−2x + 4 > 10**. Subtract 4 to get **−2x > 6**, then divide by '
          '**−2**. What is the answer?',
      choices: const [
        ChoiceOption(label: 'x > −3'),
        ChoiceOption(label: 'x < −3', isCorrect: true),
        ChoiceOption(label: 'x > 3'),
        ChoiceOption(label: 'x < 3'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'Perfect. Dividing by −2 reverses **>** into **<**, giving **x < −3**.',
      incorrectExplanation:
          'You divided by a negative, so the relationship reverses. Check both '
          'the sign and the direction.',
    ),
    LessonStep(
      id: 'm4_l4_s10',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'Solve step by step — and reverse the inequality **only** when you '
          'multiply or divide by a negative.',
      xyDialogue:
          'Next up is my favourite part: turning these answers into pictures.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 4.4',
    ),
  ],
);
