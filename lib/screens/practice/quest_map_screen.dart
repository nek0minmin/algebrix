import 'dart:math' as math;
import 'package:algebrix/core/animations/app_page_route.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/models/quest_map_model.dart';
import 'package:algebrix/screens/practice/balance_scale_screen.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/xy_mascot.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Algebrix Game World Map Screen for "Balands — The Land of Balancing".
///
/// Features an Algebrix-themed pastel math kingdom with:
/// - Crisp white & soft pastel cloud islands with faint math grid patterns.
/// - Giant 3D isometric math blocks ([x], [2x], [+3], [=], [-5]) scattered on hills.
/// - A prominent golden Balance Scale monument at the mountain summit.
/// - A winding pastel cobblestone pathway with soft pink/mint border ribbons.
/// - 3D tactile stepping-stone buttons in signature Algebrix Pink, Mint, and Purple.
class QuestMapScreen extends StatefulWidget {
  const QuestMapScreen({super.key});

  @override
  State<QuestMapScreen> createState() => _QuestMapScreenState();
}

class _QuestMapScreenState extends State<QuestMapScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double _mapCanvasHeight = 1580.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QuestMapProvider>();
      provider.loadQuestMap().then((_) {
        _autoScrollToActiveLevel(provider);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScrollToActiveLevel(QuestMapProvider provider) {
    if (!mounted || !_scrollController.hasClients) return;

    // Find highest active unlocked level (1-indexed)
    int activeLevel = 1;
    for (int i = 1; i <= 10; i++) {
      if (provider.isLevelUnlocked(i)) {
        activeLevel = i;
        if (provider.starsForLevel(i) == 0) break; // First uncompleted unlocked level
      }
    }

    final nodePos = _getNodePosition(activeLevel - 1, 400, _mapCanvasHeight);
    final targetScroll = (nodePos.dy - 320).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestMapProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FD),
      body: Stack(
        children: [
          // ─── 1. Scrollable Algebrix World Map Canvas ───────────────────────
          Positioned.fill(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.pink,
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final mapWidth = constraints.maxWidth;
                      return SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: mapWidth,
                          height: _mapCanvasHeight,
                          child: Stack(
                            children: [
                              // Background Illustrated Algebrix Landscape
                              Positioned.fill(
                                child: CustomPaint(
                                  size: Size(mapWidth, _mapCanvasHeight),
                                  painter: _AlgebrixMapLandscapePainter(
                                    mapWidth: mapWidth,
                                    mapHeight: _mapCanvasHeight,
                                    completedLevels: [
                                      for (int i = 1; i <= 10; i++)
                                        if (provider.starsForLevel(i) > 0) i,
                                    ],
                                  ),
                                ),
                              ),

                              // Interactive 3D Level Nodes
                              ...List.generate(10, (index) {
                                final levelNumber = index + 1;
                                final def = provider.levelDefinitions.length > index
                                    ? provider.levelDefinitions[index]
                                    : QuestLevelDefinition(
                                        levelNumber: levelNumber,
                                        difficulty: levelNumber <= 3 ? 2 : (levelNumber <= 7 ? 5 : 8),
                                        description: 'Level $levelNumber',
                                      );

                                final starsEarned = provider.starsForLevel(levelNumber);
                                final isUnlocked = provider.isLevelUnlocked(levelNumber);
                                final isNextPlayable = isUnlocked &&
                                    (starsEarned == 0 ||
                                        levelNumber == 10 ||
                                        !provider.isLevelUnlocked(levelNumber + 1));

                                final pos = _getNodePosition(index, mapWidth, _mapCanvasHeight);

                                return Positioned(
                                  left: pos.dx - 44,
                                  top: pos.dy - 56,
                                  child: _AlgebrixLevelNode(
                                    key: Key('quest-level-node-$levelNumber'),
                                    definition: def,
                                    starsEarned: starsEarned,
                                    bestMoves: provider.bestMovesForLevel(levelNumber),
                                    isUnlocked: isUnlocked,
                                    isNextPlayable: isNextPlayable,
                                    onTap: () {
                                      if (isUnlocked) {
                                        _showLevelPreviewSheet(
                                          context,
                                          provider,
                                          def,
                                          starsEarned,
                                          provider.bestMovesForLevel(levelNumber),
                                        );
                                      } else {
                                        showAlgebrixSnackBar(
                                          context,
                                          message:
                                              'Complete Level ${levelNumber - 1} to unlock this land! 🔒',
                                          icon: Icons.lock_rounded,
                                          isError: true,
                                        );
                                      }
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ─── 2. Floating Top Game HUD ──────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _FloatingGameHud(
              landName: 'Balands',
              landSubtitle: 'The Land of Balancing',
              starsEarned: provider.activeLandStars,
              maxStars: 30,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelPreviewSheet(
    BuildContext context,
    QuestMapProvider provider,
    QuestLevelDefinition def,
    int starsEarned,
    int? bestMoves,
  ) {
    final problem = provider.getLevelProblem(def.levelNumber);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 30,
                offset: Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator pill
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Level Header with Mascot
              Row(
                children: [
                  XyMascot(
                    asset: starsEarned == 3
                        ? AppAssets.xyHappy
                        : AppAssets.xyPractice,
                    size: 64,
                    shadowBlur: 4.0,
                    shadowOpacity: 0.2,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Level ${def.levelNumber}',
                              style: GoogleFonts.nunito(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _difficultyColor(def.difficulty)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                def.difficultyLabel,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: _difficultyColor(def.difficulty),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          def.description,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Target Equation Banner (Defensive Zero Overflow)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.extraLightPink,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.pink.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TARGET EQUATION',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkPink,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              problem.equation,
                              style: GoogleFonts.nunito(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.pink.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '${problem.optimalMoves} ${problem.optimalMoves == 1 ? "move" : "moves"}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stars & Best Moves Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final earned = i < starsEarned;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              earned
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 26,
                              color: earned
                                  ? const Color(0xFFFFB300)
                                  : const Color(0xFFBDBDBD),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  if (bestMoves != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.lightMint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.mint.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Best: $bestMoves moves',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F7263),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Start Level Button
              PrimaryButton(
                label: 'Play Level ${def.levelNumber} 🚀',
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.push(
                    context,
                    AppPageRoute(
                      child: BalanceScaleScreen(
                        questLevelNumber: def.levelNumber,
                      ),
                    ),
                  ).then((_) {
                    provider.loadQuestMap();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Color _difficultyColor(int difficulty) {
    if (difficulty <= 3) return AppColors.mint;
    if (difficulty <= 6) return const Color(0xFFFFA000);
    if (difficulty <= 8) return AppColors.pink;
    return AppColors.purple;
  }
}

// =============================================================================
// Mathematical S-Curve Node Coordinates
// =============================================================================

/// Calculates the (x, y) center coordinate of each level node along the snaking trail.
Offset _getNodePosition(int index, double mapWidth, double mapHeight) {
  final t = index / 9.0; // 0.0 (bottom) to 1.0 (top)

  // Vertical placement (from bottom Y ~1420 to top Y ~200)
  final y = (mapHeight - 160.0) - (t * (mapHeight - 340.0));

  // Horizontal snaking curve across width matching Picture 2
  const xFractions = [
    0.30, // Level 1 (bottom left)
    0.50, // Level 2 (center)
    0.72, // Level 3 (right curve)
    0.78, // Level 4 (far right)
    0.54, // Level 5 (center)
    0.32, // Level 6 (left curve)
    0.20, // Level 7 (far left before river)
    0.38, // Level 8 (across bridge center-left)
    0.58, // Level 9 (center-right)
    0.68, // Level 10 (summit right)
  ];

  final xFraction = index < xFractions.length ? xFractions[index] : 0.5;
  final x = mapWidth * xFraction;

  return Offset(x, y);
}

// =============================================================================
// Floating Top Game HUD (Header)
// =============================================================================

class _FloatingGameHud extends StatelessWidget {
  const _FloatingGameHud({
    required this.landName,
    required this.landSubtitle,
    required this.starsEarned,
    required this.maxStars,
    required this.onBack,
  });

  final String landName;
  final String landSubtitle;
  final int starsEarned;
  final int maxStars;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 44, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          // Back Button
          BouncyPressable(
            shrinkFactor: 0.88,
            enableHaptics: true,
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.pink.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pink.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.pink,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Land Title Capsule
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('⚖️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          landName,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          landSubtitle,
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Stars Progress Capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFB300),
                  size: 22,
                ),
                const SizedBox(width: 4),
                Text(
                  '$starsEarned/$maxStars',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
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
// Algebrix 3D Level Stepping Node Widget
// =============================================================================

class _AlgebrixLevelNode extends StatelessWidget {
  const _AlgebrixLevelNode({
    super.key,
    required this.definition,
    required this.starsEarned,
    required this.bestMoves,
    required this.isUnlocked,
    required this.isNextPlayable,
    required this.onTap,
  });

  final QuestLevelDefinition definition;
  final int starsEarned;
  final int? bestMoves;
  final bool isUnlocked;
  final bool isNextPlayable;
  final VoidCallback onTap;

  bool get _isCompleted => starsEarned > 0;

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      shrinkFactor: isUnlocked ? 0.90 : 0.98,
      enableHaptics: isUnlocked,
      onTap: onTap,
      child: SizedBox(
        width: 88,
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Mascot Xy perched on the active / next playable level
            if (isNextPlayable)
              Positioned(
                top: -38,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    XyMascot(
                      asset: _isCompleted
                          ? AppAssets.xyHappy
                          : AppAssets.xyDefault,
                      size: 54,
                      shadowBlur: 4.0,
                      shadowOpacity: 0.25,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33FF5CA8),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'HERE! 👇',
                        style: GoogleFonts.nunito(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Arched Stars above node
            Positioned(
              top: isNextPlayable ? 18 : 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildArchStar(0, -0.22, 3.0),
                  _buildArchStar(1, 0.0, 0.0),
                  _buildArchStar(2, 0.22, 3.0),
                ],
              ),
            ),

            // 3D Level Disc Button
            Positioned(
              bottom: 6,
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // 3D Pedestal Base in Algebrix Theme
                  color: !isUnlocked
                      ? const Color(0xFFD1C4E9) // Soft lavender stone
                      : (_isCompleted
                          ? const Color(0xFF38B2A1) // Darker mint base rim
                          : const Color(0xFFE91E8C)), // Darker pink base rim
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                    if (isNextPlayable)
                      BoxShadow(
                        color: AppColors.pink.withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Inner Glossy Gradient in Algebrix Palette
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: !isUnlocked
                            ? [
                                const Color(0xFFEDE7FF),
                                const Color(0xFFD1C4E9),
                              ]
                            : (_isCompleted
                                ? [
                                    const Color(0xFF62D9C7),
                                    const Color(0xFF32BAA6),
                                  ]
                                : [
                                    const Color(0xFFFF69B4),
                                    const Color(0xFFFF4081),
                                  ]),
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 2.2,
                      ),
                    ),
                    child: Center(
                      child: !isUnlocked
                          ? const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFF9575CD),
                              size: 24,
                            )
                          : Text(
                              '${definition.levelNumber}',
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchStar(int starIndex, double rotation, double yOffset) {
    final earned = starIndex < starsEarned;

    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.rotate(
        angle: rotation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Icon(
            earned ? Icons.star_rounded : Icons.star_rounded,
            size: 18,
            color: earned
                ? const Color(0xFFFFB300)
                : const Color(0xFFE0E0E0),
            shadows: earned
                ? const [
                    Shadow(
                      color: Color(0x60FF8F00),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Algebrix Map Landscape Custom Painter (Pastel, White & Math Blocks)
// =============================================================================

class _AlgebrixMapLandscapePainter extends CustomPainter {
  _AlgebrixMapLandscapePainter({
    required this.mapWidth,
    required this.mapHeight,
    required this.completedLevels,
  });

  final double mapWidth;
  final double mapHeight;
  final List<int> completedLevels;

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Clean White / Light Lavender Background ───────────────────────────
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF7F2FC), // Top cloud summit
          Color(0xFFFCF9FF), // Mid realm
          Color(0xFFFDFBFF), // Bottom valley
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // ── 2. Subtle Math Grid Pattern ──────────────────────────────────────────
    _drawMathGrid(canvas, size);

    // ── 3. Soft Pastel Rolling Cloud/Hill Masses ─────────────────────────────
    _drawPastelMass(
      canvas,
      size,
      0.18 * size.height,
      AppColors.lightPurple.withValues(alpha: 0.6),
    );
    _drawPastelMass(
      canvas,
      size,
      0.44 * size.height,
      AppColors.lightMint.withValues(alpha: 0.65),
    );
    _drawPastelMass(
      canvas,
      size,
      0.72 * size.height,
      AppColors.extraLightPink.withValues(alpha: 0.75),
    );

    // ── 4. Winding Pastel River Creek ────────────────────────────────────────
    _drawPastelRiver(canvas, size);

    // ── 5. Algebrix Winding Pastel Pathway ───────────────────────────────────
    _drawAlgebrixPath(canvas, size);

    // ── 6. Pastel Bridge Crossing ────────────────────────────────────────────
    _drawPastelBridge(canvas, size);

    // ── 7. Giant 3D Math Blocks & Balance Scales ─────────────────────────────
    _drawMathBlocksAndScales(canvas, size);
  }

  void _drawMathGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFEDE7F6).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    const spacing = 38.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawPastelMass(Canvas canvas, Size size, double topY, Color color) {
    final path = Path()
      ..moveTo(0, topY)
      ..cubicTo(
        size.width * 0.35,
        topY - 40,
        size.width * 0.70,
        topY + 30,
        size.width,
        topY - 20,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  void _drawPastelRiver(Canvas canvas, Size size) {
    // River crosses horizontally between Level 6 & Level 8 (around Y = 620-720)
    final riverPath = Path()
      ..moveTo(0, size.height * 0.44)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.40,
        size.width * 0.65,
        size.height * 0.49,
        size.width,
        size.height * 0.43,
      )
      ..lineTo(size.width, size.height * 0.49)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.55,
        size.width * 0.30,
        size.height * 0.46,
        0,
        size.height * 0.50,
      )
      ..close();

    // Pastel Turquoise River Water
    final riverPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFB2EBF2), Color(0xFF80DEEA)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.40, size.width, size.height * 0.15));
    canvas.drawPath(riverPath, riverPaint);

    // River Bank Edges
    final bankPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(riverPath, bankPaint);
  }

  void _drawAlgebrixPath(Canvas canvas, Size size) {
    final roadPath = Path();
    final points = List.generate(10, (i) => _getNodePosition(i, mapWidth, mapHeight));

    roadPath.moveTo(points[0].dx, points[0].dy + 40);
    roadPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midY = (p0.dy + p1.dy) / 2;

      roadPath.cubicTo(
        p0.dx,
        midY,
        p1.dx,
        midY,
        p1.dx,
        p1.dy,
      );
    }

    roadPath.lineTo(points.last.dx, points.last.dy - 40);

    // 1. Outer Pastel Pink / Purple Glow Ribbon (Wide)
    final shadowPaint = Paint()
      ..color = AppColors.lightPink.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 72
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(roadPath, shadowPaint);

    // 2. Crisp White Stepping Road
    final whiteRoadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 58
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(roadPath, whiteRoadPaint);

    // 3. Inner Lavender Track
    final innerPaint = Paint()
      ..color = AppColors.lightPurple.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(roadPath, innerPaint);

    // 4. Pedestal Bases under each Node
    for (final pt in points) {
      // Soft shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pt.dx, pt.dy + 14), width: 80, height: 44),
        Paint()..color = Colors.black.withValues(alpha: 0.08),
      );
      // Clean white pedestal
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pt.dx, pt.dy + 10), width: 76, height: 40),
        Paint()..color = Colors.white,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pt.dx, pt.dy + 8), width: 72, height: 36),
        Paint()..color = AppColors.extraLightPink,
      );
    }
  }

  void _drawPastelBridge(Canvas canvas, Size size) {
    final bridgeCenter = Offset(size.width * 0.29, size.height * 0.465);

    final plankPaint = Paint()..color = AppColors.lightPurple;
    final plankHighlight = Paint()..color = Colors.white;

    canvas.save();
    canvas.translate(bridgeCenter.dx, bridgeCenter.dy);
    canvas.rotate(0.24);

    // Draw wooden/pastel planks
    for (int i = -3; i <= 3; i++) {
      final y = i * 11.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, y), width: 68, height: 8.5),
          const Radius.circular(3),
        ),
        plankHighlight,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(0, y + 3), width: 68, height: 2),
        plankPaint,
      );
    }

    // Side Rails
    final railPaint = Paint()
      ..color = AppColors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawLine(const Offset(-32, -36), const Offset(-32, 36), railPaint);
    canvas.drawLine(const Offset(32, -36), const Offset(32, 36), railPaint);

    canvas.restore();
  }

  void _drawMathBlocksAndScales(Canvas canvas, Size size) {
    // ── 1. Giant Summit Balance Scale Monument (Near Level 10) ───────────────
    _drawGiantBalanceScaleMonument(
      canvas,
      Offset(size.width * 0.70, size.height * 0.07),
    );

    // ── 2. Mid-Mountain Balance Scale Milestone (Between Level 4 & 5) ────────
    _drawMiniBalanceScale(
      canvas,
      Offset(size.width * 0.22, size.height * 0.60),
    );

    // ── 3. 3D Isometric Math Blocks across the map ───────────────────────────
    // [ x ] Mint Block near Level 1
    _draw3DMathBlock(
      canvas,
      center: Offset(size.width * 0.15, size.height * 0.90),
      size: 42,
      label: 'x',
      color: AppColors.mint,
      textColor: const Color(0xFF0F7263),
    );

    // Stacked Toy Blocks (1, 2, 3) near Start
    _draw3DMathBlock(
      canvas,
      center: Offset(size.width * 0.78, size.height * 0.94),
      size: 34,
      label: '1',
      color: AppColors.pink,
      textColor: Colors.white,
    );
    _draw3DMathBlock(
      canvas,
      center: Offset(size.width * 0.86, size.height * 0.92),
      size: 34,
      label: '2',
      color: AppColors.yellow,
      textColor: const Color(0xFF7B5A00),
    );
    _draw3DMathBlock(
      canvas,
      center: Offset(size.width * 0.82, size.height * 0.87),
      size: 32,
      label: '3',
      color: AppColors.purple,
      textColor: Colors.white,
    );

    // [ +3 ] Pink Block near Level 3
    _draw3DMathBlock(
      canvas,
      center: Offset(size.width * 0.88, size.height * 0.78),
      size: 40,
      label: '+3',
      color: AppColors.pink,
      textColor: Colors.white,
    );

    // [ = ] Golden Block near Level 5
    _draw3DMathBlock(
      canvas,
      center: Offset(size.width * 0.80, size.height * 0.58),
      size: 38,
      label: '=',
      color: AppColors.yellow,
      textColor: const Color(0xFF7B5A00),
    );

    // [ 2x ] Purple Block near Level 6
    _draw3DMathBlock(
      canvas,
      center: Offset(size.width * 0.12, size.height * 0.48),
      size: 42,
      label: '2x',
      color: AppColors.purple,
      textColor: Colors.white,
    );

    // [ −5 ] Pink Block near Level 8
    _draw3DMathBlock(
      canvas,
      center: Offset(size.width * 0.18, size.height * 0.32),
      size: 40,
      label: '−5',
      color: AppColors.pink,
      textColor: Colors.white,
    );

    // [ ÷2 ] Mint Block near Level 9
    _draw3DMathBlock(
      canvas,
      center: Offset(size.width * 0.86, size.height * 0.22),
      size: 40,
      label: '÷2',
      color: AppColors.mint,
      textColor: const Color(0xFF0F7263),
    );

    // ── 4. Floating Pastel Clouds & Star Sparkles ────────────────────────────
    _drawFluffyCloud(canvas, Offset(size.width * 0.82, size.height * 0.12), 48);
    _drawFluffyCloud(canvas, Offset(size.width * 0.16, size.height * 0.20), 40);
    _drawFluffyCloud(canvas, Offset(size.width * 0.88, size.height * 0.40), 44);
    _drawFluffyCloud(canvas, Offset(size.width * 0.10, size.height * 0.75), 42);

    // Star Sparkles
    _drawSparkle(canvas, Offset(size.width * 0.50, size.height * 0.14), const Color(0xFFFFB300), 10);
    _drawSparkle(canvas, Offset(size.width * 0.88, size.height * 0.05), AppColors.pink, 12);
    _drawSparkle(canvas, Offset(size.width * 0.25, size.height * 0.42), AppColors.mint, 9);
    _drawSparkle(canvas, Offset(size.width * 0.70, size.height * 0.70), const Color(0xFFFFB300), 11);
  }

  void _draw3DMathBlock(
    Canvas canvas, {
    required Offset center,
    required double size,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    final half = size / 2;
    final depth = size * 0.28;

    // Drop shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + half + 6), width: size * 1.3, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    // 3D Right Side Depth Face (Darker)
    final rightFace = Path()
      ..moveTo(center.dx + half, center.dy - half)
      ..lineTo(center.dx + half + depth, center.dy - half - depth * 0.6)
      ..lineTo(center.dx + half + depth, center.dy + half - depth * 0.6)
      ..lineTo(center.dx + half, center.dy + half)
      ..close();
    canvas.drawPath(
      rightFace,
      Paint()..color = _darken(color, 0.25),
    );

    // 3D Top Depth Face (Lighter)
    final topFace = Path()
      ..moveTo(center.dx - half, center.dy - half)
      ..lineTo(center.dx - half + depth, center.dy - half - depth * 0.6)
      ..lineTo(center.dx + half + depth, center.dy - half - depth * 0.6)
      ..lineTo(center.dx + half, center.dy - half)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()..color = _lighten(color, 0.20),
    );

    // Front Face
    final frontRect = Rect.fromCenter(center: center, width: size, height: size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, Radius.circular(size * 0.2)),
      Paint()..color = color,
    );

    // Front Face Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, Radius.circular(size * 0.2)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Label Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: GoogleFonts.nunito(
          fontSize: size * 0.44,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  void _drawGiantBalanceScaleMonument(Canvas canvas, Offset center) {
    final baseColor = AppColors.purple;
    final goldBeam = const Color(0xFFFFB300);
    final goldDish = const Color(0xFFFFD54F);

    // Soft Monument Glow
    canvas.drawCircle(
      center,
      50,
      Paint()..color = AppColors.lightPurple.withValues(alpha: 0.5),
    );

    // Fulcrum Base Stand
    final fulcrumPath = Path()
      ..moveTo(center.dx, center.dy - 12)
      ..lineTo(center.dx - 18, center.dy + 20)
      ..lineTo(center.dx + 18, center.dy + 20)
      ..close();
    canvas.drawPath(fulcrumPath, Paint()..color = baseColor);

    // Pivot Pin
    canvas.drawCircle(
      Offset(center.dx, center.dy - 12),
      5,
      Paint()..color = AppColors.pink,
    );

    // Golden Balance Crossbar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 12), width: 66, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = goldBeam,
    );

    // Suspension Chains
    final chainPaint = Paint()
      ..color = const Color(0xFFB07D38)
      ..strokeWidth = 1.8;
    // Left Chain
    canvas.drawLine(Offset(center.dx - 26, center.dy - 12), Offset(center.dx - 26, center.dy + 4), chainPaint);
    // Right Chain
    canvas.drawLine(Offset(center.dx + 26, center.dy - 12), Offset(center.dx + 26, center.dy + 4), chainPaint);

    // Weighing Dishes
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx - 26, center.dy + 6), width: 22, height: 14),
      0,
      math.pi,
      false,
      Paint()..color = goldDish,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx + 26, center.dy + 6), width: 22, height: 14),
      0,
      math.pi,
      false,
      Paint()..color = goldDish,
    );

    // Block [x] inside left dish!
    _draw3DMathBlock(
      canvas,
      center: Offset(center.dx - 26, center.dy - 2),
      size: 16,
      label: 'x',
      color: AppColors.mint,
      textColor: const Color(0xFF0F7263),
    );

    // Weights [5] inside right dish!
    _draw3DMathBlock(
      canvas,
      center: Offset(center.dx + 26, center.dy - 2),
      size: 16,
      label: '5',
      color: AppColors.pink,
      textColor: Colors.white,
    );
  }

  void _drawMiniBalanceScale(Canvas canvas, Offset center) {
    final goldBeam = const Color(0xFFFFB300);

    // Base
    final fulcrumPath = Path()
      ..moveTo(center.dx, center.dy - 8)
      ..lineTo(center.dx - 12, center.dy + 12)
      ..lineTo(center.dx + 12, center.dy + 12)
      ..close();
    canvas.drawPath(fulcrumPath, Paint()..color = AppColors.pink);

    // Crossbar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 8), width: 44, height: 4),
        const Radius.circular(2),
      ),
      Paint()..color = goldBeam,
    );

    // Dishes
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx - 18, center.dy + 2), width: 14, height: 9),
      0,
      math.pi,
      false,
      Paint()..color = const Color(0xFFFFD54F),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx + 18, center.dy + 2), width: 14, height: 9),
      0,
      math.pi,
      false,
      Paint()..color = const Color(0xFFFFD54F),
    );
  }

  void _drawFluffyCloud(Canvas canvas, Offset center, double width) {
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);

    // Cloud shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 8), width: width * 1.1, height: 16),
      Paint()..color = AppColors.lightPurple.withValues(alpha: 0.25),
    );

    // Multi-puff cloud body
    canvas.drawCircle(Offset(center.dx - width * 0.25, center.dy), width * 0.28, cloudPaint);
    canvas.drawCircle(Offset(center.dx, center.dy - width * 0.12), width * 0.36, cloudPaint);
    canvas.drawCircle(Offset(center.dx + width * 0.25, center.dy), width * 0.26, cloudPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 4), width: width * 0.8, height: width * 0.35),
        Radius.circular(width * 0.18),
      ),
      cloudPaint,
    );
  }

  void _drawSparkle(Canvas canvas, Offset center, Color color, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  Color _darken(Color c, [double percent = 0.2]) {
    final f = 1 - percent;
    return Color.fromARGB(
      (c.a * 255).round(),
      ((c.r * 255) * f).round().clamp(0, 255),
      ((c.g * 255) * f).round().clamp(0, 255),
      ((c.b * 255) * f).round().clamp(0, 255),
    );
  }

  Color _lighten(Color c, [double percent = 0.2]) {
    return Color.fromARGB(
      (c.a * 255).round(),
      (((c.r * 255) + (255 - (c.r * 255)) * percent)).round().clamp(0, 255),
      (((c.g * 255) + (255 - (c.g * 255)) * percent)).round().clamp(0, 255),
      (((c.b * 255) + (255 - (c.b * 255)) * percent)).round().clamp(0, 255),
    );
  }

  @override
  bool shouldRepaint(covariant _AlgebrixMapLandscapePainter oldDelegate) {
    return completedLevels.length != oldDelegate.completedLevels.length ||
        mapWidth != oldDelegate.mapWidth ||
        mapHeight != oldDelegate.mapHeight;
  }
}
