import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m3Lesson7 = LessonContent(
  lessonId: 'm3_l7',
  title: 'Checking Solutions',
  moduleId: 'module3',
  moduleTitle: 'Solving Equations',
  objective:
      'Verify algebraic solutions through substitution and establish the self-checking habit of testing equality in the original equation.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm3_l7_s01',
      type: LessonStepType.intro,
      title: 'How Do You Know?',
      bodyText: 'Verify Your Own Math',
      xyDialogue:
          'You solved 3x + 2 = 14 and got x = 4. But how do you know you\'re right? You don\'t need an answer key—you can verify it yourself!',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Learn How to Check →',
    ),
    LessonStep(
      id: 'm3_l7_s02',
      type: LessonStepType.content,
      title: 'Substitute It Back',
      bodyText:
          'Take the original equation:\n\n**3x + 2 = 14**\n\nReplace **x** with **4**:\n\n**3(4) + 2 = 14**\n\nEvaluate the left side:\n\n**12 + 2 = 14**\n**14 = 14** ✓\n\nBoth sides agree!',
      mathExpression: '3(4) + 2 = 12 + 2 = 14   (14 = 14 ✓)',
      mathAnnotation: 'True statement: Solution verified!',
    ),
    LessonStep(
      id: 'm3_l7_s03',
      type: LessonStepType.content,
      title: 'What If We\'re Wrong?',
      bodyText:
          'Suppose we thought **x = 3** was the answer.\n\nCheck it:\n\n**3(3) + 2 = 14**\n**9 + 2 = 14**\n**11 ≠ 14** ❌\n\nThat means **x = 3** is NOT a solution!\n\nAn answer isn\'t correct because we reached it. It\'s correct because it makes the original equation true.',
      mathExpression: '3(3) + 2 = 11 ≠ 14 ❌',
      mathAnnotation: 'False statement: Not a solution.',
    ),
    LessonStep(
      id: 'm3_l7_s04',
      type: LessonStepType.content,
      title: 'Spot the Mistake',
      bodyText:
          'A student solves **2x + 4 = 12** and says **x = 5**.\n\nCheck their answer:\n**2(5) + 4 = 10 + 4 = 14 ≠ 12** ❌\n\nSomething went wrong!\n\nWhat is the correct solution?\n**2x + 4 = 12  ⇒  2x = 8  ⇒  x = 4** ✓',
      mathExpression: '2(4) + 4 = 8 + 4 = 12 ✓',
      mathAnnotation: 'Always test to catch arithmetic errors!',
    ),
    LessonStep(
      id: 'm3_l7_s05',
      type: LessonStepType.quiz,
      title: 'Your Turn',
      question: 'Does x = 6 solve the equation:\n\n2x − 3 = 9?',
      choices: [
        ChoiceOption(label: 'Yes, 2(6) − 3 = 9', isCorrect: true),
        ChoiceOption(label: 'No, 2(6) − 3 ≠ 9'),
      ],
      correctChoiceIndex: 0,
      isAnswerStep: true,
      xyAsset: AppAssets.xyQuestion,
      explanation: 'Spot on! 2(6) − 3 = 12 − 3 = 9, which matches the right side (9 = 9).',
      incorrectExplanation:
          'Substitute 6 for x: 2 × 6 = 12. Then 12 − 3 = 9. Does 9 equal 9?',
    ),
    LessonStep(
      id: 'm3_l7_s06',
      type: LessonStepType.summary,
      title: 'The Solver\'s Habit',
      bodyText:
          'Whenever you solve an equation:\n\n1. **Solve**: Find the unknown value.\n2. **Substitute**: Put your answer back into the original equation.\n3. **Compare**: Do both sides have the same value?\n\nIf yes: **Solution Verified!** 🎉\n\nDon\'t just trust your answer. Test it.',
      mathExpression: '1. Solve  →  2. Substitute  →  3. Compare',
      mathAnnotation: 'The self-checking habit makes you an unstoppable solver!',
      xyDialogue:
          'Testing your own answer gives you 100% confidence in your math!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 3.7',
    ),
  ],
);
