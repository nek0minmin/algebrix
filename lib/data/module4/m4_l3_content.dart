import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 4.3 — The Negative Number Rule
///
/// Goal: understand *why* multiplying or dividing by a negative reverses the
/// inequality, rather than memorising "negative? flip the sign".
final m4Lesson3 = LessonContent(
  lessonId: 'm4_l3',
  title: 'The Negative Number Rule',
  moduleId: 'module4',
  moduleTitle: 'Inequalities',
  objective:
      'Understand why multiplying or dividing an inequality by a negative '
      'number reverses its direction.',
  xyAsset: AppAssets.xyIdea,
  steps: [
    LessonStep(
      id: 'm4_l3_s01',
      type: LessonStepType.intro,
      title: 'Something Strange Happens',
      bodyText: 'Watch what negatives do to a true statement.',
      xyDialogue:
          'I could just tell you "negative means flip the sign". But you\'d '
          'forget it by Friday. Let\'s see **why** instead.',
      xyAsset: AppAssets.xyQuestion,
      buttonLabel: 'Show me why',
    ),
    LessonStep(
      id: 'm4_l3_s02',
      type: LessonStepType.content,
      title: 'A True Statement Breaks',
      bodyText:
          'We know **2 < 5** is true.\n\nNow multiply both values by **−1**:\n\n'
          '`2 × (−1) = −2`\n`5 × (−1) = −5`\n\nKeeping the old sign would give '
          '**−2 < −5** — and that is **false**.',
      mathExpression: '−2 > −5',
      mathAnnotation: 'The relationship reversed.',
    ),
    LessonStep(
      id: 'm4_l3_s03',
      type: LessonStepType.content,
      title: 'Look at the Number Line',
      bodyText:
          'Find both numbers on the line:\n\n'
          '`←  −5  −4  −3  −2  −1   0  →`\n\n'
          '**−2** sits to the **right** of **−5**. Further right always means '
          'greater.',
      mathExpression: '−2 > −5',
      mathAnnotation:
          'Multiplying by −1 reflected both values across zero, so their order '
          'swapped.',
    ),
    LessonStep(
      id: 'm4_l3_s04',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Mirror It',
      question:
          'Start with **3 < 7**. Multiply both sides by **−1**. What is true now?',
      choices: const [
        ChoiceOption(label: '−3 < −7'),
        ChoiceOption(label: '−3 > −7', isCorrect: true),
        ChoiceOption(label: '−3 = −7'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'Yes! Both values crossed zero and swapped places, so **<** had to '
          'become **>**.',
      incorrectExplanation:
          'Picture the number line. −3 is to the right of −7, and further right '
          'means greater.',
    ),
    LessonStep(
      id: 'm4_l3_s05',
      type: LessonStepType.xySays,
      xyDialogue:
          'Don\'t memorise "flip the sign". Remember this instead: **multiplying '
          'by a negative reverses the order of the values**. The sign just '
          'follows along.',
      xyAsset: AppAssets.xyInsight,
    ),
    LessonStep(
      id: 'm4_l3_s06',
      type: LessonStepType.content,
      title: 'The Rule',
      bodyText:
          'When you **multiply or divide both sides by a negative number**, '
          'reverse the inequality.\n\n'
          '• **<** becomes **>**\n'
          '• **≤** becomes **≥**',
      mathExpression: '−2x < 8   →   x > −4',
      mathAnnotation: 'Divide by −2, and < turns into >.',
    ),
    LessonStep(
      id: 'm4_l3_s07',
      type: LessonStepType.content,
      title: 'Do We Flip Here?',
      bodyText:
          'Solve **x − 5 < 2**.\n\nAdd **5** to both sides:\n\n`x < 7`\n\n'
          'Do we reverse the sign? **No.** We added a positive number — we never '
          'multiplied or divided by a negative.',
      mathExpression: 'x < 7',
      mathAnnotation:
          'Don\'t reverse just because you spot a minus sign somewhere.',
    ),
    LessonStep(
      id: 'm4_l3_s08',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Flip or Keep?',
      question: 'Sort each move by what it does to the inequality sign.',
      xyDialogue: 'Rapid fire! Only one kind of move reverses the sign.',
      activity: const ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'flip', label: '🔄 Flip'),
          ActivityCategory(id: 'keep', label: '➡️ Keep'),
        ],
        items: [
          ClassificationItem(id: 'add5', label: '+ 5', categoryId: 'keep'),
          ClassificationItem(id: 'sub7', label: '− 7', categoryId: 'keep'),
          ClassificationItem(id: 'mul4', label: '× 4', categoryId: 'keep'),
          ClassificationItem(id: 'divneg2', label: '÷ (−2)', categoryId: 'flip'),
          ClassificationItem(id: 'mulneg5', label: '× (−5)', categoryId: 'flip'),
          ClassificationItem(id: 'div3', label: '÷ 3', categoryId: 'keep'),
        ],
      ),
      explanation:
          'Exactly right. The sign reverses **only** when you multiply or divide '
          'both sides by a negative value.',
      incorrectExplanation:
          'Subtracting 7 is not the same as multiplying by a negative. Only × or '
          '÷ by a negative flips the sign.',
    ),
    LessonStep(
      id: 'm4_l3_s09',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'Negatives reverse the **order of values**, which is why the sign has '
          'to reverse with them.',
      xyDialogue:
          'You didn\'t just learn a rule — you learned the reason behind it. '
          'That one sticks.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 4.3',
    ),
  ],
);
