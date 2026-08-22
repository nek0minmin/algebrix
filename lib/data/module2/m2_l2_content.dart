import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m2Lesson2 = LessonContent(
  lessonId: 'm2_l2',
  title: 'Combining Like Terms',
  moduleId: 'module2',
  moduleTitle: 'Working with Expressions',
  objective:
      'Add and subtract coefficients of like terms to simplify expressions.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm2_l2_s01',
      type: LessonStepType.intro,
      title: 'Let\'s Put Them Together!',
      bodyText: 'Adding and subtracting like terms',
      xyDialogue:
          'You already know how to spot like terms. Now let\'s find out what happens when we *combine them*!',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Combine terms →',
    ),
    LessonStep(
      id: 'm2_l2_s02',
      type: LessonStepType.content,
      title: 'Think in Groups',
      bodyText:
          'Remember what coefficients mean:\n• **3x** means: **x + x + x** (3 groups of x)\n• **5x** means: **x + x + x + x + x** (5 groups of x)\n\nPut them together:\n**(3 + 5) groups of x = 8x**\n\nTherefore: **3x + 5x = 8x**',
      mathExpression: '(x + x + x) + (x + x + x + x + x) = 8x',
      mathAnnotation: 'Total: 8 groups of x',
    ),
    LessonStep(
      id: 'm2_l2_s03',
      type: LessonStepType.xySays,
      xyDialogue:
          'We\'re adding *how many* x\'s we have—not changing what *x* is!',
      xyAsset: AppAssets.xyIdea,
    ),
    LessonStep(
      id: 'm2_l2_s04',
      type: LessonStepType.content,
      title: 'The Rule for Combining',
      bodyText:
          'To combine like terms:\n1. **Find** terms with matching variable parts\n2. **Add or subtract** their coefficients\n3. **Keep** the variable part exactly the same\n\nExample:\n**7x − 2x**\nSubtract coefficients: **7 − 2 = 5**\nSo: **7x − 2x = 5x**',
      mathExpression: '7x − 2x = (7 − 2)x = 5x',
      mathAnnotation: 'Only the coefficient changes!',
    ),
    LessonStep(
      id: 'm2_l2_s05',
      type: LessonStepType.quiz,
      title: 'Try It!',
      question: 'Simplify: 4y + 3y',
      choices: [
        ChoiceOption(label: '7'),
        ChoiceOption(label: '7y', isCorrect: true),
        ChoiceOption(label: '7y²'),
        ChoiceOption(label: '12y'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'Exactly! 4 groups of y plus 3 groups of y gives us 7 groups of y (7y).',
      incorrectExplanation:
          'Add the coefficients (4 + 3) and keep the variable y attached.',
    ),
    LessonStep(
      id: 'm2_l2_s06',
      type: LessonStepType.content,
      title: 'More Than One Type',
      bodyText:
          'Simplify:\n**4x + 3 + 2x + 5**\n\n1. Find matching like terms:\n• **4x** and **2x** → **4x + 2x = 6x**\n• **3** and **5** → **3 + 5 = 8**\n\n2. Combine together:\n**6x + 8**',
      mathExpression: '(4x + 2x) + (3 + 5) = 6x + 8',
      mathAnnotation: 'Combine x terms and constants separately!',
    ),
    LessonStep(
      id: 'm2_l2_s07',
      type: LessonStepType.summary,
      title: 'Watch Out for Unlike Terms!',
      bodyText:
          'Can we simplify **3x + 4y** into **7xy**?\n\n**No!**\n**3x** and **4y** are unlike terms.\nThe simplified expression remains:\n**3x + 4y**\n\nYou learned:\n• Add and subtract coefficients of matching variable terms\n• Variables and exponents never change during addition\n• Constants and variable terms are grouped separately\n• Unlike terms cannot be combined',
      mathExpression: '3x + 4y ≠ 7xy',
      mathAnnotation: '3x + 4y is already fully simplified!',
      xyDialogue:
          'Not everything needs to combine. Sometimes an expression is already as *simple as it can be*!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Finish Lesson',
    ),
  ],
);
