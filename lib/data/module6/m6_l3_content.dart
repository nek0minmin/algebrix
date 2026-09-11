import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 6.3 — Subtracting Polynomials
///
/// Its own lesson because the negative in front of a bracket is where the
/// mistakes live.
final m6Lesson3 = LessonContent(
  lessonId: 'm6_l3',
  title: 'Subtracting Polynomials',
  moduleId: 'module6',
  moduleTitle: 'Polynomials',
  objective:
      'Subtract polynomials by distributing the negative to every term in the '
      'group before combining.',
  xyAsset: AppAssets.xyPointUp,
  steps: [
    LessonStep(
      id: 'm6_l3_s01',
      type: LessonStepType.intro,
      title: 'Addition\'s Trickier Sibling',
      bodyText: 'One sign changes everything.',
      xyDialogue:
          'In **(5x + 7) − (2x + 3)** you are subtracting the **whole** second '
          'group — so both terms inside are affected.',
      xyAsset: AppAssets.xyQuestion,
      buttonLabel: 'Watch closely',
    ),
    LessonStep(
      id: 'm6_l3_s02',
      type: LessonStepType.content,
      title: 'The Negative Applies to Everyone',
      bodyText:
          '**−(2x + 3)** means **−1 × (2x + 3)**.\n\nDistribute it and every '
          'sign inside flips:\n\n`−2x − 3`\n\nThat is the same distribution you '
          'already know from Module 2.',
      mathExpression: '−(2x + 3) = −2x − 3',
      mathAnnotation: 'The minus belongs to the whole bracket, not just the front.',
    ),
    LessonStep(
      id: 'm6_l3_s03',
      type: LessonStepType.content,
      title: 'Watch the Signs',
      bodyText:
          'Subtract **(4x² + 6x + 5) − (2x² + 3x + 1)**.\n\nDistribute first:\n\n'
          '`4x² + 6x + 5 − 2x² − 3x − 1`\n\nThen combine:\n\n'
          '• `4x² − 2x² = 2x²`\n'
          '• `6x − 3x = 3x`\n'
          '• `5 − 1 = 4`',
      mathExpression: '2x² + 3x + 4',
      mathAnnotation: 'Distribute, then combine. Never the other way round.',
    ),
    LessonStep(
      id: 'm6_l3_s04',
      type: LessonStepType.content,
      title: 'The Common Mistake',
      bodyText:
          'Someone writes **(5x + 4) − (2x − 3)** as `5x + 4 − 2x − 3`.\n\n'
          'Something slipped. The inner term was already **−3**, so flipping it '
          'gives **+3**:\n\n`5x + 4 − 2x + 3`',
      mathExpression: '3x + 7',
      mathAnnotation:
          'Subtracting a negative gives a positive. Flip every sign, including '
          'the ones already negative.',
    ),
    LessonStep(
      id: 'm6_l3_s05',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Sign Flipper',
      question:
          'Subtracting **(x² − 2x + 5)** flips every sign inside. Sort each '
          'term into what it becomes.',
      xyDialogue: 'Every single one flips — even the ones already negative.',
      activity: const ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'neg', label: 'Becomes negative'),
          ActivityCategory(id: 'pos', label: 'Becomes positive'),
        ],
        items: [
          ClassificationItem(id: 'a', label: '+x²', categoryId: 'neg'),
          ClassificationItem(id: 'b', label: '−2x', categoryId: 'pos'),
          ClassificationItem(id: 'c', label: '+5', categoryId: 'neg'),
        ],
      ),
      explanation:
          'The group becomes `−x² + 2x − 5`. The **−2x** turned **positive**, '
          'which is the step most people miss.',
      incorrectExplanation:
          'Multiply each term by −1. A term that was already negative comes '
          'out positive.',
    ),
    LessonStep(
      id: 'm6_l3_s06',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Your Turn',
      question: 'Subtract **(6x² + 5x + 3) − (2x² + x + 1)**.',
      choices: const [
        ChoiceOption(label: '4x² + 4x + 2', isCorrect: true),
        ChoiceOption(label: '4x² + 6x + 4'),
        ChoiceOption(label: '8x² + 6x + 4'),
        ChoiceOption(label: '4x² + 4x + 4'),
      ],
      correctChoiceIndex: 0,
      explanation:
          'Distribute: `6x² + 5x + 3 − 2x² − x − 1`, then combine to get '
          '**4x² + 4x + 2**.',
      incorrectExplanation:
          'Remember the lone **x** counts as **1x**, and the **+1** becomes **−1**.',
    ),
    LessonStep(
      id: 'm6_l3_s07',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Catch the Error',
      question:
          'A learner turns **(4x + 3) − (x − 2)** into `4x + 3 − x − 2`. What '
          'went wrong?',
      choices: const [
        ChoiceOption(label: 'The −2 should have become +2', isCorrect: true),
        ChoiceOption(label: 'The x should have stayed positive'),
        ChoiceOption(label: 'Nothing is wrong'),
      ],
      correctChoiceIndex: 0,
      explanation:
          'Subtracting **−2** gives **+2**, so it should read `4x + 3 − x + 2` '
          '= **3x + 5**.',
      incorrectExplanation:
          'Apply −1 to each inner term. What is `−1 × (−2)`?',
    ),
    LessonStep(
      id: 'm6_l3_s08',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'Subtracting a polynomial means **distributing −1 across the whole '
          'group** — then it is ordinary addition.',
      xyDialogue:
          'Adding and subtracting done. Next we make polynomials bigger.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 6.3',
    ),
  ],
);
