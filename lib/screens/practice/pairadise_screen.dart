import 'dart:math' as math;
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/pairadise_provider.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/models/pairadise_problem.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:algebrix/widgets/secondary_button.dart';
import 'package:algebrix/widgets/xy_mascot.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Gameplay screen for **Pairadise — The Land of Pairs**.
///
/// Design specs:
/// - Tiles, Clues, and Mystery x / y slots: **BLUE**
/// - The rest of the UI: **TEAL**
/// - CTA Buttons: **TEAL**, soft, borderless, and **NO SHADOWS**!
class PairadiseScreen extends StatefulWidget {
  const PairadiseScreen({super.key, this.questLevelNumber});

  final int? questLevelNumber;

  @override
  State<PairadiseScreen> createState() => _PairadiseScreenState();
}

class _PairadiseScreenState extends State<PairadiseScreen> {
  int? _currentLevelNumber;
  bool _dialogOpen = false;
  String? _lastPresentedProblemId;

  @override
  void initState() {
    super.initState();
    _currentLevelNumber = widget.questLevelNumber ?? 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<PairadiseProvider>();
      provider.initLevelProblem(_currentLevelNumber!);
    });
  }

  void _checkAndShowCelebration(PairadiseProvider provider) {
    if (_dialogOpen) return;
    final problem = provider.currentProblem;
    if (problem == null) return;
    if (!provider.isSolved) return;
    if (_lastPresentedProblemId == problem.id) return;

    _lastPresentedProblemId = problem.id;
    _dialogOpen = true;

    final questMapProvider = context.read<QuestMapProvider>();
    final int moveCount = provider.moveCount;
    final bool reasoningPassed = provider.reasoningPassed;
    final int starsEarned = provider.starRating;

    // Explicitly persist to 'pairadise' land with calculated mistake-based stars
    questMapProvider.submitLevelResult(
      landId: 'pairadise',
      levelNumber: _currentLevelNumber!,
      moveCount: moveCount,
      optimalMoves: provider.optimalMoves,
      reasoningPassed: reasoningPassed,
      starsEarned: starsEarned,
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ChangeNotifierProvider.value(
        value: provider,
        child: _PairadiseCelebrationDialog(
          problem: problem,
          currentLevelNumber: _currentLevelNumber!,
          onBack: () {
            Navigator.of(dialogCtx).pop();
            _dialogOpen = false;
            if (mounted) Navigator.of(context).pop();
          },
          onRetry: () {
            Navigator.of(dialogCtx).pop();
            _dialogOpen = false;
            _lastPresentedProblemId = null;
            provider.resetCurrentProblem();
          },
          onNextLevel: () {
            Navigator.of(dialogCtx).pop();
            _dialogOpen = false;
            _lastPresentedProblemId = null;
            final nextLevel = _currentLevelNumber! + 1;
            if (nextLevel <= 10) {
              setState(() => _currentLevelNumber = nextLevel);
              provider.initLevelProblem(nextLevel);
            } else {
              if (mounted) Navigator.of(context).pop();
            }
          },
        ),
      ),
    ).then((_) => _dialogOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PairadiseProvider>();
    final questMapProvider = context.watch<QuestMapProvider>();

    if (provider.isSolved && !_dialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkAndShowCelebration(provider);
      });
    }

    final int starsEarned = questMapProvider.totalStars;
    const int maxStars = 30;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFB),
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD Bar (Teal)
            _PairadiseGameHeader(
              levelNumber: _currentLevelNumber ?? 1,
              starsEarned: starsEarned,
              maxStars: maxStars,
              onBack: () => Navigator.of(context).pop(),
            ),

            // Main Scrollable Play Area
            Expanded(
              child: provider.currentProblem == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                      ),
                    )
                  : !provider.isLevelPlayable
                      ? _buildComingSoonCard()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Mascot Companion (Teal) + Clues (BLUE) Header Card
                              const _PairadiseMascotAndClueHeader(),
                              const SizedBox(height: 18),

                                if (provider.currentProblem!.mechanic ==
                                  PairadiseMechanic.discovery) ...[
                                // 3D Mystery Value Drop Slots (BLUE)
                                const _MysteryValueSlots(),
                                const SizedBox(height: 18),

                                // Responsive Value Stones Grid (BLUE Tiles)
                                const _PairadiseNumberPalette(),
                                const SizedBox(height: 20),

                                // Soft, Borderless, Shadowless Teal Test Pair Button
                                const _TestPairControls(),
                              ] else if (provider.currentProblem!.mechanic ==
                                  PairadiseMechanic.elimination) ...[
                                // Candidate Pairs Grid (BLUE Tiles)
                                const _CandidatePairsGrid(),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF80CBC4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              XyMascot(
                asset: AppAssets.xyHappy,
                size: 92,
                shadowBlur: 4.0,
                shadowOpacity: 0.2,
              ),
              const SizedBox(height: 16),
              Text(
                'Coming Soon! 🌴',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00897B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This advanced Pairadise challenge will be unlocked in the next island update.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _PairadiseCTAButton(
                label: 'Back to Map',
                height: 48,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Top HUD Bar (Teal Theme)
// =============================================================================

String _toRoman(int n) {
  const romanMap = {
    10: 'X',
    9: 'IX',
    8: 'VIII',
    7: 'VII',
    6: 'VI',
    5: 'V',
    4: 'IV',
    3: 'III',
    2: 'II',
    1: 'I',
  };
  return romanMap[n] ?? '$n';
}

class _PairadiseGameHeader extends StatelessWidget {
  const _PairadiseGameHeader({
    required this.levelNumber,
    required this.starsEarned,
    required this.maxStars,
    required this.onBack,
  });

  final int levelNumber;
  final int starsEarned;
  final int maxStars;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          // Circular Back Button
          BouncyPressable(
            shrinkFactor: 0.9,
            enableHaptics: true,
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF80CBC4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF00897B),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // PAIRADISE Capsule (Teal)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF80CBC4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF80CBC4),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.spa_rounded,
                      color: Color(0xFF00897B),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'PAIRADISE ${_toRoman(levelNumber)}',
                            style: GoogleFonts.fredoka(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: const Color(0xFF00897B),
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'The Land of Pairs',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Total Stars Pill (Compact (star) 30 format)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFE082),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18FFA000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppAssets.star, width: 18, height: 18),
                const SizedBox(width: 4),
                Text(
                  '$starsEarned',
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Mascot Companion (Teal) & Target Clues Header Card (BLUE Clues)
// =============================================================================

class _PairadiseMascotAndClueHeader extends StatelessWidget {
  const _PairadiseMascotAndClueHeader();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PairadiseProvider>();
    final problem = provider.currentProblem;
    if (problem == null) return const SizedBox.shrink();

    final moveCount = provider.moveCount;
    final optimalMoves = provider.optimalMoves;

    // Mood asset & prompt
    String mascotAsset = AppAssets.xyPractice;
    String companionPrompt = problem.mechanic == PairadiseMechanic.discovery
        ? 'Find values for 🩵 x and 🩵 y that make both clues true!'
        : 'Cross out candidate pairs until only the 1 true mystery pair remains!';

    if (provider.phase == PairadisePhase.pairFound) {
      mascotAsset = AppAssets.xyHappy;
      companionPrompt = 'Mystery Pair Found! Both clues agree! 🎉';
    } else if (provider.phase == PairadisePhase.pairFailed) {
      mascotAsset = AppAssets.xyExplaining;
      companionPrompt = problem.mechanic == PairadiseMechanic.discovery
          ? 'Not quite! Check which clue failed and try a different pair.'
          : 'Not quite! The remaining pair doesn\'t satisfy both clues. Tap crossed-out tiles to un-cross them!';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF80CBC4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Big Mascot Avatar + Mode (Teal)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Prominent Xy Mascot Circle in Teal
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE0F2F1),
                  border: Border.all(
                    color: const Color(0xFF80CBC4),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BFA5).withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: XyMascot(
                    asset: mascotAsset,
                    size: 56,
                    shadowBlur: 3.0,
                    shadowOpacity: 0.15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      problem.mechanic == PairadiseMechanic.discovery
                          ? 'DISCOVERY PUZZLE'
                          : 'ELIMINATION PUZZLE',
                      style: GoogleFonts.nunito(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: const Color(0xFF00897B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Find Mystery Pair (x, y)',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Speech Bubble Instruction Card (Teal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF80CBC4).withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Text(
              companionPrompt,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF00897B),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Clue 1 Card (BLUE)
          _ClueCard(
            clueNumber: 1,
            clueText: problem.clue1,
            isChecking: provider.phase == PairadisePhase.clue1Checking,
            hasChecked: provider.phase == PairadisePhase.clue2Checking ||
                provider.phase == PairadisePhase.pairFound ||
                provider.phase == PairadisePhase.pairFailed,
            passed: provider.clue1Passed,
          ),
          const SizedBox(height: 8),

          // Clue 2 Card (BLUE)
          _ClueCard(
            clueNumber: 2,
            clueText: problem.clue2,
            isChecking: provider.phase == PairadisePhase.clue2Checking,
            hasChecked: provider.phase == PairadisePhase.pairFound ||
                provider.phase == PairadisePhase.pairFailed,
            passed: provider.clue2Passed,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sleek Clue Card (Clean BLUE Theme)
// =============================================================================

class _ClueCard extends StatelessWidget {
  const _ClueCard({
    required this.clueNumber,
    required this.clueText,
    required this.isChecking,
    required this.hasChecked,
    required this.passed,
  });

  final int clueNumber;
  final String clueText;
  final bool isChecking;
  final bool hasChecked;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    Color cardBg = const Color(0xFFF0F9FF);
    Color cardBorder = const Color(0xFFB3E5FC);

    if (hasChecked) {
      if (passed) {
        cardBg = const Color(0xFFE1F5FE);
        cardBorder = const Color(0xFF0288D1);
      } else {
        cardBg = AppColors.extraLightPink;
        cardBorder = AppColors.pink;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'CLUE $clueNumber',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              clueText,
              style: GoogleFonts.nunito(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (isChecking)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0288D1)),
              ),
            )
          else if (hasChecked)
            Icon(
              passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: passed ? const Color(0xFF0288D1) : AppColors.error,
              size: 22,
            )
          else
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF81D4FA),
              size: 20,
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Discovery Mode: 3D Mystery Value Slots (BLUE Theme for Mystery x & y)
// =============================================================================

class _MysteryValueSlots extends StatelessWidget {
  const _MysteryValueSlots();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PairadiseProvider>();

    return Row(
      children: [
        // Left Slot: Variable X (BLUE Theme)
        Expanded(
          child: _TactileValueDropSlot(
            variableName: 'x',
            variableColor: const Color(0xFF0288D1),
            slotLightBg: const Color(0xFFE1F5FE),
            value: provider.assignedX,
            onClear: () => provider.assignX(0),
            onAccept: (val) => provider.assignX(val),
          ),
        ),
        const SizedBox(width: 14),

        // Right Slot: Variable Y (BLUE Theme)
        Expanded(
          child: _TactileValueDropSlot(
            variableName: 'y',
            variableColor: const Color(0xFF0288D1),
            slotLightBg: const Color(0xFFE1F5FE),
            value: provider.assignedY,
            onClear: () => provider.assignY(0),
            onAccept: (val) => provider.assignY(val),
          ),
        ),
      ],
    );
  }
}

class _TactileValueDropSlot extends StatelessWidget {
  const _TactileValueDropSlot({
    required this.variableName,
    required this.variableColor,
    required this.slotLightBg,
    required this.value,
    required this.onClear,
    required this.onAccept,
  });

  final String variableName;
  final Color variableColor;
  final Color slotLightBg;
  final int? value;
  final VoidCallback onClear;
  final ValueChanged<int> onAccept;

  @override
  Widget build(BuildContext context) {
    final isFilled = value != null && value != 0;

    return DragTarget<int>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: slotLightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: variableColor.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  'Mystery $variableName',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: variableColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            BouncyPressable(
              shrinkFactor: 0.95,
              onTap: isFilled ? onClear : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 94,
                decoration: BoxDecoration(
                  color: isFilled
                      ? slotLightBg
                      : isHovered
                          ? slotLightBg.withValues(alpha: 0.8)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isHovered || isFilled
                        ? variableColor
                        : const Color(0xFFB3E5FC),
                    width: isHovered ? 2.2 : 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isHovered || isFilled
                          ? variableColor.withValues(alpha: 0.25)
                          : const Color(0xFFB3E5FC).withValues(alpha: 0.35),
                      offset: const Offset(0, 3.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: isFilled
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$value',
                            style: GoogleFonts.nunito(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: variableColor,
                            ),
                          ),
                          Text(
                            'tap to remove',
                            style: GoogleFonts.nunito(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: variableColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isHovered
                                ? Icons.file_download_rounded
                                : Icons.add_rounded,
                            color: variableColor.withValues(alpha: 0.6),
                            size: 26,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isHovered ? 'Release to drop' : 'Drag value here',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Responsive Value Stones Grid (4x2 BLUE Tiles)
// =============================================================================

class _PairadiseNumberPalette extends StatelessWidget {
  const _PairadiseNumberPalette();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PairadiseProvider>();
    final problem = provider.currentProblem;
    if (problem == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Available Value Stones',
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(
              'Drag or tap to assign',
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final availableWidth = constraints.maxWidth;
            final tileWidth =
                ((availableWidth - (3 * spacing)) / 4).floorToDouble();
            final tileHeight = (tileWidth * 1.06).clamp(58.0, 74.0);
            final fontSize = (tileWidth * 0.33).clamp(16.0, 22.0);

            final values = problem.candidateValues;
            final row1 = values.length >= 4 ? values.sublist(0, 4) : values;
            final row2 = values.length >= 8
                ? values.sublist(4, 8)
                : (values.length > 4 ? values.sublist(4) : <int>[]);

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: row1.map((val) {
                    return SizedBox(
                      width: tileWidth,
                      height: tileHeight,
                      child: _buildDraggableTile(
                        val,
                        provider,
                        tileWidth,
                        tileHeight,
                        fontSize,
                      ),
                    );
                  }).toList(),
                ),
                if (row2.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: row2.map((val) {
                      return SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: _buildDraggableTile(
                          val,
                          provider,
                          tileWidth,
                          tileHeight,
                          fontSize,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDraggableTile(
    int val,
    PairadiseProvider provider,
    double tileWidth,
    double tileHeight,
    double fontSize,
  ) {
    final isAssignedToX = provider.assignedX == val;
    final isAssignedToY = provider.assignedY == val;
    final isAssigned = isAssignedToX || isAssignedToY;
    final tag = isAssignedToX ? 'x' : (isAssignedToY ? 'y' : null);

    return Draggable<int>(
      data: val,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.12,
          child: _TactileNumberTile(
            value: val,
            isDragging: true,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            fontSize: fontSize,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _TactileNumberTile(
          value: val,
          isAssigned: isAssigned,
          assignedTag: tag,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          fontSize: fontSize,
        ),
      ),
      child: BouncyPressable(
        shrinkFactor: 0.92,
        enableHaptics: true,
        onTap: () {
          if (provider.assignedX == null || provider.assignedX == 0) {
            provider.assignX(val);
          } else if (provider.assignedY == null || provider.assignedY == 0) {
            provider.assignY(val);
          } else {
            provider.assignX(val);
          }
        },
        child: _TactileNumberTile(
          value: val,
          isAssigned: isAssigned,
          assignedTag: tag,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

class _TactileNumberTile extends StatelessWidget {
  const _TactileNumberTile({
    required this.value,
    this.isDragging = false,
    this.isAssigned = false,
    this.assignedTag,
    this.tileWidth = 56,
    this.tileHeight = 62,
    this.fontSize = 22,
  });

  final int value;
  final bool isDragging;
  final bool isAssigned;
  final String? assignedTag;
  final double tileWidth;
  final double tileHeight;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // All math tiles are cleanly themed in vibrant BLUE
    const accentColor = Color(0xFF0288D1);
    final Color tileBg = isAssigned
        ? const Color(0xFFE1F5FE)
        : (isDragging ? const Color(0xFFE1F5FE) : Colors.white);

    return Container(
      width: tileWidth,
      height: tileHeight,
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAssigned || isDragging
              ? accentColor
              : const Color(0xFF29B6F6).withValues(alpha: 0.5),
          width: isAssigned || isDragging ? 2.2 : 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDragging
                ? accentColor.withValues(alpha: 0.35)
                : accentColor.withValues(alpha: 0.1),
            blurRadius: isDragging ? 14 : 6,
            offset: Offset(0, isDragging ? 6 : 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$value',
                  style: GoogleFonts.nunito(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: isAssigned ? accentColor : AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(accentColor),
                  const SizedBox(width: 2.5),
                  _dot(accentColor),
                  const SizedBox(width: 2.5),
                  _dot(accentColor),
                ],
              ),
            ],
          ),
          if (assignedTag != null)
            Positioned(
              top: 3,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0288D1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  assignedTag!,
                  style: GoogleFonts.fredoka(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 3.5,
      height: 3.5,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
    );
  }
}

// =============================================================================
// Pairadise Custom Tactile Teal CTA Button (NO Shadows, NO Borders)
// =============================================================================

class _PairadiseCTAButton extends StatelessWidget {
  const _PairadiseCTAButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 52,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return BouncyPressable(
      shrinkFactor: isEnabled ? 0.96 : 1.0,
      enableHaptics: isEnabled,
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: height,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF00BFA5) : const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(30),
          // ZERO shadows as explicitly requested by user
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isEnabled ? Colors.white : const Color(0xFF80CBC4),
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: isEnabled ? Colors.white : const Color(0xFF80CBC4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Action Controls (Soft, Borderless, Shadowless Teal Test Pair CTA Button)
// =============================================================================

class _TestPairControls extends StatelessWidget {
  const _TestPairControls();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PairadiseProvider>();
    final isChecking = provider.phase == PairadisePhase.clue1Checking ||
        provider.phase == PairadisePhase.clue2Checking;
    final isReady = provider.isPairReady &&
        provider.assignedX != 0 &&
        provider.assignedY != 0 &&
        !isChecking &&
        !provider.isSolved;

    return _PairadiseCTAButton(
      label: 'Test Pair',
      icon: Icons.search_rounded,
      height: 52,
      onPressed: isReady ? () => provider.testPair() : null,
    );
  }
}

// =============================================================================
// Elimination Mode: 3D Candidate Pairs Grid (BLUE Theme - 3 per row)
// =============================================================================

class _CandidatePairsGrid extends StatelessWidget {
  const _CandidatePairsGrid();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PairadiseProvider>();
    final problem = provider.currentProblem;
    if (problem == null) return const SizedBox.shrink();

    final remaining = provider.remainingPairCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Candidate Pairs',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: remaining == 1
                    ? AppColors.lightMint
                    : const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: remaining == 1
                      ? AppColors.mint.withValues(alpha: 0.5)
                      : const Color(0xFF80CBC4).withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                remaining == 1
                    ? '⭐ Pair Found!'
                    : '$remaining left',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: remaining == 1
                      ? const Color(0xFF0F7263)
                      : const Color(0xFF00897B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final availableWidth = constraints.maxWidth;
            final tileWidth =
                ((availableWidth - (2 * spacing)) / 3).floorToDouble();
            final tileHeight = (tileWidth * 0.58).clamp(52.0, 68.0);
            final fontSize = (tileWidth * 0.17).clamp(14.0, 18.0);

            return Wrap(
              spacing: spacing,
              runSpacing: 10.0,
              children: problem.candidatePairs.asMap().entries.map((e) {
                final index = e.key;
                final pair = e.value;
                return SizedBox(
                  width: tileWidth,
                  height: tileHeight,
                  child: _buildCandidateCard(
                    index: index,
                    pair: pair,
                    provider: provider,
                    problem: problem,
                    fontSize: fontSize,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCandidateCard({
    required int index,
    required CandidatePair pair,
    required PairadiseProvider provider,
    required PairadiseProblem problem,
    required double fontSize,
  }) {
    final isEliminated = provider.eliminatedPairIndices.contains(index);
    final isConfirmed = provider.confirmedPairIndex == index;
    final isLastRemaining =
        provider.remainingPairCount == 1 && !isEliminated;

    return BouncyPressable(
      shrinkFactor: 0.94,
      enableHaptics: true,
      onTap: () {
        if (provider.phase == PairadisePhase.clue1Checking ||
            provider.phase == PairadisePhase.clue2Checking) {
          return;
        }
        provider.togglePairElimination(index);
      },
      child: _TactilePairCard(
        pair: pair,
        isEliminated: isEliminated,
        isLastRemaining: isLastRemaining,
        isConfirmed: isConfirmed,
        fontSize: fontSize,
      ),
    );
  }
}

class _TactilePairCard extends StatelessWidget {
  const _TactilePairCard({
    required this.pair,
    required this.isEliminated,
    required this.isLastRemaining,
    required this.isConfirmed,
    this.fontSize = 16.0,
  });

  final CandidatePair pair;
  final bool isEliminated;
  final bool isLastRemaining;
  final bool isConfirmed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    Color cardBg = Colors.white;
    Color borderColor = const Color(0xFF81D4FA);
    Color rimColor = const Color(0xFF0288D1);
    Color textColor = AppColors.text;

    if (isEliminated) {
      cardBg = const Color(0xFFF9F0F2);
      borderColor = AppColors.pink.withValues(alpha: 0.25);
      rimColor = AppColors.pink.withValues(alpha: 0.3);
      textColor = AppColors.subtitle;
    } else if (isConfirmed || isLastRemaining) {
      cardBg = const Color(0xFFE1F5FE);
      borderColor = const Color(0xFF0288D1);
      rimColor = const Color(0xFF0288D1);
      textColor = const Color(0xFF0288D1);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isEliminated
            ? null
            : [
                BoxShadow(
                  color: rimColor,
                  offset: const Offset(0, 3.5),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: (isConfirmed
                          ? const Color(0xFF0288D1)
                          : Colors.black)
                      .withValues(alpha: isConfirmed ? 0.2 : 0.06),
                  blurRadius: isConfirmed ? 8 : 4,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '(${pair.x}, ${pair.y})',
                style: GoogleFonts.nunito(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  decoration: isEliminated ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.pink,
                  decorationThickness: 2.5,
                ),
              ),
            ),
          ),
          if (isEliminated)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.extraLightPink,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.pink,
                  size: 14,
                ),
              ),
            ),
          if (isConfirmed)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE1F5FE),
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF0288D1),
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Step History Card (Steps Log - TEAL Theme)
// =============================================================================

class _StepHistoryCard extends StatelessWidget {
  const _StepHistoryCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PairadiseProvider>();
    if (provider.history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attempt History (${provider.moveCount} move${provider.moveCount == 1 ? '' : 's'})',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        ...provider.history.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final step = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: step.isCorrect
                        ? const Color(0xFFE0F2F1)
                        : AppColors.extraLightPink,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$idx',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: step.isCorrect
                          ? const Color(0xFF00897B)
                          : AppColors.pink,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.description,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// =============================================================================
// Balands-Style Soft Celebration & Reasoning Pop-up Dialog
// =============================================================================

class _PairadiseCelebrationDialog extends StatefulWidget {
  const _PairadiseCelebrationDialog({
    required this.problem,
    required this.currentLevelNumber,
    required this.onBack,
    required this.onRetry,
    required this.onNextLevel,
  });

  final PairadiseProblem problem;
  final int currentLevelNumber;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback onNextLevel;

  @override
  State<_PairadiseCelebrationDialog> createState() =>
      _PairadiseCelebrationDialogState();
}

class _PairadiseCelebrationDialogState
    extends State<_PairadiseCelebrationDialog>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  bool _isAnswering = false;
  bool _showError = false;
  bool _showSuccess = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  late List<AnimationController> _starControllers;
  late List<Animation<double>> _starAnimations;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _starControllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _starAnimations = _starControllers.map((c) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: Curves.elasticOut),
      );
    }).toList();
  }

  void _triggerStars(int starRating) {
    for (int i = 0; i < starRating; i++) {
      Future.delayed(Duration(milliseconds: 150 + (i * 180)), () {
        if (mounted) _starControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    for (final c in _starControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onOptionTap(int index) {
    if (_isAnswering) return;
    _isAnswering = true;

    final provider = context.read<PairadiseProvider>();
    final isCorrect = index == widget.problem.correctReasoningIndex;

    setState(() {
      _selectedIndex = index;
      _showError = !isCorrect;
      _showSuccess = isCorrect;
    });

    if (!isCorrect) {
      _shakeController.forward(from: 0);
      showAlgebrixSnackBar(
        context,
        message:
            'Not quite! Option ${String.fromCharCode(65 + widget.problem.correctReasoningIndex)} is the correct reasoning. 🤔',
        isError: true,
      );

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        provider.submitReasoningAnswer(index);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        provider.submitReasoningAnswer(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PairadiseProvider>();
    final isCelebration = !provider.showReasoningCheck;

    if (isCelebration &&
        !_starControllers[0].isAnimating &&
        !_starControllers[0].isCompleted) {
      _triggerStars(provider.starRating);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: isCelebration
            ? _buildCelebrationView(provider)
            : _buildReasoningView(provider),
      ),
    );
  }

  Widget _buildReasoningView(PairadiseProvider provider) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = _shakeController.isAnimating
            ? math.sin(_shakeAnimation.value * math.pi * 4) *
                6 *
                (1 - _shakeAnimation.value)
            : 0.0;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF80CBC4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mascot + Header (Teal)
              Row(
                children: [
                  XyMascot(
                    asset: _showError
                        ? AppAssets.xyExplaining
                        : AppAssets.xyQuestion,
                    size: 64,
                    shadowBlur: 4.0,
                    shadowOpacity: 0.18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reasoning Check',
                          style: GoogleFonts.nunito(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF00897B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.problem.reasoningQuestion ??
                              'WHY does this pair satisfy both clues?',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Solved Recap Card (Teal)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF80CBC4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00897B),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            'MYSTERY PAIR',
                            style: GoogleFonts.nunito(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF00897B),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            'x = ${widget.problem.solutionX}, y = ${widget.problem.solutionY}',
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF00897B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.problem.clue1}   •   ${widget.problem.clue2}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF00897B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Options
              ...widget.problem.reasoningOptions.asMap().entries.map((entry) {
                final idx = entry.key;
                final text = entry.value;
                final isSelected = _selectedIndex == idx;
                final isCorrectChoice =
                    idx == widget.problem.correctReasoningIndex;

                final isWrong = _showError && isSelected;
                final isSuccess = _showSuccess && isSelected;
                final isHighlightedCorrect = _showError && isCorrectChoice;

                Color bgColor = const Color(0xFFF9FDFD);
                Color borderColor = AppColors.border;
                double borderWidth = 1.5;

                if (isWrong) {
                  bgColor = AppColors.error.withValues(alpha: 0.08);
                  borderColor = AppColors.error;
                  borderWidth = 2.0;
                } else if (isSuccess || isHighlightedCorrect) {
                  bgColor = const Color(0xFFE0F2F1);
                  borderColor = const Color(0xFF00897B);
                  borderWidth = 2.0;
                } else if (isSelected) {
                  bgColor = const Color(0xFFE0F2F1);
                  borderColor = const Color(0xFF00897B);
                  borderWidth = 2.0;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BouncyPressable(
                    shrinkFactor: 0.97,
                    enableHaptics: !_isAnswering,
                    onTap: _isAnswering ? null : () => _onOptionTap(idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                          width: borderWidth,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSuccess || isHighlightedCorrect
                                  ? const Color(0xFF00897B)
                                  : isWrong
                                      ? AppColors.error
                                      : Colors.white,
                              border: Border.all(
                                color: borderColor,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + idx),
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: (isSuccess ||
                                        isHighlightedCorrect ||
                                        isWrong)
                                    ? Colors.white
                                    : AppColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              text,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                                height: 1.35,
                              ),
                            ),
                          ),
                          if (isWrong)
                            const Icon(
                              Icons.close_rounded,
                              color: AppColors.error,
                              size: 20,
                            )
                          else if (isSuccess || isHighlightedCorrect)
                            const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF00897B),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationView(PairadiseProvider provider) {
    final starLabels = [
      'Completed!',
      'Good Effort!',
      'Great Job!',
      'Perfect!'
    ];
    final label = starLabels[provider.starRating.clamp(0, 3)];
    final isCheckpoint = widget.problem.hasReasoningCheckpoint;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF80CBC4), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mascot with soft celebration aura
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2F1),
              shape: BoxShape.circle,
            ),
            child: XyMascot(
              asset: AppAssets.xyHappy,
              size: 104,
              shadowBlur: 5.0,
              shadowOpacity: 0.18,
            ),
          ),
          const SizedBox(height: 14),

          // Star Capsule Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFE082),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final earned = i < provider.starRating;
                return AnimatedBuilder(
                  animation: _starAnimations[i],
                  builder: (ctx, child) {
                    return Transform.scale(
                      scale: earned ? _starAnimations[i].value : 0.85,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Image.asset(
                          earned
                              ? AppAssets.star
                              : AppAssets.starSilhouette,
                          width: 44,
                          height: 44,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Subtitle in Teal
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF00897B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isCheckpoint
                ? (provider.reasoningPassed
                    ? 'Mystery pair verified & reasoning mastered! 🌴'
                    : 'Mystery pair verified! 🌴')
                : 'Mystery pair verified! 🌴',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Solved Concept Recap Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF80CBC4),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.problem.clue1}  ✓',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF00897B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.problem.clue2}  ✓',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF00897B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Both clues agree! (${widget.problem.solutionX}, ${widget.problem.solutionY}) is our mystery pair!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00897B),
                  ),
                ),
              ],
            ),
          ),

          // Rewards Pods
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.lightYellow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFE082),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '+${provider.starRating} Stars',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF8D6E63),
                        ),
                      ),
                      Text(
                        'Quest Progress',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: (isCheckpoint
                            ? provider.reasoningPassed
                            : provider.failedTests == 0)
                        ? const Color(0xFFE0F2F1)
                        : AppColors.extraLightPink,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isCheckpoint
                              ? provider.reasoningPassed
                              : provider.failedTests == 0)
                          ? const Color(0xFF80CBC4)
                          : AppColors.pink,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isCheckpoint
                            ? (provider.reasoningPassed ? 'Passed' : 'Review')
                            : (provider.failedTests == 0
                                ? '1st Try!'
                                : '${provider.failedTests + 1} Checks'),
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: (isCheckpoint
                                  ? provider.reasoningPassed
                                  : provider.failedTests == 0)
                              ? const Color(0xFF00897B)
                              : AppColors.pink,
                        ),
                      ),
                      Text(
                        isCheckpoint ? 'Checkpoint' : 'Accuracy',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons: Row of (Back, Retry) + Primary (Next Level)
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  key: const Key('celebration-btn-back'),
                  label: 'Back',
                  icon: Icons.arrow_back_rounded,
                  height: 48,
                  borderColor: AppColors.border,
                  textColor: AppColors.text,
                  backgroundColor: AppColors.background,
                  onPressed: widget.onBack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  key: const Key('celebration-btn-retry'),
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  height: 48,
                  borderColor: AppColors.border,
                  textColor: AppColors.text,
                  backgroundColor: AppColors.background,
                  onPressed: widget.onRetry,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Next Level (Soft, borderless, shadowless Teal CTA)
          _PairadiseCTAButton(
            key: const Key('celebration-btn-next-level'),
            label: widget.currentLevelNumber < 10
                ? 'Next Level ➔'
                : 'Back to Quest Map ➔',
            height: 52,
            onPressed: widget.currentLevelNumber < 10
                ? widget.onNextLevel
                : widget.onBack,
          ),
        ],
      ),
    );
  }
}
