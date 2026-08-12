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
          'A number next to a variable has a special job: it tells how many of that variable we have.',
      xyAsset: AppAssets.xyExplaining,
      buttonLabel: 'Meet coefficients',
    ),
    LessonStep(
      id: 'm1_l5_s02',
      type: LessonStepType.content,
      title: 'What Is a Coefficient?',
      bodyText: 'A **coefficient** is the number multiplying a variable.',
      mathExpression: '7x',
      mathAnnotation: '7 is the coefficient because 7x means 7 × x.',
    ),
    LessonStep(
      id: 'm1_l5_s03',
      type: LessonStepType.content,
      title: 'Four Groups of x',
      bodyText:
          'Multiplication can be shown as repeated groups. Four x-groups make 4x.',
      mathExpression: 'x + x + x + x = 4x',
      mathAnnotation: 'The coefficient 4 counts the groups of x.',
    ),
    LessonStep(
      id: 'm1_l5_s04',
      type: LessonStepType.content,
      title: 'Keep the Negative Sign',
      bodyText:
          'A negative sign attached to a variable term belongs to its coefficient.',
      mathExpression: '−4y = (−4) × y',
      mathAnnotation: 'The coefficient is −4, not 4.',
    ),
    LessonStep(
      id: 'm1_l5_s05',
      type: LessonStepType.content,
      title: 'The Invisible 1',
      bodyText:
          'When a variable appears alone, its coefficient is 1. A leading minus sign means the coefficient is −1.',
      mathExpression: 'x = 1x     −x = −1x',
      mathAnnotation: 'We usually leave the 1 unwritten.',
    ),
    LessonStep(
      id: 'm1_l5_s06',
      type: LessonStepType.quiz,
      title: 'Coefficient Check',
      question: 'What is the coefficient in 7x?',
      choices: [
        ChoiceOption(label: 'x'),
        ChoiceOption(label: '1'),
        ChoiceOption(label: '7', isCorrect: true),
        ChoiceOption(label: '7x'),
      ],
      correctChoiceIndex: 2,
      isAnswerStep: true,
      explanation: 'Correct! 7 multiplies x.',
      incorrectExplanation: 'Find the number multiplying the variable.',
    ),
    LessonStep(
      id: 'm1_l5_s07',
      type: LessonStepType.quiz,
      title: 'Watch the Sign',
      question: 'What is the coefficient in −4y?',
      choices: [
        ChoiceOption(label: '4'),
        ChoiceOption(label: '−4', isCorrect: true),
        ChoiceOption(label: 'y'),
        ChoiceOption(label: '−y'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      explanation:
          'Yes! The negative sign is part of the coefficient, so it is −4.',
      incorrectExplanation:
          'Keep the sign attached to the number multiplying y.',
    ),
    LessonStep(
      id: 'm1_l5_s08',
      type: LessonStepType.quiz,
      title: 'Find the Invisible Coefficient',
      question: 'What is the coefficient in x?',
      choices: [
        ChoiceOption(label: '0'),
        ChoiceOption(label: '1', isCorrect: true),
        ChoiceOption(label: 'x'),
        ChoiceOption(label: 'There is none'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      explanation: 'Exactly! x means 1 × x, so its coefficient is 1.',
      incorrectExplanation: 'Rewrite x as a multiplication fact: 1 × x.',
    ),
    LessonStep(
      id: 'm1_l5_s09',
      type: LessonStepType.xySays,
      xyDialogue:
          'Coefficients are multipliers. Keep their signs, and remember the invisible 1 beside a lone variable!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm1_l5_s10',
      type: LessonStepType.summary,
      title: 'Coefficients Complete!',
      xyDialogue:
          'Fantastic—you can now identify the number multiplying any variable.',
      xyAsset: AppAssets.xyHappy,
      bodyText:
          'You learned:\n• A coefficient multiplies a variable\n• The sign is part of the coefficient\n• A lone variable has coefficient 1\n• A negative lone variable has coefficient −1',
    ),
  ],
);
