import 'package:algebrix/core/providers/boundaria_provider.dart';
import 'package:algebrix/models/boundaria_problem.dart';
import 'package:algebrix/services/boundaria_problem_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BoundariaProblemService();

  BoundariaProvider startedAt(int level) =>
      BoundariaProvider()..startLevel(level);

  /// Plays a level perfectly, whatever stages it happens to use.
  void playPerfectly(BoundariaProvider provider) {
    final problem = provider.problem!;
    var guard = 0;

    while (provider.currentPhase != null && guard++ < 20) {
      switch (provider.currentPhase!) {
        case BoundariaPhase.rearrange:
          provider.chooseRearrangeOption(problem.correctRearrangeIndex);
        case BoundariaPhase.plotIntercept:
          provider.plotPoint(0, problem.intercept);
        case BoundariaPhase.buildSlope:
          final step = problem.slopeStepPoint;
          provider.plotPoint(step.x, step.y);
        case BoundariaPhase.chooseBoundary:
          provider.chooseStyle(problem.correctStyle);
        case BoundariaPhase.scout:
          final point = problem.suggestedScoutPoint ?? (x: 0, y: 0);
          provider.sendScout(point.x, point.y);
        case BoundariaPhase.claim:
          provider.claimSide(problem.correctSide);
        case BoundariaPhase.inspectMaps:
          provider.chooseMap(
            problem.mapOptions.firstWhere((m) => m.isCorrect).id,
          );
      }
    }
  }

  group('Starting a level', () {
    test('every level can be played to three stars', () {
      for (var level = 1; level <= 10; level++) {
        final provider = startedAt(level);
        playPerfectly(provider);

        expect(provider.isSolved, isTrue, reason: 'level $level never finished');
        expect(provider.starsEarned, 3, reason: 'level $level');
      }
    });

    test('restarting wipes the board and the stars come back', () {
      final provider = startedAt(4);

      provider.plotPoint(3, 3); // wrong
      expect(provider.hasStar(BoundariaStar.boundary), isFalse);

      provider.restart();

      expect(provider.starsEarned, 3);
      expect(provider.interceptBeacon, isNull);
      expect(provider.currentPhase, BoundariaPhase.plotIntercept);
      expect(provider.isSolved, isFalse);
    });

    test('level 5 arrives with its scout already placed', () {
      final provider = startedAt(5);

      expect(provider.scoutPoint, (x: 0, y: 0));
      expect(provider.problem!.scoutPointIsFixed, isTrue);
      expect(provider.currentPhase, BoundariaPhase.scout);
    });

    test('a level with no construction starts with its border already up', () {
      expect(startedAt(1).hasBoundaryLine, isTrue);
      expect(startedAt(5).hasBoundaryLine, isTrue);
      expect(startedAt(3).hasBoundaryLine, isFalse);
    });
  });

  group('Stars belong to ideas, not to mistake counts', () {
    test('the worked example from the design scores 2 of 3', () {
      // y ≥ 2x − 3 in the design; level 4 is y ≥ 2x − 2 and behaves the same:
      // graph it right, pick dashed instead of solid, shade above correctly.
      final provider = startedAt(4);
      final problem = provider.problem!;

      provider.plotPoint(0, problem.intercept);
      final step = problem.slopeStepPoint;
      provider.plotPoint(step.x, step.y);
      provider.chooseStyle(BoundaryStyle.dashed); // wrong, it is ≥
      provider.claimSide(problem.correctSide);

      expect(provider.starsEarned, 2);
      expect(provider.starBreakdown, {
        BoundariaStar.boundary: true,
        BoundariaStar.border: false,
        BoundariaStar.region: true,
      });
    });

    test('a mistake only costs the star it belongs to', () {
      final provider = startedAt(4);
      final problem = provider.problem!;

      provider.plotPoint(1, 1); // wrong intercept
      provider.plotPoint(0, problem.intercept); // then right
      final step = problem.slopeStepPoint;
      provider.plotPoint(step.x, step.y);
      provider.chooseStyle(problem.correctStyle);
      provider.claimSide(problem.correctSide);

      expect(provider.hasStar(BoundariaStar.boundary), isFalse);
      expect(provider.hasStar(BoundariaStar.border), isTrue);
      expect(provider.hasStar(BoundariaStar.region), isTrue);
    });

    test('repeating the same mistake does not cost a second star', () {
      final provider = startedAt(4);

      provider.plotPoint(3, 3);
      provider.plotPoint(4, 4);
      provider.plotPoint(5, 5);

      expect(provider.starsEarned, 2, reason: 'one idea, one star');
    });

    test('a level reports which stars it actually tests', () {
      // Levels 1 and 2 never build a line, so Boundary is given, not earned.
      final gardens = startedAt(1);
      expect(gardens.isExercised(BoundariaStar.boundary), isFalse);
      expect(gardens.isExercised(BoundariaStar.border), isTrue);
      expect(gardens.isExercised(BoundariaStar.region), isTrue);

      // Level 5 only teaches the scout.
      final observatory = startedAt(5);
      expect(observatory.isExercised(BoundariaStar.boundary), isFalse);
      expect(observatory.isExercised(BoundariaStar.border), isFalse);
      expect(observatory.isExercised(BoundariaStar.region), isTrue);

      // The full loop tests everything.
      final citadel = startedAt(10);
      expect(citadel.isExercised(BoundariaStar.boundary), isTrue);
      expect(citadel.isExercised(BoundariaStar.border), isTrue);
      expect(citadel.isExercised(BoundariaStar.region), isTrue);
    });

    test('a star can never be lost for a stage the level never runs', () {
      // Level 1 has no construction, so nothing it offers can touch Boundary.
      final provider = startedAt(1);

      provider.chooseStyle(BoundaryStyle.solid); // wrong, it is >
      provider.claimSide(TerritorySide.below); // wrong, it is >

      expect(provider.hasStar(BoundariaStar.boundary), isTrue);
      expect(provider.starsEarned, 1);
    });
  });

  group('Building the border', () {
    test('a wrong anchor is refused and the stage stays open', () {
      final provider = startedAt(3);

      expect(provider.plotPoint(0, 5), isFalse);
      expect(provider.interceptBeacon, isNull);
      expect(provider.currentPhase, BoundariaPhase.plotIntercept);
      expect(provider.feedbackIsError, isTrue);

      expect(provider.plotPoint(0, 1), isTrue);
      expect(provider.currentPhase, BoundariaPhase.buildSlope);
    });

    test('anchoring off the y-axis says so specifically', () {
      final provider = startedAt(3);

      provider.plotPoint(2, 1);
      expect(provider.feedback, contains('y-axis'));
    });

    test('the slope hint points the right way for a falling border', () {
      final provider = startedAt(6); // y > −x + 2
      provider.plotPoint(0, 2);

      provider.plotPoint(1, 3); // went up instead of down
      expect(provider.feedback, contains('down'));

      expect(provider.plotPoint(1, 1), isTrue);
    });

    test('both beacons must be down before the barrier exists', () {
      final provider = startedAt(3);
      expect(provider.hasBoundaryLine, isFalse);

      provider.plotPoint(0, 1);
      expect(provider.hasBoundaryLine, isFalse);

      provider.plotPoint(1, 2);
      expect(provider.hasBoundaryLine, isTrue);
    });
  });

  group('The barrier type', () {
    test('choosing wrong still raises the correct barrier', () {
      final provider = startedAt(2); // y ≤ −1, so solid

      expect(provider.chooseStyle(BoundaryStyle.dashed), isFalse);
      expect(provider.chosenStyle, BoundaryStyle.solid,
          reason: 'the level must continue against the true border');
      expect(provider.currentPhase, BoundariaPhase.claim);
      expect(provider.hasStar(BoundariaStar.border), isFalse);
    });

    test('the correction explains which half of the symbol mattered', () {
      final inclusive = startedAt(2)..chooseStyle(BoundaryStyle.dashed);
      expect(inclusive.feedback, contains('or equal to'));

      final strict = startedAt(1)..chooseStyle(BoundaryStyle.solid);
      expect(strict.feedback, contains('dashed'));
    });
  });

  group('The scout', () {
    test('a true result celebrates and shows the substitution', () {
      final provider = startedAt(5); // y < x + 3 at the origin

      final verdict = provider.sendScout(0, 0);

      expect(verdict, ScoutVerdict.belongs);
      expect(provider.feedback, contains('0 < 3'));
      expect(provider.feedback, contains('follows the rule'));
      expect(provider.currentPhase, BoundariaPhase.claim);
    });

    test('a false result sends the learner to the other territory', () {
      final provider = startedAt(5);

      final verdict = provider.sendScout(0, 5); // 5 < 3 is false

      expect(verdict, ScoutVerdict.doesNotBelong);
      expect(provider.feedback, contains("doesn't belong"));
    });

    test('landing on the border settles nothing and costs nothing', () {
      final provider = startedAt(6); // y > −x + 2
      final problem = provider.problem!;

      provider.plotPoint(0, 2);
      provider.plotPoint(1, 1);
      provider.chooseStyle(problem.correctStyle);
      expect(provider.currentPhase, BoundariaPhase.scout);

      final verdict = provider.sendScout(0, 2); // sits on the line

      expect(verdict, ScoutVerdict.onBorder);
      expect(provider.feedback, contains('landed on the border'));
      expect(provider.currentPhase, BoundariaPhase.scout,
          reason: 'the scout should still be movable');
      expect(provider.starsEarned, 3, reason: 'this is a lesson, not an error');

      expect(provider.sendScout(0, 0), ScoutVerdict.doesNotBelong);
    });

    test('a scouted false answer still allows the correct claim', () {
      final provider = startedAt(5);

      provider.sendScout(0, 5); // false, so the solution is the other side
      provider.claimSide(TerritorySide.below);

      expect(provider.starsEarned, 3);
    });
  });

  group('Claiming the territory', () {
    test('a wrong claim reveals the right one and explains why', () {
      final provider = startedAt(1); // y > 2, so above

      expect(provider.chooseStyle(BoundaryStyle.dashed), isTrue);
      expect(provider.claimSide(TerritorySide.below), isFalse);

      expect(provider.claimedSide, TerritorySide.above,
          reason: 'the level ends showing the true territory');
      expect(provider.feedback, contains('above'));
      expect(provider.isSolved, isTrue);
      expect(provider.hasStar(BoundariaStar.region), isFalse);
    });

    test('claiming ends the level', () {
      final provider = startedAt(1);
      provider.chooseStyle(BoundaryStyle.dashed);
      provider.claimSide(TerritorySide.above);

      expect(provider.isSolved, isTrue);
      expect(provider.currentPhase, isNull);
    });
  });

  group('The Broken Map', () {
    test('the correct map takes all three stars', () {
      final provider = startedAt(9);
      final correct =
          provider.problem!.mapOptions.firstWhere((m) => m.isCorrect);

      expect(provider.chooseMap(correct.id), isTrue);
      expect(provider.starsEarned, 3);
      expect(provider.isSolved, isTrue);
    });

    test('the map chosen decides which star is lost', () {
      for (final wrong
          in service.levelProblem(9).mapOptions.where((m) => !m.isCorrect)) {
        final provider = startedAt(9);

        expect(provider.chooseMap(wrong.id), isFalse);
        expect(provider.starsEarned, 2, reason: wrong.label);
        expect(
          provider.hasStar(wrong.flaw!),
          isFalse,
          reason: '${wrong.label} should cost the ${wrong.flaw!.name} star',
        );

        // And the other two survive.
        for (final other
            in BoundariaStar.values.where((s) => s != wrong.flaw)) {
          expect(provider.hasStar(other), isTrue, reason: wrong.label);
        }
      }
    });
  });

  group('Rearranging', () {
    test('the wrong form costs the boundary star and keeps the stage open', () {
      final provider = startedAt(8); // −y < 2x − 4

      expect(provider.chooseRearrangeOption(1), isFalse);
      expect(provider.hasStar(BoundariaStar.boundary), isFalse);
      expect(provider.currentPhase, BoundariaPhase.rearrange);
      expect(provider.feedback, contains('reverses'));

      expect(provider.chooseRearrangeOption(0), isTrue);
      expect(provider.currentPhase, BoundariaPhase.plotIntercept);
    });

    test('level 7 is corrected without mentioning a flip', () {
      final provider = startedAt(7); // 2x + y > 4, no flip involved

      provider.chooseRearrangeOption(1);
      expect(provider.feedback, isNot(contains('reverses')));
    });
  });

  group('Guard rails', () {
    test('actions outside their stage are ignored', () {
      final provider = startedAt(3); // starts on plotIntercept

      expect(provider.chooseStyle(BoundaryStyle.solid), isFalse);
      expect(provider.claimSide(TerritorySide.above), isFalse);
      expect(provider.chooseMap('D'), isFalse);
      expect(provider.chooseRearrangeOption(0), isFalse);

      expect(provider.starsEarned, 3, reason: 'ignored input is not a mistake');
      expect(provider.currentPhase, BoundariaPhase.plotIntercept);
    });

    test('nothing responds once the level is solved', () {
      final provider = startedAt(1);
      provider.chooseStyle(BoundaryStyle.dashed);
      provider.claimSide(TerritorySide.above);

      expect(provider.claimSide(TerritorySide.below), isFalse);
      expect(provider.starsEarned, 3);
    });

    test('the phase rail counts the stages the level declared', () {
      final provider = startedAt(10);

      expect(provider.totalPhaseCount, 6);
      expect(provider.completedPhaseCount, 0);

      provider.chooseRearrangeOption(0);
      expect(provider.completedPhaseCount, 1);
    });

    test('hints toggle without touching the score', () {
      final provider = startedAt(7);

      expect(provider.hintVisible, isFalse);
      provider.toggleHint();
      expect(provider.hintVisible, isTrue);
      expect(provider.starsEarned, 3);
    });
  });
}
