import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/models/lesson_content_model.dart';

/// 5.8 — Line Lab
///
/// The sandbox. No timer, no score, no wrong answers — just m, b and a live
/// line. Each step is a discovery prompt that is met the moment the line
/// matches, so the learner cannot fail, only keep adjusting.
final m5Lesson8 = LessonContent(
  lessonId: 'm5_l8',
  title: 'Line Lab',
  moduleId: 'module5',
  moduleTitle: 'Linear Relationships',
  objective:
      'Discover what m and b do by moving them and watching the line answer.',
  xyAsset: AppAssets.xyIdea,
  steps: [
    LessonStep(
      id: 'm5_l8_s01',
      type: LessonStepType.intro,
      title: 'Welcome to the Line Lab',
      bodyText: 'Nothing to get wrong here.',
      xyDialogue:
          'Two sliders, one line. Drag **m** and **b** and watch what happens. '
          'There is no score in this room — just things to notice.',
      xyAsset: AppAssets.xyLessons,
      buttonLabel: 'Open the lab',
    ),
    LessonStep(
      id: 'm5_l8_s02',
      type: LessonStepType.content,
      title: 'The Two Dials',
      bodyText:
          'Every line in this lab is **y = mx + b**.\n\n'
          '• **m** is the slope — how steeply the line climbs or falls\n'
          '• **b** is the y-intercept — where it crosses the vertical axis\n\n'
          'Change one and watch which part of the line reacts.',
      mathExpression: 'y = mx + b',
      mathAnnotation: 'Two numbers. That is the whole language of a line.',
    ),
    LessonStep(
      id: 'm5_l8_s03',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Make It Steeper',
      xyDialogue:
          'Push the slope up to **3** and watch the line lean in as you go.',
      activity: const LineLabActivityData(
        goal: 'Can you make the line climb 3 for every 1 across?',
        hint: 'Slide m from 1 to 2 to 3 slowly — notice it tilt each time.',
        targetSlope: 3,
        startSlope: 1,
        startIntercept: 0,
      ),
      explanation:
          'A bigger **m** means a steeper climb. The line still passes through '
          'the same intercept — only the tilt changed.',
      incorrectExplanation: 'Keep sliding m upward until it reads 3.',
    ),
    LessonStep(
      id: 'm5_l8_s04',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Make It Flat',
      xyDialogue:
          'Now take the slope all the way down to zero. What does a line with '
          'no tilt look like?',
      activity: const LineLabActivityData(
        goal: 'Can you make the line horizontal?',
        hint: 'A flat line means y never changes. What slope does that need?',
        targetSlope: 0,
        startSlope: 3,
        startIntercept: 2,
      ),
      explanation:
          'A slope of **0** means no rise at all, so y stays put no matter how '
          'far x travels. The equation collapses to **y = b**.',
      incorrectExplanation:
          'Rise over run with zero rise. Try sliding m all the way to 0.',
    ),
    LessonStep(
      id: 'm5_l8_s05',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Make It Fall',
      xyDialogue: 'Keep going past zero. What happens on the other side?',
      activity: const LineLabActivityData(
        goal: 'Can you make the line fall from left to right?',
        hint: 'Try any value below zero.',
        targetSlope: -2,
        startSlope: 0,
        startIntercept: 1,
      ),
      explanation:
          'Below zero the line **falls**: as x grows, y drops. Rising, flat and '
          'falling are one dial, not three ideas.',
      incorrectExplanation: 'Slide m past 0 into the negatives.',
    ),
    LessonStep(
      id: 'm5_l8_s06',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Move Without Tilting',
      xyDialogue:
          'Leave the slope alone this time and slide **b** up to 4. Watch the '
          'whole line shift while its tilt stays exactly the same.',
      activity: const LineLabActivityData(
        goal: 'Can you make the line cross the y-axis at 4?',
        hint: 'Only b moves the crossing point.',
        targetIntercept: 4,
        startSlope: 1,
        startIntercept: 0,
      ),
      explanation:
          'Changing **b** slides the whole line up or down without touching its '
          'steepness — which is why b is the *starting amount* in a story.',
      incorrectExplanation:
          'The purple dot marks where the line crosses. Slide b until it sits at 4.',
    ),
    LessonStep(
      id: 'm5_l8_s07',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Both at Once',
      xyDialogue: 'Now build **y = −x + 3** from scratch.',
      activity: const LineLabActivityData(
        goal: 'Can you build a line that falls by 1 and crosses at 3?',
        hint: 'Set the slope first, then the intercept.',
        targetSlope: -1,
        targetIntercept: 3,
        startSlope: 2,
        startIntercept: -2,
      ),
      explanation:
          'Slope **−1** and intercept **3** give **y = −x + 3**. Two dials, and '
          'any line you like.',
      incorrectExplanation:
          'Falling by 1 means m is −1. Crossing at 3 means b is 3.',
    ),
    LessonStep(
      id: 'm5_l8_s08',
      type: LessonStepType.activity,
      isAnswerStep: true,
      title: 'Free Play',
      xyDialogue:
          'Last one, and it is yours. Try making two different equations with '
          'the same slope, and notice they never meet.',
      activity: const LineLabActivityData(
        goal: 'Explore freely — there is no target here.',
        hint:
            'Try: the steepest line you can make, then the same slope moved to '
            'a different intercept.',
      ),
      explanation:
          'Same **m** and different **b** gives parallel lines — same tilt, '
          'different starting point.',
      incorrectExplanation: 'Take your time. Nothing here can be wrong.',
    ),
    LessonStep(
      id: 'm5_l8_s09',
      type: LessonStepType.summary,
      title: 'Module Complete',
      bodyText:
          '**m** tilts the line. **b** slides it. Together they describe every '
          'straight line there is.',
      xyDialogue:
          'You did not get told what m and b do — you watched them do it. '
          'Ready for the module quiz?',
      xyAsset: AppAssets.xyHappy,
      buttonLabel: 'Complete 5.8',
    ),
  ],
);
