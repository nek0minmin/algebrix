import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 6.1 — Meet the Polynomials
final m6Lesson1 = LessonContent(
  lessonId: 'm6_l1',
  title: 'Meet the Polynomials',
  moduleId: 'module6',
  moduleTitle: 'Polynomials',
  objective:
      'Recognise polynomials and their terms, coefficients, variables, '
      'exponents and degree.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm6_l1_s01',
      type: LessonStepType.intro,
      title: 'Expressions Can Grow',
      bodyText: 'More terms, same ideas.',
      xyDialogue:
          'You already handle **3x + 2**. Expressions can hold more pieces, '
          'like **2x² + 3x + 5**. That is a **polynomial**.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Take it apart',
    ),
    LessonStep(
      id: 'm6_l1_s02',
      type: LessonStepType.content,
      title: 'Meet the Pieces',
      bodyText:
          'Look at **4x² + 3x − 7**.\n\nIt holds three **terms**: `4x²`, `3x` '
          'and `−7`.\n\nTerms are separated by **+** and **−**, and the sign '
          'belongs to the term after it.',
      mathExpression: '4x²  |  3x  |  −7',
      mathAnnotation: 'Each term is one piece of the polynomial.',
    ),
    LessonStep(
      id: 'm6_l1_s03',
      type: LessonStepType.content,
      title: 'Inside a Term',
      bodyText:
          'Take **5x²**:\n\n'
          '• **5** is the **coefficient**\n'
          '• **x** is the **variable**\n'
          '• **2** is the **exponent**\n\n'
          'A term with no variable, like **−8**, is a **constant**.',
      mathExpression: '5x²',
      mathAnnotation: 'All words you already know — now in one place.',
    ),
    LessonStep(
      id: 'm6_l1_s04',
      type: LessonStepType.content,
      title: 'Polynomial Names',
      bodyText:
          'We name polynomials by how many terms they have.\n\n'
          '• One term, like **4x²** → **monomial**\n'
          '• Two terms, like **x + 3** → **binomial**\n'
          '• Three terms, like **x² + 3x + 2** → **trinomial**',
      mathExpression: 'mono · bi · tri',
      mathAnnotation: 'The names just count the pieces you can see.',
    ),
    LessonStep(
      id: 'm6_l1_s05',
      type: LessonStepType.content,
      title: 'Meet the Degree',
      bodyText:
          'The **degree** is the highest exponent in the polynomial.\n\n'
          '• **3x² + 5x + 1** → degree **2**\n'
          '• **2x³ + x² − 4** → degree **3**',
      mathExpression: 'degree = highest power',
      mathAnnotation: 'Find the biggest exponent and read it off.',
    ),
    LessonStep(
      id: 'm6_l1_s06',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Polynomial Scanner',
      question:
          'In **6x² − 3x + 4**, what is the coefficient of **x²**?',
      choices: const [
        ChoiceOption(label: '6', isCorrect: true),
        ChoiceOption(label: '2'),
        ChoiceOption(label: '−3'),
        ChoiceOption(label: '4'),
      ],
      correctChoiceIndex: 0,
      explanation:
          'The coefficient is the number multiplying the variable, so **6**. '
          'The 2 is the exponent and the 4 is the constant.',
      incorrectExplanation:
          'Look for the number sitting in front of x², not the little raised one.',
    ),
    LessonStep(
      id: 'm6_l1_s07',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Count and Name',
      question:
          'How many terms does **6x² − 3x + 4** have, and what is it called?',
      choices: const [
        ChoiceOption(label: '2 terms, binomial'),
        ChoiceOption(label: '3 terms, trinomial', isCorrect: true),
        ChoiceOption(label: '1 term, monomial'),
      ],
      correctChoiceIndex: 1,
      explanation:
          'Three terms — `6x²`, `−3x` and `+4` — so it is a **trinomial**, '
          'with degree **2**.',
      incorrectExplanation:
          'Count the pieces separated by + and −. Each one is a term.',
    ),
    LessonStep(
      id: 'm6_l1_s08',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Are They Like Terms?',
      question: 'Sort each pair. This one matters for everything ahead.',
      xyDialogue:
          'Like terms need the **same variable and the same exponent**.',
      activity: const ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'like', label: 'Like terms'),
          ActivityCategory(id: 'unlike', label: 'Unlike terms'),
        ],
        items: [
          ClassificationItem(id: 'a', label: '3x² and 7x²', categoryId: 'like'),
          ClassificationItem(id: 'b', label: '3x² and 7x', categoryId: 'unlike'),
          ClassificationItem(id: 'c', label: '5x and −2x', categoryId: 'like'),
          ClassificationItem(id: 'd', label: '4x and 4y', categoryId: 'unlike'),
        ],
      ),
      explanation:
          'Only terms with an identical variable part can be combined. **3x²** '
          'and **7x** are different pieces entirely.',
      incorrectExplanation:
          'Matching coefficients do not matter. The variable **and** its '
          'exponent must be the same.',
    ),
    LessonStep(
      id: 'm6_l1_s09',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'A polynomial is just **terms joined by + and −** — and only like '
          'terms can be combined.',
      xyDialogue:
          'That last idea is the foundation for everything else in this module.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 6.1',
    ),
  ],
);
