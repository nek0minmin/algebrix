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
      bodyText: 'Make sense of the pieces',
      xyDialogue:
          'Remember terms? Some of them have more in common than you might think! Let\'s see which ones fit together.',
      xyAsset: AppAssets.xyWave,
      buttonLabel: 'Explore like terms →',
    ),
    LessonStep(
      id: 'm2_l1_s02',
      type: LessonStepType.content,
      title: 'Meet Like Terms',
      bodyText:
          '**Like terms** have the **same variable** raised to the **same exponent**.\n\nFor example:\n• **3x** and **7x** ✅ (both contain **x**)\n• **4y²** and **9y²** ✅ (both have **y²**)\n\nThe numbers in front (coefficients) can be different, but the **variable parts must match!**',
      mathExpression: '3x  and  7x  ✓   •   4y²  and  9y²  ✓',
      mathAnnotation: 'Same variable & same exponent = Like Terms!',
    ),
    LessonStep(
      id: 'm2_l1_s03',
      type: LessonStepType.xySays,
      xyDialogue:
          'The numbers in front can be completely different. What matters is that the variable parts match exactly!',
      xyAsset: AppAssets.xyExplaining,
    ),
    LessonStep(
      id: 'm2_l1_s04',
      type: LessonStepType.content,
      title: 'Not Everything Matches!',
      bodyText:
          'Look at:\n\n• **3x** and **3y** ❌ (Same coefficient, but different variables)\n• **5x** and **5x²** ❌ (Same variable, but different exponents)\n\nThese are **unlike terms** because their variable parts do not match.',
      mathExpression: '3x and 3y  ✗   •   5x and 5x²  ✗',
      mathAnnotation: 'Different variables or exponents = Unlike Terms.',
    ),
    LessonStep(
      id: 'm2_l1_s05',
      type: LessonStepType.quiz,
      title: 'Find the Pair',
      question: 'Which two are like terms?\n\n3x       5y       8x       2',
      choices: [
        ChoiceOption(label: '3x and 5y', emoji: '🔍'),
        ChoiceOption(label: '3x and 8x', emoji: '✅', isCorrect: true),
        ChoiceOption(label: '5y and 8x', emoji: '🔍'),
        ChoiceOption(label: '8x and 2', emoji: '🔍'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation: 'You got it! Both 3x and 8x have the same variable, x.',
      incorrectExplanation:
          'Look at the variable letters. Which two terms share the same variable?',
    ),
    LessonStep(
      id: 'm2_l1_s06',
      type: LessonStepType.interactive,
      title: 'A Little Trickier',
      xyDialogue:
          'Watch those exponents! Let\'s see if you can spot the matching power.',
      xyAsset: AppAssets.xyPointing,
      question: 'Which terms are like terms in 4a² + 3a + 7a²?',
      choices: [
        ChoiceOption(label: '4a² and 3a'),
        ChoiceOption(label: '3a and 7a²'),
        ChoiceOption(label: '4a² and 7a²', isCorrect: true),
        ChoiceOption(label: 'All three terms'),
      ],
      correctChoiceIndex: 2,
      isAnswerStep: true,
      explanation:
          'Nice! a and a² aren\'t the same variable power, so only 4a² and 7a² can be grouped together.',
      incorrectExplanation:
          'Remember: like terms need the exact same variable AND exponent. Look closely at a versus a².',
    ),
    LessonStep(
      id: 'm2_l1_s07',
      type: LessonStepType.summary,
      title: 'Why Does This Matter?',
      bodyText:
          'Suppose you have:\n• **3 apples + 2 apples = 5 apples** 🍎\n\nBut:\n• **3 apples + 2 oranges** doesn\'t become **5 apple-oranges** 😭\n\nAlgebra works similarly:\n• **3x + 2x** can be combined into **5x**\n• **3x + 2y** cannot be combined\n\nYou learned:\n• Like terms have identical variable letters and powers\n• Only like terms can be combined\n• Unlike terms represent different quantities and stay separate',
      mathExpression: '3x + 2x = 5x',
      mathAnnotation: '3x + 2y cannot combine because they are unlike terms!',
      xyDialogue:
          'Like terms represent the same kind of quantity. That\'s why we can combine them!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Finish Lesson',
    ),
  ],
);
