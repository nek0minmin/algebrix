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
          'Expressions are built from smaller chunks called terms. Let’s learn how to see each chunk.',
      xyAsset: AppAssets.xyExplaining,
      buttonLabel: 'Find the terms',
    ),
    LessonStep(
      id: 'm1_l3_s02',
      type: LessonStepType.content,
      title: 'What Is a Term?',
      bodyText:
          'A **term** is one number, one variable, or a product of numbers and variables. Addition and subtraction separate terms.',
      mathExpression: '6x + 4 - 2y + 9',
      mathAnnotation: 'This expression contains four terms.',
    ),
    LessonStep(
      id: 'm1_l3_s03',
      type: LessonStepType.content,
      title: 'The Sign Belongs to the Term',
      bodyText:
          'When subtraction separates terms, keep the minus sign with the term that follows it.',
      mathExpression: '6x + 4 + (-2y) + 9',
      mathAnnotation: 'The third term is −2y, not 2y.',
    ),
    LessonStep(
      id: 'm1_l3_s04',
      type: LessonStepType.content,
      title: 'Different Kinds of Terms',
      bodyText:
          'A term can be a variable term, such as 6x or −2y, or a constant term, such as 4 or 9.',
      mathExpression: '6x | 4 | −2y | 9',
      mathAnnotation: 'Each separated chunk is one complete term.',
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
      explanation: 'The four terms are 6x, 4, −2y, and 9.',
      incorrectExplanation:
          'Choose complete chunks separated by addition or subtraction, keeping a minus sign with its term.',
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
      explanation: 'Correct: 3x, 5, and −y are three terms.',
      incorrectExplanation:
          'Split the expression at addition and subtraction signs, then count the chunks.',
    ),
    LessonStep(
      id: 'm1_l3_s07',
      type: LessonStepType.xySays,
      xyDialogue:
          'Why identify terms? Once an expression is split into terms, you can compare and combine matching kinds later.',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm1_l3_s08',
      type: LessonStepType.summary,
      title: 'Terms Complete!',
      xyDialogue:
          'Nice work—you can break an expression into its building blocks!',
      xyAsset: AppAssets.xyHappy,
      bodyText:
          'You learned:\n• Addition and subtraction separate terms\n• A sign belongs to the term after it\n• Terms can contain variables or be constants\n• Count terms by finding complete separated chunks',
    ),
  ],
);
