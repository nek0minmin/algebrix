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
      xyDialogue:
          'Think of simplifying like organizing a messy desk. We aren\'t changing what\'s there—we\'re arranging it better!',
      xyAsset: AppAssets.xyExplaining,
      bodyText:
          'Look at this:\n\n**3x + 5 + 2x + 4**\n\nIt looks busy.\n\nBut you\'ve already learned everything you need to make it simpler!',
      mathExpression: '3x + 5 + 2x + 4',
      buttonLabel: 'Start simplifying',
    ),
    LessonStep(
      id: 'm2_l5_s02',
      type: LessonStepType.content,
      title: 'Step 1: Find Like Terms',
      bodyText:
          'Start with:\n**3x + 5 + 2x + 4**\n\nFind the matching pieces:\n• **3x** and **2x**\n• **5** and **4**\n\nGroup them:\n**(3x + 2x) + (5 + 4)**',
      mathExpression: '(3x + 2x) + (5 + 4)',
      mathAnnotation: 'Pair up like variables and constants!',
      xyDialogue: 'Group before you combine!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm2_l5_s03',
      type: LessonStepType.content,
      title: 'Step 2: Combine',
      bodyText:
          'Combine the x terms:\n**3x + 2x = 5x**\n\nCombine the constants:\n**5 + 4 = 9**\n\nTherefore:\n**5x + 9**\n\nThat\'s our simplified expression!',
      mathExpression: '3x + 5 + 2x + 4 = 5x + 9',
      xyDialogue: 'No more terms can combine, so we\'re done!',
      xyAsset: AppAssets.xyExplaining,
    ),
    LessonStep(
      id: 'm2_l5_s04',
      type: LessonStepType.content,
      title: 'Add Distribution',
      bodyText:
          'Now try:\n**2(x + 3) + 4x**\n\nWe can\'t combine everything yet. First, distribute:\n\n**2(x + 3)** becomes **2x + 6**\n\nNow we have:\n**2x + 6 + 4x**',
      mathExpression: '2(x + 3) + 4x = 2x + 6 + 4x',
      mathAnnotation: 'Distribute first to remove parentheses!',
      xyDialogue: 'Always unlock parentheses before combining!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm2_l5_s05',
      type: LessonStepType.content,
      title: 'Finish the Simplification',
      bodyText:
          'From **2x + 6 + 4x**:\n\nFind the like terms:\n**2x + 4x = 6x**\n\nThe constant stays: **+6**\n\nTherefore:\n**2(x + 3) + 4x = 6x + 6**',
      mathExpression: '2(x + 3) + 4x = 6x + 6',
      xyDialogue: 'See how our earlier lessons are starting to work together?',
      xyAsset: AppAssets.xyHappy,
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
          'Awesome! 5x + 3x = 8x, and 2 + 4 = 6, giving 8x + 6 🎉',
      incorrectExplanation:
          'Combine the x terms (5x + 3x) and the constants (2 + 4) separately.',
    ),
    LessonStep(
      id: 'm2_l5_s07',
      type: LessonStepType.summary,
      title: 'What Does "Simplified" Mean?',
      bodyText:
          'Simplifying doesn\'t mean making an expression smaller.\n\nIt means rewriting it in a form that is **easier to understand or work with without changing its value**.\n\nFor example, **3x + 2x + 4** and **5x + 4** represent the exact same quantity.',
      mathExpression: '3x + 2x + 4 \\equiv 5x + 4',
      xyDialogue: 'We changed how it looks—not what it means!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Finish Lesson',
    ),
  ],
);
