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
      xyDialogue:
          'Let\'s find out what those coefficients are really telling us!',
      xyAsset: AppAssets.xyExplaining,
      bodyText:
          'You already know that **3x** and **5x** are like terms.\n\nSo what happens when we add them?\n\n**3x + 5x = ?**',
      mathExpression: '3x + 5x = ?',
      buttonLabel: 'Explore combining',
    ),
    LessonStep(
      id: 'm2_l2_s02',
      type: LessonStepType.content,
      title: 'Think in Groups',
      bodyText:
          'Remember:\n• **3x** means: **x + x + x** (3 groups of x)\n• **5x** means: **x + x + x + x + x** (5 groups of x)\n\nPut them together and we have:\n**8 groups of x**, or **8x**!\n\nTherefore:\n**3x + 5x = 8x**',
      mathExpression: '(x + x + x) + (x + x + x + x + x) = 8x',
      mathAnnotation: 'Total: 8 groups of x',
      xyDialogue:
          'We\'re adding how many x\'s we have—not changing what x is!',
      xyAsset: AppAssets.xyExplaining,
    ),
    LessonStep(
      id: 'm2_l2_s03',
      type: LessonStepType.content,
      title: 'The Rule for Combining',
      bodyText:
          'To combine like terms:\n1. **Find** terms with matching variable parts.\n2. **Add or subtract** their coefficients.\n3. **Keep** the variable part the same.\n\nExample:\n**7x − 2x**\nSubtract coefficients: **7 − 2 = 5**\nSo: **7x − 2x = 5x**',
      mathExpression: '7x − 2x = (7 − 2)x = 5x',
      mathAnnotation: 'Subtract the coefficients, keep x the same!',
      xyDialogue:
          'Only the coefficients change. The variable rides along!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm2_l2_s04',
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
      xyAsset: AppAssets.xyHappy,
      explanation:
          'Exactly! 4 groups of y plus 3 groups of y gives us 7 groups of y (7y).',
      incorrectExplanation:
          'Add the coefficients (4 + 3) and keep the variable y attached.',
    ),
    LessonStep(
      id: 'm2_l2_s05',
      type: LessonStepType.content,
      title: 'More Than One Type',
      bodyText:
          'Simplify:\n**4x + 3 + 2x + 5**\n\nFirst, find the like terms:\n• **4x** and **2x**  →  **4x + 2x = 6x**\n• **3** and **5**  →  **3 + 5 = 8**\n\nNow combine:\n**6x + 8**',
      mathExpression: '(4x + 2x) + (3 + 5) = 6x + 8',
      mathAnnotation: 'Combine x terms and constants separately!',
      xyDialogue:
          'Notice that we combined the x terms and the constants separately!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm2_l2_s06',
      type: LessonStepType.summary,
      title: 'Watch Out for Unlike Terms!',
      bodyText:
          'Can we simplify **3x + 4y** into **7xy**?\n\n**No! ❌**\n**3x** and **4y** are unlike terms.\n\nThe simplified expression remains:\n**3x + 4y**',
      mathExpression: '3x + 4y ≠ 7xy',
      mathAnnotation: '3x + 4y is already as simple as it can be!',
      xyDialogue:
          'Not everything needs to combine. Sometimes an expression is already as simple as it can be!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Finish Lesson',
    ),
  ],
);
