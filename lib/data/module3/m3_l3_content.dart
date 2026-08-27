import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m3Lesson3 = LessonContent(
  lessonId: 'm3_l3',
  title: 'One-Step Equations',
  moduleId: 'module3',
  moduleTitle: 'Solving Equations',
  objective:
      'Solve one-step addition, subtraction, multiplication, and division equations by applying a single inverse operation to both sides.',
  xyAsset: AppAssets.xyPointUp,
  steps: [
    LessonStep(
      id: 'm3_l3_s01',
      type: LessonStepType.intro,
      title: 'One Move Away',
      bodyText: 'One Inverse Operation',
      xyDialogue:
          'Some equations only need one inverse operation! For x + 6 = 10, ask: What is happening to x? (+6). What undoes it? (−6)!',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Learn One-Step Moves →',
    ),
    LessonStep(
      id: 'm3_l3_s02',
      type: LessonStepType.content,
      title: 'Addition Equations',
      bodyText:
          'Solve:\n\n**x + 6 = 10**\n\nSubtract 6 from both sides:\n\n**x + 6 − 6 = 10 − 6**\n\nSimplify:\n\n**x = 4**\n\nThat\'s it!',
      mathExpression: 'x + 6 − 6 = 10 − 6   ⇒   x = 4',
      mathAnnotation: 'Undo addition with subtraction.',
    ),
    LessonStep(
      id: 'm3_l3_s03',
      type: LessonStepType.content,
      title: 'Subtraction Equations',
      bodyText:
          'Solve:\n\n**x − 3 = 8**\n\nUndo **−3** by adding **3** to both sides:\n\n**x − 3 + 3 = 8 + 3**\n\nTherefore:\n\n**x = 11**',
      mathExpression: 'x − 3 + 3 = 8 + 3   ⇒   x = 11',
      mathAnnotation: 'Undo subtraction with addition.',
    ),
    LessonStep(
      id: 'm3_l3_s04',
      type: LessonStepType.content,
      title: 'Multiplication Equations',
      bodyText:
          'Solve:\n\n**4x = 20**\n\n**x** is being multiplied by 4.\n\nUndo it by **dividing both sides by 4**:\n\n**4x ÷ 4 = 20 ÷ 4**\n\n**x = 5**',
      mathExpression: '4x ÷ 4 = 20 ÷ 4   ⇒   x = 5',
      mathAnnotation: 'Undo multiplication with division.',
    ),
    LessonStep(
      id: 'm3_l3_s05',
      type: LessonStepType.content,
      title: 'Division Equations',
      bodyText:
          'Solve:\n\n**x / 3 = 4**\n\nUndo division by 3 using **multiplication**:\n\n**(x / 3) × 3 = 4 × 3**\n\n**x = 12**',
      mathExpression: '(x / 3) × 3 = 4 × 3   ⇒   x = 12',
      mathAnnotation: 'Undo division with multiplication.',
    ),
    LessonStep(
      id: 'm3_l3_s06',
      type: LessonStepType.quiz,
      title: 'Choose Your Move',
      question: 'To solve x − 9 = 5, what should you do to both sides?',
      choices: [
        ChoiceOption(label: '+9', isCorrect: true),
        ChoiceOption(label: '−9'),
        ChoiceOption(label: '×9'),
        ChoiceOption(label: '÷9'),
      ],
      correctChoiceIndex: 0,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation: 'Spot on! x − 9 + 9 = 5 + 9, so x = 14.',
      incorrectExplanation:
          'x is having 9 subtracted from it. What is the opposite of −9?',
    ),
    LessonStep(
      id: 'm3_l3_s07',
      type: LessonStepType.summary,
      title: 'Your Turn',
      bodyText:
          'Solve **5x = 35**:\n\n• Choose action: **÷5** on both sides\n• Result: **5x ÷ 5 = 35 ÷ 5**\n• **x = 7**\n\nOne-step equations: **identify the operation, then undo it!**',
      mathExpression: '5x ÷ 5 = 35 ÷ 5   ⇒   x = 7',
      mathAnnotation: 'One-step equations: Identify & Undo!',
      xyDialogue:
          'One move is all it takes! Identify what is happening to the variable and reverse it.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 3.3',
    ),
  ],
);
