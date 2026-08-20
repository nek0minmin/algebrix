import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m2Lesson6 = LessonContent(
  lessonId: 'm2_l6',
  title: 'Evaluating Expressions',
  moduleId: 'module2',
  moduleTitle: 'Working with Expressions',
  objective:
      'Substitute numeric values into variables and calculate the result using order of operations.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm2_l6_s01',
      type: LessonStepType.intro,
      title: 'What If We Know x?',
      bodyText: 'Evaluating algebraic expressions',
      xyDialogue:
          'Until now, we didn\'t know what x was. But what if x = 4? Now we can find the expression\'s actual numeric value!',
      xyAsset: AppAssets.xyWave,
      buttonLabel: 'Learn substitution →',
    ),
    LessonStep(
      id: 'm2_l6_s02',
      type: LessonStepType.content,
      title: 'Step 1: Substitute',
      bodyText:
          'We have **3x + 2** and **x = 4**.\n\nReplace x with 4. This is called **substitution**.\n\nSo **3x + 2** becomes **3(4) + 2**.\n\n(Remember: 3(4) means 3 × 4).',
      mathExpression: '3x + 2  →  3(4) + 2',
      mathAnnotation: 'Substitute 4 wherever x appears!',
    ),
    LessonStep(
      id: 'm2_l6_s03',
      type: LessonStepType.xySays,
      xyDialogue:
          'Use parentheses around the number when substituting to keep multiplication crystal clear!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm2_l6_s04',
      type: LessonStepType.content,
      title: 'Step 2: Evaluate',
      bodyText:
          'Now use the order of operations:\n**3(4) + 2**\n\n1. Multiply first: **12 + 2**\n2. Then add: **14**\n\nSo when x = 4, **3x + 2 = 14**!',
      mathExpression: '3(4) + 2 = 12 + 2 = 14',
      mathAnnotation: 'Multiply first, then add!',
    ),
    LessonStep(
      id: 'm2_l6_s05',
      type: LessonStepType.quiz,
      title: 'Your Turn',
      question:
          'If x = 5, evaluate: 2x + 3\n\n1. Substitute: 2(5) + 3\n2. Multiply: 10 + 3\n3. What is the final value?',
      choices: [
        ChoiceOption(label: '10', emoji: '❌'),
        ChoiceOption(label: '13', emoji: '✅', isCorrect: true),
        ChoiceOption(label: '16', emoji: '❌'),
        ChoiceOption(label: '28', emoji: '❌'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation: 'Spot on! 2(5) + 3 = 10 + 3 = 13 ✅',
      incorrectExplanation:
          'Multiply 2 by 5 first (which is 10), then add 3.',
    ),
    LessonStep(
      id: 'm2_l6_s06',
      type: LessonStepType.content,
      title: 'Two Variables',
      bodyText:
          'Sometimes there\'s more than one variable:\n\nIf **a = 3** and **b = 4**, evaluate:\n**2a + b**\n\n1. Substitute: **2(3) + 4**\n2. Evaluate: **6 + 4 = 10**',
      mathExpression: '2(3) + 4 = 6 + 4 = 10',
      mathAnnotation: 'Keep track of which number belongs to which letter!',
    ),
    LessonStep(
      id: 'm2_l6_s07',
      type: LessonStepType.summary,
      title: 'Connect the Dots',
      bodyText:
          'Look how far we\'ve come!\nFor **3x + 2x + 4** when **x = 2**:\n\n1. First, simplify: **5x + 4**\n2. Substitute: **5(2) + 4**\n3. Evaluate: **10 + 4 = 14**\n\nYou learned:\n• Substitution replaces variable letters with numbers\n• Always use order of operations to calculate\n• Simplify first before substituting to make calculations easier',
      mathExpression: '3x + 2x + 4  →  5x + 4  →  5(2) + 4 = 14',
      mathAnnotation: 'Simplify → Substitute → Evaluate!',
      xyDialogue:
          'You just combined like terms, simplified an expression, substituted a value, AND used order of operations!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Finish Lesson',
    ),
  ],
);
