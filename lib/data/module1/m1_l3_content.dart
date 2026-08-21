import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m1Lesson3 = LessonContent(
  lessonId: 'm1_l3',
  title: 'Terms',
  moduleId: 'module1',
  moduleTitle: 'Algebra Foundations',
  objective: 'Identify and count terms in an algebraic expression.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm1_l3_s01',
      type: LessonStepType.intro,
      title: 'Terms',
      bodyText: 'The chunks that build an expression',
      xyDialogue:
          'Expressions are built from smaller chunks called *terms*. Let’s learn how to see each chunk.',
      xyAsset: AppAssets.xyExplaining,
      buttonLabel: 'Find the terms',
    ),
    LessonStep(
      id: 'm1_l3_s02',
      type: LessonStepType.content,
      title: 'What Is a Term?',
      bodyText:
          'A **term** is one number, one variable, or a product of numbers and variables.\n\n➕ **Addition** and ➖ **Subtraction** separate terms from each other.',
      mathExpression: '6x + 4 - 2y + 9',
      mathAnnotation: 'This expression contains four separate terms.',
      xyDialogue:
          'Think of terms like *train cars* connected by plus and minus signs!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm1_l3_s03',
      type: LessonStepType.content,
      title: 'The Sign Belongs to the Term',
      bodyText:
          'When subtraction separates terms, **always keep the minus sign with the term that follows it**.\n\n• First term: **6x**\n• Second term: **+4**\n• Third term: **−2y**\n• Fourth term: **+9**',
      mathExpression: '6x + 4 + (-2y) + 9',
      mathAnnotation: 'The third term is −2y, not 2y.',
      xyDialogue:
          'The sign in front *glues* to the term right after it!',
      xyAsset: AppAssets.xyExplaining,
    ),
    LessonStep(
      id: 'm1_l3_s04',
      type: LessonStepType.content,
      title: 'Different Kinds of Terms',
      bodyText:
          '• 🌸 **Variable Terms**: Contain letters, such as `6x` or `−2y`\n• 🟡 **Constant Terms**: Numbers alone, such as `4` or `9`',
      mathExpression: '6x   •   4   •   −2y   •   9',
      mathAnnotation: 'Each separated chunk is one complete term.',
      xyDialogue:
          'Every term is either a *variable term* or a *constant term*!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm1_l3_s05',
      type: LessonStepType.activity,
      title: 'Select Every Term',
      question: 'Select all the complete terms in 6x + 4 − 2y + 9.',
      isAnswerStep: true,
      activity: TermSelectionActivityData(
        tokens: [
          TermToken(id: '6x', label: '6x', isTerm: true),
          TermToken(id: 'plus1', label: '+', isTerm: false),
          TermToken(id: '4', label: '4', isTerm: true),
          TermToken(id: 'neg2y', label: '−2y', isTerm: true),
          TermToken(id: 'plus2', label: '+', isTerm: false),
          TermToken(id: '9', label: '9', isTerm: true),
        ],
      ),
      explanation: 'Great! The terms are 6x, 4, −2y, and 9.',
      incorrectExplanation:
          'Remember to include the negative sign with −2y, and leave out the standalone + operators.',
    ),
    LessonStep(
      id: 'm1_l3_s06',
      type: LessonStepType.quiz,
      title: 'Count the Terms',
      question: 'How many terms are in 3x + 5 − y?',
      choices: [
        ChoiceOption(label: '2'),
        ChoiceOption(label: '3', isCorrect: true),
        ChoiceOption(label: '4'),
        ChoiceOption(label: '5'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation: 'Correct! The 3 terms are 3x, 5, and −y.',
      incorrectExplanation:
          'Count each chunk separated by + or − (remember −y is one complete term).',
    ),
    LessonStep(
      id: 'm1_l3_s07',
      type: LessonStepType.summary,
      title: 'Terms Summary',
      xyDialogue:
          'Awesome! You now know how to *break any expression into its building blocks*.',
      xyAsset: AppAssets.xyHappy,
      bodyText:
          'You learned:\n• Terms are separated by + and − signs\n• The sign in front belongs to that term\n• A term can be a constant, variable, or product of both\n• Knowing terms helps you combine and simplify expressions later',
    ),
  ],
);
