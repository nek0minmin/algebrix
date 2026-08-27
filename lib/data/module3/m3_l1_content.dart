import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m3Lesson1 = LessonContent(
  lessonId: 'm3_l1',
  title: 'Understanding Equations',
  moduleId: 'module3',
  moduleTitle: 'Solving Equations',
  objective:
      'Understand what makes an equation, see equality as a balance, and identify solutions.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm3_l1_s01',
      type: LessonStepType.intro,
      title: 'Meet the Equation',
      bodyText: 'What Makes an Equation?',
      xyDialogue:
          'You\'ve worked with expressions like 3x + 2. Look what happens when we add an equals sign: 3x + 2 = 11! Think of = as saying *has the same value as*.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Explore Equations →',
    ),
    LessonStep(
      id: 'm3_l1_s02',
      type: LessonStepType.content,
      title: 'Two Sides, One Relationship',
      bodyText:
          'Every equation has **two sides** connected by an equals sign:\n\n• **Left side**: 3x + 2\n• **Right side**: 11\n\nThe equals sign tells us that **3x + 2** and **11** must represent the **exact same amount**.',
      mathExpression: '3x + 2 = 11',
      mathAnnotation: 'Left Side (3x + 2)  =  Right Side (11)',
    ),
    LessonStep(
      id: 'm3_l1_s03',
      type: LessonStepType.content,
      title: 'Equality Is a Balance',
      bodyText:
          'Imagine **x + 3 = 7** as a balanced physical scale ⚖️.\n\n• One pan contains: **x + 3**\n• The other pan contains: **7**\n\nBecause they are equal, the scale stays **perfectly level**.\n\nIf you change one side without changing the other, the equality breaks! This is the big idea behind solving equations.',
      mathExpression: 'x + 3 = 7',
      mathAnnotation: '⚖️ Both pans must stay in balance!',
    ),
    LessonStep(
      id: 'm3_l1_s04',
      type: LessonStepType.content,
      title: 'What Are We Looking For?',
      bodyText:
          'Consider **x + 3 = 7**.\n\nWe are looking for a value of **x** that makes the equation true:\n\n• Try **x = 2**: 2 + 3 = 5, but 5 ≠ 7 ❌\n• Try **x = 4**: 4 + 3 = 7, and 7 = 7 ✅\n\nTherefore, **x = 4** is the **solution**.',
      mathExpression: 'x = 4',
      mathAnnotation: '4 + 3 = 7 (Makes the equation true!)',
    ),
    LessonStep(
      id: 'm3_l1_s05',
      type: LessonStepType.quiz,
      title: 'Try It',
      question: 'Which value makes this equation true?\n\nx + 2 = 8',
      choices: [
        ChoiceOption(label: '4'),
        ChoiceOption(label: '5'),
        ChoiceOption(label: '6', isCorrect: true),
        ChoiceOption(label: '10'),
      ],
      correctChoiceIndex: 2,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation: 'Awesome! 6 + 2 = 8, so x = 6 makes both sides equal.',
      incorrectExplanation:
          'Substitute each number in for x: which one gives 8 when you add 2?',
    ),
    LessonStep(
      id: 'm3_l1_s06',
      type: LessonStepType.summary,
      title: 'Explore the Why',
      bodyText:
          'Why do we solve equations?\n\n• Solving an equation means finding the **unknown value** that makes the relationship true.\n• We aren\'t just trying to "get x alone."\n• We are asking: *"What value makes both sides equal?"*\n\nRemember: **Equality must be preserved from beginning to end.**',
      mathExpression: 'Balance: Left = Right',
      mathAnnotation: 'A solution preserves equality on both sides!',
      xyDialogue:
          'Never forget: an equation is a balance! Keep both sides equal every step of the way.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 3.1',
    ),
  ],
);
