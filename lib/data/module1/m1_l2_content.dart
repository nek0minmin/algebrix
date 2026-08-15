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
          'Variables can change, but some values stay fixed. Those steady values are called constants.',
      xyAsset: AppAssets.xyExplaining,
      buttonLabel: 'Meet constants',
    ),
    LessonStep(
      id: 'm1_l2_s02',
      type: LessonStepType.content,
      title: 'What Is a Constant?',
      bodyText:
          'A **constant** is a number whose value stays the same. Examples include **5**, **12**, **100**, **−3**, and **½**.',
      mathExpression: 'x + 5',
      mathAnnotation: 'x may change, but 5 always has the value 5.',
    ),
    LessonStep(
      id: 'm1_l2_s03',
      type: LessonStepType.content,
      title: 'Change One Part',
      bodyText:
          'Try different values for x and watch what happens:\n\nx = 1  →  1 + 5\nx = 4  →  4 + 5\nx = 10 → 10 + 5',
      mathExpression: 'x + 5',
      mathAnnotation:
          'The x-value changes in every row. The constant 5 stays put.',
    ),
    LessonStep(
      id: 'm1_l2_s04',
      type: LessonStepType.xySays,
      xyDialogue:
          'A constant is the dependable part of an expression—it keeps the same value even when a variable changes.',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm1_l2_s05',
      type: LessonStepType.activity,
      title: 'Change or Stay?',
      question:
          'Sort each part by whether its value can change or must stay fixed.',
      isAnswerStep: true,
      xyAsset: AppAssets.xyPointing,
      activity: ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'change', label: 'Can change'),
          ActivityCategory(id: 'stay', label: 'Stays fixed'),
        ],
        items: [
          ClassificationItem(id: 'x', label: 'x', categoryId: 'change'),
          ClassificationItem(id: 'seven', label: '7', categoryId: 'stay'),
          ClassificationItem(id: 'y', label: 'y', categoryId: 'change'),
          ClassificationItem(id: 'fifteen', label: '15', categoryId: 'stay'),
          ClassificationItem(id: 'a', label: 'a', categoryId: 'change'),
          ClassificationItem(
            id: 'negative-four',
            label: '−4',
            categoryId: 'stay',
          ),
        ],
      ),
      explanation:
          'Letters such as x, y, and a can represent changing values. The numbers 7, 15, and −4 are constants.',
      incorrectExplanation:
          'Ask whether the symbol can take different values. A number written by itself stays fixed.',
    ),
    LessonStep(
      id: 'm1_l2_s06',
      type: LessonStepType.content,
      title: 'The Sign Belongs to the Number',
      bodyText:
          'A negative sign written with a constant is part of that constant.',
      mathExpression: 'x - 4 = x + (-4)',
      mathAnnotation: 'The constant is −4, not just 4.',
    ),
    LessonStep(
      id: 'm1_l2_s07',
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
      xyAsset: AppAssets.xyPointing,
      explanation: 'Correct! 9 is written by itself, so its value stays fixed.',
      incorrectExplanation:
          'Look for the number written by itself rather than the number multiplying x.',
    ),
    LessonStep(
      id: 'm1_l2_s08',
      type: LessonStepType.interactive,
      title: 'Why Is It Constant?',
      question: 'If x changes from 2 to 10 in x + 7, what happens to 7?',
      choices: [
        ChoiceOption(label: 'It changes to 10'),
        ChoiceOption(label: 'It stays 7', isCorrect: true),
        ChoiceOption(label: 'It changes to 2'),
        ChoiceOption(label: 'It disappears'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyPointing,
      explanation: 'Exactly. x can change from 2 to 10, while 7 remains 7.',
      incorrectExplanation: 'A constant is defined by keeping the same value.',
    ),
    LessonStep(
      id: 'm1_l2_s09',
      type: LessonStepType.summary,
      title: 'Constants Complete!',
      xyDialogue: 'Great work! You can now spot the values that stay fixed.',
      xyAsset: AppAssets.xyHappy,
      bodyText:
          'You learned:\n• Constants keep the same value\n• A standalone number is a constant\n• A negative sign belongs to its constant\n• Constants differ from variables, which can change',
    ),
  ],
);
