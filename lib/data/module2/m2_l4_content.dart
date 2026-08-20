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
      xyDialogue:
          'Let\'s discover some patterns that mathematics lets us rely on.',
      xyAsset: AppAssets.xyExplaining,
      bodyText:
          'Compare:\n\n**3 + 5 = 8**\nand\n**5 + 3 = 8**\n\nSomething interesting happened. We changed the order... but the answer stayed the same!',
      mathExpression: '3 + 5 = 5 + 3 = 8',
      buttonLabel: 'Discover properties',
    ),
    LessonStep(
      id: 'm2_l4_s02',
      type: LessonStepType.content,
      title: 'Commutative Property',
      bodyText:
          '**Change the Order**\n\n**a + b = b + a**\n\nExample:\n**4 + 7 = 7 + 4 = 11**\n\nIt also works with multiplication:\n**3 × 5 = 5 × 3 = 15**\n\nThis is called the **Commutative Property**.',
      mathExpression: 'a + b = b + a    •    a × b = b × a',
      mathAnnotation: 'Order changes, but result stays the same!',
      xyDialogue: 'Think: commute = move around!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm2_l4_s03',
      type: LessonStepType.content,
      title: 'Does It Always Work?',
      bodyText:
          'What about:\n**10 − 4 = 6**\n\nIf we switch them:\n**4 − 10 = −6** (Not the same!)\n\nSo subtraction is **not** commutative. Neither is division (**10 ÷ 2 ≠ 2 ÷ 10**).',
      mathExpression: '10 − 4 ≠ 4 − 10    •    10 ÷ 2 ≠ 2 ÷ 10',
      mathAnnotation: 'Subtraction & division are NOT commutative!',
      xyDialogue:
          'A pattern is only useful when we know where it works!',
      xyAsset: AppAssets.xyExplaining,
    ),
    LessonStep(
      id: 'm2_l4_s04',
      type: LessonStepType.content,
      title: 'Associative Property',
      bodyText:
          '**Change the Grouping**\n\nLook at:\n**(2 + 3) + 4**  →  **5 + 4 = 9**\n\nNow:\n**2 + (3 + 4)**  →  **2 + 7 = 9**\n\nChanging the grouping didn\'t change the answer.\nThis is the **Associative Property**.',
      mathExpression: '(a + b) + c = a + (b + c)',
      mathAnnotation: 'Grouping changes, result stays identical!',
      xyDialogue: 'Think: associate = who you group with!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm2_l4_s05',
      type: LessonStepType.content,
      title: 'Identity Property',
      bodyText:
          'Some numbers leave values exactly as they are:\n\n• **Addition**: **x + 0 = x** (Adding zero changes nothing)\n• **Multiplication**: **x × 1 = x** (Multiplying by one changes nothing)\n\nThese are called identity elements.',
      mathExpression: 'x + 0 = x    •    x × 1 = x',
      mathAnnotation: 'Zero & One keep values unchanged.',
      xyDialogue:
          'Zero and one know when to leave things alone!',
      xyAsset: AppAssets.xyExplaining,
    ),
    LessonStep(
      id: 'm2_l4_s06',
      type: LessonStepType.content,
      title: 'Zero Property',
      bodyText:
          'What happens when we multiply something by zero?\n\n• **8 × 0 = 0**\n• **100 × 0 = 0**\n• **x × 0 = 0**\n\nAnything multiplied by zero equals zero!',
      mathExpression: 'x × 0 = 0',
      mathAnnotation: 'Zero product property',
      xyDialogue: 'Zero absorbs everything in multiplication!',
      xyAsset: AppAssets.xyPointing,
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
          'Right! The numbers switched places, but the result stayed the same. That\'s the Commutative Property.',
      incorrectExplanation:
          'Notice that the order of the numbers changed (switched positions).',
      buttonLabel: 'Finish Lesson',
    ),
  ],
);
