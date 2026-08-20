import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m2Lesson3 = LessonContent(
  lessonId: 'm2_l3',
  title: 'Distributive Property',
  moduleId: 'module2',
  moduleTitle: 'Working with Expressions',
  objective:
      'Expand expressions with parentheses using the distributive property.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm2_l3_s01',
      type: LessonStepType.intro,
      title: 'Share With Everyone!',
      bodyText: 'The Distributive Property',
      xyDialogue:
          'Look at 3(x + 2). What does the 3 outside really mean? Let\'s open those parentheses and see what\'s inside!',
      xyAsset: AppAssets.xyWave,
      buttonLabel: 'Explore distribution →',
    ),
    LessonStep(
      id: 'm2_l3_s02',
      type: LessonStepType.content,
      title: 'See the Groups',
      bodyText:
          '**3(x + 2)** means:\n**(x + 2) + (x + 2) + (x + 2)**\n\nCount everything:\n• There are 3 x\'s: **3x**\n• And three groups of 2: **6**\n\nSo:\n**3(x + 2) = 3x + 6**',
      mathExpression: '(x + 2) + (x + 2) + (x + 2) = 3x + 6',
      mathAnnotation: '3 groups of x + 3 groups of 2!',
    ),
    LessonStep(
      id: 'm2_l3_s03',
      type: LessonStepType.xySays,
      xyDialogue:
          'The number outside doesn\'t choose favorites. Everyone inside gets multiplied!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm2_l3_s04',
      type: LessonStepType.content,
      title: 'The Shortcut: Distribute',
      bodyText:
          'Instead of expanding all the groups, we can **distribute** the multiplier:\n\nFor **3(x + 2)**:\n• **3 × x = 3x**\n• **3 × 2 = 6**\n\nTherefore:\n**3(x + 2) = 3x + 6**',
      mathExpression: '3(x + 2) = 3(x) + 3(2) = 3x + 6',
      mathAnnotation: 'Multiply the outside number by each inside term!',
    ),
    LessonStep(
      id: 'm2_l3_s05',
      type: LessonStepType.quiz,
      title: 'Your Turn',
      question:
          'Expand: 4(x + 3)\n\nFirst: 4 × x = 4x\nThen: 4 × 3 = 12\n\nWhat is the expanded expression?',
      choices: [
        ChoiceOption(label: '4x + 3', emoji: '❌'),
        ChoiceOption(label: '4x + 12', emoji: '✅', isCorrect: true),
        ChoiceOption(label: '7x', emoji: '❌'),
        ChoiceOption(label: 'x + 12', emoji: '❌'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation:
          'Spot on! 4 × x is 4x and 4 × 3 is 12, giving 4x + 12.',
      incorrectExplanation:
          'Multiply the 4 by both the x and the 3: (4 × x) + (4 × 3).',
    ),
    LessonStep(
      id: 'm2_l3_s06',
      type: LessonStepType.content,
      title: 'What About Subtraction?',
      bodyText:
          'Try:\n**2(x − 5)**\n\nDistribute 2:\n• **2 × x = 2x**\n• **2 × (−5) = −10**\n\nTherefore:\n**2(x − 5) = 2x − 10**',
      mathExpression: '2(x − 5) = 2(x) + 2(−5) = 2x − 10',
      mathAnnotation: 'The negative sign stays with 5!',
    ),
    LessonStep(
      id: 'm2_l3_s07',
      type: LessonStepType.summary,
      title: 'Why Does It Work?',
      bodyText:
          'Remember:\n**3(x + 2)** really means **3 groups of (x + 2)**.\n\nThe distributive property is simply a faster way of counting everything in those groups.\n\nYou learned:\n• Distribute the outside multiplier to every term inside\n• a(b + c) = ab + ac\n• Watch the signs when distributing negatives: a(b − c) = ab − ac\n• Distribution unlocks parentheses for simplifying',
      mathExpression: 'a(b + c) = ab + ac',
      mathAnnotation: 'The Distributive Property Shortcut',
      xyDialogue:
          'So it\'s not just a rule to memorize. It\'s a shortcut for something we already understand!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Finish Lesson',
    ),
  ],
);
