import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m1Lesson6 = LessonContent(
  lessonId: 'm1_l6',
  title: 'Order of Operations',
  moduleId: 'module1',
  moduleTitle: 'Algebra Foundations',
  objective: 'Apply the correct order of operations (PEMDAS/BODMAS).',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm1_l6_s01',
      type: LessonStepType.intro,
      title: 'Order of Operations',
      bodyText: 'A shared path to one clear answer',
      xyDialogue:
          'When a calculation has several operations, mathematicians follow one shared order so everyone gets the same answer.',
      xyAsset: AppAssets.xyExplaining,
      buttonLabel: 'Learn the order',
    ),
    LessonStep(
      id: 'm1_l6_s02',
      type: LessonStepType.content,
      title: 'Why Order Matters',
      bodyText:
          'Doing operations in different orders can produce **completely different results**.\n\nThe agreed **Order of Operations** removes all confusion and guarantees one true answer!',
      mathExpression: '2 + 3 × 4',
      mathAnnotation:
          'Adding first gives 20, but multiplying first gives the agreed answer: 14.',
      xyDialogue:
          'Without standard rules, one math problem could have *multiple conflicting answers*!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm1_l6_s03',
      type: LessonStepType.quiz,
      title: 'What Comes First?',
      question: 'Which operation should you do first in 6 + 4 × 3?',
      choices: [
        ChoiceOption(label: '6 + 4'),
        ChoiceOption(label: '4 × 3', isCorrect: true),
        ChoiceOption(label: '6 × 3'),
        ChoiceOption(label: 'Any operation'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation: 'Correct! Multiplication comes before addition.',
      incorrectExplanation:
          'Use the order of operations: multiplication is completed before addition.',
    ),
    LessonStep(
      id: 'm1_l6_s04',
      type: LessonStepType.content,
      title: 'The PEMDAS Rule',
      bodyText:
          'Remember the order of operations using **PEMDAS**:\n\n• 🟣 **P** — **Parentheses** `( )` first\n• 🌸 **E** — **Exponents** `x²` next\n• 🩵 **M / D** — **Multiply & Divide** (left to right)\n• 🟡 **A / S** — **Add & Subtract** (left to right)',
      mathExpression: 'P  →  E  →  M/D  →  A/S',
      mathAnnotation:
          'Multiplication & division share equal rank—work left to right!',
      xyDialogue:
          'Think: *Please Excuse My Dear Aunt Sally*!',
      xyAsset: AppAssets.xyExplaining,
    ),
    LessonStep(
      id: 'm1_l6_s05',
      type: LessonStepType.content,
      title: 'Work It Step by Step',
      bodyText:
          'Let\'s follow the rule for **8 + 2 × 5**:\n\n1. ⚡ **Multiply first**: `2 × 5 = 10`\n2. ➕ **Then add**: `8 + 10 = 18`',
      mathExpression: '8 + 2 × 5  →  8 + 10  →  18',
      mathAnnotation: 'Multiplication takes priority before addition!',
      xyDialogue:
          'Always scan for the *highest-priority operation* first before adding!',
      xyAsset: AppAssets.xyPointing,
    ),
    LessonStep(
      id: 'm1_l6_s06',
      type: LessonStepType.content,
      title: 'Parentheses Change Everything!',
      bodyText:
          'Parentheses **( )** tell us to jump ahead and complete the grouped operation first!\n\n• Without: `2 + 3 × 4 = 14`\n• With `( )`: `(2 + 3) × 4 = 20`',
      mathExpression: '2 + 3 × 4 = 14   •   (2 + 3) × 4 = 20',
      mathAnnotation:
          'The same numbers and operations give different results when parentheses change the order.',
      xyDialogue:
          'Parentheses are like a *VIP fast pass* in the operation line!',
      xyAsset: AppAssets.xyHappy,
    ),
    LessonStep(
      id: 'm1_l6_s07',
      type: LessonStepType.activity,
      title: 'Put the Steps in Order',
      question: 'Arrange the solution steps for 3 + 2 × 5.',
      isAnswerStep: true,
      activity: OrderingActivityData(
        items: [
          OrderingItem(id: 'answer', label: '13'),
          OrderingItem(id: 'add', label: '3 + 10'),
          OrderingItem(id: 'multiply', label: '2 × 5'),
        ],
        correctOrderIds: ['multiply', 'add', 'answer'],
      ),
      explanation: 'Identify and complete multiplication first, then add.',
      incorrectExplanation:
          'Start by finding the highest-priority operation, then calculate from there.',
    ),
    LessonStep(
      id: 'm1_l6_s08',
      type: LessonStepType.quiz,
      title: 'Quick Check',
      question: 'What is 5 + 3 × 2?',
      choices: [
        ChoiceOption(label: '16'),
        ChoiceOption(label: '11', isCorrect: true),
        ChoiceOption(label: '13'),
        ChoiceOption(label: '10'),
      ],
      correctChoiceIndex: 1,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation: 'Correct! Multiply 3 × 2 = 6, then add 5 to get 11.',
      incorrectExplanation: 'Complete multiplication before addition.',
    ),
    LessonStep(
      id: 'm1_l6_s09',
      type: LessonStepType.quiz,
      title: 'Order Challenge',
      question: 'What is (4 + 2) × 3 − 5?',
      choices: [
        ChoiceOption(label: '13', isCorrect: true),
        ChoiceOption(label: '15'),
        ChoiceOption(label: '9'),
        ChoiceOption(label: '25'),
      ],
      correctChoiceIndex: 0,
      isAnswerStep: true,
      xyAsset: AppAssets.xyHappy,
      explanation:
          'Exactly! Parentheses first: 4 + 2 = 6. Then 6 × 3 = 18, and 18 − 5 = 13.',
      incorrectExplanation:
          'Work through parentheses, multiplication, and subtraction in that order.',
    ),
    LessonStep(
      id: 'm1_l6_s10',
      type: LessonStepType.summary,
      title: 'Order of Operations Complete!',
      xyDialogue:
          'Amazing! You now have a *reliable path* through calculations with several operations.',
      xyAsset: AppAssets.xyHappy,
      bodyText:
          'You learned:\n• Parentheses come first\n• Exponents follow\n• Multiply and divide left to right\n• Add and subtract left to right\n• A shared order keeps answers consistent',
    ),
  ],
);
