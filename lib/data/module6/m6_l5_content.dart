import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 6.5 — Factoring Polynomials
///
/// Factoring is framed as multiplication run backwards, so the area model from
/// 6.4 is reused rather than replaced by a new procedure.
final m6Lesson5 = LessonContent(
  lessonId: 'm6_l5',
  title: 'Factoring Polynomials',
  moduleId: 'module6',
  moduleTitle: 'Polynomials',
  objective:
      'Factor out a common factor and factor simple trinomials by running '
      'multiplication backwards.',
  xyAsset: AppAssets.xyIdea,
  steps: [
    LessonStep(
      id: 'm6_l5_s01',
      type: LessonStepType.intro,
      title: 'Multiplication in Reverse',
      bodyText: 'Start with the answer. Find the pieces.',
      xyDialogue:
          'Last lesson you turned **(x + 2)(x + 3)** into **x² + 5x + 6**. Now '
          'we go the other way — start at the answer and find what was '
          'multiplied.',
      xyAsset: AppAssets.xyQuestion,
      buttonLabel: 'Go backwards',
    ),
    LessonStep(
      id: 'm6_l5_s02',
      type: LessonStepType.content,
      title: 'Pull Out What They Share',
      bodyText:
          'Look at **6x + 9**.\n\nBoth terms are divisible by **3**, so pull it '
          'out front:\n\n`3(2x + 3)`\n\nCheck by distributing: `3 × 2x = 6x` and '
          '`3 × 3 = 9` ✓',
      mathExpression: '6x + 9 = 3(2x + 3)',
      mathAnnotation: 'This is the distributive property, used in reverse.',
    ),
    LessonStep(
      id: 'm6_l5_s03',
      type: LessonStepType.content,
      title: 'Variables Can Come Out Too',
      bodyText:
          'In **4x² + 6x**, both terms share a **2** and both share an **x**.\n\n'
          'So the common factor is **2x**:\n\n`2x(2x + 3)`\n\nAlways take the '
          '**greatest** factor they share, not just any one.',
      mathExpression: '4x² + 6x = 2x(2x + 3)',
      mathAnnotation: 'Take the biggest piece both terms have in common.',
    ),
    LessonStep(
      id: 'm6_l5_s04',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Factor It Out',
      question: 'Factor **10x + 15**.',
      choices: const [
        ChoiceOption(label: '5(2x + 3)', isCorrect: true),
        ChoiceOption(label: '5(2x + 15)'),
        ChoiceOption(label: '10(x + 15)'),
        ChoiceOption(label: '5x(2 + 3)'),
      ],
      correctChoiceIndex: 0,
      explanation:
          'Both terms divide by **5**: `10x ÷ 5 = 2x` and `15 ÷ 5 = 3`, giving '
          '**5(2x + 3)**.',
      incorrectExplanation:
          'Divide **every** term by the factor you pull out — including the '
          'constant.',
    ),
    LessonStep(
      id: 'm6_l5_s05',
      type: LessonStepType.content,
      title: 'Factoring a Trinomial',
      bodyText:
          'For **x² + 5x + 6**, look for two numbers that\n\n'
          '• **multiply** to **6** (the constant)\n'
          '• **add** to **5** (the middle coefficient)\n\n'
          '**2** and **3** do both, so the factors are `(x + 2)(x + 3)`.',
      mathExpression: 'x² + 5x + 6 = (x + 2)(x + 3)',
      mathAnnotation:
          'Those are exactly the two numbers from the area model last lesson.',
    ),
    LessonStep(
      id: 'm6_l5_s06',
      type: LessonStepType.xySays,
      xyDialogue:
          'Why does that work? The last boxes of the rectangle multiply to the '
          'constant, and the two middle boxes add to the middle term. Factoring '
          'is just reading the same grid in reverse.',
      xyAsset: AppAssets.xyInsight,
    ),
    LessonStep(
      id: 'm6_l5_s07',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Find the Pair',
      question:
          'To factor **x² + 7x + 12**, sort each pair by whether it works.',
      xyDialogue:
          'The pair has to satisfy **both** conditions — multiply to 12 AND add to 7.',
      activity: const ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'yes', label: 'Works'),
          ActivityCategory(id: 'no', label: 'Does not work'),
        ],
        items: [
          ClassificationItem(id: 'a', label: '3 and 4', categoryId: 'yes'),
          ClassificationItem(id: 'b', label: '2 and 6', categoryId: 'no'),
          ClassificationItem(id: 'c', label: '1 and 12', categoryId: 'no'),
          ClassificationItem(id: 'd', label: '5 and 2', categoryId: 'no'),
        ],
      ),
      explanation:
          'Only **3 and 4** multiply to 12 and add to 7, so the answer is '
          '`(x + 3)(x + 4)`. The others fail one test or the other.',
      incorrectExplanation:
          '2 and 6 multiply to 12 but add to 8. Both conditions must hold at once.',
    ),
    LessonStep(
      id: 'm6_l5_s08',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Your Turn',
      question: 'Factor **x² + 8x + 15**.',
      choices: const [
        ChoiceOption(label: '(x + 3)(x + 5)', isCorrect: true),
        ChoiceOption(label: '(x + 1)(x + 15)'),
        ChoiceOption(label: '(x + 4)(x + 4)'),
        ChoiceOption(label: '(x + 8)(x + 15)'),
      ],
      correctChoiceIndex: 0,
      explanation:
          '**3 × 5 = 15** and **3 + 5 = 8**, so it factors to `(x + 3)(x + 5)` '
          '— the very expression you multiplied in 6.4.',
      incorrectExplanation:
          'Find two numbers that multiply to 15 and add to 8. Check both before '
          'choosing.',
    ),
    LessonStep(
      id: 'm6_l5_s09',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Check by Multiplying',
      question:
          'Someone factors **x² + 6x + 8** as `(x + 2)(x + 4)`. Is it right?',
      choices: const [
        ChoiceOption(label: 'Yes — it multiplies back correctly', isCorrect: true),
        ChoiceOption(label: 'No, it should be (x + 1)(x + 8)'),
        ChoiceOption(label: 'No, it should be (x + 3)(x + 5)'),
      ],
      correctChoiceIndex: 0,
      explanation:
          'Multiply it out: `x² + 4x + 2x + 8 = x² + 6x + 8` ✓ Factoring can '
          'always be checked by multiplying back.',
      incorrectExplanation:
          'Run the area model forwards. Do you land back on the original?',
    ),
    LessonStep(
      id: 'm6_l5_s10',
      type: LessonStepType.summary,
      title: 'Module Complete',
      bodyText:
          'Factoring is **multiplication run backwards** — and you can always '
          'check your answer by multiplying it out again.',
      xyDialogue:
          'Terms, adding, subtracting, multiplying and factoring. That is the '
          'whole polynomial toolkit.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 6.5',
    ),
  ],
);
