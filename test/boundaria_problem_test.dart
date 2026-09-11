import 'package:algebrix/models/boundaria_problem.dart';
import 'package:algebrix/services/boundaria_problem_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BoundariaProblemService();
  final levels = service.allLevels;

  group('Boundaria level catalogue', () {
    test('ships exactly ten levels, numbered in order', () {
      expect(levels, hasLength(BoundariaProblemService.levelCount));
      for (var i = 0; i < levels.length; i++) {
        expect(levels[i].levelNumber, i + 1);
      }
    });

    test('every level is reachable by number and clamps out of range', () {
      for (var n = 1; n <= 10; n++) {
        expect(service.levelProblem(n).levelNumber, n);
      }
      expect(service.levelProblem(0).levelNumber, 1);
      expect(service.levelProblem(99).levelNumber, 10);
    });

    test('every level has a run that keeps the comparison honest', () {
      // satisfies() scales both sides by the run, which only preserves the
      // inequality while the run is positive.
      for (final level in levels) {
        expect(level.riseOverRun.run, greaterThan(0),
            reason: 'level ${level.levelNumber} has a non-positive run');
      }
    });

    test('every level ends on a stage that can finish it', () {
      for (final level in levels) {
        expect(level.phases, isNotEmpty);
        expect(
          level.phases.last,
          anyOf(BoundariaPhase.claim, BoundariaPhase.inspectMaps),
          reason: 'level ${level.levelNumber} never reaches a claim',
        );
      }
    });

    test('mechanics unlock in the order the land introduces them', () {
      BoundariaProblem at(int n) => service.levelProblem(n);

      // 1–2: no line building at all.
      for (final n in [1, 2]) {
        expect(at(n).phases, isNot(contains(BoundariaPhase.plotIntercept)));
        expect(at(n).phases, isNot(contains(BoundariaPhase.scout)));
      }

      // 3–4: build the line, still no scout.
      for (final n in [3, 4]) {
        expect(at(n).phases, contains(BoundariaPhase.buildSlope));
        expect(at(n).phases, isNot(contains(BoundariaPhase.scout)));
      }

      // 5 onward: the scout is in play.
      for (final n in [5, 6, 7, 8, 10]) {
        expect(at(n).phases, contains(BoundariaPhase.scout),
            reason: 'level $n should use the scout');
      }

      // Rearranging only appears once the rules stop arriving solved for y.
      for (final n in [1, 2, 3, 4, 5, 6]) {
        expect(at(n).needsRearranging, isFalse);
      }
      for (final n in [7, 8, 10]) {
        expect(at(n).needsRearranging, isTrue);
      }
    });

    test('every rearrange level offers its own answer exactly once', () {
      for (final level in levels.where((l) => l.needsRearranging)) {
        expect(level.rearrangeOptions, hasLength(4),
            reason: 'level ${level.levelNumber}');
        expect(
          level.rearrangeOptions.toSet(),
          hasLength(4),
          reason: 'level ${level.levelNumber} repeats an option',
        );
        expect(
          level.rearrangeOptions[level.correctRearrangeIndex],
          level.solvedRule,
          reason: 'level ${level.levelNumber} marks the wrong option correct',
        );
      }
    });

    test('levels that do not rearrange already show the solved rule', () {
      for (final level in levels.where((l) => !l.needsRearranging)) {
        if (level.levelNumber == 9) continue; // shown with a ½ for readability
        expect(level.displayedRule, level.solvedRule,
            reason: 'level ${level.levelNumber} needs a rearrange stage');
      }
    });
  });

  group('Barrier type and territory side', () {
    test('a plain > or < excludes the border', () {
      expect(InequalitySign.greater.includesBoundary, isFalse);
      expect(InequalitySign.less.includesBoundary, isFalse);
      expect(InequalitySign.greaterOrEqual.includesBoundary, isTrue);
      expect(InequalitySign.lessOrEqual.includesBoundary, isTrue);
    });

    test('each level derives the barrier the rule actually calls for', () {
      const expected = <int, BoundaryStyle>{
        1: BoundaryStyle.dashed,
        2: BoundaryStyle.solid,
        3: BoundaryStyle.dashed,
        4: BoundaryStyle.solid,
        5: BoundaryStyle.dashed,
        6: BoundaryStyle.dashed,
        7: BoundaryStyle.dashed,
        8: BoundaryStyle.dashed,
        9: BoundaryStyle.solid,
        10: BoundaryStyle.solid,
      };

      expected.forEach((level, style) {
        expect(service.levelProblem(level).correctStyle, style,
            reason: 'level $level');
      });
    });

    test('each level claims the side its rule points to', () {
      const expected = <int, TerritorySide>{
        1: TerritorySide.above,
        2: TerritorySide.below,
        3: TerritorySide.above,
        4: TerritorySide.above,
        5: TerritorySide.below,
        6: TerritorySide.above,
        7: TerritorySide.above,
        8: TerritorySide.above,
        9: TerritorySide.above,
        10: TerritorySide.above,
      };

      expected.forEach((level, side) {
        expect(service.levelProblem(level).correctSide, side,
            reason: 'level $level');
      });
    });
  });

  group('The scout', () {
    test('level 5 reproduces the worked example from the design', () {
      // y < x + 3 tested at the origin: 0 < 3, which is true.
      final level = service.levelProblem(5);

      expect(level.satisfies(0, 0), isTrue);
      expect(level.sideOf(0, 0), TerritorySide.below);
      expect(level.scoutWorking(0, 0), '0 < 3');
    });

    test('a point on the barrier belongs to neither side', () {
      final level = service.levelProblem(3); // y > x + 1

      expect(level.isOnBoundary(0, 1), isTrue);
      expect(level.sideOf(0, 1), isNull);
      expect(level.isOnBoundary(2, 3), isTrue);
      expect(level.isOnBoundary(0, 0), isFalse);
    });

    test('a strict rule excludes its own border, an inclusive one does not', () {
      final strict = service.levelProblem(3); // y > x + 1
      final inclusive = service.levelProblem(4); // y ≥ 2x − 2

      expect(strict.isOnBoundary(0, 1), isTrue);
      expect(strict.satisfies(0, 1), isFalse,
          reason: '> excludes the border itself');

      expect(inclusive.isOnBoundary(0, -2), isTrue);
      expect(inclusive.satisfies(0, -2), isTrue,
          reason: '≥ includes the border itself');
    });

    test('a fractional slope stays exact rather than drifting', () {
      final level = service.levelProblem(9); // y ≥ ½x − 2

      // (4, 0) sits exactly on the line: ½(4) − 2 = 0.
      expect(level.isOnBoundary(4, 0), isTrue);
      expect(level.satisfies(4, 0), isTrue);

      // (4, -1) is one below it.
      expect(level.isOnBoundary(4, -1), isFalse);
      expect(level.satisfies(4, -1), isFalse);
      expect(level.sideOf(4, -1), TerritorySide.below);

      // An odd x still resolves cleanly: ½(3) − 2 = −0.5.
      expect(level.satisfies(3, 0), isTrue);
      expect(level.satisfies(3, -1), isFalse);
      expect(level.isOnBoundary(3, 0), isFalse);
    });

    test('the suggested scout point never lands on the border', () {
      for (final level in levels) {
        final point = level.suggestedScoutPoint;
        if (point == null) continue;
        expect(
          level.isOnBoundary(point.x, point.y),
          isFalse,
          reason: 'level ${level.levelNumber} suggests a point on the barrier, '
              'which tests nothing',
        );
      }
    });

    test('satisfying the rule and sitting on the solution side agree', () {
      for (final level in levels) {
        for (var x = -4; x <= 4; x++) {
          for (var y = -4; y <= 4; y++) {
            if (level.isOnBoundary(x, y)) continue;
            final onSolutionSide = level.sideOf(x, y) == level.correctSide;
            expect(
              level.satisfies(x, y),
              onSolutionSide,
              reason: 'level ${level.levelNumber} disagrees with itself at '
                  '($x, $y)',
            );
          }
        }
      }
    });
  });

  group('Building the border', () {
    test('the slope step lands one run right and one rise up', () {
      expect(service.levelProblem(3).slopeStepPoint, (x: 1, y: 2));
      expect(service.levelProblem(4).slopeStepPoint, (x: 1, y: 0));
      expect(service.levelProblem(6).slopeStepPoint, (x: 1, y: 1));
      expect(service.levelProblem(9).slopeStepPoint, (x: 2, y: -1));
    });

    test('both beacons sit on the barrier and inside the grid', () {
      for (final level in levels) {
        expect(level.isOnBoundary(0, level.intercept), isTrue,
            reason: 'level ${level.levelNumber} intercept is off its own line');

        final step = level.slopeStepPoint;
        expect(level.isOnBoundary(step.x, step.y), isTrue,
            reason: 'level ${level.levelNumber} slope step is off the line');

        for (final value in [level.intercept, step.x, step.y]) {
          expect(value.abs(), lessThanOrEqualTo(level.gridRange),
              reason: 'level ${level.levelNumber} needs a point off the grid');
        }
      }
    });

    test('solvedRule reads the way a learner would write it', () {
      expect(service.levelProblem(1).solvedRule, 'y > 2');
      expect(service.levelProblem(2).solvedRule, 'y ≤ −1');
      expect(service.levelProblem(3).solvedRule, 'y > x + 1');
      expect(service.levelProblem(4).solvedRule, 'y ≥ 2x − 2');
      expect(service.levelProblem(6).solvedRule, 'y > −x + 2');
      expect(service.levelProblem(7).solvedRule, 'y > −2x + 4');
      expect(service.levelProblem(10).solvedRule, 'y ≥ 2x − 4');
    });
  });

  group('The Broken Map', () {
    final broken = service.levelProblem(9);

    test('offers four maps with exactly one correct', () {
      expect(broken.mapOptions, hasLength(4));
      expect(broken.mapOptions.where((m) => m.isCorrect), hasLength(1));
    });

    test('each wrong map breaks a different star', () {
      final flaws = broken.mapOptions
          .where((m) => !m.isCorrect)
          .map((m) => m.flaw)
          .toSet();

      expect(flaws, {
        BoundariaStar.boundary,
        BoundariaStar.border,
        BoundariaStar.region,
      }, reason: 'a wrong pick should say which idea slipped');
    });

    test('the correct map matches what the rule actually describes', () {
      final correct = broken.mapOptions.firstWhere((m) => m.isCorrect);

      expect(correct.intercept, broken.intercept);
      expect(correct.style, broken.correctStyle);
      expect(correct.side, broken.correctSide);
    });

    test('every wrong map differs from the truth in exactly one way', () {
      for (final map in broken.mapOptions.where((m) => !m.isCorrect)) {
        final differences = [
          map.intercept != broken.intercept,
          map.style != broken.correctStyle,
          map.side != broken.correctSide,
        ].where((d) => d).length;

        expect(differences, 1,
            reason: '${map.label} should isolate one mistake, not blur several');
      }
    });
  });
}
