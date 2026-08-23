import 'package:algebrix/core/animations/app_page_route.dart';
import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/models/quest_map_model.dart';
import 'package:algebrix/screens/practice/balance_scale_screen.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/xy_mascot.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Quest Map screen showing a vertical level path for a single land.
///
/// Each level node displays its number, star count, lock state, and difficulty.
/// Tapping an unlocked node navigates to the BalanceScaleScreen for that level.
class QuestMapScreen extends StatefulWidget {
  const QuestMapScreen({super.key});

  @override
  State<QuestMapScreen> createState() => _QuestMapScreenState();
}

class _QuestMapScreenState extends State<QuestMapScreen> {
  @override
  void initState() {
    super.initState();
    // Load quest map data on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestMapProvider>().loadQuestMap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestMapProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const SecondaryPageAppBar(
              title: 'Balands',
              supportingText: 'The Land of Balancing',
            ),

            // Star Progress Banner
            _StarProgressBanner(
              starsEarned: provider.activeLandStars,
              maxStars: 30,
            ),

            // Level Path
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.pink,
                      ),
                    )
                  : _LevelPathList(provider: provider),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Star Progress Banner
// =============================================================================

class _StarProgressBanner extends StatelessWidget {
  const _StarProgressBanner({
    required this.starsEarned,
    required this.maxStars,
  });

  final int starsEarned;
  final int maxStars;

  @override
  Widget build(BuildContext context) {
    final progress = maxStars > 0 ? starsEarned / maxStars : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFE082),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.star_rounded,
              color: Color(0xFFFFB300),
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$starsEarned / $maxStars Stars',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFFFE082).withValues(alpha: 0.4),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFB300),
                      ),
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
}

// =============================================================================
// Level Path List
// =============================================================================

class _LevelPathList extends StatelessWidget {
  const _LevelPathList({required this.provider});

  final QuestMapProvider provider;

  @override
  Widget build(BuildContext context) {
    final defs = provider.levelDefinitions;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Xy mascot at the top of the map
          XyMascot(
            asset: AppAssets.xyPractice,
            size: 80,
            shadowBlur: 4.0,
            shadowOpacity: 0.18,
          ),
          const SizedBox(height: 6),
          Text(
            'Begin your journey!',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Level nodes
          for (int i = 0; i < defs.length; i++) ...[
            if (i > 0) _PathConnector(
              isCompleted: provider.starsForLevel(defs[i - 1].levelNumber) > 0,
            ),
            _LevelNode(
              definition: defs[i],
              starsEarned: provider.starsForLevel(defs[i].levelNumber),
              bestMoves: provider.bestMovesForLevel(defs[i].levelNumber),
              isUnlocked: provider.isLevelUnlocked(defs[i].levelNumber),
              onTap: () => _navigateToLevel(context, defs[i].levelNumber),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _navigateToLevel(BuildContext context, int levelNumber) {
    Navigator.push(
      context,
      AppPageRoute(
        child: BalanceScaleScreen(
          questLevelNumber: levelNumber,
        ),
      ),
    ).then((_) {
      // Refresh progress when returning from the balance scale.
      provider.loadQuestMap();
    });
  }
}

// =============================================================================
// Path Connector (dotted line between levels)
// =============================================================================

class _PathConnector extends StatelessWidget {
  const _PathConnector({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Center(
        child: CustomPaint(
          size: const Size(2, 36),
          painter: _DottedLinePainter(
            color: isCompleted ? AppColors.mint : AppColors.border,
          ),
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const dashHeight = 5.0;
    const gapHeight = 4.0;
    double y = 0;

    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dashHeight).clamp(0, size.height)),
        paint,
      );
      y += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}

// =============================================================================
// Level Node
// =============================================================================

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.definition,
    required this.starsEarned,
    required this.bestMoves,
    required this.isUnlocked,
    required this.onTap,
  });

  final QuestLevelDefinition definition;
  final int starsEarned;
  final int? bestMoves;
  final bool isUnlocked;
  final VoidCallback onTap;

  bool get _isCompleted => starsEarned > 0;

  Color get _nodeColor {
    if (!isUnlocked) return AppColors.border;
    if (_isCompleted) return AppColors.mint;
    return AppColors.pink;
  }

  Color get _nodeSurfaceColor {
    if (!isUnlocked) return AppColors.background;
    if (_isCompleted) return AppColors.lightMint;
    return AppColors.extraLightPink;
  }

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      shrinkFactor: isUnlocked ? 0.96 : 1.0,
      enableHaptics: isUnlocked,
      onTap: isUnlocked ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _nodeColor.withValues(alpha: isUnlocked ? 0.5 : 0.25),
            width: isUnlocked ? 2 : 1.5,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: _nodeColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Level Number Circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _nodeSurfaceColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _nodeColor.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: isUnlocked
                    ? Text(
                        '${definition.levelNumber}',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _nodeColor,
                        ),
                      )
                    : Icon(
                        Icons.lock_rounded,
                        color: AppColors.border,
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Level Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Level ${definition.levelNumber}',
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: isUnlocked
                              ? AppColors.text
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Difficulty Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _difficultyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          definition.difficultyLabel,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _difficultyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    definition.description,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Star Row
                  Row(
                    children: [
                      ...List.generate(3, (i) {
                        final earned = i < starsEarned;
                        return Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Icon(
                            earned
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 20,
                            color: earned
                                ? const Color(0xFFFFB300)
                                : AppColors.border,
                          ),
                        );
                      }),
                      if (bestMoves != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '$bestMoves moves',
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow or Lock
            if (isUnlocked)
              Icon(
                Icons.play_circle_fill_rounded,
                color: _nodeColor,
                size: 32,
              ),
          ],
        ),
      ),
    );
  }

  Color get _difficultyColor {
    if (definition.difficulty <= 3) return AppColors.mint;
    if (definition.difficulty <= 6) return AppColors.yellow;
    if (definition.difficulty <= 8) return AppColors.pink;
    return AppColors.purple;
  }
}
