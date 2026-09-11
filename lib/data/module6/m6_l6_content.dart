import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 6.6 — Module 6 Challenge: Polynomial Workshop
final m6Lesson6 = LessonContent(
  lessonId: 'm6_l6',
  title: 'Module 6 Challenge',
  moduleId: 'module6',
  moduleTitle: 'Polynomials',
  objective:
      'Prove mastery of polynomials across ten mixed challenges spanning '
      'naming, adding, subtracting, multiplying and factoring.',
  xyAsset: AppAssets.xyHappy,
  steps: [
    LessonStep(
      id: 'm6_l6_s01',
      type: LessonStepType.intro,
      title: 'Polynomial Workshop',
      bodyText: 'Build It. Break It Apart.',
      xyDialogue:
          'Everything from this module in one place. Ten challenges — some '
          'build polynomials up, some take them apart.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Start Challenge →',
    ),
    LessonStep(
      id: 'm6_l6_s02',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 1: Name It',
      question: 'What is **x² + 3x + 2** called?',
      choices: const [
        ChoiceOption(label: 'Trinomial', isCorrect: true),
        ChoiceOption(label: 'Binomial'),
        ChoiceOption(label: 'Monomial'),
        ChoiceOption(label: 'Constant'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation: 'Three terms means a **trinomial**. Tri for three.',
      incorrectExplanation:
          'Count the pieces separated by + and −. How many are there?',
    ),
    LessonStep(
      id: 'm6_l6_s03',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 2: Find the Degree',
      question: 'What is the degree of **2x³ + 5x² − x + 9**?',
      choices: const [
        ChoiceOption(label: '3', isCorrect: true),
        ChoiceOption(label: '2'),
        ChoiceOption(label: '4'),
        ChoiceOption(label: '9'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'The degree is the **highest exponent**, which is the 3 in `2x³`.',
      incorrectExplanation:
          'Look for the biggest little raised number, not the biggest coefficient.',
    ),
    LessonStep(
      id: 'm6_l6_s04',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Challenge 3: Like or Unlike?',
      question: 'Sort each pair.',
      xyDialogue: 'Same variable **and** same exponent, or it is not a match.',
      activity: const ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'like', label: 'Like terms'),
          ActivityCategory(id: 'unlike', label: 'Unlike terms'),
        ],
        items: [
          ClassificationItem(id: 'a', label: '6x³ and −x³', categoryId: 'like'),
          ClassificationItem(id: 'b', label: '2x² and 2x³', categoryId: 'unlike'),
          ClassificationItem(id: 'c', label: '7 and −4', categoryId: 'like'),
          ClassificationItem(id: 'd', label: '5x and 5', categoryId: 'unlike'),
        ],
      ),
      explanation:
          'Coefficients are irrelevant. **5x** and **5** differ because one '
          'carries a variable and the other does not.',
      incorrectExplanation:
          'Ignore the numbers in front. Compare the variable part only.',
    ),
    LessonStep(
      id: 'm6_l6_s05',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 4: Add Them',
      question: 'Add **(2x² + 7x + 1) + (5x² − 3x + 6)**.',
      choices: const [
        ChoiceOption(label: '7x² + 4x + 7', isCorrect: true),
        ChoiceOption(label: '7x² + 10x + 7'),
        ChoiceOption(label: '7x⁴ + 4x² + 7'),
        ChoiceOption(label: '7x² − 4x + 7'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          '`2x² + 5x² = 7x²`, `7x − 3x = 4x`, `1 + 6 = 7`. Exponents never add '
          'when combining like terms.',
      incorrectExplanation:
          'The second group has a **−3x**. Adding it lowers the middle term.',
    ),
    LessonStep(
      id: 'm6_l6_s06',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 5: The Sign Trap',
      question: 'Subtract **(8x + 2) − (3x − 5)**.',
      choices: const [
        ChoiceOption(label: '5x + 7', isCorrect: true),
        ChoiceOption(label: '5x − 3'),
        ChoiceOption(label: '11x − 3'),
        ChoiceOption(label: '5x − 7'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'Distribute the negative: `8x + 2 − 3x + 5`. The **−5** became '
          '**+5**, giving **5x + 7**.',
      incorrectExplanation:
          'What does `−1 × (−5)` give? Every sign inside the bracket flips.',
    ),
    LessonStep(
      id: 'm6_l6_s07',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Challenge 6: Fill the Rectangle',
      xyDialogue: 'Every box is one pair of terms multiplied.',
      activity: const AreaModelActivityData(
        expression: '(x + 4)(x + 2)',
        topLabels: ['x', '2'],
        sideLabels: ['x', '4'],
        cells: ['x²', '2x', '4x', '8'],
        choices: ['x²', '2x', '4x', '8', '6x', '6'],
        result: 'x² + 6x + 8',
      ),
      explanation:
          '`x² + 2x + 4x + 8`, and the middle pair combines to **6x**.',
      incorrectExplanation:
          'The bottom-right box is `4 × 2`, not `4 + 2`.',
    ),
    LessonStep(
      id: 'm6_l6_s08',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 7: Mind the Sign',
      question: 'Multiply **(x + 6)(x − 3)**.',
      choices: const [
        ChoiceOption(label: 'x² + 3x − 18', isCorrect: true),
        ChoiceOption(label: 'x² + 9x − 18'),
        ChoiceOption(label: 'x² − 3x − 18'),
        ChoiceOption(label: 'x² + 3x + 18'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          '`x²`, `−3x`, `+6x`, `−18`. The middle pair gives **+3x** and the '
          'constant is negative.',
      incorrectExplanation:
          'Combine `−3x` and `+6x` carefully, and remember `6 × −3` is negative.',
    ),
    LessonStep(
      id: 'm6_l6_s09',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 8: Pull It Out',
      question: 'Factor **12x² + 18x**.',
      choices: const [
        ChoiceOption(label: '6x(2x + 3)', isCorrect: true),
        ChoiceOption(label: '6(2x² + 3x)'),
        ChoiceOption(label: '3x(4x + 6)'),
        ChoiceOption(label: '6x(2x + 18)'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'Both terms share **6** and both share **x**, so the greatest common '
          'factor is **6x**, leaving `2x + 3`.',
      incorrectExplanation:
          'Two of these options are true but incomplete — take the **greatest** '
          'factor the terms share.',
    ),
    LessonStep(
      id: 'm6_l6_s10',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 9: Break It Apart',
      question: 'Factor **x² + 9x + 20**.',
      choices: const [
        ChoiceOption(label: '(x + 4)(x + 5)', isCorrect: true),
        ChoiceOption(label: '(x + 2)(x + 10)'),
        ChoiceOption(label: '(x + 1)(x + 20)'),
        ChoiceOption(label: '(x + 9)(x + 20)'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          '**4 × 5 = 20** and **4 + 5 = 9**. The other pairs multiply to 20 but '
          'add to the wrong number.',
      incorrectExplanation:
          'Both conditions must hold at once: multiply to 20 AND add to 9.',
    ),
    LessonStep(
      id: 'm6_l6_s11',
      type: LessonStepType.quiz,
      isAnswerStep: true,
      title: 'Challenge 10: Check the Work',
      question:
          'Someone factors **x² + 7x + 10** as `(x + 2)(x + 5)`. How would you '
          'check it?',
      choices: const [
        ChoiceOption(
          label: 'Multiply it back out and compare',
          isCorrect: true,
        ),
        ChoiceOption(label: 'Add the two numbers in the brackets'),
        ChoiceOption(label: 'You cannot check a factorisation'),
      ],
      correctChoiceIndex: 0,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'Multiplying gives `x² + 5x + 2x + 10 = x² + 7x + 10` ✓ Factoring '
          'always has a free check built into it.',
      incorrectExplanation:
          'Factoring and multiplying are the same journey in opposite '
          'directions, so one verifies the other.',
    ),
    LessonStep(
      id: 'm6_l6_s12',
      type: LessonStepType.summary,
      title: 'Challenge Complete',
      bodyText:
          'You can **build** polynomials up and **break** them apart — and '
          'check either one with the other.',
      xyDialogue:
          'One room left, and in that one the polynomials are things you can '
          'actually pick up.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete the Challenge',
    ),
  ],
);
