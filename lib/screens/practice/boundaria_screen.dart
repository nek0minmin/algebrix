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
// Middle: the territory itself
// ─────────────────────────────────────────────────────────────────────────────

class _TerritoryBoard extends StatelessWidget {
  const _TerritoryBoard({required this.provider, required this.problem});

  final BoundariaProvider provider;
  final BoundariaProblem problem;

  /// Lattice points are only tappable while a stage is asking for one.
  bool get _acceptsTaps {
    final phase = provider.currentPhase;
    return phase == BoundariaPhase.plotIntercept ||
        phase == BoundariaPhase.buildSlope ||
        (phase == BoundariaPhase.scout && !problem.scoutPointIsFixed);
  }

  void _handleTap(int x, int y) {
    switch (provider.currentPhase) {
      case BoundariaPhase.plotIntercept:
      case BoundariaPhase.buildSlope:
        provider.plotPoint(x, y);
      case BoundariaPhase.scout:
        provider.sendScout(x, y);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = problem.gridRange;
    final ticks = [for (var v = -range; v <= range; v++) v];

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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TerritoryPainter(
                        problem: problem,
                        showLine: provider.hasBoundaryLine,
                        style: provider.chosenStyle ?? problem.correctStyle,
                        styleDecided: provider.chosenStyle != null ||
                            !problem.phases
                                .contains(BoundariaPhase.chooseBoundary),
                        claimed: provider.claimedSide,
                        beacons: [
                          if (provider.interceptBeacon != null)
                            provider.interceptBeacon!,
                          if (provider.slopeBeacon != null)
                            provider.slopeBeacon!,
                        ],
                        scout: provider.scoutPoint,
                        scoutVerdict: provider.scoutVerdict,
                      ),
                    ),
                  ),
                  // A transparent tap target per lattice point.
                  if (_acceptsTaps)
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
  });

  final BoundariaProblem problem;
  final bool showLine;
  final BoundaryStyle style;
  final bool styleDecided;
  final TerritorySide? claimed;
  final List<({int x, int y})> beacons;
  final ({int x, int y})? scout;
  final ScoutVerdict? scoutVerdict;

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
      canvas.drawCircle(centre, 11, Paint()..color = colour.withValues(alpha: 0.3));
      canvas.drawCircle(centre, 6.5, Paint()..color = colour);
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
      old.scoutVerdict != scoutVerdict;
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
