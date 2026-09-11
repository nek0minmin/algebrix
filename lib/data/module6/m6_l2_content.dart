import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 6.2 — Adding Polynomials
final m6Lesson2 = LessonContent(
  lessonId: 'm6_l2',
  title: 'Adding Polynomials',
  moduleId: 'module6',
  moduleTitle: 'Polynomials',
  objective:
      'Add polynomials by identifying and combining like terms.',
  xyAsset: AppAssets.xySitPencil,
  steps: [
    LessonStep(
      id: 'm6_l2_s01',
      type: LessonStepType.intro,
      title: 'Put the Pieces Together',
      bodyText: 'Match first. Then add.',
      xyDialogue:
          'For **(2x + 3) + (4x + 5)**, drop the brackets and gather the '
          'matching pieces: **6x + 8**.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Show me how',
    ),
    LessonStep(
      id: 'm6_l2_s02',
      type: LessonStepType.content,
      title: 'Match Before You Add',
      bodyText:
          'Take **(3x² + 2x + 1) + (2x² + 5x + 4)**.\n\nPair up the same kinds '
          'of term:\n\n'
          '• `3x² + 2x²` → **5x²**\n'
          '• `2x + 5x` → **7x**\n'
          '• `1 + 4` → **5**',
      mathExpression: '5x² + 7x + 5',
      mathAnnotation: 'Match the variable AND the exponent before combining.',
    ),
    LessonStep(
      id: 'm6_l2_s03',
      type: LessonStepType.content,
      title: 'Why Not Combine Everything?',
      bodyText:
          'Could **3x² + 2x** become **5x³**?\n\n**No.**\n\n**x²** and **x** do '
          'not measure the same thing. It is like trying to add 3 squares and '
          '2 lines and calling the result 5 cubes.',
      mathExpression: '3x² + 2x  stays  3x² + 2x',
      mathAnnotation: 'Unlike pieces simply sit side by side.',
    ),
    LessonStep(
      id: 'm6_l2_s04',
      type: LessonStepType.xySays,
      xyDialogue:
          'A tidy trick: stack them so like terms line up in columns, then add '
          'straight down. It scales much better than hunting across a line.',
      xyAsset: AppAssets.xyIdea,
    ),
    LessonStep(
      id: 'm6_l2_s05',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Term Magnet',
      question: 'Sort these tiles by which ones can combine with each other.',
      xyDialogue: 'Only matching pieces snap together.',
      activity: const ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'sq', label: 'x² pieces'),
          ActivityCategory(id: 'lin', label: 'x pieces'),
          ActivityCategory(id: 'con', label: 'Constants'),
        ],
        items: [
          ClassificationItem(id: 'a', label: '3x²', categoryId: 'sq'),
          ClassificationItem(id: 'b', label: '2x²', categoryId: 'sq'),
          ClassificationItem(id: 'c', label: '5x', categoryId: 'lin'),
          ClassificationItem(id: 'd', label: '2x', categoryId: 'lin'),
          ClassificationItem(id: 'e', label: '4', categoryId: 'con'),
          ClassificationItem(id: 'f', label: '1', categoryId: 'con'),
        ],
      ),
      explanation:
          'Three families, three totals: **5x²**, **7x** and **5**. Only within '
          'a family can the pieces merge.',
      incorrectExplanation:
          'A tile with x² can only join another x². The exponent has to match.',
    ),
    LessonStep(
      id: 'm6_l2_s06',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Your Turn',
      question: 'Add **(4x² + 3x + 2) + (x² + 2x + 6)**.',
      choices: const [
        ChoiceOption(label: '5x² + 5x + 8', isCorrect: true),
        ChoiceOption(label: '4x² + 5x + 8'),
        ChoiceOption(label: '5x⁴ + 5x² + 8'),
        ChoiceOption(label: '10x² + 8'),
      ],
      correctChoiceIndex: 0,
      explanation:
          '`4x² + x² = 5x²`, `3x + 2x = 5x`, `2 + 6 = 8`. Adding polynomials '
          'means combining matching pieces.',
      incorrectExplanation:
          'A lone **x²** still counts as **1x²**. And exponents never add when '
          'you are combining like terms.',
    ),
    LessonStep(
      id: 'm6_l2_s07',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'Addition is just **gathering the matching pieces** and leaving the '
          'rest alone.',
      xyDialogue:
          'Subtraction looks almost identical — except for one sign that trips '
          'nearly everybody.',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 6.2',
    ),
  ],
);
