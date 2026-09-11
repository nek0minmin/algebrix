import 'package:algebrix/core/providers/boundaria_provider.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/models/boundaria_problem.dart';
import 'package:algebrix/models/quest_map_model.dart';
import 'package:algebrix/screens/practice/boundaria_screen.dart';
import 'package:algebrix/services/quest_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late BoundariaProvider boundaria;
  late QuestMapProvider questMap;
  late _MemoryQuestRepository repository;

  void sizeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  setUp(() {
    boundaria = BoundariaProvider();
    repository = _MemoryQuestRepository();
    questMap = QuestMapProvider(repository: repository);
  });

  Future<void> pumpLevel(WidgetTester tester, int level) async {
    sizeScreen(tester);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BoundariaProvider>.value(value: boundaria),
          ChangeNotifierProvider<QuestMapProvider>.value(value: questMap),
        ],
        child: MaterialApp(home: BoundariaScreen(questLevelNumber: level)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('level 1 shows the rule and only the stage it is on',
      (tester) async {
    await pumpLevel(tester, 1);

    expect(find.byKey(const Key('boundaria-rule')), findsOneWidget);
    expect(find.text('y > 2'), findsOneWidget);

    // Boundary type first, and nothing from a later stage.
    expect(find.byKey(const Key('boundaria-style-dashed')), findsOneWidget);
    expect(find.byKey(const Key('boundaria-style-solid')), findsOneWidget);
    expect(find.byKey(const Key('boundaria-claim-above')), findsNothing);
  });

  testWidgets('the controls change as the loop advances', (tester) async {
    await pumpLevel(tester, 1);

    await tapKey(tester, 'boundaria-style-dashed');

    // Barrier decided, so the deck moves on to claiming.
    expect(find.byKey(const Key('boundaria-style-dashed')), findsNothing);
    expect(find.byKey(const Key('boundaria-claim-above')), findsOneWidget);
    expect(find.byKey(const Key('boundaria-claim-below')), findsOneWidget);
  });

  testWidgets('claiming the right territory ends the level with three stars',
      (tester) async {
    await pumpLevel(tester, 1);

    await tapKey(tester, 'boundaria-style-dashed');
    await tapKey(tester, 'boundaria-claim-above');

    expect(boundaria.isSolved, isTrue);
    expect(boundaria.starsEarned, 3);

    final title = find.byKey(const Key('boundaria-result-title'));
    expect(title, findsOneWidget);
    // The phrase also appears in the control deck feedback, so match the
    // dialog's own widget rather than the words.
    expect(tester.widget<Text>(title).data, 'Territory restored!');
    expect(find.byKey(const Key('boundaria-result-stars')), findsOneWidget);
    expect(find.text('3 / 3 Stars'), findsOneWidget);
  });

  testWidgets('the result names which idea needs practice', (tester) async {
    await pumpLevel(tester, 1); // y > 2, so dashed and above

    await tapKey(tester, 'boundaria-style-solid'); // wrong barrier
    await tapKey(tester, 'boundaria-claim-above');

    expect(find.text('2 / 3 Stars'), findsOneWidget);

    // Boundary was never asked about at this level, so it reads as given
    // rather than claiming the learner did something they did not.
    expect(find.byKey(const Key('boundaria-result-boundary')), findsOneWidget);
    expect(find.text('Given'), findsOneWidget);
    expect(find.text('Needs practice'), findsOneWidget);
    expect(find.text('Understood'), findsOneWidget);
  });

  testWidgets('the result is written to the quest map', (tester) async {
    await pumpLevel(tester, 1);

    await tapKey(tester, 'boundaria-style-dashed');
    await tapKey(tester, 'boundaria-claim-above');

    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.landId, 'boundaria');
    expect(repository.saved.single.levelNumber, 1);
    expect(repository.saved.single.stars, 3);
  });

  testWidgets('a construction level accepts taps on the grid', (tester) async {
    await pumpLevel(tester, 3); // y > x + 1

    expect(find.byKey(const Key('boundaria-cell-0_1')), findsOneWidget);

    await tapKey(tester, 'boundaria-cell-0_1');
    expect(boundaria.interceptBeacon, (x: 0, y: 1));
    expect(boundaria.currentPhase, BoundariaPhase.buildSlope);

    await tapKey(tester, 'boundaria-cell-1_2');
    expect(boundaria.slopeBeacon, (x: 1, y: 2));
    expect(boundaria.hasBoundaryLine, isTrue);
  });

  testWidgets('the grid stops accepting taps once the stage moves on',
      (tester) async {
    await pumpLevel(tester, 3);

    await tapKey(tester, 'boundaria-cell-0_1');
    await tapKey(tester, 'boundaria-cell-1_2');

    // Now on the barrier choice, so the lattice is inert.
    expect(find.byKey(const Key('boundaria-cell-0_1')), findsNothing);
    expect(find.byKey(const Key('boundaria-style-dashed')), findsOneWidget);
  });

  testWidgets('level 5 offers a fixed scout button rather than a free tap',
      (tester) async {
    await pumpLevel(tester, 5);

    expect(find.byKey(const Key('boundaria-scout-go')), findsOneWidget);
    expect(find.byKey(const Key('boundaria-cell-0_0')), findsNothing,
        reason: 'the scout point is fixed at this level');

    await tapKey(tester, 'boundaria-scout-go');

    expect(boundaria.scoutVerdict, ScoutVerdict.belongs);
    expect(find.byKey(const Key('boundaria-feedback')), findsOneWidget);
    expect(find.textContaining('0 < 3'), findsOneWidget);
  });

  testWidgets('a rearrange level shows its options and keeps the solved rule',
      (tester) async {
    await pumpLevel(tester, 7); // 2x + y > 4

    expect(find.text('2x + y > 4'), findsOneWidget);
    expect(find.byKey(const Key('boundaria-solved-rule')), findsNothing);

    for (var i = 0; i < 4; i++) {
      expect(find.byKey(Key('boundaria-rearrange-$i')), findsOneWidget);
    }

    await tapKey(tester, 'boundaria-rearrange-0');

    // The solved form stays on screen, because every later stage works from it.
    expect(find.byKey(const Key('boundaria-solved-rule')), findsOneWidget);
    expect(boundaria.currentPhase, BoundariaPhase.plotIntercept);
  });

  testWidgets('the Broken Map level offers four maps instead of a grid',
      (tester) async {
    await pumpLevel(tester, 9);

    expect(find.text('Which map follows the Territory Rule?'), findsOneWidget);
    for (final id in ['A', 'B', 'C', 'D']) {
      expect(find.byKey(Key('boundaria-map-$id')), findsOneWidget);
    }
    expect(find.byKey(const Key('boundaria-cell-0_0')), findsNothing);

    await tapKey(tester, 'boundaria-map-D');

    expect(boundaria.starsEarned, 3);
    expect(find.text('3 / 3 Stars'), findsOneWidget);
  });

  testWidgets('the hint stays hidden until it is asked for', (tester) async {
    await pumpLevel(tester, 8);

    expect(find.byKey(const Key('boundaria-hint-text')), findsNothing);

    await tapKey(tester, 'boundaria-hint');
    expect(find.byKey(const Key('boundaria-hint-text')), findsOneWidget);
    expect(find.textContaining('reverses the inequality'), findsOneWidget);

    await tapKey(tester, 'boundaria-hint');
    expect(find.byKey(const Key('boundaria-hint-text')), findsNothing);
  });

  testWidgets('replaying from the result screen resets the board',
      (tester) async {
    await pumpLevel(tester, 1);

    await tapKey(tester, 'boundaria-style-solid'); // wrong on purpose
    await tapKey(tester, 'boundaria-claim-above');
    expect(boundaria.starsEarned, 2);

    await tapKey(tester, 'boundaria-result-replay');

    expect(boundaria.starsEarned, 3);
    expect(boundaria.isSolved, isFalse);
    expect(find.byKey(const Key('boundaria-style-dashed')), findsOneWidget);
  });
}

class _SavedResult {
  const _SavedResult(this.landId, this.levelNumber, this.stars);

  final String landId;
  final int levelNumber;
  final int stars;
}

class _MemoryQuestRepository implements QuestRepository {
  final List<_SavedResult> saved = [];

  @override
  Future<List<QuestLand>> fetchAllLands() async => const [
        QuestLand(
          id: 'balands',
          name: 'Balands',
          subtitle: 'The Land of Balancing',
          sortOrder: 1,
          totalLevels: 10,
          unlockStarsRequired: 0,
        ),
        QuestLand(
          id: 'boundaria',
          name: 'Boundaria',
          subtitle: 'The Land of Boundaries',
          sortOrder: 3,
          totalLevels: 10,
          unlockStarsRequired: 55,
        ),
      ];

  @override
  Future<List<QuestLevelProgress>> fetchLandProgress(String landId) async => [];

  @override
  Future<int> fetchTotalStars() async =>
      saved.fold<int>(0, (sum, r) => sum + r.stars);

  @override
  Future<void> saveLevelResult({
    required String landId,
    required int levelNumber,
    required int starsEarned,
    required int moveCount,
    required bool reasoningPassed,
  }) async {
    saved.add(_SavedResult(landId, levelNumber, starsEarned));
  }
}
