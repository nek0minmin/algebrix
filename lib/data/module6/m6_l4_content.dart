import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 6.4 — Multiplying Polynomials
///
/// The area model comes first and FOIL arrives late, named explicitly as a
/// shortcut for distribution rather than a rule of its own.
final m6Lesson4 = LessonContent(
  lessonId: 'm6_l4',
  title: 'Multiplying Polynomials',
  moduleId: 'module6',
  moduleTitle: 'Polynomials',
  objective:
      'Multiply binomials using an area model, then recognise FOIL as a '
      'shortcut for the same distribution.',
  xyAsset: AppAssets.xyIdea,
  steps: [
    LessonStep(
      id: 'm6_l4_s01',
      type: LessonStepType.intro,
      title: 'Multiplication Means Groups',
      bodyText: 'Every piece meets every piece.',
      xyDialogue:
          'You already know **3(x + 2) = 3x + 6**, because the 3 reaches every '
          'term inside. So what happens when **both** groups have pieces?',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Find out',
    ),
    LessonStep(
      id: 'm6_l4_s02',
      type: LessonStepType.content,
      title: 'Every Piece Meets Every Piece',
      bodyText:
          'For **(x + 2)(x + 3)**, each term on the left multiplies each term '
          'on the right:\n\n'
          '• `x × x` → **x²**\n'
          '• `x × 3` → **3x**\n'
          '• `2 × x` → **2x**\n'
          '• `2 × 3` → **6**\n\n'
          'Then combine the like terms.',
      mathExpression: 'x² + 5x + 6',
      mathAnnotation: 'Four products, because two pieces met two pieces.',
    ),
    LessonStep(
      id: 'm6_l4_s03',
      type: LessonStepType.content,
      title: 'See the Area',
      bodyText:
          'Picture a rectangle whose sides are **x + 2** and **x + 3**.\n\n'
          'Split each side and the rectangle breaks into four regions — one for '
          'each product. Their total area **is** the answer.',
      mathExpression: 'x² + 3x + 2x + 6',
      mathAnnotation:
          'Multiplication is not a procedure here. It is literally the area.',
    ),
    LessonStep(
      id: 'm6_l4_s04',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Fill the Area Model',
      xyDialogue:
          'Each box is one pair of terms multiplied together. Fill them all in.',
      activity: const AreaModelActivityData(
        expression: '(x + 2)(x + 3)',
        topLabels: ['x', '3'],
        sideLabels: ['x', '2'],
        cells: ['x²', '3x', '2x', '6'],
        choices: ['x²', '3x', '2x', '6', '5x', 'x'],
        result: 'x² + 5x + 6',
      ),
      explanation:
          'Add the four regions: `x² + 3x + 2x + 6`. Combine the middle two '
          'and you get **x² + 5x + 6**.',
      incorrectExplanation:
          'Each box is its row label times its column label. Top-left is `x × x`.',
    ),
    LessonStep(
      id: 'm6_l4_s05',
      type: LessonStepType.content,
      title: 'Why x²?',
      bodyText:
          'Why does `x × x` become **x²**?\n\nBecause **x² means x multiplied '
          'by x** — two factors of x.\n\nIn the same way, `x² × x = x³`.',
      mathExpression: 'x × x = x²',
      mathAnnotation: 'Exponents count how many copies are being multiplied.',
    ),
    LessonStep(
      id: 'm6_l4_s06',
      type: LessonStepType.xySays,
      xyDialogue:
          'You may hear **FOIL** — First, Outer, Inner, Last. It is not a new '
          'rule. It is just a name for the four products you already found in '
          'the rectangle.',
      xyAsset: AppAssets.xyInsight,
    ),
    LessonStep(
      id: 'm6_l4_s07',
      type: LessonStepType.content,
      title: 'Negative Terms',
      bodyText:
          'Multiply **(x + 4)(x − 2)**:\n\n'
          '• `x × x` → **x²**\n'
          '• `x × −2` → **−2x**\n'
          '• `4 × x` → **4x**\n'
          '• `4 × −2` → **−8**\n\n'
          'Combine the middle: `−2x + 4x = 2x`.',
      mathExpression: 'x² + 2x − 8',
      mathAnnotation: 'The same four products. Just watch the signs.',
    ),
    LessonStep(
      id: 'm6_l4_s08',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Complete the Grid',
      xyDialogue: 'One more, with slightly bigger numbers.',
      activity: const AreaModelActivityData(
        expression: '(x + 3)(x + 5)',
        topLabels: ['x', '5'],
        sideLabels: ['x', '3'],
        cells: ['x²', '5x', '3x', '15'],
        choices: ['x²', '5x', '3x', '15', '8x', '8'],
        result: 'x² + 8x + 15',
      ),
      explanation:
          '`x² + 5x + 3x + 15`, and the middle terms combine to **8x**, giving '
          '**x² + 8x + 15**.',
      incorrectExplanation:
          'Bottom-right is the two numbers multiplied: `3 × 5`. It is not their sum.',
    ),
    LessonStep(
      id: 'm6_l4_s09',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Without the Grid',
      question: 'Multiply **(x + 5)(x − 2)**.',
      choices: const [
        ChoiceOption(label: 'x² + 3x − 10', isCorrect: true),
        ChoiceOption(label: 'x² + 7x − 10'),
        ChoiceOption(label: 'x² − 3x − 10'),
        ChoiceOption(label: 'x² + 3x + 10'),
      ],
      correctChoiceIndex: 0,
      explanation:
          '`x²`, `−2x`, `+5x`, `−10`. The middle pair gives **+3x**, so the '
          'answer is **x² + 3x − 10**.',
      incorrectExplanation:
          'Combine `−2x` and `+5x` carefully — and remember `5 × −2` is negative.',
    ),
    LessonStep(
      id: 'm6_l4_s10',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'Multiplying polynomials is **every piece meeting every piece** — the '
          'rectangle shows you why.',
      xyDialogue:
          'Now the fun part: running the whole thing backwards.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 6.4',
    ),
  ],
);
