import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m2Lesson1 = LessonContent(
  lessonId: 'm2_l1',
  title: 'Like and Unlike Terms',
  moduleId: 'module2',
  moduleTitle: 'Working with Expressions',
  objective:
      'Identify like and unlike terms by examining their variable parts and exponents.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm2_l1_s01',
      type: LessonStepType.intro,
      title: 'Which Ones Belong Together?',
      xyDialogue:
          'Remember terms? Some of them have more in common than you might think!',
      xyAsset: AppAssets.xyWave,
      bodyText:
          'Take a look:\n\n**3x + 5x**\n\nBoth terms contain the same variable, **x**.\n\nWe call these **like terms**.',
      mathExpression: '3x + 5x',
      mathAnnotation: 'Both terms contain the variable x.',
      buttonLabel: 'Explore →',
    ),
    LessonStep(
      id: 'm2_l1_s02',
      type: LessonStepType.content,
      title: 'Meet Like Terms',
      bodyText:
          '**Like terms** have the **same variable** raised to the **same exponent**.\n\nFor example:\n• **3x** and **7x** ✅ (both contain x)\n• **4y²** and **9y²** ✅ (both have y²)',
      mathExpression: '3x  \\text{and}  7x  \\checkmark \\quad\\quad 4y^2  \\text{and}  9y^2  \\checkmark',
      mathAnnotation: 'The variable parts match exactly!',
      xyDialogue:
          'The numbers can be different. What matters is that the variable parts match!',
      xyAsset: AppAssets.xyExplaining,
    ),
    LessonStep(
      id: 'm2_l1_s03',
      type: LessonStepType.content,
      title: 'Not Everything Matches!',
      bodyText:
          'Look at:\n\n**3x** and **3y**\n\nThey have the same coefficient, but different variables. So they are **unlike terms**.\n\nThe same is true for:\n\n**5x** and **5x²**\n\nEven though both contain x, their exponents are different.',
      mathExpression: '3x  \\text{and}  3y  \\times \\quad\\quad 5x  \\text{and}  5x^2  \\times',
      mathAnnotation: 'Different variables or exponents mean unlike terms.',
      xyDialogue:
          'For terms to be alike, their variable parts need to match exactly!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm2_l1_s04',
      type: LessonStepType.quiz,
      title: 'Find the Pair',
      question: 'Which two are like terms?\n\n3x       5y       8x       2',
      choices: [
        ChoiceOption(label: '3x and 5y'),
        ChoiceOption(label: '3x and 8x', isCorrect: true),
        ChoiceOption(label: '5y and 8x'),
        ChoiceOption(label: '8x and 2'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation: 'You got it! Both 3x and 8x have the same variable, x.',
      incorrectExplanation:
          'Look at the variable, not just the number in front. Which two match?',
    ),
    LessonStep(
      id: 'm2_l1_s05',
      type: LessonStepType.interactive,
      title: 'A Little Trickier',
      question: 'Which terms are like terms in 4a² + 3a + 7a²?',
      choices: [
        ChoiceOption(label: '4a² and 3a'),
        ChoiceOption(label: '3a and 7a²'),
        ChoiceOption(label: '4a² and 7a²', isCorrect: true),
        ChoiceOption(label: 'All three terms'),
      ],
      correctChoiceIndex: 2,
      isAnswerStep: true,
      xyAsset: AppAssets.xyExplaining,
      explanation:
          'Nice! a and a² aren\'t the same variable part, so only 4a² and 7a² can be grouped together.',
      incorrectExplanation:
          'Remember: like terms need the exact same variable AND exponent. Look closely at a versus a².',
    ),
    LessonStep(
      id: 'm2_l1_s06',
      type: LessonStepType.summary,
      title: 'Why Does This Matter?',
      bodyText:
          'Suppose you have:\n**3 apples + 2 apples = 5 apples** 🍎\n\nBut:\n**3 apples + 2 oranges** doesn\'t become **5 apple-oranges** 😭\n\nAlgebra works similarly:\n• **3x + 2x** can be combined into **5x**\n• **3x + 2y** cannot be combined',
      mathExpression: '3x + 2x = 5x \\quad\\quad 3x + 2y = 3x + 2y',
      xyDialogue:
          'Like terms represent the same kind of quantity. That\'s why we can combine them!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Finish Lesson',
    ),
  ],
);
