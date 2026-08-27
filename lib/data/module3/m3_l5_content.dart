import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

const m3Lesson5 = LessonContent(
  lessonId: 'm3_l5',
  title: 'Variables on Both Sides',
  moduleId: 'module3',
  moduleTitle: 'Solving Equations',
  objective:
      'Collect variable terms onto one side of the equation and constant terms on the other to solve equations with variables on both sides.',
  xyAsset: AppAssets.xyExplaining,
  steps: [
    LessonStep(
      id: 'm3_l5_s01',
      type: LessonStepType.intro,
      title: 'x Is Everywhere!',
      bodyText: 'Variables on Both Sides',
      xyDialogue:
          'What about 5x + 2 = 3x + 10? There\'s an x on both sides! Don\'t panic—our goal hasn\'t changed: find a value that makes both sides equal.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Bring Terms Together →',
    ),
    LessonStep(
      id: 'm3_l5_s02',
      type: LessonStepType.content,
      title: 'Bring Like Terms Together',
      bodyText:
          'Start with:\n\n**5x + 2 = 3x + 10**\n\nWe want all variable terms on one side. **Subtract 3x from both sides**:\n\n**5x − 3x + 2 = 3x − 3x + 10**\n\nSimplify:\n\n**2x + 2 = 10**\n\nNow it looks like a familiar two-step equation!',
      mathExpression: '5x − 3x + 2 = 3x − 3x + 10   ⇒   2x + 2 = 10',
      mathAnnotation: 'Subtract 3x from both sides to collect x terms.',
    ),
    LessonStep(
      id: 'm3_l5_s03',
      type: LessonStepType.content,
      title: 'Finish Solving',
      bodyText:
          'We have:\n\n**2x + 2 = 10**\n\n1. Subtract 2 from both sides:\n**2x = 8**\n\n2. Divide both sides by 2:\n**x = 4**',
      mathExpression: '2x = 8   ⇒   x = 4',
      mathAnnotation: 'Isolate x in two easy steps.',
    ),
    LessonStep(
      id: 'm3_l5_s04',
      type: LessonStepType.content,
      title: 'Check the Relationship',
      bodyText:
          'Our original equation:\n\n**5x + 2 = 3x + 10**\n\nSubstitute **x = 4** into both sides:\n\n• **Left**: 5(4) + 2 = 20 + 2 = **22**\n• **Right**: 3(4) + 10 = 12 + 10 = **22**\n\n**22 = 22** ✅\n\nOur solution works perfectly!',
      mathExpression: '5(4) + 2 = 22   and   3(4) + 10 = 22',
      mathAnnotation: 'Both sides evaluate to 22!',
    ),
    LessonStep(
      id: 'm3_l5_s05',
      type: LessonStepType.content,
      title: 'Which Side?',
      bodyText:
          'Consider **2x + 8 = 5x − 1**.\n\nYou could subtract 2x from both sides:\n**8 = 3x − 1**\n\nOr subtract 5x from both sides:\n**−3x + 8 = −1**\n\n**Both are completely valid!** One may just keep coefficients positive.\n\nDifferent valid paths can lead to the same solution.',
      mathExpression: 'Path A: 8 = 3x − 1   |   Path B: −3x + 8 = −1',
      mathAnnotation: 'Multiple valid paths lead to the same solution!',
    ),
    LessonStep(
      id: 'm3_l5_s06',
      type: LessonStepType.summary,
      title: 'Your Turn',
      bodyText:
          'Solve **4x + 1 = 2x + 9**:\n\n1. Subtract 2x: **2x + 1 = 9**\n2. Subtract 1: **2x = 8**\n3. Divide by 2: **x = 4** 🎉\n\nYou mastered collecting like terms across the equals sign!',
      mathExpression: '4x + 1 = 2x + 9   ⇒   2x = 8   ⇒   x = 4',
      mathAnnotation: 'Group variables, group constants, solve!',
      xyDialogue:
          'Move variable terms to one side and constants to the other. You\'ve got this!',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 3.5',
    ),
  ],
);
