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
/// - Illustrated Mascot Xy placed in spacious open realms of the map:
///     • Lower Valley: `xy-sit-pencil` studying math concepts
///     • Mid Highlands: `xy-balance` balancing on the scale
///     • Summit Mountain: `xy-and-chemie` conducting math experiments
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
                            clipBehavior: Clip.none,
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

                              // ── Mascot Xy Waypoint 1 (Lower Valley Meadow - Pic 1) ──────────
                              Positioned(
                                left: mapWidth * 0.10,
                                top: _mapCanvasHeight * 0.58,
                                child: _MapMascotWaypoint(
                                  asset: AppAssets.xySitPencil,
                                  size: 140,
                                  bubbleText: 'Equation balancing! ✏️',
                                  bubbleColor: AppColors.pink,
                                ),
                              ),

                              // ── Mascot Xy Waypoint 2 (Mid-Highlands Meadow - Pic 2) ─────────
                              Positioned(
                                right: mapWidth * 0.08,
                                top: _mapCanvasHeight * 0.35,
                                child: _MapMascotWaypoint(
                                  asset: AppAssets.xyBalance,
                                  size: 145,
                                  bubbleText: 'Keep it balanced! ⚖️',
                                  bubbleColor: AppColors.purple,
                                ),
                              ),

                              // ── Mascot Xy Waypoint 3 (Upper-Left Summit Meadow - Pic 3) ────
                              Positioned(
                                left: mapWidth * 0.08,
                                top: _mapCanvasHeight * 0.10,
                                child: _MapMascotWaypoint(
                                  asset: AppAssets.xyAndChemie,
                                  size: 145,
                                  bubbleText: 'Summit Master! 🧪✨',
                                  bubbleColor: AppColors.mint,
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
                                  top: pos.dy - 44,
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
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Image.asset(
                              earned
                                  ? AppAssets.star
                                  : AppAssets.starSilhouette,
                              width: 32,
                              height: 32,
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
// Map Mascot Waypoint Widget (Placed in Spacious Open Map Realms)
// =============================================================================

class _MapMascotWaypoint extends StatelessWidget {
  const _MapMascotWaypoint({
    required this.asset,
    required this.size,
    required this.bubbleText,
    required this.bubbleColor,
  });

  final String asset;
  final double size;
  final String bubbleText;
  final Color bubbleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speech Dialogue Bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bubbleColor.withValues(alpha: 0.4),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: bubbleColor.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            bubbleText,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Mascot with Soft Shadow Aura
        XyMascot(
          asset: asset,
          size: size,
          shadowBlur: 10.0,
          shadowOpacity: 0.24,
        ),
      ],
    );
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
                Image.asset(
                  AppAssets.star,
                  width: 22,
                  height: 22,
                ),
                const SizedBox(width: 5),
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
        height: 88,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Arched Stars above node
            Positioned(
              top: -12,
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
            Container(
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
          child: Image.asset(
            earned ? AppAssets.star : AppAssets.starSilhouette,
            width: 22,
            height: 22,
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

    // ── 2. 3D Isometric Pastel Toy Blocks across the map ───────────────────
    // Stacked Toy Blocks (1, 2, 3) near Start on the right
    _drawToyAlphabetBlock(
      canvas,
      center: Offset(size.width * 0.80, size.height * 0.94),
      size: 44,
      label: '1',
      color: const Color(0xFFEDA0D8), // Pastel Pink (Block 1 in ref)
      faceLeft: false,
      rotation: -0.06,
    );
    _drawToyAlphabetBlock(
      canvas,
      center: Offset(size.width * 0.90, size.height * 0.90),
      size: 44,
      label: '2',
      color: const Color(0xFFF6C774), // Pastel Yellow (Block 4 in ref)
      faceLeft: true,
      rotation: 0.08,
    );
    _drawToyAlphabetBlock(
      canvas,
      center: Offset(size.width * 0.84, size.height * 0.84),
      size: 42,
      label: '3',
      color: const Color(0xFF64C7E8), // Sky Blue (Block 5 in ref)
      faceLeft: false,
      rotation: -0.04,
    );

    // [ +3 ] Pastel Yellow Block near Level 3 (Right)
    _drawToyAlphabetBlock(
      canvas,
      center: Offset(size.width * 0.88, size.height * 0.77),
      size: 48,
      label: '+3',
      color: const Color(0xFFF6C774),
      faceLeft: false,
      rotation: 0.07,
    );

    // [ 2x ] Purple Block near Level 4 (Left - below Waypoint 1)
    _drawToyAlphabetBlock(
      canvas,
      center: Offset(size.width * 0.12, size.height * 0.76),
      size: 48,
      label: '2x',
      color: const Color(0xFFC7A2E7),
      faceLeft: true,
      rotation: -0.08,
    );

    // [ = ] Mint Green Block near Level 5 (Right)
    _drawToyAlphabetBlock(
      canvas,
      center: Offset(size.width * 0.82, size.height * 0.56),
      size: 46,
      label: '=',
      color: const Color(0xFF86E0B4), // Pastel Mint (Block N in ref)
      faceLeft: false,
      rotation: -0.05,
    );

    // [ −5 ] Pink Block near Level 7 (Right - above Waypoint 2)
    _drawToyAlphabetBlock(
      canvas,
      center: Offset(size.width * 0.86, size.height * 0.26),
      size: 48,
      label: '−5',
      color: const Color(0xFFEDA0D8),
      faceLeft: true,
      rotation: 0.09,
    );

    // [ ÷2 ] Sky Blue Block near Summit (Right)
    _drawToyAlphabetBlock(
      canvas,
      center: Offset(size.width * 0.84, size.height * 0.18),
      size: 46,
      label: '÷2',
      color: const Color(0xFF64C7E8),
      faceLeft: false,
      rotation: -0.07,
    );

    // ── 3. Floating Pastel Clouds ───────────────────────────────────────────
    _drawFluffyCloud(canvas, Offset(size.width * 0.82, size.height * 0.12), 48);
    _drawFluffyCloud(canvas, Offset(size.width * 0.16, size.height * 0.10), 40);
    _drawFluffyCloud(canvas, Offset(size.width * 0.88, size.height * 0.40), 44);
    _drawFluffyCloud(canvas, Offset(size.width * 0.10, size.height * 0.86), 42);
  }

  void _drawToyAlphabetBlock(
    Canvas canvas, {
    required Offset center,
    required double size,
    required String label,
    required Color color,
    required bool faceLeft, // true: right face visible, false: left face visible
    double rotation = 0.0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (rotation != 0.0) {
      canvas.rotate(rotation);
    }

    final sideDir = faceLeft ? 1.0 : -1.0;
    final w = size * 0.86;
    final h = size * 0.86;
    final extX = sideDir * size * 0.28;
    final extY = -size * 0.24;

    // ── 1. Soft Ground Shadow ───────────────────────────────────────────────
    final shadowOffset = Offset(extX * 0.35, h * 0.52 + 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowOffset,
        width: size * 1.35,
        height: size * 0.38,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // ── 2. Top Face ─────────────────────────────────────────────────────────
    final topFacePath = Path()
      ..moveTo(-w / 2, -h / 2)
      ..lineTo(w / 2, -h / 2)
      ..lineTo(w / 2 + extX, -h / 2 + extY)
      ..lineTo(-w / 2 + extX, -h / 2 + extY)
      ..close();
    canvas.drawPath(topFacePath, Paint()..color = _lighten(color, 0.28));

    // Top Face Inset Cream Panel
    final topInnerInset = 0.72;
    final topInnerPath = Path()
      ..moveTo(
        (-w / 2) * topInnerInset + extX * (1 - topInnerInset) * 0.5,
        -h / 2 + extY * 0.14,
      )
      ..lineTo(
        (w / 2) * topInnerInset + extX * (1 - topInnerInset) * 0.5,
        -h / 2 + extY * 0.14,
      )
      ..lineTo((w / 2) * topInnerInset + extX * 0.86, -h / 2 + extY * 0.86)
      ..lineTo((-w / 2) * topInnerInset + extX * 0.86, -h / 2 + extY * 0.86)
      ..close();
    canvas.drawPath(topInnerPath, Paint()..color = const Color(0xFFFFFDF2));

    // ── 3. Side Face (Left or Right) ────────────────────────────────────────
    final sideFacePath = Path();
    if (sideDir == -1.0) {
      // Left Face
      sideFacePath
        ..moveTo(-w / 2, -h / 2)
        ..lineTo(-w / 2, h / 2)
        ..lineTo(-w / 2 + extX, h / 2 + extY)
        ..lineTo(-w / 2 + extX, -h / 2 + extY)
        ..close();
    } else {
      // Right Face
      sideFacePath
        ..moveTo(w / 2, -h / 2)
        ..lineTo(w / 2, h / 2)
        ..lineTo(w / 2 + extX, h / 2 + extY)
        ..lineTo(w / 2 + extX, -h / 2 + extY)
        ..close();
    }
    canvas.drawPath(sideFacePath, Paint()..color = _darken(color, 0.18));

    // Side Face Inset Cream/Beige Panel
    final sideInnerPath = Path();
    if (sideDir == -1.0) {
      sideInnerPath
        ..moveTo(-w / 2 + extX * 0.14, (-h / 2) * 0.72)
        ..lineTo(-w / 2 + extX * 0.14, (h / 2) * 0.72)
        ..lineTo(-w / 2 + extX * 0.86, (h / 2) * 0.72 + extY * 0.72)
        ..lineTo(-w / 2 + extX * 0.86, (-h / 2) * 0.72 + extY * 0.72)
        ..close();
    } else {
      sideInnerPath
        ..moveTo(w / 2 + extX * 0.14, (-h / 2) * 0.72)
        ..lineTo(w / 2 + extX * 0.14, (h / 2) * 0.72)
        ..lineTo(w / 2 + extX * 0.86, (h / 2) * 0.72 + extY * 0.72)
        ..lineTo(w / 2 + extX * 0.86, (-h / 2) * 0.72 + extY * 0.72)
        ..close();
    }
    canvas.drawPath(sideInnerPath, Paint()..color = const Color(0xFFEFE8D8));

    // ── 4. Front Face Outer Frame ───────────────────────────────────────────
    final frontRect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, const Radius.circular(5)),
      Paint()..color = color,
    );

    // Front Face Inset Cream Panel
    final innerW = w * 0.70;
    final innerH = h * 0.70;
    final innerRect = Rect.fromCenter(
      center: Offset.zero,
      width: innerW,
      height: innerH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFFFFFDF2),
    );

    // Front Face Inner Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(3)),
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── 5. Corner Sparkle Stars on Front Cream Panel ─────────────────────────
    final starRadius = innerW * 0.055;
    final starInset = innerW * 0.36;
    _drawMiniStar(canvas, Offset(-starInset, -starInset), color, starRadius);
    _drawMiniStar(canvas, Offset(starInset, -starInset), color, starRadius);
    _drawMiniStar(canvas, Offset(-starInset, starInset), color, starRadius);
    _drawMiniStar(canvas, Offset(starInset, starInset), color, starRadius);

    // ── 6. 3D Raised Embossed Number in Center ──────────────────────────────
    final fontSize = innerH * 0.62;
    // Number drop shadow
    final shadowPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: GoogleFonts.nunito(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: _darken(color, 0.28),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    shadowPainter.paint(
      canvas,
      Offset(-shadowPainter.width / 2 + 1.8, -shadowPainter.height / 2 + 2.2),
    );

    // Main 3D Number
    final numPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: GoogleFonts.nunito(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    numPainter.paint(
      canvas,
      Offset(-numPainter.width / 2, -numPainter.height / 2),
    );

    canvas.restore();
  }

  void _drawMiniStar(Canvas canvas, Offset center, Color color, double r) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final double outerAngle = -math.pi / 2 + i * (2 * math.pi / 5);
      final double innerAngle = outerAngle + math.pi / 5;
      final double x1 = center.dx + r * math.cos(outerAngle);
      final double y1 = center.dy + r * math.sin(outerAngle);
      final double x2 = center.dx + (r * 0.45) * math.cos(innerAngle);
      final double y2 = center.dy + (r * 0.45) * math.sin(innerAngle);
      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      path.lineTo(x2, y2);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.85));
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
    _drawToyAlphabetBlock(
      canvas,
      center: Offset(center.dx - 26, center.dy - 4),
      size: 18,
      label: 'x',
      color: const Color(0xFF86E0B4),
      faceLeft: false,
    );

    // Weights [5] inside right dish!
    _drawToyAlphabetBlock(
      canvas,
      center: Offset(center.dx + 26, center.dy - 4),
      size: 18,
      label: '5',
      color: const Color(0xFFF6C774),
      faceLeft: true,
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
