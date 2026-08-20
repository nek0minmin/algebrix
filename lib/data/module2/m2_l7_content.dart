import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m2Lesson7 = LessonContent(
  lessonId: 'm2_l7',
  title: 'Expression Challenge',
  moduleId: 'module2',
  moduleTitle: 'Working with Expressions',
  objective: 'Demonstrate mastery across all Module 2 expression concepts.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm2_l7_s01',
      type: LessonStepType.intro,
      title: 'Ready to Put It All Together?',
      bodyText: 'Mastery Challenge',
      xyDialogue:
          'You\'ve learned how to recognize patterns, combine terms, distribute, simplify, and evaluate expressions.\n\nNow let\'s see if you understand the why behind them!',
      xyAsset: AppAssets.xyWave,
      buttonLabel: 'START CHALLENGE →',
    ),
    LessonStep(
      id: 'm2_l7_s02',
      type: LessonStepType.quiz,
      title: 'Challenge 1: Like Terms',
      question: 'Which pair contains like terms?',
      choices: [
        ChoiceOption(label: '3x and 3y'),
        ChoiceOption(label: '5x and 2x', isCorrect: true),
        ChoiceOption(label: '4x and 4x²'),
        ChoiceOption(label: '7 and 7y'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyPointing,
      explanation:
          'Correct! Both 5x and 2x share the exact same variable x raised to the power 1.',
      incorrectExplanation:
          'Like terms must have the exact same variable and exponent.',
    ),
    LessonStep(
      id: 'm2_l7_s03',
      type: LessonStepType.quiz,
      title: 'Challenge 2: Combining',
      question: 'Simplify: 6x + 3x',
      choices: [
        ChoiceOption(label: '9'),
        ChoiceOption(label: '9x', isCorrect: true),
        ChoiceOption(label: '9x²'),
        ChoiceOption(label: '18x'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyPointing,
      explanation: 'Correct! 6 + 3 = 9, so 6x + 3x = 9x.',
      incorrectExplanation: 'Add the coefficients (6 + 3) and keep the variable x.',
    ),
    LessonStep(
      id: 'm2_l7_s04',
      type: LessonStepType.quiz,
      title: 'Challenge 3: Why It Works',
      question: 'Why can 6x + 3x become 9x?',
      choices: [
        ChoiceOption(label: 'The coefficients are the same.'),
        ChoiceOption(
          label: 'Both terms represent groups of the same variable.',
          isCorrect: true,
        ),
        ChoiceOption(label: 'Every addition can be combined.'),
        ChoiceOption(label: 'x always equals 1.'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyExplaining,
      explanation:
          'Exactly! Both terms represent groups of the same entity x (6 groups + 3 groups = 9 groups).',
      incorrectExplanation:
          'Think about what like terms actually represent: groups of the same unknown quantity.',
    ),
    LessonStep(
      id: 'm2_l7_s05',
      type: LessonStepType.quiz,
      title: 'Challenge 4: Distribute',
      question: 'Expand: 3(x + 4)',
      choices: [
        ChoiceOption(label: '3x + 4'),
        ChoiceOption(label: '3x + 12', isCorrect: true),
        ChoiceOption(label: '7x'),
        ChoiceOption(label: 'x + 12'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyPointing,
      explanation: 'Great! 3 × x = 3x and 3 × 4 = 12, giving 3x + 12.',
      incorrectExplanation:
          'Remember the distributive property: multiply 3 by both x and 4.',
    ),
    LessonStep(
      id: 'm2_l7_s06',
      type: LessonStepType.quiz,
      title: 'Challenge 5: Simplify',
      question: 'Simplify: 4x + 3 + 2x + 5',
      choices: [
        ChoiceOption(label: '6x + 8', isCorrect: true),
        ChoiceOption(label: '14x'),
        ChoiceOption(label: '6x + 15'),
        ChoiceOption(label: '8x + 6'),
      ],
      correctChoiceIndex: 0,
      isAnswerStep: true,
      xyAsset: AppAssets.xyPointing,
      explanation: 'Spot on! (4x + 2x) + (3 + 5) = 6x + 8.',
      incorrectExplanation:
          'Combine the x terms (4x + 2x) and the constants (3 + 5) separately.',
    ),
    LessonStep(
      id: 'm2_l7_s07',
      type: LessonStepType.quiz,
      title: 'Challenge 6: Property',
      question: 'Which property is shown?\n\n5 + 8 = 8 + 5',
      choices: [
        ChoiceOption(label: 'Associative Property'),
        ChoiceOption(label: 'Commutative Property', isCorrect: true),
        ChoiceOption(label: 'Identity Property'),
        ChoiceOption(label: 'Distributive Property'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation:
          'Right! Switching the order of addition demonstrates the Commutative Property.',
      incorrectExplanation:
          'Think: "commute" means moving around / changing order.',
    ),
    LessonStep(
      id: 'm2_l7_s08',
      type: LessonStepType.quiz,
      title: 'Challenge 7: Evaluate',
      question: 'If x = 3, evaluate: 4x + 2',
      choices: [
        ChoiceOption(label: '14', isCorrect: true),
        ChoiceOption(label: '18'),
        ChoiceOption(label: '20'),
        ChoiceOption(label: '24'),
      ],
      correctChoiceIndex: 0,
      isAnswerStep: true,
      xyAsset: AppAssets.xyPointing,
      explanation: '4(3) + 2 = 12 + 2 = 14.',
      incorrectExplanation: 'Substitute 3 for x: 4(3) = 12, then add 2.',
    ),
    LessonStep(
      id: 'm2_l7_s09',
      type: LessonStepType.quiz,
      title: 'Challenge 8: Explore the Why',
      question: 'Why does 2(x + 3) become 2x + 6?',
      choices: [
        ChoiceOption(
          label: 'Because 2 multiplies every term inside the parentheses.',
          isCorrect: true,
        ),
        ChoiceOption(label: 'Because parentheses always mean add 6.'),
        ChoiceOption(label: 'Because x equals 3.'),
        ChoiceOption(label: 'Because 2 + 3 = 5 and 5 + 1 = 6.'),
      ],
      correctChoiceIndex: 0,
      isAnswerStep: true,
      xyAsset: AppAssets.xyExplaining,
      explanation:
          'Exactly! The multiplier outside distributes to every term inside the parentheses.',
      incorrectExplanation:
          'Recall how 2(x + 3) represents 2 identical groups of (x + 3).',
    ),
    LessonStep(
      id: 'm2_l7_s10',
      type: LessonStepType.quiz,
      title: 'Challenge 9: Distribute & Combine',
      question: 'Simplify: 3(x + 2) + 2x',
      choices: [
        ChoiceOption(label: '5x + 6', isCorrect: true),
        ChoiceOption(label: '3x + 8'),
        ChoiceOption(label: '5x + 2'),
        ChoiceOption(label: '11x'),
      ],
      correctChoiceIndex: 0,
      isAnswerStep: true,
      xyAsset: AppAssets.xyPointing,
      explanation:
          'First distribute: 3x + 6 + 2x. Then combine like terms: (3x + 2x) + 6 = 5x + 6!',
      incorrectExplanation:
          'Distribute 3 to (x + 2) first to get 3x + 6, then add 2x.',
    ),
    LessonStep(
      id: 'm2_l7_s11',
      type: LessonStepType.quiz,
      title: 'Challenge 10: Multi-Step Evaluate',
      question: 'If x = 2, evaluate: 3x + 4x + 1',
      choices: [
        ChoiceOption(label: '15', isCorrect: true),
        ChoiceOption(label: '14'),
        ChoiceOption(label: '16'),
        ChoiceOption(label: '22'),
      ],
      correctChoiceIndex: 0,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation:
          'Awesome! Simplify: 7x + 1. Substitute x = 2: 7(2) + 1 = 14 + 1 = 15.',
      incorrectExplanation:
          'Combine like terms: 3x + 4x = 7x. Then 7(2) + 1 = 14 + 1 = 15.',
    ),
    LessonStep(
      id: 'm2_l7_s12',
      type: LessonStepType.summary,
      title: 'EXPRESSIONS MASTERED! 🎉',
      xyDialogue:
          'You did it! Expressions aren\'t just a bunch of symbols anymore.\n\nYou can see which terms belong together, understand why they can be combined, use algebraic properties, simplify expressions, and find their values!',
      xyAsset: AppAssets.xyHappy,
      bodyText:
          'You learned:\n• Like & Unlike Terms\n• Combining Like Terms\n• Distributive Property\n• Properties of Operations\n• Simplifying Expressions\n• Evaluating Expressions\n\n+200 XP • 🏆 Expression Explorer',
      buttonLabel: 'Finish Module 2',
    ),
  ],
);
