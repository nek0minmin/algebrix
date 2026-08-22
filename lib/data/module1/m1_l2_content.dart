import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m1Lesson2 = LessonContent(
  lessonId: 'm1_l2',
  title: 'Constants',
  moduleId: 'module1',
  moduleTitle: 'Algebra Foundations',
  objective: 'Identify constants and explain how they differ from variables.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm1_l2_s01',
      type: LessonStepType.intro,
      title: 'Constants',
      bodyText: 'Numbers that stay fixed',
      xyDialogue:
          'Variables can change, but some values stay fixed. Those steady values are called *constants*.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Meet constants',
    ),
    LessonStep(
      id: 'm1_l2_s02',
      type: LessonStepType.content,
      title: 'What Is a Constant?',
      bodyText:
          'A **constant** is a number whose value stays completely the same.\n\nExamples include: **5**, **12**, **100**, **−3**, and **½**.',
      mathExpression: 'x + 5',
      mathAnnotation: 'x may change, but 5 always has the value 5.',
      xyDialogue:
          'No matter what happens to x, the *constant 5* never changes!',
      xyAsset: AppAssets.xyPointUp,
    ),
    LessonStep(
      id: 'm1_l2_s03',
      type: LessonStepType.content,
      title: 'Change One Part',
      bodyText:
          'Watch what happens when **x** changes:\n\n• `x = 1`  →  `1 + 5 = 6`\n• `x = 4`  →  `4 + 5 = 9`\n• `x = 10` →  `10 + 5 = 15`',
      mathExpression: 'x = 1 → 6   •   x = 4 → 9   •   x = 10 → 15',
      mathAnnotation:
          'The x-value changes in every row. The constant 5 stays put.',
      xyDialogue:
          'The variable x shifts, but the *constant stays steady*!',
      xyAsset: AppAssets.xyExplaining,
    ),
    LessonStep(
      id: 'm1_l2_s04',
      type: LessonStepType.xySays,
      xyDialogue:
          'A constant is the *dependable part* of an expression—it keeps the same value even when a variable changes.',
      xyAsset: AppAssets.xyPointUp,
    ),
    LessonStep(
      id: 'm1_l2_s05',
      type: LessonStepType.activity,
      title: 'Change or Stay?',
      question:
          'Sort each part by whether its value can change or must stay fixed.',
      isAnswerStep: true,
      xyAsset: AppAssets.xyPointUp,
      activity: ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'change', label: 'Can change'),
          ActivityCategory(id: 'stay', label: 'Stays fixed'),
        ],
        items: [
          ClassificationItem(id: 'x', label: 'x', categoryId: 'change'),
          ClassificationItem(id: '7', label: '7', categoryId: 'stay'),
          ClassificationItem(id: 'y', label: 'y', categoryId: 'change'),
          ClassificationItem(id: '12', label: '12', categoryId: 'stay'),
        ],
      ),
      explanation: 'Variables change; numbers alone are constants.',
      incorrectExplanation:
          'Letters are variables that can take different values. Numbers alone stay fixed.',
    ),
    LessonStep(
      id: 'm1_l2_s06',
      type: LessonStepType.quiz,
      title: 'Quick Check',
      question: 'Which number is the constant in 4x + 9?',
      choices: [
        ChoiceOption(label: '4'),
        ChoiceOption(label: 'x'),
        ChoiceOption(label: '9', isCorrect: true),
        ChoiceOption(label: '4x'),
      ],
      correctChoiceIndex: 2,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'Correct! 9 is the standalone constant. 4 is the coefficient attached to x.',
      incorrectExplanation:
          'Look for the number standing by itself without a variable.',
    ),
    LessonStep(
      id: 'm1_l2_s07',
      type: LessonStepType.quiz,
      title: 'Think About It',
      question: 'If x changes from 2 to 10 in x + 7, what happens to 7?',
      choices: [
        ChoiceOption(label: 'It increases'),
        ChoiceOption(label: 'It stays 7', isCorrect: true),
        ChoiceOption(label: 'It becomes 10'),
        ChoiceOption(label: 'It changes to 17'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation:
          'Exactly! A constant never changes its value—that is why it is called constant.',
      incorrectExplanation:
          'Remember: constants stay fixed regardless of how the variable changes.',
    ),
    LessonStep(
      id: 'm1_l2_s08',
      type: LessonStepType.summary,
      title: 'Constants Summary',
      xyDialogue:
          'Great job! You can now tell the difference between what *shifts* and what *stays fixed*.',
      xyAsset: AppAssets.xyHappy,
      bodyText:
          'You learned:\n• A constant is a fixed number with a definite value\n• Constants do not change when variables change\n• In x + 5, x is the variable and 5 is the constant\n• A number standing alone without a variable is always a constant',
    ),
  ],
);
