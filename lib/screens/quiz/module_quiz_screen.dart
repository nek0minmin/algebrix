import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/models/module_quiz_model.dart';
import 'package:algebrix/services/module_quiz_service.dart';
import 'package:algebrix/widgets/primary_button.dart';

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

class _ModuleQuizScreenState extends State<ModuleQuizScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _loadingAnimController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _quizService = widget.quizService ?? ModuleQuizService();

    _loadingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _loadingAnimController,
        curve: Curves.easeInOut,
      ),
    );

    final isTesting =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTesting) {
      _loadingAnimController.repeat(reverse: true);
    }

    _loadQuiz();
  }

  @override
  void dispose() {
    _loadingAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
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
      setState(() {
        _quiz = quiz;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not generate quiz: $e';
        _isLoading = false;
      });
    }
  }

  void _handleSelectOption(int index) {
    if (_isAnswered || _quiz == null) return;

    final currentQ = _quiz!.questions[_currentIndex];
    final isCorrect = index == currentQ.correctIndex;

    setState(() {
      _selectedChoiceIndex = index;
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
    }
  }

  int get _starRating {
    final total = _quiz?.questions.length ?? 15;
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
            : _errorMessage != null
                ? _buildErrorScreen()
                : _isFinished
                    ? _buildVictoryScreen()
                    : _buildQuizActiveScreen(),
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
            ScaleTransition(
              scale: _pulseAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.pink.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 104,
                    height: 104,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E2024),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: Image.asset(
                        widget.module.xyAsset ?? AppAssets.xyExplaining,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
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
              'Synthesizing 15 progressive questions from ${widget.module.title}',
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

    final difficultyLabel = question.difficulty == 1
        ? 'FOUNDATIONS'
        : (question.difficulty == 2 ? 'PROCEDURAL' : 'MASTERY CHALLENGE');
    final difficultyColor = question.difficulty == 1
        ? AppColors.mint
        : (question.difficulty == 2 ? AppColors.purple : AppColors.pink);

    return Column(
      children: [
        // Top Progress Row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                      color: difficultyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      difficultyLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: difficultyColor,
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
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pink),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Question & Options
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sub-lesson Tag
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.extraLightPink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        question.subLessonTitle.toUpperCase(),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pink,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Question Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _buildRichQuestionPrompt(question.question),
                ),
                const SizedBox(height: 20),

                // Choices
                for (var i = 0; i < question.options.length; i++) ...[
                  _buildOptionTile(
                    optionIndex: i,
                    label: question.options[i],
                    isCorrectChoice: i == question.correctIndex,
                  ),
                  const SizedBox(height: 12),
                ],

                // Answer Feedback Banner
                if (_isAnswered) ...[
                  const SizedBox(height: 8),
                  _buildAnswerFeedback(question),
                ],
              ],
            ),
          ),
        ),

        // Bottom Action Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: PrimaryButton(
            label: _currentIndex + 1 == total
                ? 'Finish Quiz 🎉'
                : 'Next Question →',
            onPressed: _isAnswered ? _handleNextQuestion : null,
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

    if (_isAnswered) {
      if (isCorrectChoice) {
        borderColor = AppColors.mint;
        bgColor = AppColors.lightMint;
      } else if (isSelected && !isCorrectChoice) {
        borderColor = AppColors.pink;
        bgColor = AppColors.extraLightPink;
      }
    } else if (isSelected) {
      borderColor = AppColors.purple;
      bgColor = AppColors.lightPurple.withValues(alpha: 0.25);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isAnswered ? null : () => _handleSelectOption(optionIndex),
        borderRadius: BorderRadius.circular(32),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: borderColor,
              width: (isSelected || (_isAnswered && isCorrectChoice)) ? 2 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected || (_isAnswered && isCorrectChoice))
                    ? borderColor.withValues(alpha: 0.15)
                    : AppColors.shadow.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isSelected || (_isAnswered && isCorrectChoice))
                      ? borderColor
                      : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + optionIndex),
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: (isSelected || (_isAnswered && isCorrectChoice))
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildOptionLabel(
                  label: label,
                  isAnswered: _isAnswered,
                  isCorrectChoice: isCorrectChoice,
                  isSelected: isSelected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionLabel({
    required String label,
    required bool isAnswered,
    required bool isCorrectChoice,
    required bool isSelected,
  }) {
    if (isAnswered) {
      if (isCorrectChoice) {
        return Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F7263),
          ),
        );
      } else if (isSelected && !isCorrectChoice) {
        return Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.darkPink,
          ),
        );
      }
    }

    final spans = _parseMathSpans(label, fontSize: 16);
    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildAnswerFeedback(ModuleQuizQuestion question) {
    final isCorrect = _selectedChoiceIndex == question.correctIndex;
    final accent = isCorrect ? AppColors.mint : AppColors.pink;
    final surface = isCorrect ? AppColors.lightMint : AppColors.extraLightPink;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2024),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: Image.asset(
                    isCorrect
                        ? (widget.module.xyAsset ?? AppAssets.xyHappy)
                        : AppAssets.xyExplaining,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect ? 'Spot On! 🎉' : 'Let\'s Learn! 💡',
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isCorrect ? const Color(0xFF0F7263) : AppColors.darkPink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.explanation,
            style: GoogleFonts.nunito(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Victory & Mastery Review Screen ─────────────────────────────────────
  Widget _buildVictoryScreen() {
    final total = _quiz?.questions.length ?? 15;
    final percent = total > 0 ? ((_correctCount / total) * 100).round() : 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mascot Hero
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Color(0xFF1E2024),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: ClipOval(
                child: Image.asset(
                  AppAssets.xyHappy,
                  fit: BoxFit.contain,
                ),
              ),
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

                // XP Reward Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.mint,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+150 XP Earned!',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F7263),
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
            label: 'Retake Quiz 🔄',
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
        // Dark gray for numbers, equations, operations, and variables
        spans.add(
          TextSpan(
            text: cleanText,
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
    final spans = _parseMathSpans(questionText, fontSize: 18.5);

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }
}
