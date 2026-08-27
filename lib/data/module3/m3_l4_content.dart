import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m3Lesson4 = LessonContent(
  lessonId: 'm3_l4',
  title: 'Two-Step Equations',
  moduleId: 'module3',
  moduleTitle: 'Solving Equations',
  objective:
      'Solve two-step linear equations by reversing operations in backwards order (undoing addition/subtraction before multiplication/division).',
  xyAsset: AppAssets.xyIdea,
  steps: [
    LessonStep(
      id: 'm3_l4_s01',
      type: LessonStepType.intro,
      title: 'Two Things Happened!',
      bodyText: 'Reversing Multiple Operations',
      xyDialogue:
          'Consider 2x + 3 = 11. Two operations are affecting x: it was multiplied by 2, then 3 was added. To isolate x, we undo them in reverse order!',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Learn Two-Step Solving →',
    ),
    LessonStep(
      id: 'm3_l4_s02',
      type: LessonStepType.content,
      title: 'Think Backwards',
      bodyText:
          'Imagine building the expression:\n\n**x → ×2 → +3 → 11**\n\nTo solve and go backward:\n\n**11 → −3 → ÷2 → x**\n\nSolving is like **retracing your steps**!',
      mathExpression: 'Forward: x → ×2 → +3 = 11\nBackward: 11 → −3 → ÷2 = x',
      mathAnnotation: 'Reverse the journey to isolate x!',
    ),
    LessonStep(
      id: 'm3_l4_s03',
      type: LessonStepType.content,
      title: 'First Move',
      bodyText:
          'Solve:\n\n**2x + 3 = 11**\n\nUndo **+3** first by subtracting 3 from both sides:\n\n**2x + 3 − 3 = 11 − 3**\n\nNow we have:\n\n**2x = 8**\n\nWe are one step closer!',
      mathExpression: '2x + 3 − 3 = 11 − 3   ⇒   2x = 8',
      mathAnnotation: 'Step 1: Undo addition.',
    ),
    LessonStep(
      id: 'm3_l4_s04',
      type: LessonStepType.content,
      title: 'Second Move',
      bodyText:
          'We have:\n\n**2x = 8**\n\nUndo multiplication by 2:\n\n**2x ÷ 2 = 8 ÷ 2**\n\n**x = 4** 🎉',
      mathExpression: '2x ÷ 2 = 8 ÷ 2   ⇒   x = 4',
      mathAnnotation: 'Step 2: Undo multiplication.',
    ),
    LessonStep(
      id: 'm3_l4_s05',
      type: LessonStepType.content,
      title: 'Why Not Divide First?',
      bodyText:
          'Could we divide **2x + 3 = 11** by 2 immediately?\n\nIf we do, the division must apply to the **entire side**, giving:\n\n**x + 1.5 = 5.5**\n\nThat creates fractions and unnecessary complexity!\n\nInstead, undo operations in **reverse order**:\n• **+3** → undo first (−3)\n• **×2** → undo second (÷2)',
      mathExpression: 'Undo + / − first   ⇒   Undo × / ÷ second',
      mathAnnotation: 'Choose steps that keep the math clean!',
    ),
    LessonStep(
      id: 'm3_l4_s06',
      type: LessonStepType.content,
      title: 'Another Example',
      bodyText:
          'Solve:\n\n**3x − 5 = 16**\n\n1. Undo **−5** (Add 5 to both sides):\n**3x = 21**\n\n2. Undo **×3** (Divide both sides by 3):\n**x = 7**',
      mathExpression: '3x − 5 = 16  ⇒  3x = 21  ⇒  x = 7',
      mathAnnotation: 'Two clean moves: Add 5, then divide by 3.',
    ),
    LessonStep(
      id: 'm3_l4_s07',
      type: LessonStepType.quiz,
      title: 'Your Turn',
      question: 'Solve for x:\n\n4x + 2 = 18',
      choices: [
        ChoiceOption(label: 'x = 3'),
        ChoiceOption(label: 'x = 4', isCorrect: true),
        ChoiceOption(label: 'x = 5'),
        ChoiceOption(label: 'x = 8'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation: 'Great job! 4x = 18 − 2 = 16, then 16 ÷ 4 = 4.',
      incorrectExplanation:
          'First subtract 2 from 18 to get 4x = 16. Then divide 16 by 4.',
    ),
    LessonStep(
      id: 'm3_l4_s08',
      type: LessonStepType.summary,
      title: 'Explore the Why',
      bodyText:
          'Why do we usually undo addition/subtraction before multiplication/division?\n\nBecause we are **reversing the operations that built the expression**.\n\nIf **x → ×4 → +2**, then solving goes **−2 → ÷4**.\n\n**Build forward. Solve backward.**',
      mathExpression: 'Build: → ×4 → +2   |   Solve: −2 → ÷4 ←',
      mathAnnotation: 'Build forward. Solve backward.',
      xyDialogue:
          'Retracing your steps in reverse is the key to solving any multi-step equation!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 3.4',
    ),
  ],
);
