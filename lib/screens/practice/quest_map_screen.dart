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

/// Full Game World Map Screen for "Balands — The Land of Balancing".
///
/// Features a winding S-curve dirt pathway climbing from Level 1 at the valley
/// to Level 10 at the mountain summit. Includes rich illustrated landscape
/// elements (river, wooden bridge, hollow log, trees, flowers, rocks), 3D tactile
/// stepping-stone nodes, 3-star arches, and Xy mascot perched on the active level.
class QuestMapScreen extends StatefulWidget {
  const QuestMapScreen({super.key});

  @override
  State<QuestMapScreen> createState() => _QuestMapScreenState();
}

class _QuestMapScreenState extends State<QuestMapScreen> {
  final ScrollController _scrollController = ScrollController();
  static const double _mapCanvasHeight = 1560.0;

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
    final targetScroll = (nodePos.dy - 300).clamp(
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
      backgroundColor: const Color(0xFF73C873),
      body: Stack(
        children: [
          // ─── 1. Scrollable Illustrated World Map ───────────────────────────
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
                              // Background Illustrated Landscape (Painter)
                              Positioned.fill(
                                child: CustomPaint(
                                  size: Size(mapWidth, _mapCanvasHeight),
                                  painter: _GameMapLandscapePainter(
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
                                  child: _GameLevelNode(
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

              // Target Equation Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
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
  // 10 levels: Level 1 (index 0) at the bottom valley, Level 10 (index 9) at the summit.
  final t = index / 9.0; // 0.0 (bottom) to 1.0 (top)

  // Vertical placement (from bottom Y ~1400 to top Y ~200)
  final y = (mapHeight - 160.0) - (t * (mapHeight - 340.0));

  // Horizontal snaking curve across width
  // Uses custom tuned points to create natural S-turns matching Picture 2
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
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.text,
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
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🗺️', style: TextStyle(fontSize: 18)),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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
// 3D Game Level Stepping Node Widget
// =============================================================================

class _GameLevelNode extends StatelessWidget {
  const _GameLevelNode({
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
                            color: Colors.black26,
                            blurRadius: 4,
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

            // Arched Stars above node (when completed or unlocked)
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
                  // Wooden / Stone 3D Pedestal Base
                  color: !isUnlocked
                      ? const Color(0xFF607D8B)
                      : (_isCompleted
                          ? const Color(0xFFB87333) // Bronze/wood rim
                          : const Color(0xFFC2185B)), // Active pink rim
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                    if (isNextPlayable)
                      BoxShadow(
                        color: AppColors.pink.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.5),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Inner Glossy Gradient
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: !isUnlocked
                            ? [
                                const Color(0xFFCFD8DC),
                                const Color(0xFF90A4AE),
                              ]
                            : (_isCompleted
                                ? [
                                    const Color(0xFF4FC3F7),
                                    const Color(0xFF0288D1),
                                  ]
                                : [
                                    const Color(0xFFFF69B4),
                                    const Color(0xFFE91E63),
                                  ]),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: !isUnlocked
                          ? const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFFECEFF1),
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
                                    color: Colors.black38,
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
                : const Color(0xFFB0BEC5).withValues(alpha: 0.6),
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
// Game Map Landscape Custom Painter
// =============================================================================

class _GameMapLandscapePainter extends CustomPainter {
  _GameMapLandscapePainter({
    required this.mapWidth,
    required this.mapHeight,
    required this.completedLevels,
  });

  final double mapWidth;
  final double mapHeight;
  final List<int> completedLevels;

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Lush Green Landscape Gradient Background ──────────────────────────
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF5EBA5E), // Mountain summit forest green
          Color(0xFF76CD76), // Mid highland grass
          Color(0xFF86D986), // Low valley meadow
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // ── 2. Rolling Green Hills & Elevation Shading ───────────────────────────
    _drawHill(canvas, size, 0.20 * size.height, const Color(0xFF4DA84D));
    _drawHill(canvas, size, 0.45 * size.height, const Color(0xFF62BC62));
    _drawHill(canvas, size, 0.75 * size.height, const Color(0xFF70C970));

    // ── 3. Winding Blue Creek / River ────────────────────────────────────────
    _drawRiver(canvas, size);

    // ── 4. Winding S-Curve Sandy Road ────────────────────────────────────────
    _drawSandyRoad(canvas, size);

    // ── 5. Wooden Bridge crossing the River ──────────────────────────────────
    _drawWoodenBridge(canvas, size);

    // ── 6. Scenery Details: Trees, Logs, Rocks, Flowers ──────────────────────
    _drawSceneryElements(canvas, size);
  }

  void _drawHill(Canvas canvas, Size size, double topY, Color color) {
    final path = Path()
      ..moveTo(0, topY)
      ..cubicTo(
        size.width * 0.35,
        topY - 45,
        size.width * 0.70,
        topY + 35,
        size.width,
        topY - 20,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  void _drawRiver(Canvas canvas, Size size) {
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

    // River Water
    final riverPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.40, size.width, size.height * 0.15));
    canvas.drawPath(riverPath, riverPaint);

    // River Bank Edges
    final bankPaint = Paint()
      ..color = const Color(0xFFB2DFDB).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(riverPath, bankPaint);

    // Lily Pads
    _drawLilyPad(canvas, Offset(size.width * 0.18, size.height * 0.45));
    _drawLilyPad(canvas, Offset(size.width * 0.82, size.height * 0.46));
  }

  void _drawLilyPad(Canvas canvas, Offset center) {
    final paint = Paint()..color = const Color(0xFF388E3C);
    canvas.drawCircle(center, 9, paint);
    // Flower dot
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFFFF80AB));
  }

  void _drawSandyRoad(Canvas canvas, Size size) {
    final roadPath = Path();

    // Construct smooth continuous spline through all 10 node coordinates
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

    // Top finish line extending past Level 10
    roadPath.lineTo(points.last.dx, points.last.dy - 40);

    // 1. Road Dirt Shadow / Earth Border (Wide)
    final shadowPaint = Paint()
      ..color = const Color(0xFFC7A263)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 72
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(roadPath, shadowPaint);

    // 2. Main Sand / Cobblestone Road
    final sandPaint = Paint()
      ..color = const Color(0xFFFBE4B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 58
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(roadPath, sandPaint);

    // 3. Inner Trail Highlights (Footpath)
    final innerPaint = Paint()
      ..color = const Color(0xFFFFF2D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(roadPath, innerPaint);

    // 4. Pedestal Bases under each Node
    for (final pt in points) {
      // Wood base ring
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pt.dx, pt.dy + 12), width: 78, height: 44),
        Paint()..color = const Color(0xFF8D5B28),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pt.dx, pt.dy + 8), width: 74, height: 40),
        Paint()..color = const Color(0xFFC48E56),
      );
    }
  }

  void _drawWoodenBridge(Canvas canvas, Size size) {
    // Bridge at crossing point between Level 7 and Level 8 (around Y = 680, X = 0.32)
    final bridgeCenter = Offset(size.width * 0.29, size.height * 0.465);

    // Bridge Planks
    final plankPaint = Paint()..color = const Color(0xFF9E642E);
    final plankHighlight = Paint()..color = const Color(0xFFD49E6A);

    canvas.save();
    canvas.translate(bridgeCenter.dx, bridgeCenter.dy);
    canvas.rotate(0.24); // Slight angle to match road curve

    // Draw 6 wooden planks
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

    // Wooden Side Rails
    final railPaint = Paint()
      ..color = const Color(0xFF6D4016)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawLine(const Offset(-32, -36), const Offset(-32, 36), railPaint);
    canvas.drawLine(const Offset(32, -36), const Offset(32, 36), railPaint);

    canvas.restore();
  }

  void _drawSceneryElements(Canvas canvas, Size size) {
    // ── Hollow Log (Picture 2 inspired) ──────────────────────────────────────
    _drawHollowLog(canvas, Offset(size.width * 0.82, size.height * 0.58));

    // ── Milestone Direction Sign ─────────────────────────────────────────────
    _drawWoodenSign(canvas, Offset(size.width * 0.38, size.height * 0.72));

    // ── Cartoon Trees ────────────────────────────────────────────────────────
    _drawTree(canvas, Offset(size.width * 0.12, size.height * 0.92), 26);
    _drawTree(canvas, Offset(size.width * 0.88, size.height * 0.88), 30);
    _drawTree(canvas, Offset(size.width * 0.10, size.height * 0.65), 32);
    _drawTree(canvas, Offset(size.width * 0.88, size.height * 0.35), 34);
    _drawTree(canvas, Offset(size.width * 0.14, size.height * 0.24), 28);
    _drawTree(canvas, Offset(size.width * 0.22, size.height * 0.08), 36);

    // ── Wildflowers ──────────────────────────────────────────────────────────
    _drawFlower(canvas, Offset(size.width * 0.22, size.height * 0.85), const Color(0xFFFF80AB));
    _drawFlower(canvas, Offset(size.width * 0.60, size.height * 0.82), const Color(0xFFFFD54F));
    _drawFlower(canvas, Offset(size.width * 0.84, size.height * 0.76), const Color(0xFFBA68C8));
    _drawFlower(canvas, Offset(size.width * 0.44, size.height * 0.56), const Color(0xFFFF80AB));
    _drawFlower(canvas, Offset(size.width * 0.78, size.height * 0.22), const Color(0xFFFFD54F));

    // ── Summit Balance Monument (Near Level 10) ──────────────────────────────
    _drawSummitScaleMonument(canvas, Offset(size.width * 0.68, size.height * 0.06));
  }

  void _drawTree(Canvas canvas, Offset root, double radius) {
    // Tree Trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(root.dx, root.dy + 8), width: 10, height: 20),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF795548),
    );

    // Tree Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(root.dx, root.dy + 16), width: radius * 1.6, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Fluffy Green Foliage
    final foliageDark = Paint()..color = const Color(0xFF2E7D32);
    final foliageLight = Paint()..color = const Color(0xFF4CAF50);
    final foliageTop = Paint()..color = const Color(0xFF81C784);

    canvas.drawCircle(Offset(root.dx, root.dy - 2), radius, foliageDark);
    canvas.drawCircle(Offset(root.dx, root.dy - 6), radius * 0.85, foliageLight);
    canvas.drawCircle(Offset(root.dx - 3, root.dy - 10), radius * 0.65, foliageTop);
  }

  void _drawHollowLog(Canvas canvas, Offset center) {
    // Hollow log matching reference image
    final logBody = Paint()..color = const Color(0xFF8D5B28);
    final logRing = Paint()..color = const Color(0xFFD49E6A);
    final logHole = Paint()..color = const Color(0xFF3E2723);

    // Outer body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 62, height: 34),
        const Radius.circular(8),
      ),
      logBody,
    );

    // End cross-section ring
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - 22, center.dy), width: 18, height: 32),
      logRing,
    );
    // Dark hollow opening
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - 22, center.dy), width: 12, height: 24),
      logHole,
    );
  }

  void _drawWoodenSign(Canvas canvas, Offset center) {
    // Post
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 10), width: 6, height: 22),
      Paint()..color = const Color(0xFF6D4016),
    );
    // Board
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 34, height: 16),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFB07D38),
    );
  }

  void _drawFlower(Canvas canvas, Offset center, Color color) {
    final petalPaint = Paint()..color = color;
    canvas.drawCircle(Offset(center.dx - 3, center.dy), 3, petalPaint);
    canvas.drawCircle(Offset(center.dx + 3, center.dy), 3, petalPaint);
    canvas.drawCircle(Offset(center.dx, center.dy - 3), 3, petalPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + 3), 3, petalPaint);
    // Center dot
    canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFFFFF9C4));
  }

  void _drawSummitScaleMonument(Canvas canvas, Offset center) {
    // Golden Balance Scale Icon / Arch at summit
    final goldPaint = Paint()..color = const Color(0xFFFFD700);
    final amberPaint = Paint()..color = const Color(0xFFFFA000);

    // Fulcrum Base
    final path = Path()
      ..moveTo(center.dx, center.dy - 10)
      ..lineTo(center.dx - 14, center.dy + 14)
      ..lineTo(center.dx + 14, center.dy + 14)
      ..close();
    canvas.drawPath(path, amberPaint);

    // Scale Beam
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 10), width: 42, height: 5),
        const Radius.circular(2),
      ),
      goldPaint,
    );

    // Scale Dishes
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx - 16, center.dy - 2), width: 14, height: 10),
      0,
      math.pi,
      false,
      goldPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx + 16, center.dy - 2), width: 14, height: 10),
      0,
      math.pi,
      false,
      goldPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GameMapLandscapePainter oldDelegate) {
    return completedLevels.length != oldDelegate.completedLevels.length ||
        mapWidth != oldDelegate.mapWidth ||
        mapHeight != oldDelegate.mapHeight;
  }
}
