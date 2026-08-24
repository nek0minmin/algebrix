import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/quiz_provider.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/module_quiz_model.dart';
import 'package:algebrix/services/module_quiz_service.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/xy_mascot.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// Interactive AI-Powered 15-Question Module Quiz with progressive difficulty and mascot feedback.
class ModuleQuizScreen extends StatefulWidget {
  final ModuleContent module;
  final ModuleQuizService? quizService;

  const ModuleQuizScreen({
    super.key,
    required this.module,
    this.quizService,
  });

  @override
  State<ModuleQuizScreen> createState() => _ModuleQuizScreenState();
}

class _ModuleQuizScreenState extends State<ModuleQuizScreen> {
  late final ModuleQuizService _quizService;

  bool _isLoading = true;
  String? _errorMessage;
  ModuleQuiz? _quiz;

  int _currentIndex = 0;
  int? _selectedChoiceIndex;
  bool _isAnswered = false;
  int _correctCount = 0;
  final List<bool> _answerHistory = [];

  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _quizService = widget.quizService ?? ModuleQuizService();
    _loadQuiz();
  }

  bool _isCountingDown = false;
  int _countdownStep = 3;

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _isCountingDown = false;
      _errorMessage = null;
      _currentIndex = 0;
      _selectedChoiceIndex = null;
      _isAnswered = false;
      _correctCount = 0;
      _answerHistory.clear();
      _isFinished = false;
    });

    try {
      final quiz = await _quizService.generateQuiz(module: widget.module);
      if (!mounted) return;
      await _startCountdown(quiz);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not generate quiz: $e';
        _isLoading = false;
        _isCountingDown = false;
      });
    }
  }

  Future<void> _startCountdown(ModuleQuiz quiz) async {
    final isTesting =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTesting) {
      setState(() {
        _quiz = quiz;
        _isLoading = false;
        _isCountingDown = false;
      });
      return;
    }

    setState(() {
      _quiz = quiz;
      _isLoading = false;
      _isCountingDown = true;
      _countdownStep = 3;
    });

    for (int step = 2; step >= 0; step--) {
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() {
        _countdownStep = step;
      });
    }

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _isCountingDown = false;
    });
  }

  void _handleSelectOption(int index) {
    if (_isAnswered || _quiz == null) return;
    setState(() {
      _selectedChoiceIndex = index;
    });
  }

  void _handleConfirmAnswer() {
    if (_isAnswered || _selectedChoiceIndex == null || _quiz == null) return;

    final currentQ = _quiz!.questions[_currentIndex];
    final isCorrect = _selectedChoiceIndex == currentQ.correctIndex;

    setState(() {
      _isAnswered = true;
      if (isCorrect) {
        _correctCount++;
      }
      _answerHistory.add(isCorrect);
    });
  }

  void _handleNextQuestion() {
    if (_quiz == null) return;

    if (_currentIndex + 1 < _quiz!.questions.length) {
      setState(() {
        _currentIndex++;
        _selectedChoiceIndex = null;
        _isAnswered = false;
      });
    } else {
      setState(() {
        _isFinished = true;
      });
      final total = _quiz?.questions.length ?? 10;
      try {
        context.read<QuizProvider>().recordQuizResult(
          moduleId: widget.module.id,
          score: _correctCount,
          totalQuestions: total,
        );
      } catch (_) {}
    }
  }

  int get _starRating {
    final total = _quiz?.questions.length ?? 10;
    final percent = total > 0 ? (_correctCount / total) * 100 : 0;
    if (percent >= 80) return 3;
    if (percent >= 60) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.module.title} Quiz',
          style: GoogleFonts.nunito(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingScreen()
            : _isCountingDown
                ? _buildCountdownScreen()
                : _errorMessage != null
                    ? _buildErrorScreen()
                    : _isFinished
                        ? _buildVictoryScreen()
                        : _buildQuizActiveScreen(),
      ),
    );
  }

  // ── 1. Dedicated Xy Mascot Countdown Screen (3-2-1-GO!) ─────────────────────
  Widget _buildCountdownScreen() {
    String mascotAsset;
    String countLabel;
    String countSubtitle;
    Color countColor;

    switch (_countdownStep) {
      case 3:
        mascotAsset = AppAssets.xyThree;
        countLabel = '3';
        countSubtitle = 'Get ready!';
        countColor = AppColors.pink;
        break;
      case 2:
        mascotAsset = AppAssets.xyTwo;
        countLabel = '2';
        countSubtitle = 'Get set!';
        countColor = AppColors.purple;
        break;
      case 1:
        mascotAsset = AppAssets.xyOne;
        countLabel = '1';
        countSubtitle = 'Focus!';
        countColor = AppColors.mint;
        break;
      default:
        mascotAsset = AppAssets.xyGo;
        countLabel = 'GO!';
        countSubtitle = 'Good luck!';
        countColor = AppColors.pink;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              mascotAsset,
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              countLabel,
              style: GoogleFonts.nunito(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: countColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              countSubtitle,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Dedicated Xy Mascot Loading Screen ──────────────────────────────────
  Widget _buildLoadingScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.xyLoading,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 28),
            Text(
              'Xy is preparing a quiz for you...',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Synthesizing 10 progressive questions from ${widget.module.title}',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.pink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. Error Screen ────────────────────────────────────────────────────────
  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Could not load quiz',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Try again',
              onPressed: _loadQuiz,
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Active Quiz Question View ───────────────────────────────────────────
  Widget _buildQuizActiveScreen() {
    final quiz = _quiz!;
    final question = quiz.questions[_currentIndex];
    final total = quiz.questions.length;
    final progressFraction = (_currentIndex + 1) / total;

    final typeLabel = question.type == QuizQuestionType.multipleChoice
        ? 'MULTIPLE CHOICE'
        : 'TRUE OR FALSE';

    // Pick dynamic reaction mascot for Xy (Only ONE mascot per page)
    final isCorrect =
        _isAnswered && _selectedChoiceIndex == question.correctIndex;
    final mascotAsset = !_isAnswered
        ? AppAssets.xyQuestion
        : (isCorrect ? AppAssets.xyHappy : AppAssets.xyExplaining);

    return Column(
      children: [
        // ── Top Progress Row ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentIndex + 1} of $total',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.extraLightPink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question.subLessonTitle.toUpperCase(),
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.pink,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.pink),
                ),
              ),
            ],
          ),
        ),

        // ── Scrollable Body: Type Badge → Question Prompt → Big Mascot → Explanation → Choices ──
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),

                // 1. Question Type Badge (Centered)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF), // Soft purple badge
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    typeLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF7C3AED),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Question Prompt (Centered, Bold, Clear)
                _buildRichQuestionPrompt(question.question),
                const SizedBox(height: 16),

                // 3. ONE SINGLE BIG Mascot Picture (Centered, with contrast shadow)
                XyMascot(
                  key: ValueKey('mascot-$mascotAsset'),
                  asset: mascotAsset,
                  size: 155,
                  shadowBlur: 6.0,
                  shadowOpacity: 0.22,
                ),

                // 4. Insight / Mini Explanation (Centered directly below mascot when answered)
                if (_isAnswered) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      question.explanation,
                      style: GoogleFonts.nunito(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // 5. Answer Choices (Rounded Pills)
                for (var i = 0; i < question.options.length; i++) ...[
                  _buildOptionTile(
                    optionIndex: i,
                    label: question.options[i],
                    isCorrectChoice: i == question.correctIndex,
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // ── 6. Bottom Action Button (Confirm Answer / Next Question) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: !_isAnswered
              ? PrimaryButton(
                  label: 'Confirm Answer',
                  backgroundColor: AppColors.mint,
                  icon: Icons.check_rounded,
                  onPressed:
                      _selectedChoiceIndex != null ? _handleConfirmAnswer : null,
                )
              : PrimaryButton(
                  label: _currentIndex + 1 == total
                      ? 'Finish Quiz'
                      : 'Next Question',
                  icon: _currentIndex + 1 == total
                      ? Icons.check_circle_outline_rounded
                      : Icons.arrow_forward_rounded,
                  backgroundColor: AppColors.pink,
                  onPressed: _handleNextQuestion,
                ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required int optionIndex,
    required String label,
    required bool isCorrectChoice,
  }) {
    final isSelected = _selectedChoiceIndex == optionIndex;

    Color borderColor = AppColors.border;
    Color bgColor = Colors.white;
    Color textColor = AppColors.text;

    if (_isAnswered) {
      if (isCorrectChoice) {
        borderColor = AppColors.mint;
        bgColor = AppColors.lightMint.withValues(alpha: 0.6);
        textColor = const Color(0xFF0F7263);
      } else if (isSelected && !isCorrectChoice) {
        borderColor = AppColors.pink;
        bgColor = AppColors.extraLightPink;
        textColor = AppColors.darkPink;
      } else {
        borderColor = AppColors.border.withValues(alpha: 0.5);
        bgColor = Colors.white;
        textColor = AppColors.textSecondary.withValues(alpha: 0.6);
      }
    } else if (isSelected) {
      borderColor = AppColors.mint;
      bgColor = AppColors.lightMint.withValues(alpha: 0.4);
      textColor = const Color(0xFF0F7263);
    }

    return BouncyPressable(
      shrinkFactor: 0.97,
      enableHaptics: true,
      onTap: _isAnswered ? null : () => _handleSelectOption(optionIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: borderColor,
            width: (isSelected || (_isAnswered && isCorrectChoice)) ? 2 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected || (_isAnswered && isCorrectChoice))
                  ? borderColor.withValues(alpha: 0.15)
                  : AppColors.shadow.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _buildOptionLabel(
          label: label,
          isAnswered: _isAnswered,
          isCorrectChoice: isCorrectChoice,
          isSelected: isSelected,
          textColor: textColor,
        ),
      ),
    );
  }

  Widget _buildOptionLabel({
    required String label,
    required bool isAnswered,
    required bool isCorrectChoice,
    required bool isSelected,
    required Color textColor,
  }) {
    if (isAnswered && (isCorrectChoice || (isSelected && !isCorrectChoice))) {
      return Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      );
    }

    if (!_isAnswered && isSelected) {
      return Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      );
    }

    final spans = _parseMathSpans(label, fontSize: 16);
    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }

  // ── 4. Victory & Mastery Review Screen ─────────────────────────────────────
  Widget _buildVictoryScreen() {
    final total = _quiz?.questions.length ?? 10;
    final percent = total > 0 ? ((_correctCount / total) * 100).round() : 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mascot Hero (Clean, prominent, soft drop shadow)
          Center(
            child: XyMascot(
              asset: percent >= 60 ? AppAssets.xyHappy : AppAssets.xyDefault,
              size: 155,
              shadowBlur: 6.0,
              shadowOpacity: 0.22,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Quiz Completed!',
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.module.title} Mastery Check',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Score Summary Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isEarned = index < _starRating;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isEarned
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 38,
                        color: isEarned ? AppColors.yellow : AppColors.border,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Text(
                  '$_correctCount / $total',
                  style: GoogleFonts.nunito(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.pink,
                  ),
                ),
                Text(
                  '$percent% Accuracy',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Pass / Fail Requirement Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: percent >= 60
                        ? AppColors.lightMint
                        : AppColors.extraLightPink,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: percent >= 60
                          ? AppColors.mint.withValues(alpha: 0.5)
                          : AppColors.pink.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        percent >= 60
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        color: percent >= 60 ? AppColors.mint : AppColors.darkPink,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        percent >= 60
                            ? 'PASSED (≥60% Requirement Met)'
                            : 'NEEDS REVIEW (60% Required to Advance)',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: percent >= 60
                              ? const Color(0xFF0F7263)
                              : AppColors.darkPink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Review Section Header
          Text(
            'Question Review',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),

          // 15-Question Review List
          if (_quiz != null)
            for (var i = 0; i < _quiz!.questions.length; i++) ...[
              _buildReviewItem(
                index: i,
                question: _quiz!.questions[i],
                isCorrect: i < _answerHistory.length ? _answerHistory[i] : true,
              ),
              const SizedBox(height: 10),
            ],

          const SizedBox(height: 20),

          // Action Buttons
          PrimaryButton(
            label: 'Retake Quiz',
            icon: Icons.replay_rounded,
            onPressed: _loadQuiz,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Back to Lessons',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReviewItem({
    required int index,
    required ModuleQuizQuestion question,
    required bool isCorrect,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? AppColors.mint.withValues(alpha: 0.4)
              : AppColors.pink.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? AppColors.mint : AppColors.pink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Q${index + 1}: ${question.subLessonTitle}',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            question.question,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Answer: ${question.options[question.correctIndex]}',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F7263),
            ),
          ),
        ],
      ),
    );
  }

  static const Set<String> _englishWords = {
    'a', 'an', 'the', 'in', 'of', 'on', 'at', 'to', 'for', 'with', 'from', 'by', 'into',
    'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
    'do', 'does', 'did', 'can', 'could', 'should', 'would', 'may', 'might', 'must',
    'what', 'which', 'who', 'whom', 'whose', 'why', 'where', 'when', 'how',
    'this', 'that', 'these', 'those', 'there', 'here',
    'and', 'or', 'not', 'but', 'nor', 'so', 'yet',
    'if', 'then', 'else', 'because', 'as', 'until', 'while',
    'true', 'false', 'evaluate', 'simplify', 'expand', 'calculate', 'solve',
    'identify', 'find', 'count', 'select', 'choose', 'statement', 'question',
    'expression', 'expressions', 'equation', 'equations', 'term', 'terms',
    'variable', 'variables', 'constant', 'constants', 'coefficient', 'coefficients',
    'like', 'unlike', 'property', 'properties', 'operation', 'operations',
    'order', 'addition', 'subtraction', 'multiplication', 'division',
    'commutative', 'associative', 'distributive', 'identity', 'inverse', 'zero',
    'first', 'second', 'third', 'fourth', 'fifth', 'next', 'last',
    'left', 'right', 'both', 'side', 'sides', 'value', 'values', 'part', 'parts',
    'all', 'any', 'each', 'every', 'some', 'many', 'more', 'most', 'less',
    'pair', 'pairs', 'following', 'represents', 'stands', 'alone', 'standalone',
    'implicit', 'invisible', 'completely', 'instead', 'according', 'shows',
    'number', 'numbers', 'letter', 'letters', 'phrase', 'phrases', 'group', 'groups',
  };

  bool _looksLikeMathExpression(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    // Contains math operators, powers, variables with coefficients, or algebraic symbols
    return RegExp(r'[+\−\-\×\*\÷\/\=\<\>\^\(\)\[\]²³]').hasMatch(t) ||
        RegExp(r'\d+[a-zA-Z]').hasMatch(t) ||
        (t.length <= 20 && RegExp(r'\d').hasMatch(t));
  }

  bool _isMathToken(String rawToken) {
    final token = rawToken.trim();
    if (token.isEmpty) return false;

    if ((token.startsWith('`') && token.endsWith('`')) ||
        (token.startsWith('"') && token.endsWith('"')) ||
        (token.startsWith("'") && token.endsWith("'"))) {
      return true;
    }

    // Contains digits (e.g. 7x, 5, 12, 4a²)
    if (RegExp(r'\d').hasMatch(token)) return true;

    // Contains math operators or parentheses
    if (RegExp(r'[+\−\-\×\*\÷\/\=\<\>\^\(\)\[\]²³]').hasMatch(token)) {
      return true;
    }

    // Single letter variables (x, y, n, z, b) — excluding English 'a' and 'i' in sentence context
    final cleanAlpha = token.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    if (cleanAlpha.length == 1) {
      if (cleanAlpha == 'a' || cleanAlpha == 'i') {
        return false;
      }
      return true;
    }

    // Check if clean word is common English prose
    if (_englishWords.contains(cleanAlpha)) {
      return false;
    }

    // If it's a short variable combination like 2x or 3xy or ab
    if (cleanAlpha.length > 1 && cleanAlpha.length <= 4) {
      return true;
    }

    return false;
  }

  List<InlineSpan> _parseMathSpans(
    String text, {
    required double fontSize,
  }) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\`[^\`]+\`|"[^"]+"|[^\s]+|\s+)');
    final matches = regex.allMatches(text);

    for (final m in matches) {
      final token = m.group(0)!;
      if (token.trim().isEmpty) {
        spans.add(const TextSpan(text: ' '));
        continue;
      }

      final isMath = _isMathToken(token);
      final cleanText = token.replaceAll('`', '').replaceAll('"', '');

      if (cleanText == '×' || cleanText == '*') {
        spans.add(
          TextSpan(
            text: '×',
            style: GoogleFonts.nunito(
              fontSize: fontSize * 0.88,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF222428), // Dark gray
              height: 1.45,
            ),
          ),
        );
      } else if (isMath) {
        // Dark gray for numbers, equations, operations, and variables.
        // Using non-breaking spaces ensures math terms never break mid-token.
        final nonBreakingMath = cleanText.replaceAll(' ', '\u00A0');
        spans.add(
          TextSpan(
            text: nonBreakingMath,
            style: GoogleFonts.nunito(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF222428), // Dark gray
              letterSpacing: 0.3,
              height: 1.45,
            ),
          ),
        );
      } else {
        // Soft gray for the rest of the question words
        spans.add(
          TextSpan(
            text: cleanText,
            style: GoogleFonts.nunito(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5A5A5A), // Soft gray
              letterSpacing: 0.2,
              height: 1.45,
            ),
          ),
        );
      }
    }

    return spans;
  }

  Widget _buildRichQuestionPrompt(String questionText) {
    final colonIndex = questionText.indexOf(':');

    // If the question contains a colon and the trailing segment is an equation/expression
    if (colonIndex != -1) {
      final promptPart = questionText.substring(0, colonIndex + 1).trim();
      final mathPart = questionText.substring(colonIndex + 1).trim();

      if (mathPart.isNotEmpty && _looksLikeMathExpression(mathPart)) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Prompt Text
            Text.rich(
              TextSpan(children: _parseMathSpans(promptPart, fontSize: 17)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Dedicated Single-Line Responsive Equation Card (Never wraps across lines)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightPurple.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mathPart,
                  style: GoogleFonts.nunito(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF222428),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ],
        );
      }
    }

    final spans = _parseMathSpans(questionText, fontSize: 18.5);

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }
}
