import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 4.2 — One-Step Inequalities
///
/// Goal: solve simple inequalities with inverse operations, and see that the
/// answer is a range rather than a single value.
final m4Lesson2 = LessonContent(
  lessonId: 'm4_l2',
  title: 'One-Step Inequalities',
  moduleId: 'module4',
  moduleTitle: 'Inequalities',
  objective:
      'Solve one-step inequalities using inverse operations while preserving '
      'the relationship between both sides.',
  xyAsset: AppAssets.xyBalance,
  steps: [
    LessonStep(
      id: 'm4_l2_s01',
      type: LessonStepType.intro,
      title: 'This Looks Familiar',
      bodyText: 'Same moves. Different kind of answer.',
      xyDialogue:
          '**x + 3 < 8** looks a lot like **x + 3 = 8**. Good news — the same '
          'inverse operations still work.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Let\'s solve',
    ),
    LessonStep(
      id: 'm4_l2_s02',
      type: LessonStepType.content,
      title: 'Subtract From Both Sides',
      bodyText:
          'Solve **x + 3 < 8**.\n\nSubtract **3** from both sides:\n\n'
          '`x + 3 − 3 < 8 − 3`',
      mathExpression: 'x < 5',
      mathAnnotation:
          'One difference: the answer isn\'t a number, it\'s a range.',
    ),
    LessonStep(
      id: 'm4_l2_s03',
      type: LessonStepType.content,
      title: 'Undoing Addition',
      bodyText:
          'Solve **x + 4 > 9**.\n\nWhat is happening to x? **+4**.\n\nUndo it '
          'with **−4** on both sides:\n\n`x + 4 − 4 > 9 − 4`',
      bulletPoints: ['6 ✓', '7 ✓', '20 ✓'],
      mathExpression: 'x > 5',
      mathAnnotation:
          'Every number past 5 is a solution — infinitely many of them.',
    ),
    LessonStep(
      id: 'm4_l2_s04',
      type: LessonStepType.content,
      title: 'Undoing Subtraction',
      bodyText:
          'Solve **x − 2 ≤ 6**.\n\nUndo **−2** by adding **2** to both sides:\n\n'
          '`x − 2 + 2 ≤ 6 + 2`',
      mathExpression: 'x ≤ 8',
      mathAnnotation: 'Because the symbol is ≤, 8 itself is included.',
    ),
    LessonStep(
      id: 'm4_l2_s05',
      type: LessonStepType.content,
      title: 'Undoing Multiplication',
      bodyText:
          'Solve **3x < 12**.\n\nx is multiplied by **3**, so divide both sides '
          'by **3**:\n\n`3x ÷ 3 < 12 ÷ 3`',
      mathExpression: 'x < 4',
      mathAnnotation: 'Simple enough… for now.',
    ),
    LessonStep(
      id: 'm4_l2_s06',
      type: LessonStepType.content,
      title: 'Undoing Division',
      bodyText:
          'Solve **x ÷ 4 ≥ 3**.\n\nUndo the division by multiplying both sides '
          'by **4**:\n\n`(x ÷ 4) × 4 ≥ 3 × 4`',
      mathExpression: 'x ≥ 12',
      mathAnnotation: 'The same inverse-operation thinking you already use.',
    ),
    LessonStep(
      id: 'm4_l2_s07',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Choose Your Move',
      question: 'To solve **x − 7 > 4**, what should you do to both sides?',
      choices: const [
        ChoiceOption(label: '− 7'),
        ChoiceOption(label: '+ 7', isCorrect: true),
        ChoiceOption(label: '× 7'),
        ChoiceOption(label: '÷ 7'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'Exactly. `x − 7 + 7 > 4 + 7` gives **x > 11**.',
      incorrectExplanation:
          'x is having 7 taken away. To undo subtraction, add the same amount to '
          'both sides.',
    ),
    LessonStep(
      id: 'm4_l2_s08',
      type: LessonStepType.xySays,
      xyDialogue:
          'Every solution has a **boundary** — the number where the answer flips '
          'from working to not working. Spotting it is the whole game.',
      xyAsset: AppAssets.xyInsight,
    ),
    LessonStep(
      id: 'm4_l2_s09',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Find the Boundary',
      question:
          'Solve **x + 3 < 9**, then pick the boundary — the number where the '
          'answer changes.',
      choices: const [
        ChoiceOption(label: '3'),
        ChoiceOption(label: '6', isCorrect: true),
        ChoiceOption(label: '9'),
        ChoiceOption(label: '12'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'Nice. **x < 6**, so 6 sits right on the line between values that work '
          'and values that don\'t.',
      incorrectExplanation:
          'Subtract 3 from both sides first: `x + 3 − 3 < 9 − 3`. What number do '
          'you land on?',
    ),
    LessonStep(
      id: 'm4_l2_s10',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'Solve inequalities with the **same inverse-operation thinking** you '
          'already know — the answer is just a range.',
      xyDialogue:
          'One warning before you get comfortable: negative numbers are about to '
          'do something sneaky.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 4.2',
    ),
  ],
);
