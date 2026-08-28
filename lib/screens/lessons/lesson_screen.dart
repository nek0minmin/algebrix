import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/widgets/lesson/lesson_progress_bar.dart';
import 'package:algebrix/widgets/lesson/xy_speech_bubble.dart';
import 'package:algebrix/widgets/lesson/content_card.dart';
import 'package:algebrix/widgets/lesson/math_highlight_box.dart';
import 'package:algebrix/widgets/lesson/interactive_choice_grid.dart';
import 'package:algebrix/widgets/lesson/lesson_nav_buttons.dart';
import 'package:algebrix/widgets/lesson/xp_reward_animation.dart';
import 'package:algebrix/screens/lessons/lesson_complete_screen.dart';
import 'package:algebrix/widgets/lesson/activities/classification_activity.dart';
import 'package:algebrix/widgets/lesson/activities/ordering_activity.dart';
import 'package:algebrix/widgets/lesson/activities/term_selection_activity.dart';
import 'package:algebrix/widgets/xy_mascot.dart';
import 'package:algebrix/widgets/page_headers.dart';

/// Main Lesson Viewer — the core interactive learning experience.
///
/// Renders lesson steps as a PageView, with each step type showing the
/// appropriate widget (intro, content, xySays, interactive, quiz, summary).
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _showXpReward = false;
  int _xpAmount = 0;
  bool? _lastAnswerCorrect;

  Future<void> _handleAnswer(int index, bool isCorrect) async {
    final lessonProvider = context.read<LessonProvider>();
    if (lessonProvider.isRecording) return;
    if (!isCorrect) {
      setState(() => _lastAnswerCorrect = false);
      await lessonProvider.answerQuestion(false);
      return;
    }

    final xpAwarded = await lessonProvider.answerQuestion(true);
    if (!mounted) return;
    if (xpAwarded == null) {
      setState(() => _lastAnswerCorrect = null);
      _showProgressError(lessonProvider);
      return;
    }

    setState(() {
      _lastAnswerCorrect = true;
      _showXpReward = false; // XP pop-up disabled
      _xpAmount = 0;
    });
  }

  Future<void> _handleNext() async {
    final lessonProvider = context.read<LessonProvider>();

    if (lessonProvider.isLastStep) {
      final completed = await lessonProvider.completeLesson();
      if (!mounted) return;
      if (!completed) {
        _showProgressError(lessonProvider);
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LessonCompleteScreen()),
      );
    } else {
      final saved = await lessonProvider.nextStep();
      if (!mounted) return;
      if (saved) {
        setState(() => _lastAnswerCorrect = null);
      } else {
        _showProgressError(lessonProvider);
      }
    }
  }

  Future<void> _handleBack() async {
    final lessonProvider = context.read<LessonProvider>();
    if (lessonProvider.isFirstStep) {
      Navigator.of(context).pop();
    } else {
      final saved = await lessonProvider.prevStep();
      if (!mounted) return;
      if (saved) {
        setState(() => _lastAnswerCorrect = null);
      } else {
        _showProgressError(lessonProvider);
      }
    }
  }

  void _showProgressError(LessonProvider provider) {
    final message = provider.errorMessage;
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$message Try again.'),
          backgroundColor: AppColors.error,
        ),
      );
  }

  bool _canProceed(LessonStep step, bool isAnswered) {
    if (step.type == LessonStepType.interactive ||
        step.type == LessonStepType.quiz ||
        step.type == LessonStepType.activity) {
      return isAnswered;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final lessonProvider = context.watch<LessonProvider>();
    final lesson = lessonProvider.currentLesson;
    final step = lessonProvider.currentStep;

    if (lesson == null || step == null) {
      return const Scaffold(body: Center(child: Text('No lesson loaded.')));
    }

    final moduleTitle = lessonProvider.currentModule?.title ?? 'Lesson';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AlgebrixAppBar(
        title: lesson.title,
        subtitle: moduleTitle,
        onBack: () => _showExitDialog(context),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LessonProgressBar(
                  currentStep: lessonProvider.currentStepIndex + 1,
                  totalSteps: lesson.totalSteps,
                ),
              ),
              const SizedBox(height: 8),

              // Step content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: SingleChildScrollView(
                    key: ValueKey(step.id),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: _buildStepContent(
                      step,
                      lessonProvider.currentStepAnswered,
                    ),
                  ),
                ),
              ),

              // Navigation buttons
              if (lessonProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${lessonProvider.errorMessage} Try again.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: LessonNavButtons(
                  onBack: lessonProvider.isBusy ? null : _handleBack,
                  onNext: _handleNext,
                  showBack: !lessonProvider.isFirstStep,
                  isNextEnabled:
                      _canProceed(step, lessonProvider.currentStepAnswered) &&
                      !lessonProvider.isBusy,
                  isLoading:
                      lessonProvider.isRecording || lessonProvider.isCompleting,
                  nextLabel:
                      step.buttonLabel ??
                      (lessonProvider.isLastStep
                          ? 'Complete Lesson 🎉'
                          : 'Continue'),
                ),
              ),
            ],
          ),

          // XP reward overlay
          if (_showXpReward)
            Positioned.fill(
              child: Center(
                child: XpRewardAnimation(
                  xpAmount: _xpAmount,
                  onComplete: () {
                    setState(() => _showXpReward = false);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(LessonStep step, bool isAnswered) {
    switch (step.type) {
      case LessonStepType.intro:
        return _buildIntroStep(step);
      case LessonStepType.content:
        return _buildContentStep(step);
      case LessonStepType.xySays:
        return _buildXySaysStep(step);
      case LessonStepType.interactive:
        return _buildInteractiveStep(step, isAnswered);
      case LessonStepType.quiz:
        return _buildQuizStep(step, isAnswered);
      case LessonStepType.summary:
        return _buildSummaryStep(step);
      case LessonStepType.activity:
        return _buildActivityStep(step, isAnswered);
    }
  }

  /// Intro step — dedicated grand topic entrance for Lesson 1.
  Widget _buildIntroStep(LessonStep step) {
    if (step.id == 'step1') return _LessonIntroEntrance(step: step);
    return _ModuleLessonIntro(step: step);
  }

  /// Content step — educational explanation with optional math highlight and mascot tip.
  Widget _buildContentStep(LessonStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step.title != null)
          ContentCard(
            title: step.title,
            body: step.bodyText,
            bulletPoints: step.bulletPoints,
            xyAsset: step.xyDialogue == null ? step.xyAsset : null,
          ),
        if (step.mathExpression != null) ...[
          const SizedBox(height: 16),
          MathHighlightBox(
            expression: step.mathExpression!,
            annotation: step.mathAnnotation,
          ),
        ],
        if (step.xyDialogue != null) ...[
          const SizedBox(height: 16),
          XySpeechBubble(
            message: step.xyDialogue!,
            xyAsset: AppAssets.xyInsight,
          ),
        ],
      ],
    );
  }

  /// Xy Says step — full-width mascot speech bubble with tip.
  Widget _buildXySaysStep(LessonStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Center(
          child: XyMascot(
            asset: AppAssets.xyExplaining,
            size: 140,
            shadowBlur: 6.0,
            shadowOpacity: 0.22,
          ),
        ),
        const SizedBox(height: 24),
        if (step.xyDialogue != null)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.extraLightPink,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.pink.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'XY’S INSIGHT',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColors.pink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  step.xyDialogue!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.text,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Interactive step — question with choice grid, bold centered title, and Xy Question mascot.
  Widget _buildInteractiveStep(LessonStep step, bool isAnswered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step.xyDialogue != null) ...[
          XySpeechBubble(
            message: step.xyDialogue!,
            xyAsset: AppAssets.xyInsight,
            xySize: 64,
          ),
          const SizedBox(height: 16),
        ] else ...[
          Center(
            child: XyMascot(
              asset: AppAssets.xyQuestion,
              size: 120,
              shadowBlur: 5.0,
              shadowOpacity: 0.22,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (step.title != null) ...[
          Text(
            step.title!,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (step.question != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildQuestionText(step.question!, fontSize: 18),
          ),
        const SizedBox(height: 20),
        if (step.choices != null)
          InteractiveChoiceGrid(
            choices: step.choices!,
            isAnswered: isAnswered,
            isEnabled: !context.watch<LessonProvider>().isRecording,
            onAnswered: _handleAnswer,
          ),
        if (_lastAnswerCorrect != null) _buildAnswerFeedback(step),
      ],
    );
  }

  /// Quiz step — structured quiz question with feedback and Xy Question mascot.
  Widget _buildQuizStep(LessonStep step, bool isAnswered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: XyMascot(
            asset: AppAssets.xyQuestion,
            size: 120,
            shadowBlur: 5.0,
            shadowOpacity: 0.22,
          ),
        ),
        const SizedBox(height: 14),

        // Quiz badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.quiz_rounded,
                  size: 18,
                  color: AppColors.purple,
                ),
                const SizedBox(width: 8),
                Text(
                  step.title ?? 'Quick Check',
                  style: AppTextStyles.subtitle2.copyWith(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (step.question != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: _buildQuestionText(step.question!, fontSize: 19),
          ),
        const SizedBox(height: 20),

        if (step.choices != null)
          InteractiveChoiceGrid(
            choices: step.choices!,
            isAnswered: isAnswered,
            isEnabled: !context.watch<LessonProvider>().isRecording,
            onAnswered: _handleAnswer,
          ),

        if (_lastAnswerCorrect != null) _buildAnswerFeedback(step),
      ],
    );
  }

  Widget _buildActivityStep(LessonStep step, bool isAnswered) {
    final activity = step.activity;
    final lessonProvider = context.watch<LessonProvider>();
    final enabled = !isAnswered && !lessonProvider.isRecording;

    Widget activityWidget;
    if (activity is ClassificationActivityData) {
      activityWidget = ClassificationActivity(
        key: ValueKey(step.id),
        data: activity,
        enabled: enabled,
        onAnswered: (isCorrect) => _handleAnswer(0, isCorrect),
      );
    } else if (activity is TermSelectionActivityData) {
      activityWidget = TermSelectionActivity(
        key: ValueKey(step.id),
        data: activity,
        enabled: enabled,
        onAnswered: (isCorrect) => _handleAnswer(0, isCorrect),
      );
    } else if (activity is OrderingActivityData) {
      activityWidget = OrderingActivity(
        key: ValueKey(step.id),
        data: activity,
        enabled: enabled,
        onAnswered: (isCorrect) => _handleAnswer(0, isCorrect),
      );
    } else {
      activityWidget = Text(
        'This activity is not available yet.',
        style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step.xyDialogue != null) ...[
          XySpeechBubble(
            message: step.xyDialogue!,
            xyAsset: AppAssets.xyInsight,
            xySize: 64,
          ),
          const SizedBox(height: 16),
        ] else ...[
          Center(
            child: XyMascot(
              asset: AppAssets.xyQuestion,
              size: 120,
              shadowBlur: 5.0,
              shadowOpacity: 0.22,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (step.title != null) ...[
          Text(
            step.title!,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (step.question != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildQuestionText(step.question!, fontSize: 17),
          ),
          const SizedBox(height: 20),
        ],
        activityWidget,
        if (_lastAnswerCorrect != null) _buildAnswerFeedback(step),
      ],
    );
  }

  Widget _buildAnswerFeedback(LessonStep step) {
    final isCorrect = _lastAnswerCorrect == true;
    final message = isCorrect
        ? step.explanation
        : step.incorrectExplanation ??
              'Not quite. Review what the variable represents and try the next example carefully.';

    if (message == null) return const SizedBox.shrink();

    final backgroundColor = isCorrect
        ? AppColors.lightMint
        : const Color(0xFFFFF1F2);
    final accentColor = isCorrect ? AppColors.mint : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCorrect ? Icons.check_circle_rounded : Icons.refresh_rounded,
              color: accentColor,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'That works!' : 'Try a different idea',
                    style: AppTextStyles.subtitle2.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.text,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Summary step — lesson completion review.
  Widget _buildSummaryStep(LessonStep step) {
    final rawTitle = step.title ?? 'Lesson Complete!';
    final cleanTitle = rawTitle
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '')
        .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          cleanTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: XyMascot(
            asset: AppAssets.xyGo,
            size: 136,
            shadowBlur: 8.0,
            shadowOpacity: 0.22,
          ),
        ),
        const SizedBox(height: 18),
        if (step.xyDialogue != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              step.xyDialogue!,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.text,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (step.bodyText != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.mint.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mint.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.lightMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.mint,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'KEY TAKEAWAYS',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mint,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                EmphasizedText(
                  step.bodyText!,
                  baseStyle: AppTextStyles.body1.copyWith(
                    color: AppColors.text,
                    height: 1.65,
                  ),
                  highlightStyle: AppTextStyles.body1.copyWith(
                    color: AppColors.pink,
                    fontWeight: FontWeight.w800,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (step.mathExpression != null) ...[
          const SizedBox(height: 16),
          MathHighlightBox(
            expression: step.mathExpression!,
            annotation: step.mathAnnotation,
            accentColor: AppColors.mint,
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionText(String questionText, {double fontSize = 18}) {
    final spans = <InlineSpan>[];
    final regex = RegExp(
      r'([\×\*]|\b[+\−\-\÷\=]\b|[+\−\-\÷\=]|\n+|[^\s\×\*\+\−\-\÷\=]+|\s+)',
    );
    final matches = regex.allMatches(questionText);

    if (matches.isEmpty) {
      return Text(
        questionText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
          height: 1.45,
        ),
      );
    }

    var lastEnd = 0;
    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(
          TextSpan(
            text: questionText.substring(lastEnd, m.start),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              height: 1.45,
            ),
          ),
        );
      }

      final token = m.group(0)!;
      if (token == '×' || token == '*') {
        // Distinct pink and slightly smaller multiplication symbol so it NEVER gets confused with variable x!
        spans.add(
          TextSpan(
            text: ' × ',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize * 0.85,
              fontWeight: FontWeight.w900,
              color: AppColors.pink,
              height: 1.45,
            ),
          ),
        );
      } else if (token == '+' ||
          token == '−' ||
          token == '-' ||
          token == '÷' ||
          token == '=') {
        spans.add(
          TextSpan(
            text: ' $token ',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.purple,
              height: 1.45,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              height: 1.45,
            ),
          ),
        );
      }
      lastEnd = m.end;
    }

    if (lastEnd < questionText.length) {
      spans.add(
        TextSpan(
          text: questionText.substring(lastEnd),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
            height: 1.45,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Leave Lesson?',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Your progress in this lesson will not be saved.',
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Stay',
              style: AppTextStyles.button.copyWith(color: AppColors.pink),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Leave',
              style: AppTextStyles.button.copyWith(color: AppColors.subtitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleLessonIntro extends StatelessWidget {
  const _ModuleLessonIntro({required this.step});

  final LessonStep step;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.watch<LessonProvider>().currentLesson?.moduleTitle.toUpperCase() ?? 'ALGEBRA',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step.title ?? 'Explore the why',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.pink,
                fontSize: compact ? 28 : 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (step.bodyText != null) ...[
              const SizedBox(height: 8),
              Text(
                step.bodyText!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              height: compact ? 170 : 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.extraLightPink,
                    AppColors.lightPurple.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.pink.withValues(alpha: 0.12),
                ),
              ),
              child: XyMascot(
                asset: step.xyAsset ?? AppAssets.xyLessons,
                size: compact ? 135 : 160,
                shadowBlur: 6.0,
                shadowOpacity: 0.25,
              ),
            ),
            if (step.xyDialogue != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  step.xyDialogue!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.text,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LessonIntroEntrance extends StatefulWidget {
  final LessonStep step;

  const _LessonIntroEntrance({required this.step});

  @override
  State<_LessonIntroEntrance> createState() => _LessonIntroEntranceState();
}

class _LessonIntroEntranceState extends State<_LessonIntroEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _headingOpacity;
  late final Animation<Offset> _headingOffset;
  late final Animation<double> _heroOpacity;
  late final Animation<Offset> _heroOffset;
  late final Animation<double> _clueOpacity;
  late final Animation<Offset> _clueOffset;
  bool _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _headingOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.42, curve: Curves.easeOut),
    );
    _headingOffset =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.42, curve: Curves.easeOutCubic),
          ),
        );
    _heroOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.72, curve: Curves.easeOut),
    );
    _heroOffset = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.18, 0.72, curve: Curves.easeOutCubic),
          ),
        );
    _clueOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1, curve: Curves.easeOut),
    );
    _clueOffset = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (animationsDisabled || isTest) {
      _controller.value = 1;
      _entranceStarted = true;
    } else if (!_entranceStarted) {
      _entranceStarted = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final heroHeight = compact ? 180.0 : 210.0;
        final mascotSize = compact ? 138.0 : 164.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeTransition(
              opacity: _headingOpacity,
              child: SlideTransition(
                position: _headingOffset,
                child: Column(
                  children: [
                    Text(
                      'LESSON 1 · ALGEBRA FOUNDATIONS',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Variables',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.pink,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Letters that can hold a mystery value.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _heroOpacity,
              child: SlideTransition(
                position: _heroOffset,
                child: Container(
                  key: const ValueKey('variables-intro-hero'),
                  height: heroHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.extraLightPink,
                        AppColors.lightPurple.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.pink.withValues(alpha: 0.12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: XyMascot(
                    asset: AppAssets.xyLessons,
                    imageKey: const ValueKey('variables-intro-xy'),
                    size: mascotSize,
                    shadowBlur: 6.0,
                    shadowOpacity: 0.25,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _clueOpacity,
              child: SlideTransition(
                position: _clueOffset,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.extraLightPink,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.pink.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'XY’S CLUE',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.pink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _IntroClueText(
                        widget.step.xyDialogue ??
                            'A variable is like a **mystery box**. Its **value can change**.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IntroClueText extends StatelessWidget {
  final String text;

  const _IntroClueText(this.text);

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    return Text.rich(
      TextSpan(
        children: [
          for (var index = 0; index < parts.length; index++)
            TextSpan(
              text: parts[index],
              style: AppTextStyles.body1.copyWith(
                color: index.isOdd ? AppColors.pink : AppColors.text,
                fontWeight: index.isOdd ? FontWeight.w800 : FontWeight.w400,
                height: 1.55,
              ),
            ),
        ],
      ),
    );
  }
}
