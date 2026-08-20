import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m2Lesson5 = LessonContent(
  lessonId: 'm2_l5',
  title: 'Simplifying Expressions',
  moduleId: 'module2',
  moduleTitle: 'Working with Expressions',
  objective:
      'Combine distribution and like terms to write expressions in simplest form.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm2_l5_s01',
      type: LessonStepType.intro,
      title: 'Clean It Up!',
      bodyText: 'Simplifying algebraic expressions',
      xyDialogue:
          'Look at 3x + 5 + 2x + 4. It looks busy, but you already have all the tools to clean it up! Let\'s organize it step-by-step.',
      xyAsset: AppAssets.xyWave,
      buttonLabel: 'Start simplifying →',
    ),
    LessonStep(
      id: 'm2_l5_s02',
      type: LessonStepType.xySays,
      xyDialogue:
          'Think of simplifying like organizing a messy desk. We aren\'t changing what\'s there—we\'re arranging it better!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm2_l5_s03',
      type: LessonStepType.content,
      title: 'Step 1: Find Like Terms',
      bodyText:
          'Start with: **3x + 5 + 2x + 4**\n\n1. Find the matching pieces:\n• **3x** and **2x**\n• **5** and **4**\n\n2. Group them together:\n**(3x + 2x) + (5 + 4)**',
      mathExpression: '(3x + 2x) + (5 + 4)',
      mathAnnotation: 'Pair up like variables and constants!',
    ),
    LessonStep(
      id: 'm2_l5_s04',
      type: LessonStepType.content,
      title: 'Step 2: Combine',
      bodyText:
          'Combine the x terms:\n**3x + 2x = 5x**\n\nCombine the constants:\n**5 + 4 = 9**\n\nTherefore:\n**5x + 9**',
      mathExpression: '3x + 5 + 2x + 4 = 5x + 9',
      mathAnnotation: 'Fully combined and simplified: 5x + 9',
    ),
    LessonStep(
      id: 'm2_l5_s05',
      type: LessonStepType.content,
      title: 'Add Distribution',
      bodyText:
          'Now try:\n**2(x + 3) + 4x**\n\n1. Distribute first:\n**2(x + 3) → 2x + 6**\n\n2. Rewrite expression:\n**2x + 6 + 4x**\n\n3. Combine like terms:\n**(2x + 4x) + 6 = 6x + 6**',
      mathExpression: '2(x + 3) + 4x = 6x + 6',
      mathAnnotation: 'Distribute first, then combine like terms!',
    ),
    LessonStep(
      id: 'm2_l5_s06',
      type: LessonStepType.quiz,
      title: 'Your Turn',
      question:
          'Simplify: 5x + 2 + 3x + 4\n\nStep 1: 5x + 3x\nStep 2: 2 + 4\n\nWhat is the simplified expression?',
      choices: [
        ChoiceOption(label: '8x + 6', isCorrect: true),
        ChoiceOption(label: '14x'),
        ChoiceOption(label: '8x + 2'),
        ChoiceOption(label: '15x + 8'),
      ],
      correctChoiceIndex: 0,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation:
          'Awesome! 5x + 3x = 8x, and 2 + 4 = 6, giving 8x + 6.',
      incorrectExplanation:
          'Combine the x terms (5x + 3x) and the constants (2 + 4) separately.',
    ),
    LessonStep(
      id: 'm2_l5_s07',
      type: LessonStepType.summary,
      title: 'What Does "Simplified" Mean?',
      bodyText:
          'Simplifying doesn\'t mean making an expression smaller.\n\nIt means rewriting it in a form that is **easier to understand or work with without changing its value**.\n\nFor example, **3x + 2x + 4** and **5x + 4** represent the exact same quantity.\n\nYou learned:\n• Step 1: Distribute to clear parentheses\n• Step 2: Group like variable terms and constants\n• Step 3: Combine coefficients\n• Simplified expressions retain their exact same value',
      mathExpression: '3x + 2x + 4 = 5x + 4',
      mathAnnotation: 'Both forms have the exact same value!',
      xyDialogue: 'We changed how it looks—not what it means!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Finish Lesson',
    ),
  ],
);
