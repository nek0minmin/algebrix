import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m2Lesson4 = LessonContent(
  lessonId: 'm2_l4',
  title: 'Properties of Operations',
  moduleId: 'module2',
  moduleTitle: 'Working with Expressions',
  objective:
      'Recognize and apply commutative, associative, identity, and zero properties.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm2_l4_s01',
      type: LessonStepType.intro,
      title: 'Algebra Has Patterns',
      bodyText: 'Properties of Operations',
      xyDialogue:
          'Compare 3 + 5 = 8 and 5 + 3 = 8. We changed the order, but the answer stayed the same! Let\'s discover the *patterns* math lets us rely on.',
      xyAsset: AppAssets.xyWave,
      buttonLabel: 'Discover patterns →',
    ),
    LessonStep(
      id: 'm2_l4_s02',
      type: LessonStepType.content,
      title: 'Commutative Property',
      bodyText:
          '**Change the Order**\n\n• **a + b = b + a** (Addition: 4 + 7 = 7 + 4 = 11)\n• **a × b = b × a** (Multiplication: 3 × 5 = 5 × 3 = 15)\n\nThis is called the **Commutative Property**.',
      mathExpression: 'a + b = b + a    •    a × b = b × a',
      mathAnnotation: 'Order changes, result stays the same!',
    ),
    LessonStep(
      id: 'm2_l4_s03',
      type: LessonStepType.xySays,
      xyDialogue:
          'Think: *commute = move around*! Numbers can switch seats in addition and multiplication.',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm2_l4_s04',
      type: LessonStepType.content,
      title: 'Does It Always Work?',
      bodyText:
          'What about subtraction?\n**10 − 4 = 6**, but **4 − 10 = −6** (Not the same!)\n\nWhat about division?\n**10 ÷ 2 = 5**, but **2 ÷ 10 = 0.2** (Not the same!)\n\nSubtraction and division are **NOT commutative**.',
      mathExpression: '10 − 4 ≠ 4 − 10    •    10 ÷ 2 ≠ 2 ÷ 10',
      mathAnnotation: 'A pattern is only useful when we know where it works!',
    ),
    LessonStep(
      id: 'm2_l4_s05',
      type: LessonStepType.content,
      title: 'Associative Property',
      bodyText:
          '**Change the Grouping**\n\nLook at:\n• **(2 + 3) + 4** = 5 + 4 = 9\n• **2 + (3 + 4)** = 2 + 7 = 9\n\nChanging the grouping parentheses does not change the answer.\n**(a + b) + c = a + (b + c)**',
      mathExpression: '(a + b) + c = a + (b + c)',
      mathAnnotation: 'Think: associate = who you group with!',
    ),
    LessonStep(
      id: 'm2_l4_s06',
      type: LessonStepType.content,
      title: 'Identity & Zero Properties',
      bodyText:
          '• **Identity of Addition**: **x + 0 = x** (Zero changes nothing)\n• **Identity of Multiplication**: **x × 1 = x** (One changes nothing)\n• **Zero Property**: **x × 0 = 0** (Zero absorbs multiplication)',
      mathExpression: 'x + 0 = x    •    x × 1 = x    •    x × 0 = 0',
      mathAnnotation: 'Zero and one know when to leave things alone!',
    ),
    LessonStep(
      id: 'm2_l4_s07',
      type: LessonStepType.quiz,
      title: 'Quick Check',
      question: 'Which property is shown?\n\n7 + 4 = 4 + 7',
      choices: [
        ChoiceOption(label: 'Associative Property'),
        ChoiceOption(label: 'Commutative Property', isCorrect: true),
        ChoiceOption(label: 'Identity Property'),
        ChoiceOption(label: 'Distributive Property'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation:
          'Right! The numbers switched places, but the result stayed the same. That is the Commutative Property.',
      incorrectExplanation:
          'Notice that the order of the numbers changed (switched positions).',
    ),
    LessonStep(
      id: 'm2_l4_s08',
      type: LessonStepType.summary,
      title: 'Properties Complete!',
      bodyText:
          'You learned:\n• Commutative Property: a + b = b + a (change order)\n• Associative Property: (a + b) + c = a + (b + c) (change grouping)\n• Identity Elements: x + 0 = x and x × 1 = x\n• Zero Property: x × 0 = 0\n• Subtraction and division are NOT commutative',
      xyDialogue:
          'These patterns are the *golden rules* that make algebra trustworthy!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Finish Lesson',
    ),
  ],
);
