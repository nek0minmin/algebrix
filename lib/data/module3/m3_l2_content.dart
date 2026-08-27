import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m3Lesson2 = LessonContent(
  lessonId: 'm3_l2',
  title: 'Inverse Operations',
  moduleId: 'module3',
  moduleTitle: 'Solving Equations',
  objective:
      'Learn how inverse operations undo additions, subtractions, multiplications, and divisions while keeping both sides balanced.',
  xyAsset: AppAssets.xyIdea,
  steps: [
    LessonStep(
      id: 'm3_l2_s01',
      type: LessonStepType.intro,
      title: 'Undo It!',
      bodyText: 'Operations Can Be Reversed',
      xyDialogue:
          'Suppose x + 5 = 12. Something happened to x: 5 was added! How can we undo +5? With −5! Addition and subtraction are inverse operations.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Meet the Opposites →',
    ),
    LessonStep(
      id: 'm3_l2_s02',
      type: LessonStepType.content,
      title: 'Operation Pairs',
      bodyText:
          'Operations can **undo** each other:\n\n• **+ 5 ↔ − 5** (Addition undoes Subtraction)\n• **× 3 ↔ ÷ 3** (Multiplication undoes Division)\n\nThese are called **inverse operations**.',
      mathExpression: '+ ↔ −   •   × ↔ ÷',
      mathAnnotation: 'Inverse operations help us undo what is happening to the variable!',
    ),
    LessonStep(
      id: 'm3_l2_s03',
      type: LessonStepType.content,
      title: 'Undoing Addition',
      bodyText:
          'Consider **x + 4 = 10**.\n\nWe want to undo **+4**, so we subtract **4**.\n\nBut remember equality!\n\n**x + 4 − 4 = 10 − 4**\n\nThe **+4** and **−4** cancel to 0:\n\n**x = 6**',
      mathExpression: 'x + 4 − 4 = 10 − 4   ⇒   x = 6',
      mathAnnotation: 'Subtract 4 from BOTH sides to isolate x.',
    ),
    LessonStep(
      id: 'm3_l2_s04',
      type: LessonStepType.content,
      title: 'Why Both Sides?',
      bodyText:
          'What if we removed 4 only from the left?\n\nx + 4 = 10  ⇒  x = 10 ❌\n\nWe changed one side without changing the other, so the equation is **no longer equivalent**!\n\nInstead, **x + 4 − 4 = 10 − 4** keeps both sides equal ⚖️.\n\n**Whatever you do to one side, do to the other.**',
      mathExpression: '⚖️ Left Side − 4  =  Right Side − 4',
      mathAnnotation: 'Change one side, you MUST change the other!',
    ),
    LessonStep(
      id: 'm3_l2_s05',
      type: LessonStepType.content,
      title: 'Undoing Multiplication',
      bodyText:
          'Now consider **3x = 12**.\n\n**3x** means **3 × x**.\n\nTo undo multiplication by 3, **divide both sides by 3**:\n\n**3x ÷ 3 = 12 ÷ 3**\n\nTherefore:\n\n**x = 4**',
      mathExpression: '3x ÷ 3 = 12 ÷ 3   ⇒   x = 4',
      mathAnnotation: 'Division undoes multiplication!',
    ),
    LessonStep(
      id: 'm3_l2_s06',
      type: LessonStepType.quiz,
      title: 'Quick Check',
      question: 'Which operation would undo:\n\nx − 7',
      choices: [
        ChoiceOption(label: '−7'),
        ChoiceOption(label: '+7', isCorrect: true),
        ChoiceOption(label: '×7'),
        ChoiceOption(label: '÷7'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation: 'Correct! −7 + 7 = 0, so adding 7 undoes subtracting 7.',
      incorrectExplanation:
          'What is the opposite operation of subtraction? If you subtracted 7, how do you cancel it?',
    ),
    LessonStep(
      id: 'm3_l2_s07',
      type: LessonStepType.summary,
      title: 'Don\'t "Move" It!',
      bodyText:
          'You may have heard:\n*"Move the number to the other side and change its sign."*\n\nThat\'s just a shortcut—there is real math happening underneath!\n\nFor **x + 5 = 9**, we are actually **subtracting 5 from both sides**:\n\n**x + 5 − 5 = 9 − 5  ⇒  x = 4**\n\nUnderstand the operation first. The shortcut will make sense later!',
      mathExpression: 'x + 5 − 5 = 9 − 5   ⇒   x = 4',
      mathAnnotation: 'Understand the operation first!',
      xyDialogue:
          'Understanding why operations work makes algebra make sense forever!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 3.2',
    ),
  ],
);
