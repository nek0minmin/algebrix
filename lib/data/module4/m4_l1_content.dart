import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 4.1 — Understanding Inequalities
///
/// Goal: recognise inequality symbols and grasp that an inequality describes a
/// range of values rather than one answer.
final m4Lesson1 = LessonContent(
  lessonId: 'm4_l1',
  title: 'Understanding Inequalities',
  moduleId: 'module4',
  moduleTitle: 'Inequalities',
  objective:
      'Understand what inequalities represent, recognize their symbols, and '
      'tell an inequality apart from an equation.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm4_l1_s01',
      type: LessonStepType.intro,
      title: 'Equal Isn\'t Always Enough',
      bodyText: 'What if things aren\'t equal?',
      xyDialogue:
          'You already know **x + 2 = 7** has one answer. But what about a game '
          'that needs **at least 10 points**? Lots of scores work!',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Show me',
    ),
    LessonStep(
      id: 'm4_l1_s02',
      type: LessonStepType.content,
      title: 'More Than One Winner',
      bodyText:
          'To unlock the reward you need **at least 10 points**.\n\nThese all '
          'work:',
      bulletPoints: ['10 ✓', '11 ✓', '15 ✓', '100 ✓'],
      mathExpression: 'points ≥ 10',
      mathAnnotation:
          'One rule, many winning scores. That is an inequality.',
    ),
    LessonStep(
      id: 'm4_l1_s03',
      type: LessonStepType.content,
      title: 'Meet the Symbols',
      bodyText:
          'Inequalities tell us how two values **compare**.\n\n'
          '• **<** — less than, e.g. `x < 5`\n'
          '• **>** — greater than, e.g. `x > 5`\n'
          '• **≤** — less than **or equal to**, e.g. `x ≤ 5`\n'
          '• **≥** — greater than **or equal to**, e.g. `x ≥ 5`',
      mathExpression: '3 < 8',
      mathAnnotation: 'The wide side faces the bigger value.',
    ),
    LessonStep(
      id: 'm4_l1_s04',
      type: LessonStepType.xySays,
      xyDialogue:
          'Here\'s my trick: the **wide side** of < or > always opens toward the '
          '**greater** value. The pointy end aims at the smaller one.',
      xyAsset: AppAssets.xyIdea,
    ),
    LessonStep(
      id: 'm4_l1_s05',
      type: LessonStepType.content,
      title: 'One Answer vs. Many',
      bodyText:
          'An equation like **x = 4** describes **one** value.\n\nAn inequality '
          'like **x > 4** opens the door to many:',
      bulletPoints: ['5 ✓', '6 ✓', '10 ✓', '100 ✓', '4 ✗', '3 ✗'],
      mathExpression: 'x > 4',
      mathAnnotation:
          'An inequality can describe a whole range of possible values.',
    ),
    LessonStep(
      id: 'm4_l1_s06',
      type: LessonStepType.interactive,
      isAnswerStep: true,
      title: 'Does It Belong?',
      question: 'If x < 6, which value does **not** belong?',
      choices: const [
        ChoiceOption(label: '2'),
        ChoiceOption(label: '5'),
        ChoiceOption(label: '6', isCorrect: true),
        ChoiceOption(label: '1'),
      ],
      correctChoiceIndex: 2,
      explanation:
          'Right. Put 6 in and you get **6 < 6**, which is false — so 6 is left out.',
      incorrectExplanation:
          'Try substituting each one. Which makes the statement false? Check 6.',
    ),
    LessonStep(
      id: 'm4_l1_s07',
      type: LessonStepType.content,
      title: 'What About the Equal Line?',
      bodyText:
          'That tiny line underneath changes everything.\n\n'
          '**x < 6** means less than 6, so **6 is out**.\n\n'
          '**x ≤ 6** means less than **or equal to** 6, so **6 is in**.',
      bulletPoints: ['5 ✓', '6 ✓', '7 ✗'],
      mathExpression: '≤   and   ≥',
      mathAnnotation: 'These two include the boundary value.',
    ),
    LessonStep(
      id: 'm4_l1_s08',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Value Sorter',
      question: 'Given **x ≥ 4**, sort each value.',
      xyDialogue: 'Drop each number where it belongs. Remember what ≥ includes!',
      activity: const ClassificationActivityData(
        categories: [
          ActivityCategory(id: 'belongs', label: '✓ Belongs'),
          ActivityCategory(id: 'nope', label: '✗ Doesn\'t belong'),
        ],
        items: [
          ClassificationItem(id: 'v1', label: '1', categoryId: 'nope'),
          ClassificationItem(id: 'v3', label: '3', categoryId: 'nope'),
          ClassificationItem(id: 'v4', label: '4', categoryId: 'belongs'),
          ClassificationItem(id: 'v5', label: '5', categoryId: 'belongs'),
          ClassificationItem(id: 'v7', label: '7', categoryId: 'belongs'),
        ],
      ),
      explanation:
          'Notice something? There isn\'t just one solution — **4, 5, 7** and '
          'every number above them all work.',
      incorrectExplanation:
          'Careful with 4 itself. Because the symbol is ≥, the boundary counts too.',
    ),
    LessonStep(
      id: 'm4_l1_s09',
      type: LessonStepType.summary,
      title: 'Lesson Complete',
      bodyText:
          'Inequalities describe **relationships and ranges** — not just one answer.',
      xyDialogue:
          'You can read all four symbols now, and you know when the boundary '
          'joins the party. Next up: solving them!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 4.1',
    ),
  ],
);
