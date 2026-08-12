import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/data/module1/m1_l2_content.dart';
import 'package:algebrix/data/module1/m1_l3_content.dart';
import 'package:algebrix/data/module1/m1_l4_content.dart';
import 'package:algebrix/data/module1/m1_l5_content.dart';
import 'package:algebrix/data/module1/m1_l6_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';

final module1 = ModuleContent(
  id: 'module1',
  title: 'Welcome to Algebra!',
  description:
      'Algebra might look like a bunch of letters and numbers thrown together. But there\'s actually a pattern behind it!\n\nIn this module, we\'ll discover what those letters and numbers mean, how they work together, and why they matter.',
  icon: '✨',
  xyDialogue:
      "Hey there! I'm Xy!\nBefore we solve equations, let's explore the small ideas that make algebra work.",
  xyAsset: AppAssets.xyWave,
  buttonLabel: 'Explore Module 1',
  lessons: [
    LessonContent(
      lessonId: 'm1_l1',
      title: 'Variables',
      moduleId: 'module1',
      moduleTitle: 'Algebra Foundations',
      objective:
          'Understand what variables are and how they represent unknown values.',
      xyAsset: AppAssets.xyExplaining,
      steps: [
        LessonStep(
          id: 'step1',
          type: LessonStepType.intro,
          xyDialogue:
              'A variable is like a **mystery box**. It holds a value, and that **value can change**.',
          xyAsset: AppAssets.xyExplaining,
          buttonLabel: 'Explore variables',
        ),
        LessonStep(
          id: 'step2',
          type: LessonStepType.content,
          title: 'What is a Variable?',
          bodyText:
              'A **variable** is a letter or symbol that **represents a value** that can change or is unknown.',
          bulletPoints: ['x', 'y', 'a', 'b', 'n'],
          mathExpression: 'x + 5',
          mathAnnotation: 'Here, x is the variable. It could be 1, 10, or 100!',
        ),
        LessonStep(
          id: 'step3',
          type: LessonStepType.xySays,
          xyDialogue:
              "Think of a variable like a mystery box. 📦\nWe don't always know what's inside — but we can still work with it!",
          xyAsset: AppAssets.xyPointing,
        ),
        LessonStep(
          id: 'step4',
          type: LessonStepType.interactive,
          isAnswerStep: true,
          title: 'Mystery Box Challenge',
          question: 'If 🎁 + 5 = 12, what could be inside the box?',
          choices: const [
            ChoiceOption(label: '3'),
            ChoiceOption(label: '5'),
            ChoiceOption(label: '7', isCorrect: true),
            ChoiceOption(label: '10'),
          ],
          correctChoiceIndex: 2,
          explanation:
              'Exactly! The mystery value was 7. In algebra, instead of drawing a box, we often use a letter like x.',
          incorrectExplanation:
              'Not quite. Subtract 5 from 12 to uncover the mystery value, then try that result.',
        ),
        LessonStep(
          id: 'step5',
          type: LessonStepType.interactive,
          isAnswerStep: true,
          xyDialogue: "Great job! Now let me ask you something...",
          question: 'In the expression y + 3, which letter is the variable?',
          choices: const [
            ChoiceOption(label: 'y', isCorrect: true),
            ChoiceOption(label: '3'),
            ChoiceOption(label: '+'),
            ChoiceOption(label: 'None'),
          ],
          correctChoiceIndex: 0,
          explanation:
              'Yes! y is the variable because it represents an unknown value.',
          incorrectExplanation:
              'Look for the letter that can stand in for an unknown value. The number and operation symbol stay fixed.',
        ),
        LessonStep(
          id: 'step6',
          type: LessonStepType.quiz,
          isAnswerStep: true,
          title: 'Quick Check',
          question: 'Which of the following is a variable?',
          choices: const [
            ChoiceOption(label: '12'),
            ChoiceOption(label: '+'),
            ChoiceOption(label: 'x', isCorrect: true),
            ChoiceOption(label: '7'),
          ],
          correctChoiceIndex: 2,
          explanation:
              'Correct! x is a variable — it represents an unknown or changing value.',
          incorrectExplanation:
              'A variable is represented by a letter or symbol whose value can change. Check the choices for a letter.',
        ),
        LessonStep(
          id: 'step7',
          type: LessonStepType.summary,
          title: 'Lesson Complete! 🎉',
          xyDialogue:
              "Amazing work! You now know what variables are and how they work in algebra. Let's keep going!",
          xyAsset: AppAssets.xyHappy,
          bodyText:
              'You learned:\n• What a variable is\n• Common variable letters (x, y, a, b, n)\n• How variables represent unknown values\n• How to identify variables in expressions',
        ),
      ],
    ),
    m1Lesson2,
    m1Lesson3,
    m1Lesson4,
    m1Lesson5,
    m1Lesson6,
  ],
);
