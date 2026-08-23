import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m1Lesson5 = LessonContent(
  lessonId: 'm1_l5',
  title: 'Coefficients',
  moduleId: 'module1',
  moduleTitle: 'Algebra Foundations',
  objective: 'Identify coefficients in algebraic terms.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm1_l5_s01',
      type: LessonStepType.intro,
      title: 'Coefficients',
      bodyText: 'Numbers that tell how many variables',
      xyDialogue:
          'A number next to a variable has a special job: it tells *how many* of that variable we have.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Meet coefficients',
    ),
    LessonStep(
      id: 'm1_l5_s02',
      type: LessonStepType.content,
      title: 'What Is a Coefficient?',
      bodyText:
          'A **coefficient** is the numerical factor multiplying a variable.\n\nIn `7x`, **7** is the coefficient because `7x` means **7 × x**.',
      mathExpression: '7x = 7 × x',
      mathAnnotation: '7 is the multiplier (coefficient) in front of x.',
      xyDialogue:
          'The coefficient acts like a *multiplier tag* attached to the variable!',
      xyAsset: AppAssets.xyPointUp,
    ),
    LessonStep(
      id: 'm1_l5_s03',
      type: LessonStepType.content,
      title: 'Four Groups of x',
      bodyText:
          'Multiplication can be shown as repeated groups.\n\n`x + x + x + x` makes **4x**.',
      mathExpression: 'x + x + x + x = 4x',
      mathAnnotation: 'The coefficient 4 counts the 4 groups of x.',
      xyDialogue:
          'Coefficients simply count *how many identical pieces* you have!',
      xyAsset: AppAssets.xyExplaining,
    ),
    LessonStep(
      id: 'm1_l5_s04',
      type: LessonStepType.content,
      title: 'Keep the Negative Sign',
      bodyText:
          'A negative sign attached to a variable term **belongs to its coefficient**.\n\nIn `−4y`, the coefficient is **−4**, not 4.',
      mathExpression: '−4y = (−4) × y',
      mathAnnotation: 'The negative sign stays with the number!',
      xyDialogue:
          'The negative sign is *welded* to the coefficient!',
      xyAsset: AppAssets.xyPointUp,
    ),
    LessonStep(
      id: 'm1_l5_s05',
      type: LessonStepType.content,
      title: 'The Invisible 1',
      bodyText:
          '• When `x` appears alone, its coefficient is **1** (`x = 1x`)\n• A leading minus `-x` means the coefficient is **−1** (`-x = −1x`)',
      mathExpression: 'x = 1x   •   −x = −1x',
      mathAnnotation: 'We usually leave the 1 unwritten for simplicity.',
      xyDialogue:
          'Even when unwritten, there is always an *invisible 1* standing with x!',
      xyAsset: AppAssets.xyHappy,
    ),
    LessonStep(
      id: 'm1_l5_s06',
      type: LessonStepType.quiz,
      title: 'Coefficient Check',
      question: 'What is the coefficient in 7x?',
      choices: [
        ChoiceOption(label: 'x'),
        ChoiceOption(label: '7', isCorrect: true),
        ChoiceOption(label: '7x'),
        ChoiceOption(label: '1'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation: 'Correct! 7 is the multiplier in front of x.',
      incorrectExplanation:
          'The coefficient is the number multiplying the variable.',
    ),
    LessonStep(
      id: 'm1_l5_s07',
      type: LessonStepType.quiz,
      title: 'Negative Coefficient',
      question: 'What is the coefficient in −4y?',
      choices: [
        ChoiceOption(label: '4'),
        ChoiceOption(label: '−4', isCorrect: true),
        ChoiceOption(label: 'y'),
        ChoiceOption(label: '−y'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation: 'Right! The negative sign stays with the 4, making it −4.',
      incorrectExplanation: 'Include the negative sign with the numerical coefficient.',
    ),
    LessonStep(
      id: 'm1_l5_s08',
      type: LessonStepType.quiz,
      title: 'Invisible 1 Check',
      question: 'What is the coefficient in x?',
      choices: [
        ChoiceOption(label: '0'),
        ChoiceOption(label: '1', isCorrect: true),
        ChoiceOption(label: 'x'),
        ChoiceOption(label: 'None'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation: 'Exactly! A single variable always has an implicit coefficient of 1.',
      incorrectExplanation: 'A variable with no number in front has a coefficient of 1 (1x = x).',
    ),
    LessonStep(
      id: 'm1_l5_s09',
      type: LessonStepType.xySays,
      xyDialogue:
          'Remember: every single variable has a multiplier—even when it looks all alone!',
      xyAsset: AppAssets.xyIdea,
    ),
    LessonStep(
      id: 'm1_l5_s10',
      type: LessonStepType.summary,
      title: 'Coefficients Summary',
      xyDialogue:
          'Great job! You know how to identify *coefficients*, even when they are negative or invisible.',
      xyAsset: AppAssets.xyHappy,
      bodyText:
          'You learned:\n• A coefficient is the number multiplying a variable\n• Negative signs stay attached to the coefficient\n• A lone variable has an invisible coefficient of 1\n• Coefficients tell you how many groups of the variable you have',
    ),
  ],
);
