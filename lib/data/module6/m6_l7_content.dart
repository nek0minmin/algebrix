import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 6.7 — Polynomial Playground
///
/// The sandbox. Polynomials stop being written and start being held: an x²
/// square, x strips and unit squares that lay out into a rectangle. BUILD
/// starts from the factors, FACTOR starts from the trinomial, and both end at
/// the same picture.
final m6Lesson7 = LessonContent(
  lessonId: 'm6_l7',
  title: 'Polynomial Playground',
  moduleId: 'module6',
  moduleTitle: 'Polynomials',
  objective:
      'Build and factor quadratics with algebra tiles, reading a rectangle as '
      'both an area and a pair of sides.',
  xyAsset: AppAssets.xyIdea,
  steps: [
    LessonStep(
      id: 'm6_l7_s01',
      type: LessonStepType.intro,
      title: 'Pick Up a Polynomial',
      bodyText: 'Pieces you can actually arrange.',
      xyDialogue:
          'In this room polynomials are physical. Three shapes, one rectangle, '
          'and both directions of Module 6 in a single picture.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Enter the playground',
    ),
    LessonStep(
      id: 'm6_l7_s02',
      type: LessonStepType.content,
      title: 'Meet the Tiles',
      bodyText:
          'Three pieces, and their **areas** are their names:\n\n'
          '• A large square is **x²** — sides of x by x\n'
          '• A thin strip is **x** — sides of x by 1\n'
          '• A small square is **1** — sides of 1 by 1\n\n'
          'So **x² + 5x + 6** is one square, five strips and six units.',
      mathExpression: 'x²  ·  x  ·  1',
      mathAnnotation: 'Each tile is named after the area it covers.',
    ),
    LessonStep(
      id: 'm6_l7_s03',
      type: LessonStepType.content,
      title: 'Why a Rectangle?',
      bodyText:
          'Lay the tiles out as one clean rectangle and two things become '
          'readable at the same time:\n\n'
          '• The **total area** is the expanded polynomial\n'
          '• The **two sides** are its factors\n\n'
          'They were never separate ideas.',
      mathExpression: 'sides × sides = area',
      mathAnnotation: 'Factoring and multiplying, in one picture.',
    ),
    LessonStep(
      id: 'm6_l7_s04',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Build: (x + 2)(x + 3)',
      xyDialogue:
          'Set the sides to match the factors and watch the tiles fill in.',
      activity: const AlgebraTilesActivityData(
        mode: AlgebraTilesMode.build,
        prompt: 'Set the sides so the rectangle is (x + 2)(x + 3).',
        factorP: 2,
        factorQ: 3,
      ),
      explanation:
          'One **x²**, five **x** strips and six **units** — which reads as '
          '**x² + 5x + 6**. The 5 strips are the 2 and the 3 along the edges, '
          'and the 6 units are 2 × 3.',
      incorrectExplanation:
          'One side needs the 2 and the other needs the 3. Either way round works.',
    ),
    LessonStep(
      id: 'm6_l7_s05',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Build: (x + 1)(x + 4)',
      xyDialogue:
          'Same total strips as last time. Does the rectangle look the same?',
      activity: const AlgebraTilesActivityData(
        mode: AlgebraTilesMode.build,
        prompt: 'Set the sides so the rectangle is (x + 1)(x + 4).',
        factorP: 1,
        factorQ: 4,
      ),
      explanation:
          'Also **5** strips — but only **4** units, not 6. The strips come from '
          'the **sum** and the units from the **product**, which is exactly the '
          'rule from 6.5.',
      incorrectExplanation: 'One side is x + 1 and the other is x + 4.',
    ),
    LessonStep(
      id: 'm6_l7_s06',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Factor: x² + 7x + 12',
      xyDialogue:
          'Now backwards. Rearrange the pieces until they form a clean '
          'rectangle, and Algebrix will read you its sides.',
      activity: const AlgebraTilesActivityData(
        mode: AlgebraTilesMode.factor,
        prompt: 'Find the two sides whose rectangle is x² + 7x + 12.',
        factorP: 3,
        factorQ: 4,
      ),
      explanation:
          'Sides of **x + 3** and **x + 4**: 3 and 4 add to the 7 strips and '
          'multiply to the 12 units.',
      incorrectExplanation:
          'You need 7 strips and 12 units at once. Which pair does both?',
    ),
    LessonStep(
      id: 'm6_l7_s07',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Factor: x² + 6x + 9',
      xyDialogue: 'This one has a shape worth noticing.',
      activity: const AlgebraTilesActivityData(
        mode: AlgebraTilesMode.factor,
        prompt: 'Find the two sides whose rectangle is x² + 6x + 9.',
        factorP: 3,
        factorQ: 3,
      ),
      explanation:
          'Both sides are **x + 3**, so the rectangle is a **square**. Some '
          'trinomials are squares, and the tiles show it before the algebra does.',
      incorrectExplanation:
          'Look for a pair that adds to 6 and multiplies to 9. They may match.',
    ),
    LessonStep(
      id: 'm6_l7_s08',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'What the Tiles Taught You',
      question:
          'In any of these rectangles, where do the **x strips** come from?',
      choices: const [
        ChoiceOption(
          label: 'The two side numbers added together',
          isCorrect: true,
        ),
        ChoiceOption(label: 'The two side numbers multiplied'),
        ChoiceOption(label: 'The x² tile'),
      ],
      correctChoiceIndex: 0,
      explanation:
          'Strips run along both edges, so there are **p + q** of them — while '
          'the units in the corner number **p × q**. That is the whole factoring '
          'rule, drawn.',
      incorrectExplanation:
          'Count the strips in the picture: one row of p and one column of q.',
    ),
    LessonStep(
      id: 'm6_l7_s09',
      type: LessonStepType.summary,
      title: 'Module Complete',
      bodyText:
          'A trinomial is a **rectangle**. Its area is the expanded form and '
          'its sides are the factors — read it either way.',
      xyDialogue:
          'Inequalities you painted, lines you walked, polynomials you built. '
          'Ready for the module quiz?',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 6.7',
    ),
  ],
);
