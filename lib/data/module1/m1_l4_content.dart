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
          'Variables, constants, and operations join together to create *algebraic expressions*.',
      xyAsset: AppAssets.xyExplaining,
      buttonLabel: 'Build expressions',
    ),
    LessonStep(
      id: 'm1_l4_s02',
      type: LessonStepType.content,
      title: 'What Is an Expression?',
      bodyText:
          'An **expression** is a mathematical phrase made from numbers, variables, and operations.\n\n✨ It **never** has an equals sign `=`.',
      mathExpression: '4x + 7',
      mathAnnotation: 'Other expressions include 3y, a − 2, and 5 + n.',
      xyDialogue:
          'Think of an expression like a *sentence fragment*—it describes a value!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm1_l4_s03',
      type: LessonStepType.content,
      title: 'Connect the Parts',
      bodyText:
          'Let\'s dissect `4x + 7`:\n\n• 🌸 **x** is the **variable**\n• 🟣 **4** is its **coefficient**\n• ➕ **+** is the **operation**\n• 🟡 **7** is the **constant**',
      mathExpression: '4x + 7',
      mathAnnotation: 'All four parts work together to form one expression.',
      xyDialogue:
          'Every algebraic expression is built from these core ingredients!',
      xyAsset: AppAssets.xyExplaining,
    ),
    LessonStep(
      id: 'm1_l4_s04',
      type: LessonStepType.xySays,
      xyDialogue:
          'Think of an expression as a math phrase. It represents a value, but it does *not make an equality claim*.',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm1_l4_s05',
      type: LessonStepType.content,
      title: 'Expression or Equation?',
      bodyText:
          '• 📝 **Expression**: No equals sign (`4x + 7`)\n• ⚖️ **Equation**: States two sides are equal (`4x + 7 = 19`)',
      mathExpression: '4x + 7   •   4x + 7 = 19',
      mathAnnotation:
          'The equals sign = turns a phrase into a balanced equation!',
      xyDialogue:
          'An equation is like a *complete sentence* with a balance scale in the middle!',
      xyAsset: AppAssets.xyHappy,
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
          ClassificationItem(id: '3x_plus_2', label: '3x + 2', categoryId: 'expression'),
          ClassificationItem(id: '3x_eq_11', label: '3x + 2 = 11', categoryId: 'equation'),
          ClassificationItem(id: 'y_minus_5', label: 'y − 5', categoryId: 'expression'),
          ClassificationItem(id: '2a_eq_8', label: '2a = 8', categoryId: 'equation'),
        ],
      ),
      explanation: 'No equals sign = expression. An equals sign = equation.',
      incorrectExplanation:
          'Look for the = sign. Items with = are equations; items without are expressions.',
    ),
    LessonStep(
      id: 'm1_l4_s07',
      type: LessonStepType.quiz,
      title: 'Quick Check',
      question: 'Which of these is an expression?',
      choices: [
        ChoiceOption(label: '2x + 5 = 15'),
        ChoiceOption(label: '2x + 5', isCorrect: true),
        ChoiceOption(label: 'x = 5'),
        ChoiceOption(label: '2x + 5 = y'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation: 'Correct! 2x + 5 has no equals sign, so it is an expression.',
      incorrectExplanation: 'Choose the option that does not contain an equals sign.',
    ),
    LessonStep(
      id: 'm1_l4_s08',
      type: LessonStepType.quiz,
      title: 'Spot the Difference',
      question: 'Why is 3x + 5 = 20 an equation instead of an expression?',
      choices: [
        ChoiceOption(label: 'It has a variable'),
        ChoiceOption(label: 'It has an equals sign', isCorrect: true),
        ChoiceOption(label: 'It has two numbers'),
        ChoiceOption(label: 'It uses addition'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation:
          'Spot on! The equals sign = is what makes it an equation.',
      incorrectExplanation:
          'The defining feature of an equation is the equals sign connecting two sides.',
    ),
    LessonStep(
      id: 'm1_l4_s09',
      type: LessonStepType.summary,
      title: 'Expressions Summary',
      xyDialogue:
          'Great work! You now know how to tell *expressions* apart from *equations*.',
      xyAsset: AppAssets.xyHappy,
      bodyText:
          'You learned:\n• Expressions are math phrases without an equals sign\n• Equations claim that two expressions are equal\n• Expressions can be evaluated, simplified, and transformed\n• Equations can be solved to find missing values',
    ),
  ],
);
