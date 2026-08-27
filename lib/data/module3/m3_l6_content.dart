import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m3Lesson6 = LessonContent(
  lessonId: 'm3_l6',
  title: 'Equations with Parentheses',
  moduleId: 'module3',
  moduleTitle: 'Solving Equations',
  objective:
      'Solve linear equations involving parentheses by applying the Distributive Property, combining like terms, and isolating the variable.',
  xyAsset: AppAssets.xyIdea,
  steps: [
    LessonStep(
      id: 'm3_l6_s01',
      type: LessonStepType.intro,
      title: 'Something\'s Inside!',
      bodyText: 'Equations with Parentheses',
      xyDialogue:
          'Solve 2(x + 3) = 14. You\'ve seen those parentheses before in Module 2! Remember the Distributive Property? 2(x + 3) becomes 2x + 6.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Distribute & Solve →',
    ),
    LessonStep(
      id: 'm3_l6_s02',
      type: LessonStepType.content,
      title: 'Distribute First',
      bodyText:
          'Start:\n\n**2(x + 3) = 14**\n\nDistribute 2 across the parentheses:\n\n**2(x) + 2(3) = 14**\n\n**2x + 6 = 14**\n\nNow we have an ordinary two-step equation!',
      mathExpression: '2(x + 3) = 14   ⇒   2x + 6 = 14',
      mathAnnotation: 'Step 1: Clear parentheses with distribution.',
    ),
    LessonStep(
      id: 'm3_l6_s03',
      type: LessonStepType.content,
      title: 'Solve It',
      bodyText:
          'From **2x + 6 = 14**:\n\n1. Subtract 6 from both sides:\n**2x = 8**\n\n2. Divide both sides by 2:\n**x = 4** 🎉\n\nA new-looking equation can often become something you already know how to solve!',
      mathExpression: '2x + 6 = 14  ⇒  2x = 8  ⇒  x = 4',
      mathAnnotation: 'Step 2: Solve the simplified two-step equation.',
    ),
    LessonStep(
      id: 'm3_l6_s04',
      type: LessonStepType.content,
      title: 'Combine What You\'ve Learned',
      bodyText:
          'Try:\n\n**3(x + 2) + x = 14**\n\n1. Distribute:\n**3x + 6 + x = 14**\n\n2. Combine like terms (3x + x):\n**4x + 6 = 14**\n\n3. Now solve:\n4x = 8  ⇒  **x = 2**\n\nLook at what you used:\n✓ Distributive Property\n✓ Combining Like Terms\n✓ Inverse Operations',
      mathExpression: '3(x + 2) + x = 14  ⇒  4x + 6 = 14  ⇒  x = 2',
      mathAnnotation: 'Distribute → Combine like terms → Isolate x.',
    ),
    LessonStep(
      id: 'm3_l6_s05',
      type: LessonStepType.quiz,
      title: 'Your Turn',
      question: 'Solve for x:\n\n2(x + 4) = 18',
      choices: [
        ChoiceOption(label: 'x = 4'),
        ChoiceOption(label: 'x = 5', isCorrect: true),
        ChoiceOption(label: 'x = 7'),
        ChoiceOption(label: 'x = 9'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation: 'Great! 2x + 8 = 18  ⇒  2x = 10  ⇒  x = 5.',
      incorrectExplanation:
          'Distribute 2 first: 2(x) + 2(4) = 18, so 2x + 8 = 18. Then solve for x.',
    ),
    LessonStep(
      id: 'm3_l6_s06',
      type: LessonStepType.summary,
      title: 'Choose Your Strategy',
      bodyText:
          'For **4(x − 2) = 20**:\n\n• What should you do first? **Distribute 4**\n• Expand: **4x − 8 = 20**\n• Add 8: **4x = 28**\n• Divide by 4: **x = 7** ✓\n\nClear parentheses first to turn complex problems into simple ones!',
      mathExpression: '4(x − 2) = 20  ⇒  4x − 8 = 20  ⇒  x = 7',
      mathAnnotation: 'Distribute → Simplify → Solve!',
      xyDialogue:
          'You can unlock any equation with parentheses using the Distributive Property!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 3.6',
    ),
  ],
);
