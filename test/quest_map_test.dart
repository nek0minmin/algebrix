import 'package:algebrix/core/providers/balance_scale_provider.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/models/quest_map_model.dart';
import 'package:algebrix/screens/practice/quest_map_screen.dart';
import 'package:algebrix/services/math_api_service.dart';
import 'package:algebrix/services/quest_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeQuestRepository implements QuestRepository {
  final List<QuestLand> _lands = [
    const QuestLand(
      id: 'balands',
      name: 'Balands',
      subtitle: 'The Land of Balancing',
      sortOrder: 1,
      totalLevels: 10,
      unlockStarsRequired: 0,
    ),
    const QuestLand(
      id: 'equatopia',
      name: 'Equatopia',
      subtitle: 'The Land of Systems',
      sortOrder: 2,
      totalLevels: 10,
      unlockStarsRequired: 25,
    ),
  ];

  final Map<int, QuestLevelProgress> _progress = {};

  @override
  Future<List<QuestLand>> fetchAllLands() async => _lands;

  @override
  Future<List<QuestLevelProgress>> fetchLandProgress(String landId) async {
    return _progress.values.where((p) => p.landId == landId).toList();
  }

  @override
  Future<int> fetchTotalStars() async {
    return _progress.values.fold<int>(0, (sum, p) => sum + p.starsEarned);
  }

  @override
  Future<void> saveLevelResult({
    required String landId,
    required int levelNumber,
    required int starsEarned,
    required int moveCount,
    required bool reasoningPassed,
  }) async {
    final existing = _progress[levelNumber];
    final bestStars = existing != null && existing.starsEarned > starsEarned
        ? existing.starsEarned
        : starsEarned;
    final bestMoves = existing?.bestMoves != null && existing!.bestMoves! < moveCount
        ? existing.bestMoves!
        : moveCount;

    _progress[levelNumber] = QuestLevelProgress(
      userId: 'test-user',
      landId: landId,
      levelNumber: levelNumber,
      starsEarned: bestStars,
      bestMoves: bestMoves,
      reasoningPassed: reasoningPassed || (existing?.reasoningPassed ?? false),
      completedAt: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quest Map Model & Land Unlock Tests', () {
    test('QuestLand unlock threshold logic', () {
      const land1 = QuestLand(
        id: 'balands',
        name: 'Balands',
        subtitle: 'The Land of Balancing',
        sortOrder: 1,
        totalLevels: 10,
        unlockStarsRequired: 0,
      );

      const land2 = QuestLand(
        id: 'equatopia',
        name: 'Equatopia',
        subtitle: 'The Land of Systems',
        sortOrder: 2,
        totalLevels: 10,
        unlockStarsRequired: 25,
      );

      expect(land1.isUnlocked(0), isTrue);
      expect(land1.isUnlocked(24), isTrue);
      expect(land1.maxStars, 30);

      // Land 2 requires 25 stars
      expect(land2.isUnlocked(0), isFalse);
      expect(land2.isUnlocked(24), isFalse);
      expect(land2.isUnlocked(25), isTrue);
      expect(land2.isUnlocked(30), isTrue);
    });

    test('QuestLevelDefinition difficulty labels', () {
      const def1 = QuestLevelDefinition(
        levelNumber: 1,
        difficulty: 2,
        description: 'Simple addition',
      );
      const def2 = QuestLevelDefinition(
        levelNumber: 5,
        difficulty: 5,
        description: 'Two-step with subtraction',
      );
      const def3 = QuestLevelDefinition(
        levelNumber: 8,
        difficulty: 8,
        description: 'Variables on both sides',
      );
      const def4 = QuestLevelDefinition(
        levelNumber: 10,
        difficulty: 10,
        description: 'Expert challenge',
      );

      expect(def1.difficultyLabel, 'Easy');
      expect(def2.difficultyLabel, 'Medium');
      expect(def3.difficultyLabel, 'Hard');
      expect(def4.difficultyLabel, 'Expert');
    });
  });

  group('MathApiService Quest Level Bank Tests', () {
    test('provides exactly 10 ordered progressive quest levels', () {
      final api = MathApiService();
      expect(api.totalQuestLevels, 10);

      for (int i = 1; i <= 10; i++) {
        final problem = api.getLevelProblem(i);
        expect(problem.id, 'level_$i');
        expect(problem.equation, isNotEmpty);
        expect(problem.reasoningOptions.length, 3);
        expect(problem.correctReasoningIndex, inInclusiveRange(0, 2));
      }

      // Early levels are 1 move, later levels are 2-3 moves
      expect(api.getLevelProblem(1).optimalMoves, 1);
      expect(api.getLevelProblem(2).optimalMoves, 1);
      expect(api.getLevelProblem(3).optimalMoves, 1);
      expect(api.getLevelProblem(4).optimalMoves, 2);
      expect(api.getLevelProblem(9).optimalMoves, 3);
      expect(api.getLevelProblem(10).optimalMoves, 3);
    });
  });

  group('QuestMapProvider & Star Rubric Tests', () {
    late FakeQuestRepository repo;
    late QuestMapProvider provider;

    setUp(() {
      repo = FakeQuestRepository();
      provider = QuestMapProvider(repository: repo);
    });

    test('initial state: level 1 unlocked, levels 2-10 locked', () async {
      await provider.loadQuestMap();

      expect(provider.isLevelUnlocked(1), isTrue);
      expect(provider.isLevelUnlocked(2), isFalse);
      expect(provider.isLevelUnlocked(10), isFalse);
      expect(provider.totalStars, 0);
      expect(provider.activeLandStars, 0);
    });

    test('star rating rubric: 3 stars for within moves + reasoning correct', () async {
      await provider.loadQuestMap();

      // 3 Stars: withinMoves (2 <= 2) AND reasoningPassed (true)
      final stars = await provider.submitLevelResult(
        levelNumber: 1,
        moveCount: 1,
        optimalMoves: 1,
        reasoningPassed: true,
      );

      expect(stars, 3);
      expect(provider.starsForLevel(1), 3);
      expect(provider.isLevelUnlocked(2), isTrue); // Level 2 now unlocked!
    });

    test('star rating rubric: 2 stars for within moves but wrong reasoning', () async {
      await provider.loadQuestMap();

      // 2 Stars: withinMoves (1 <= 1) BUT reasoningPassed (false)
      final stars = await provider.submitLevelResult(
        levelNumber: 1,
        moveCount: 1,
        optimalMoves: 1,
        reasoningPassed: false,
      );

      expect(stars, 2);
      expect(provider.starsForLevel(1), 2);
      expect(provider.isLevelUnlocked(2), isTrue); // Level 2 still unlocks with 2 stars!
    });

    test('star rating rubric: 2 stars for exceeded moves but correct reasoning', () async {
      await provider.loadQuestMap();

      // 2 Stars: exceeded moves (3 > 1) BUT reasoningPassed (true)
      final stars = await provider.submitLevelResult(
        levelNumber: 1,
        moveCount: 3,
        optimalMoves: 1,
        reasoningPassed: true,
      );

      expect(stars, 2);
      expect(provider.starsForLevel(1), 2);
    });

    test('star rating rubric: 1 star for exceeded moves and wrong reasoning', () async {
      await provider.loadQuestMap();

      // 1 Star: exceeded moves (4 > 1) AND reasoningPassed (false)
      final stars = await provider.submitLevelResult(
        levelNumber: 1,
        moveCount: 4,
        optimalMoves: 1,
        reasoningPassed: false,
      );

      expect(stars, 1);
      expect(provider.starsForLevel(1), 1);
      expect(provider.isLevelUnlocked(2), isTrue); // Level 2 unlocks with 1 star!
    });

    test('replaying a level preserves best stars and moves', () async {
      await provider.loadQuestMap();

      // First run: 1 star (slow, wrong reasoning)
      await provider.submitLevelResult(
        levelNumber: 1,
        moveCount: 5,
        optimalMoves: 1,
        reasoningPassed: false,
      );
      expect(provider.starsForLevel(1), 1);
      expect(provider.bestMovesForLevel(1), 5);

      // Replay run: 3 stars (optimal moves, correct reasoning)
      await provider.submitLevelResult(
        levelNumber: 1,
        moveCount: 1,
        optimalMoves: 1,
        reasoningPassed: true,
      );
      expect(provider.starsForLevel(1), 3);
      expect(provider.bestMovesForLevel(1), 1);

      // Third run: worse score (2 stars) should NOT downgrade best stars
      await provider.submitLevelResult(
        levelNumber: 1,
        moveCount: 3,
        optimalMoves: 1,
        reasoningPassed: true,
      );
      expect(provider.starsForLevel(1), 3); // Still 3 stars!
      expect(provider.bestMovesForLevel(1), 1); // Still 1 move!
    });

    test('currentLandAndLevelLabel tracks player frontier with Roman numerals', () async {
      await provider.loadQuestMap();

      // Initially on Level 1
      expect(provider.currentLevel, 1);
      expect(provider.currentLandAndLevelLabel, 'Balands I (Level 1)');

      // Complete Level 1 -> frontier is Level 2
      await provider.submitLevelResult(
        levelNumber: 1,
        moveCount: 1,
        optimalMoves: 1,
        reasoningPassed: true,
      );
      expect(provider.currentLevel, 2);
      expect(provider.currentLandAndLevelLabel, 'Balands II (Level 2)');

      // Complete Level 2 and 3 -> frontier is Level 4
      await provider.submitLevelResult(
        levelNumber: 2,
        moveCount: 1,
        optimalMoves: 1,
        reasoningPassed: true,
      );
      await provider.submitLevelResult(
        levelNumber: 3,
        moveCount: 1,
        optimalMoves: 1,
        reasoningPassed: true,
      );
      expect(provider.currentLevel, 4);
      expect(provider.currentLandAndLevelLabel, 'Balands IV (Level 4)');
    });
  });

  group('QuestMapScreen UI Widget Tests', () {
    testWidgets('renders Balands header, HUD star capsule, and 10 level nodes with preview sheet', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeQuestRepository();
      final questProvider = QuestMapProvider(repository: repo);
      final scaleProvider = BalanceScaleProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<QuestMapProvider>.value(value: questProvider),
            ChangeNotifierProvider<BalanceScaleProvider>.value(value: scaleProvider),
          ],
          child: const MaterialApp(
            home: QuestMapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Balands'), findsOneWidget);
      expect(find.text('The Land of Balancing'), findsOneWidget);
      expect(find.text('0/30'), findsOneWidget);
      expect(find.byKey(const Key('quest-level-node-1')), findsOneWidget);
      expect(find.byKey(const Key('quest-level-node-10')), findsOneWidget);

      // Tap Level 1 to open Level Preview Bottom Sheet
      await tester.tap(find.byKey(const Key('quest-level-node-1')));
      await tester.pumpAndSettle();

      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Play Level 1 🚀'), findsOneWidget);
      expect(find.text('Simple addition'), findsOneWidget);
      expect(find.text('x + 3 = 7'), findsOneWidget);
    });
  });
}
