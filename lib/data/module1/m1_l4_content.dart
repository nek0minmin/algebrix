import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m1Lesson4 = LessonContent(
  lessonId: 'm1_l4',
  title: 'Expressions',
  moduleId: 'module1',
  moduleTitle: 'Algebra Foundations',
  objective: 'Differentiate between expressions and equations.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm1_l4_s01',
      type: LessonStepType.intro,
      title: 'Expressions',
      bodyText: 'Mathematical phrases without an equals sign',
      xyDialogue:
          'Variables, constants, and operations can join to make an algebraic expression.',
      xyAsset: AppAssets.xyExplaining,
      buttonLabel: 'Build expressions',
    ),
    LessonStep(
      id: 'm1_l4_s02',
      type: LessonStepType.content,
      title: 'What Is an Expression?',
      bodyText:
          'An **expression** is a mathematical phrase made from numbers, variables, and operations. It does not have an equals sign.',
      mathExpression: '4x + 7',
      mathAnnotation: 'Other expressions include 3y, a − 2, and 5 + n.',
    ),
    LessonStep(
      id: 'm1_l4_s03',
      type: LessonStepType.content,
      title: 'Connect the Parts',
      bodyText:
          'In 4x + 7, x is a variable, 4 is its coefficient, + is an operation, and 7 is a constant.',
      mathExpression: '4x + 7',
      mathAnnotation: 'All four parts work together to form one expression.',
    ),
    LessonStep(
      id: 'm1_l4_s04',
      type: LessonStepType.xySays,
      xyDialogue:
          'Think of an expression as a math phrase. It represents a value, but it does not make an equality claim.',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm1_l4_s05',
      type: LessonStepType.content,
      title: 'Expression or Equation?',
      bodyText:
          'An expression has no equals sign. An equation says two quantities are equal.',
      mathExpression: 'Expression: 4x + 7     Equation: 4x + 7 = 19',
      mathAnnotation:
          'The equals sign turns a mathematical phrase into an equation.',
    ),
    LessonStep(
      id: 'm1_l4_s06',
      type: LessonStepType.activity,
      title: 'Sort Expressions and Equations',
      question: 'Sort each item by whether it has an equals sign.',
      isAnswerStep: true,
      activity: ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'expression', label: 'Expression'),
          ActivityCategory(id: 'equation', label: 'Equation'),
        ],
        items: [
          ClassificationItem(
            id: '3x+2',
            label: '3x + 2',
            categoryId: 'expression',
          ),
          ClassificationItem(id: 'y=8', label: 'y = 8', categoryId: 'equation'),
          ClassificationItem(
            id: '5-a',
            label: '5 − a',
            categoryId: 'expression',
          ),
          ClassificationItem(
            id: '2n=10',
            label: '2n = 10',
            categoryId: 'equation',
          ),
        ],
      ),
      explanation: 'Expressions have no equals sign; equations do.',
      incorrectExplanation:
          'Look for =. Its presence is what separates an equation from an expression.',
    ),
    LessonStep(
      id: 'm1_l4_s07',
      type: LessonStepType.quiz,
      title: 'Spot the Expression',
      question: 'Which of these is an expression?',
      choices: [
        ChoiceOption(label: 'x + 4 = 10'),
        ChoiceOption(label: 'x + 5', isCorrect: true),
        ChoiceOption(label: '7 = 7'),
        ChoiceOption(label: 'a = 5'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      explanation:
          'Correct! x + 5 has a variable, a number, and an operation—but no equals sign.',
      incorrectExplanation: 'An expression never contains an equals sign.',
    ),
    LessonStep(
      id: 'm1_l4_s08',
      type: LessonStepType.interactive,
      title: 'Why the Equals Sign Matters',
      question: 'Why is 3x + 5 = 20 an equation instead of an expression?',
      choices: [
        ChoiceOption(label: 'It contains x'),
        ChoiceOption(label: 'It contains 3'),
        ChoiceOption(label: 'It has an equals sign', isCorrect: true),
        ChoiceOption(label: 'It has two terms'),
      ],
      correctChoiceIndex: 2,
      isAnswerStep: true,
      explanation:
          'Exactly. The equals sign states that two quantities have the same value.',
      incorrectExplanation:
          'Focus on the symbol that connects the left and right sides.',
    ),
    LessonStep(
      id: 'm1_l4_s09',
      type: LessonStepType.summary,
      title: 'Expressions Complete!',
      xyDialogue:
          'Excellent! You can recognize a mathematical phrase and tell it apart from an equation.',
      xyAsset: AppAssets.xyHappy,
      bodyText:
          'You learned:\n• Expressions combine numbers, variables, and operations\n• Expressions do not contain an equals sign\n• Equations state that two quantities are equal\n• Variables, coefficients, operations, and constants form expressions',
    ),
  ],
);
