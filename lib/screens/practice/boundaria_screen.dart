import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/boundaria_provider.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/models/boundaria_problem.dart';
import 'package:algebrix/services/sound_service.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// Boundaria's palette: pastel celestial cartography rather than the playroom
/// of Balands or the tropics of Pairadise.
abstract final class _Sky {
  static const ground = Color(0xFFF7F5FD);
  static const plate = Color(0xFFFFFFFF);
  static const fog = Color(0xFFE8E4F2);
  static const gridLine = Color(0xFFE4DEF3);
  static const axis = Color(0xFF9A8FB8);
  static const ink = Color(0xFF3B3355);
  static const gold = Color(0xFFE8B84B);
  static const claimed = Color(0xFFCDEFE6);
  static const beacon = Color(0xFF7C6BB5);
}

/// Gameplay screen for **Boundaria — The Land of Boundaries**.
///
/// Runs the Claim the Region loop: plot the anchor, walk the slope, choose the
/// barrier, send the scout, claim the territory. Which of those a level asks
/// for is the level's business, not this screen's — it renders whatever stage
/// the provider says is current.
class BoundariaScreen extends StatefulWidget {
  const BoundariaScreen({super.key, this.questLevelNumber});

  final int? questLevelNumber;

  @override
  State<BoundariaScreen> createState() => _BoundariaScreenState();
}

class _BoundariaScreenState extends State<BoundariaScreen> {
  late final int _levelNumber = widget.questLevelNumber ?? 1;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BoundariaProvider>().startLevel(_levelNumber);
    });
  }

  void _maybeShowResult(BoundariaProvider provider) {
    if (_resultShown || !provider.isSolved) return;
    _resultShown = true;

    final stars = provider.starsEarned;
    context.read<QuestMapProvider>().submitLevelResult(
          landId: 'boundaria',
          levelNumber: _levelNumber,
          moveCount: provider.totalPhaseCount,
          optimalMoves: provider.totalPhaseCount,
          reasoningPassed: stars == 3,
          starsEarned: stars,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SoundService.playComplete();
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _ResultDialog(
          provider: provider,
          onReplay: () {
            Navigator.of(dialogContext).pop();
            setState(() => _resultShown = false);
            provider.restart();
          },
          onLeave: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop();
          },
        ),
      );
    });
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _HowToPlaySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoundariaProvider>();
    final problem = provider.problem;

    if (problem == null) {
      return const Scaffold(
        backgroundColor: _Sky.ground,
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }

    _maybeShowResult(provider);

    return Scaffold(
      backgroundColor: _Sky.ground,
      appBar: AppBar(
        backgroundColor: _Sky.ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const Key('boundaria-back'),
          icon: const Icon(Icons.arrow_back_rounded, color: _Sky.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Level ${problem.levelNumber} — ${problem.title}',
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: _Sky.ink,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('boundaria-how-to-play'),
            tooltip: 'How to Play',
            icon: const Icon(
              Icons.help_outline_rounded,
              color: _Sky.axis,
            ),
            onPressed: () => _showHowToPlay(context),
          ),
          IconButton(
            key: const Key('boundaria-hint'),
            tooltip: 'Hint',
            icon: Icon(
              Icons.lightbulb_outline_rounded,
              color: provider.hintVisible ? _Sky.gold : _Sky.axis,
            ),
            onPressed: provider.toggleHint,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _RuleHeader(provider: provider, problem: problem),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: problem.phases.contains(BoundariaPhase.inspectMaps)
                    ? _BrokenMapBoard(provider: provider, problem: problem)
                    : _TerritoryBoard(provider: provider, problem: problem),
              ),
            ),
            _ControlDeck(provider: provider, problem: problem),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top: the territory rule and the three stars
// ─────────────────────────────────────────────────────────────────────────────

class _RuleHeader extends StatelessWidget {
  const _RuleHeader({required this.provider, required this.problem});

  final BoundariaProvider provider;
  final BoundariaProblem problem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _Sky.plate,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Sky.gridLine),
      ),
      child: Column(
        children: [
          Text(
            'TERRITORY RULE',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: _Sky.axis,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              problem.displayedRule,
              key: const Key('boundaria-rule'),
              style: GoogleFonts.nunito(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: _Sky.ink,
              ),
            ),
          ),
          // Once rearranged, keep the solved form on screen — it is what every
          // later stage is actually working from.
          if (problem.needsRearranging &&
              provider.completedPhaseCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              problem.solvedRule,
              key: const Key('boundaria-solved-rule'),
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.purple,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _ActiveTermCard(phase: provider.currentPhase, problem: problem),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final star in BoundariaStar.values) ...[
                Icon(
                  provider.hasStar(star)
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 22,
                  color: provider.hasStar(star) ? _Sky.gold : _Sky.fog,
                ),
                const SizedBox(width: 2),
              ],
            ],
          ),
          if (provider.hintVisible) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.lightYellow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                problem.hintDialogue,
                key: const Key('boundaria-hint-text'),
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7A5C10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formula syntax highlight badge
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveTermCard extends StatelessWidget {
  const _ActiveTermCard({required this.phase, required this.problem});

  final BoundariaPhase? phase;
  final BoundariaProblem problem;

  @override
  Widget build(BuildContext context) {
    if (phase == null) return const SizedBox.shrink();

    final ({Color accent, Color background, IconData icon, String label, String description}) info =
        switch (phase!) {
      BoundariaPhase.rearrange => (
          accent: AppColors.purple,
          background: AppColors.lightPurple.withValues(alpha: 0.5),
          icon: Icons.transform_rounded,
          label: 'Algebra Stage: Isolate y',
          description: 'Rearrange the rule into slope-intercept form (y > mx + b)',
        ),
      BoundariaPhase.plotIntercept => (
          accent: AppColors.mint,
          background: AppColors.lightMint,
          icon: Icons.pin_drop_rounded,
          label: 'Anchor: y-intercept (b = ${problem.intercept})',
          description: 'Find (0, ${problem.intercept}) where the border touches the vertical y-axis',
        ),
      BoundariaPhase.buildSlope => (
          accent: AppColors.purple,
          background: AppColors.lightPurple,
          icon: Icons.directions_walk_rounded,
          label: 'Slope Guide: m = ${problem.riseOverRun.rise}/${problem.riseOverRun.run}',
          description:
              'From your anchor, step ${problem.riseOverRun.run} right and ${problem.riseOverRun.rise.abs()} ${problem.riseOverRun.rise < 0 ? 'down' : 'up'}',
        ),
      BoundariaPhase.chooseBoundary => (
          accent: const Color(0xFF9A6B00),
          background: AppColors.lightYellow,
          icon: Icons.line_style_rounded,
          label: 'Barrier Type: "${problem.sign.symbol}"',
          description: problem.sign.includesBoundary
              ? 'Solid border ━ (Points on the line count: ≤ or ≥)'
              : 'Dashed border ✦ (Points on the line excluded: < or >)',
        ),
      BoundariaPhase.scout => (
          accent: AppColors.mint,
          background: AppColors.lightMint,
          icon: Icons.explore_rounded,
          label: 'Scout Exploration',
          description: 'Test a location to see if it satisfies the inequality',
        ),
      BoundariaPhase.claim => (
          accent: AppColors.mint,
          background: AppColors.lightMint,
          icon: Icons.auto_awesome_rounded,
          label: 'Claim Territory',
          description:
              'Shade the half-plane that contains the solutions (${problem.sign.solutionIsAbove ? 'Above ▲' : 'Below ▼'})',
        ),
      BoundariaPhase.inspectMaps => (
          accent: AppColors.purple,
          background: AppColors.lightPurple,
          icon: Icons.map_rounded,
          label: 'Cartographer Inspection',
          description: 'Identify the map that correctly follows the rule',
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: info.accent.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(info.icon, size: 18, color: info.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  info.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: info.accent,
                  ),
                ),
                Text(
                  info.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    height: 1.2,
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

class _CoordinateInspectorPill extends StatelessWidget {
  const _CoordinateInspectorPill({
    required this.hoverPoint,
    required this.phase,
  });

  final ({int x, int y})? hoverPoint;
  final BoundariaPhase? phase;

  @override
  Widget build(BuildContext context) {
    if (hoverPoint == null) return const SizedBox.shrink();

    final pt = hoverPoint!;
    final isYAxis = pt.x == 0;
    final isXAxis = pt.y == 0;
    final isOrigin = pt.x == 0 && pt.y == 0;

    final badge = isOrigin
        ? 'Origin'
        : isYAxis
            ? 'y-axis'
            : isXAxis
                ? 'x-axis'
                : null;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.extraLightPink.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.pink, width: 1.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.my_location_rounded, size: 13, color: AppColors.darkPink),
            const SizedBox(width: 5),
            Text(
              '(${pt.x}, ${pt.y})',
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: AppColors.darkPink,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Middle: the territory itself
// ─────────────────────────────────────────────────────────────────────────────

class _TerritoryBoard extends StatefulWidget {
  const _TerritoryBoard({required this.provider, required this.problem});

  final BoundariaProvider provider;
  final BoundariaProblem problem;

  @override
  State<_TerritoryBoard> createState() => _TerritoryBoardState();
}

class _TerritoryBoardState extends State<_TerritoryBoard> {
  ({int x, int y})? _hoverPoint;

  /// Lattice points are only tappable while a stage is asking for one.
  bool get _acceptsTaps {
    final phase = widget.provider.currentPhase;
    return phase == BoundariaPhase.plotIntercept ||
        phase == BoundariaPhase.buildSlope ||
        (phase == BoundariaPhase.scout && !widget.problem.scoutPointIsFixed);
  }

  void _handleTap(int x, int y) {
    if (mounted) {
      setState(() => _hoverPoint = (x: x, y: y));
    }
    switch (widget.provider.currentPhase) {
      case BoundariaPhase.plotIntercept:
      case BoundariaPhase.buildSlope:
        widget.provider.plotPoint(x, y);
      case BoundariaPhase.scout:
        widget.provider.sendScout(x, y);
      default:
        break;
    }
  }

  void _handlePan(Offset localPos, double dimension, int range) {
    if (!_acceptsTaps || dimension <= 0 || !mounted) return;
    final span = range * 2;
    final unit = dimension / span;
    final gx = ((localPos.dx / unit) - range).round().clamp(-range, range);
    final gy = (range - (localPos.dy / unit)).round().clamp(-range, range);
    if (_hoverPoint?.x != gx || _hoverPoint?.y != gy) {
      setState(() {
        _hoverPoint = (x: gx, y: gy);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = widget.problem.gridRange;
    final ticks = [for (var v = -range; v <= range; v++) v];
    final acceptsTaps = _acceptsTaps;
    final activeHover = acceptsTaps ? _hoverPoint : null;
    final showSlopeGuide = widget.provider.currentPhase == BoundariaPhase.buildSlope &&
        widget.provider.interceptBeacon != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 380, maxWidth: 380),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _Sky.plate,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _Sky.gridLine, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanDown: (details) =>
                        _handlePan(details.localPosition, constraints.maxWidth, range),
                    onPanUpdate: (details) =>
                        _handlePan(details.localPosition, constraints.maxWidth, range),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TerritoryPainter(
                              problem: widget.problem,
                              showLine: widget.provider.hasBoundaryLine,
                              style: widget.provider.chosenStyle ?? widget.problem.correctStyle,
                              styleDecided: widget.provider.chosenStyle != null ||
                                  !widget.problem.phases.contains(BoundariaPhase.chooseBoundary),
                              claimed: widget.provider.claimedSide,
                              beacons: [
                                if (widget.provider.interceptBeacon != null)
                                  widget.provider.interceptBeacon!,
                                if (widget.provider.slopeBeacon != null)
                                  widget.provider.slopeBeacon!,
                              ],
                              scout: widget.provider.scoutPoint,
                              scoutVerdict: widget.provider.scoutVerdict,
                              hoverPoint: activeHover,
                              showSlopeGuide: showSlopeGuide,
                            ),
                          ),
                        ),
                        // Floating coordinate HUD pill overlay
                        if (activeHover != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _CoordinateInspectorPill(
                              hoverPoint: activeHover,
                              phase: widget.provider.currentPhase,
                            ),
                          ),
                        // A transparent tap target per lattice point.
                        if (acceptsTaps)
                          Column(
                            children: [
                              for (final y in ticks.reversed)
                                Expanded(
                                  child: Row(
                                    children: [
                                      for (final x in ticks)
                                        Expanded(
                                          child: GestureDetector(
                                            key: Key('boundaria-cell-${x}_$y'),
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _handleTap(x, y),
                                            child: const SizedBox.expand(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TerritoryPainter extends CustomPainter {
  _TerritoryPainter({
    required this.problem,
    required this.showLine,
    required this.style,
    required this.styleDecided,
    required this.claimed,
    required this.beacons,
    required this.scout,
    required this.scoutVerdict,
    this.hoverPoint,
    this.showSlopeGuide = false,
  });

  final BoundariaProblem problem;
  final bool showLine;
  final BoundaryStyle style;
  final bool styleDecided;
  final TerritorySide? claimed;
  final List<({int x, int y})> beacons;
  final ({int x, int y})? scout;
  final ScoutVerdict? scoutVerdict;
  final ({int x, int y})? hoverPoint;
  final bool showSlopeGuide;

  @override
  void paint(Canvas canvas, Size size) {
    final range = problem.gridRange;
    final span = range * 2;
    final unit = size.width / span;

    Offset toScreen(double x, double y) =>
        Offset((x + range) * unit, (range - y) * unit);

    // Fog everywhere until a territory is claimed, then colour the winning
    // side and leave the other faded — the picture a linear inequality makes.
    canvas.drawRect(Offset.zero & size, Paint()..color = _Sky.plate);

    if (showLine) {
      final solutionPath = _sidePath(size, toScreen, problem.correctSide);
      final otherPath = _sidePath(
        size,
        toScreen,
        problem.correctSide == TerritorySide.above
            ? TerritorySide.below
            : TerritorySide.above,
      );

      if (claimed == null) {
        canvas.drawPath(solutionPath, Paint()..color = _Sky.fog);
        canvas.drawPath(otherPath, Paint()..color = _Sky.fog);
      } else {
        canvas.drawPath(solutionPath, Paint()..color = _Sky.claimed);
        canvas.drawPath(otherPath, Paint()..color = _Sky.fog.withValues(alpha: 0.55));
      }
    }

    final grid = Paint()
      ..color = _Sky.gridLine
      ..strokeWidth = 1;
    for (var i = -range; i <= range; i++) {
      canvas.drawLine(
        toScreen(i.toDouble(), -range.toDouble()),
        toScreen(i.toDouble(), range.toDouble()),
        grid,
      );
      canvas.drawLine(
        toScreen(-range.toDouble(), i.toDouble()),
        toScreen(range.toDouble(), i.toDouble()),
        grid,
      );
    }

    final axis = Paint()
      ..color = _Sky.axis
      ..strokeWidth = 2;
    canvas.drawLine(
      toScreen(-range.toDouble(), 0),
      toScreen(range.toDouble(), 0),
      axis,
    );
    canvas.drawLine(
      toScreen(0, -range.toDouble()),
      toScreen(0, range.toDouble()),
      axis,
    );

    // Axis tick marks & coordinate number labels (every 2 units)
    final axisTickPaint = Paint()
      ..color = _Sky.axis.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    for (var i = -range; i <= range; i++) {
      if (i == 0) continue;
      // Tick mark on X-axis
      final xPos = toScreen(i.toDouble(), 0);
      canvas.drawLine(
        Offset(xPos.dx, xPos.dy - 3),
        Offset(xPos.dx, xPos.dy + 3),
        axisTickPaint,
      );

      // Tick mark on Y-axis
      final yPos = toScreen(0, i.toDouble());
      canvas.drawLine(
        Offset(yPos.dx - 3, yPos.dy),
        Offset(yPos.dx + 3, yPos.dy),
        axisTickPaint,
      );

      // Number labels every 2 units
      if (i % 2 == 0 && i.abs() < range) {
        // X label
        final xSpan = TextSpan(
          text: '$i',
          style: GoogleFonts.nunito(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: _Sky.axis.withValues(alpha: 0.8),
          ),
        );
        final xPainter = TextPainter(
          text: xSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        xPainter.paint(
          canvas,
          Offset(xPos.dx - xPainter.width / 2, xPos.dy + 4),
        );

        // Y label
        final ySpan = TextSpan(
          text: '$i',
          style: GoogleFonts.nunito(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: _Sky.axis.withValues(alpha: 0.8),
          ),
        );
        final yPainter = TextPainter(
          text: ySpan,
          textDirection: TextDirection.ltr,
        )..layout();
        yPainter.paint(
          canvas,
          Offset(yPos.dx - yPainter.width - 5, yPos.dy - yPainter.height / 2),
        );
      }
    }

    // Label the X and Y axes
    final xLabelPainter = TextPainter(
      text: TextSpan(
        text: 'x',
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: _Sky.axis,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xLabelPainter.paint(
      canvas,
      Offset(toScreen(range.toDouble(), 0).dx - 12, toScreen(range.toDouble(), 0).dy + 4),
    );

    final yLabelPainter = TextPainter(
      text: TextSpan(
        text: 'y',
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: _Sky.axis,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yLabelPainter.paint(
      canvas,
      Offset(toScreen(0, range.toDouble()).dx + 4, toScreen(0, range.toDouble()).dy + 2),
    );

    // Slope guide staircase: illustrates rise and run from intercept beacon
    if (showSlopeGuide && beacons.isNotEmpty) {
      final anchor = beacons.first;
      final target = problem.slopeStepPoint;
      final start = toScreen(anchor.x.toDouble(), anchor.y.toDouble());
      final corner = toScreen(target.x.toDouble(), anchor.y.toDouble());
      final end = toScreen(target.x.toDouble(), target.y.toDouble());

      final slopeGuidePaint = Paint()
        ..color = AppColors.purple.withValues(alpha: 0.55)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;

      _drawDashed(canvas, start, corner, slopeGuidePaint);
      _drawDashed(canvas, corner, end, slopeGuidePaint);

      // Target ghost beacon indicator
      canvas.drawCircle(
        end,
        8,
        Paint()
          ..color = AppColors.purple.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        end,
        8,
        Paint()
          ..color = AppColors.purple
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Crosshair through active/hovered point
    if (hoverPoint != null) {
      final hp = toScreen(hoverPoint!.x.toDouble(), hoverPoint!.y.toDouble());
      final crossPaint = Paint()
        ..color = AppColors.purple.withValues(alpha: 0.35)
        ..strokeWidth = 1.2;
      _drawDashed(canvas, Offset(0, hp.dy), Offset(size.width, hp.dy), crossPaint);
      _drawDashed(canvas, Offset(hp.dx, 0), Offset(hp.dx, size.height), crossPaint);

      // Targeting reticle
      canvas.drawCircle(hp, 13, Paint()..color = AppColors.purple.withValues(alpha: 0.15));
      canvas.drawCircle(
        hp,
        7,
        Paint()
          ..color = AppColors.purple
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    if (showLine) {
      final a = _boundaryPointAt(-range.toDouble());
      final b = _boundaryPointAt(range.toDouble());
      final paint = Paint()
        ..color = styleDecided ? AppColors.purple : _Sky.axis
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      if (style == BoundaryStyle.solid) {
        canvas.drawLine(toScreen(a.dx, a.dy), toScreen(b.dx, b.dy), paint);
      } else {
        _drawDashed(canvas, toScreen(a.dx, a.dy), toScreen(b.dx, b.dy), paint);
      }
    }

    for (final beacon in beacons) {
      final centre = toScreen(beacon.x.toDouble(), beacon.y.toDouble());
      canvas.drawCircle(centre, 9, Paint()..color = _Sky.gold.withValues(alpha: 0.35));
      canvas.drawCircle(centre, 5.5, Paint()..color = _Sky.beacon);
      canvas.drawCircle(
        centre,
        5.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    if (scout != null) {
      final centre = toScreen(scout!.x.toDouble(), scout!.y.toDouble());
      final colour = switch (scoutVerdict) {
        ScoutVerdict.belongs => AppColors.mint,
        ScoutVerdict.doesNotBelong => AppColors.pink,
        _ => _Sky.gold,
      };
      // Soft radar ripple & glowing core
      canvas.drawCircle(centre, 16, Paint()..color = colour.withValues(alpha: 0.18));
      canvas.drawCircle(centre, 10, Paint()..color = colour.withValues(alpha: 0.35));
      canvas.drawCircle(centre, 6.5, Paint()..color = colour);
      canvas.drawCircle(
        centre,
        6.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );

      // Coordinate tag pinned above scout
      final tagSpan = TextSpan(
        text: '(${scout!.x}, ${scout!.y})',
        style: GoogleFonts.nunito(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: colour,
        ),
      );
      final tagPainter = TextPainter(text: tagSpan, textDirection: TextDirection.ltr)..layout();
      tagPainter.paint(
        canvas,
        Offset(centre.dx - tagPainter.width / 2, centre.dy - tagPainter.height - 8),
      );
    }
  }

  /// The boundary's y at [x], in graph coordinates.
  Offset _boundaryPointAt(double x) {
    final slope = problem.riseOverRun.rise / problem.riseOverRun.run;
    return Offset(x, slope * x + problem.intercept);
  }

  /// A filled region covering one side of the barrier.
  Path _sidePath(
    Size size,
    Offset Function(double, double) toScreen,
    TerritorySide side,
  ) {
    final range = problem.gridRange.toDouble();
    final left = _boundaryPointAt(-range);
    final right = _boundaryPointAt(range);
    final edge = side == TerritorySide.above ? range : -range;

    return Path()
      ..moveTo(toScreen(left.dx, left.dy).dx, toScreen(left.dx, left.dy).dy)
      ..lineTo(toScreen(right.dx, right.dy).dx, toScreen(right.dx, right.dy).dy)
      ..lineTo(toScreen(range, edge).dx, toScreen(range, edge).dy)
      ..lineTo(toScreen(-range, edge).dx, toScreen(-range, edge).dy)
      ..close();
  }

  void _drawDashed(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 10.0;
    const gap = 7.0;
    final total = (to - from).distance;
    if (total == 0) return;
    final step = (to - from) / total;

    var travelled = 0.0;
    while (travelled < total) {
      final end = (travelled + dash).clamp(0.0, total);
      canvas.drawLine(from + step * travelled, from + step * end, paint);
      travelled = end + gap;
    }
  }

  @override
  bool shouldRepaint(_TerritoryPainter old) =>
      old.showLine != showLine ||
      old.style != style ||
      old.styleDecided != styleDecided ||
      old.claimed != claimed ||
      old.beacons.length != beacons.length ||
      old.scout != scout ||
      old.scoutVerdict != scoutVerdict ||
      old.hoverPoint != hoverPoint ||
      old.showSlopeGuide != showSlopeGuide;
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 9: the Cartographer's Archive
// ─────────────────────────────────────────────────────────────────────────────

class _BrokenMapBoard extends StatelessWidget {
  const _BrokenMapBoard({required this.provider, required this.problem});

  final BoundariaProvider provider;
  final BoundariaProblem problem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Which map follows the Territory Rule?',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: _Sky.ink,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final option in problem.mapOptions)
                _MapCard(
                  option: option,
                  problem: problem,
                  isChosen: provider.chosenMapId == option.id,
                  enabled: !provider.isSolved,
                  onTap: () => provider.chooseMap(option.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.option,
    required this.problem,
    required this.isChosen,
    required this.enabled,
    required this.onTap,
  });

  final BoundariaMapOption option;
  final BoundariaProblem problem;
  final bool isChosen;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      onTap: enabled ? onTap : null,
      child: Container(
        key: Key('boundaria-map-${option.id}'),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _Sky.plate,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isChosen ? AppColors.purple : _Sky.gridLine,
            width: isChosen ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              option.label,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: _Sky.ink,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _MapThumbPainter(option: option, problem: problem),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapThumbPainter extends CustomPainter {
  _MapThumbPainter({required this.option, required this.problem});

  final BoundariaMapOption option;
  final BoundariaProblem problem;

  static const double _range = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / (_range * 2);
    Offset toScreen(double x, double y) =>
        Offset((x + _range) * unit, (_range - y) * unit);

    final slope = problem.riseOverRun.rise / problem.riseOverRun.run;
    double lineY(double x) => slope * x + option.intercept;

    canvas.drawRect(Offset.zero & size, Paint()..color = _Sky.plate);

    // The claimed side, so a wrong shade is visible at a glance.
    final edge = option.side == TerritorySide.above ? _range : -_range;
    final region = Path()
      ..moveTo(toScreen(-_range, lineY(-_range)).dx,
          toScreen(-_range, lineY(-_range)).dy)
      ..lineTo(
          toScreen(_range, lineY(_range)).dx, toScreen(_range, lineY(_range)).dy)
      ..lineTo(toScreen(_range, edge).dx, toScreen(_range, edge).dy)
      ..lineTo(toScreen(-_range, edge).dx, toScreen(-_range, edge).dy)
      ..close();
    canvas.drawPath(region, Paint()..color = _Sky.claimed);

    final grid = Paint()
      ..color = _Sky.gridLine
      ..strokeWidth = 0.6;
    for (var i = -_range.toInt(); i <= _range.toInt(); i += 2) {
      canvas.drawLine(
          toScreen(i.toDouble(), -_range), toScreen(i.toDouble(), _range), grid);
      canvas.drawLine(
          toScreen(-_range, i.toDouble()), toScreen(_range, i.toDouble()), grid);
    }

    final axis = Paint()
      ..color = _Sky.axis
      ..strokeWidth = 1.2;
    canvas.drawLine(toScreen(-_range, 0), toScreen(_range, 0), axis);
    canvas.drawLine(toScreen(0, -_range), toScreen(0, _range), axis);

    final paint = Paint()
      ..color = AppColors.purple
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final from = toScreen(-_range, lineY(-_range));
    final to = toScreen(_range, lineY(_range));

    if (option.style == BoundaryStyle.solid) {
      canvas.drawLine(from, to, paint);
    } else {
      const dash = 6.0;
      const gap = 4.0;
      final total = (to - from).distance;
      final step = (to - from) / total;
      var travelled = 0.0;
      while (travelled < total) {
        final end = (travelled + dash).clamp(0.0, total);
        canvas.drawLine(from + step * travelled, from + step * end, paint);
        travelled = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_MapThumbPainter old) => old.option.id != option.id;
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom: controls for the current stage only
// ─────────────────────────────────────────────────────────────────────────────

class _ControlDeck extends StatelessWidget {
  const _ControlDeck({required this.provider, required this.problem});

  final BoundariaProvider provider;
  final BoundariaProblem problem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Sky.plate,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Sky.gridLine),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.feedback != null) ...[
            if (provider.scoutVerdict != null && provider.scoutPoint != null)
              _ScoutReportDialogue(provider: provider, problem: problem)
            else
              Text(
                provider.feedback!,
                key: const Key('boundaria-feedback'),
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: provider.feedbackIsError ? AppColors.error : _Sky.ink,
                ),
              ),
            const SizedBox(height: 10),
          ] else ...[
            Text(
              problem.introDialogue,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
          ],
          _controlsFor(provider.currentPhase),
        ],
      ),
    );
  }

  Widget _controlsFor(BoundariaPhase? phase) {
    switch (phase) {
      case BoundariaPhase.rearrange:
        return Column(
          children: [
            _Prompt('Solve the rule for y'),
            const SizedBox(height: 8),
            for (var i = 0; i < problem.rearrangeOptions.length; i++) ...[
              _WideChoice(
                optionKey: Key('boundaria-rearrange-$i'),
                label: problem.rearrangeOptions[i],
                onTap: () => provider.chooseRearrangeOption(i),
              ),
              if (i < problem.rearrangeOptions.length - 1)
                const SizedBox(height: 6),
            ],
          ],
        );

      case BoundariaPhase.plotIntercept:
        return _Prompt('Tap where the border crosses the y-axis');

      case BoundariaPhase.buildSlope:
        final rise = problem.riseOverRun.rise;
        final run = problem.riseOverRun.run;
        return _Prompt(
          'Now walk the slope: $run right, '
          '${rise.abs()} ${rise < 0 ? 'down' : 'up'}',
        );

      case BoundariaPhase.chooseBoundary:
        return Row(
          children: [
            Expanded(
              child: _Choice(
                optionKey: const Key('boundaria-style-dashed'),
                label: '✦ Dashed',
                caption: 'Border excluded',
                onTap: () => provider.chooseStyle(BoundaryStyle.dashed),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Choice(
                optionKey: const Key('boundaria-style-solid'),
                label: '━ Solid',
                caption: 'Border included',
                onTap: () => provider.chooseStyle(BoundaryStyle.solid),
              ),
            ),
          ],
        );

      case BoundariaPhase.scout:
        if (problem.scoutPointIsFixed) {
          final point = provider.scoutPoint ?? (x: 0, y: 0);
          return Column(
            children: [
              _Prompt('Send the scout to (${point.x}, ${point.y})'),
              const SizedBox(height: 8),
              _WideChoice(
                optionKey: const Key('boundaria-scout-go'),
                label: '🧭 Test this location',
                onTap: () => provider.sendScout(point.x, point.y),
              ),
            ],
          );
        }
        return _Prompt('Tap a location to send the scout');

      case BoundariaPhase.claim:
        return Row(
          children: [
            Expanded(
              child: _Choice(
                optionKey: const Key('boundaria-claim-above'),
                label: '▲ Above',
                caption: 'Claim this side',
                onTap: () => provider.claimSide(TerritorySide.above),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Choice(
                optionKey: const Key('boundaria-claim-below'),
                label: '▼ Below',
                caption: 'Claim this side',
                onTap: () => provider.claimSide(TerritorySide.below),
              ),
            ),
          ],
        );

      case BoundariaPhase.inspectMaps:
        return _Prompt('Choose the map that follows the rule');

      case null:
        return _Prompt('Territory restored ✨');
    }
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      key: const Key('boundaria-prompt'),
      textAlign: TextAlign.center,
      style: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: AppColors.purple,
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.optionKey,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  final Key optionKey;
  final String label;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      onTap: onTap,
      child: Container(
        key: optionKey,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.lightPurple.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.purple,
              ),
            ),
            Text(
              caption,
              style: GoogleFonts.nunito(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideChoice extends StatelessWidget {
  const _WideChoice({
    required this.optionKey,
    required this.label,
    required this.onTap,
  });

  final Key optionKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      onTap: onTap,
      child: Container(
        key: optionKey,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.lightPurple.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.purple,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result
// ─────────────────────────────────────────────────────────────────────────────

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.provider,
    required this.onReplay,
    required this.onLeave,
  });

  final BoundariaProvider provider;
  final VoidCallback onReplay;
  final VoidCallback onLeave;

  static const _labels = {
    BoundariaStar.boundary: 'Boundary',
    BoundariaStar.border: 'Border',
    BoundariaStar.region: 'Region',
  };

  @override
  Widget build(BuildContext context) {
    final stars = provider.starsEarned;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              stars == 3 ? AppAssets.xyHappy : AppAssets.xyIdea,
              width: 72,
              height: 72,
            ),
            const SizedBox(height: 12),
            Text(
              stars == 3 ? 'Territory restored!' : 'Territory claimed',
              key: const Key('boundaria-result-title'),
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _Sky.ink,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final star in BoundariaStar.values)
                  Icon(
                    provider.hasStar(star)
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 30,
                    color: provider.hasStar(star) ? _Sky.gold : _Sky.fog,
                  ),
              ],
            ),
            Text(
              '$stars / 3 Stars',
              key: const Key('boundaria-result-stars'),
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            // The point of Boundaria's scoring: say which idea landed, rather
            // than counting mistakes.
            for (final star in BoundariaStar.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  key: Key('boundaria-result-${star.name}'),
                  children: [
                    Icon(
                      provider.hasStar(star)
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      size: 17,
                      color: provider.hasStar(star)
                          ? AppColors.mint
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _labels[star]!,
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: _Sky.ink,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      !provider.isExercised(star)
                          ? 'Given'
                          : provider.hasStar(star)
                              ? 'Understood'
                              : 'Needs practice',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('boundaria-result-replay'),
                    onPressed: onReplay,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Replay',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        color: _Sky.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('boundaria-result-continue'),
                    onPressed: onLeave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scout Probe Speech Card
// ─────────────────────────────────────────────────────────────────────────────

class _ScoutReportDialogue extends StatelessWidget {
  const _ScoutReportDialogue({
    required this.provider,
    required this.problem,
  });

  final BoundariaProvider provider;
  final BoundariaProblem problem;

  @override
  Widget build(BuildContext context) {
    final pt = provider.scoutPoint;
    final verdict = provider.scoutVerdict;
    if (pt == null || verdict == null) {
      return Text(
        provider.feedback ?? '',
        key: const Key('boundaria-feedback'),
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: provider.feedbackIsError ? AppColors.error : _Sky.ink,
        ),
      );
    }

    final isBelongs = verdict == ScoutVerdict.belongs;
    final isOnBorder = verdict == ScoutVerdict.onBorder;
    final mascotAsset = isBelongs
        ? AppAssets.xyInsight
        : isOnBorder
            ? AppAssets.xyIdea
            : AppAssets.xyExplaining;

    final badgeColor = isBelongs
        ? AppColors.mint
        : isOnBorder
            ? const Color(0xFF9A6B00)
            : AppColors.pink;

    final bgColor = isBelongs
        ? AppColors.lightMint
        : isOnBorder
            ? AppColors.lightYellow
            : AppColors.extraLightPink;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                mascotAsset,
                width: 38,
                height: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Scout Probe at (${pt.x}, ${pt.y})',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isBelongs
                                ? '✓ Belongs'
                                : isOnBorder
                                    ? '✦ On Line'
                                    : '✗ Outside',
                            style: GoogleFonts.nunito(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Preserves exact feedback string with key for test backward compatibility
                    Text(
                      provider.feedback!,
                      key: const Key('boundaria-feedback'),
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _Sky.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// How to Play Tutorial Modal Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Image.asset(
                    AppAssets.xyExplaining,
                    width: 52,
                    height: 52,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to Play Boundaria',
                          key: const Key('boundaria-how-to-play-title'),
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _Sky.ink,
                          ),
                        ),
                        Text(
                          'Master 3 ideas to earn all 3 stars!',
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
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
              _buildStarRuleCard(
                icon: Icons.push_pin_rounded,
                accentColor: AppColors.purple,
                bgColor: AppColors.lightPurple.withValues(alpha: 0.5),
                title: '⭐ 1. The Boundary (The Line)',
                subtitle: 'Anchor & Slope',
                description:
                    'Drop your anchor at the y-intercept (0, b). Then walk the slope m = rise/run by stepping right by run and up/down by rise.',
              ),
              const SizedBox(height: 10),
              _buildStarRuleCard(
                icon: Icons.line_style_rounded,
                accentColor: const Color(0xFF9A6B00),
                bgColor: AppColors.lightYellow,
                title: '⭐ 2. The Border (The Barrier)',
                subtitle: 'Solid vs. Dashed',
                description:
                    'If the sign has "or equal to" (≤ or ≥), raise a Solid ━ barrier. If it is strict (< or >), raise a Dashed ✦ barrier.',
              ),
              const SizedBox(height: 10),
              _buildStarRuleCard(
                icon: Icons.explore_rounded,
                accentColor: AppColors.mint,
                bgColor: AppColors.lightMint,
                title: '⭐ 3. The Region (The Territory)',
                subtitle: 'Scout & Claim',
                description:
                    'Send a Scout to test any coordinate (like (0, 0)). If the inequality holds true (✓), claim that half-plane!',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('boundaria-how-to-play-close'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Got it, let's explore!",
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRuleCard({
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: _Sky.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subtitle,
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    height: 1.25,
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
