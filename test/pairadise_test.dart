import 'package:algebrix/core/providers/pairadise_provider.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/models/pairadise_problem.dart';
import 'package:algebrix/models/quest_map_model.dart';
import 'package:algebrix/screens/practice/pairadise_screen.dart';
import 'package:algebrix/services/pairadise_problem_service.dart';
import 'package:algebrix/services/quest_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeQuestRepository implements QuestRepository {
  @override
  Future<List<QuestLand>> fetchAllLands() async => [
        const QuestLand(
          id: 'pairadise',
          name: 'Pairadise',
          subtitle: 'The Land of Pairs',
          sortOrder: 2,
          totalLevels: 10,
          unlockStarsRequired: 25,
        ),
      ];

  @override
  Future<List<QuestLevelProgress>> fetchLandProgress(String landId) async => [];

  @override
  Future<int> fetchTotalStars() async => 25;

  @override
  Future<void> saveLevelResult({
    required String landId,
    required int levelNumber,
    required int starsEarned,
    required int moveCount,
    required bool reasoningPassed,
  }) async {}
}

void main() {
  group('PairadiseProblemService Tests', () {
    const service = PairadiseProblemService();

    test('retrieves valid problems for levels 1 through 10', () {
      for (int i = 1; i <= 10; i++) {
        final problem = service.getLevelProblem(i);
        expect(problem.levelNumber, i);
        expect(problem.clue1.isNotEmpty, isTrue);
        expect(problem.clue2.isNotEmpty, isTrue);
      }
    });

    test('L1 & L2 are free discovery puzzles without reasoning interruptions', () {
      final l1 = service.getLevelProblem(1);
      final l2 = service.getLevelProblem(2);
      expect(l1.hasReasoningCheckpoint, isFalse);
      expect(l2.hasReasoningCheckpoint, isFalse);
    });

    test('L3 is an elimination puzzle with a conceptual reasoning checkpoint', () {
      final l3 = service.getLevelProblem(3);
      expect(l3.hasReasoningCheckpoint, isTrue);
      expect(l3.reasoningQuestion, isNotNull);
      expect(l3.reasoningOptions.length, 4);
      expect(l3.correctReasoningIndex, 1);
    });

    test('L1 evaluates discovery solution (4, 3) correctly', () {
      final l1 = service.getLevelProblem(1);
      expect(l1.mechanic, PairadiseMechanic.discovery);
      expect(l1.evaluateClue1(4, 3), isTrue); // 4 + 3 = 7
      expect(l1.evaluateClue2(4, 3), isTrue); // 4 - 3 = 1
      expect(l1.evaluateClue1(5, 2), isTrue); // 5 + 2 = 7 (works for clue 1)
      expect(l1.evaluateClue2(5, 2), isFalse); // 5 - 2 = 3 != 1 (fails clue 2)
      expect(l1.checkSolution(4, 3), isTrue);
    });

    test('L3 evaluates elimination candidates and solution (5, 3)', () {
      final l3 = service.getLevelProblem(3);
      expect(l3.mechanic, PairadiseMechanic.elimination);
      expect(l3.candidatePairs.length, 6);
      expect(l3.evaluateClue2(2, 6), isFalse); // 2 - 6 = -4 != 2
      expect(l3.evaluateClue2(3, 5), isFalse); // 3 - 5 = -2 != 2
      expect(l3.evaluateClue2(4, 4), isFalse); // 4 - 4 = 0 != 2
      expect(l3.evaluateClue2(5, 3), isTrue); // 5 - 3 = 2
      expect(l3.evaluateClue2(6, 2), isFalse); // 6 - 2 = 4 != 2
      expect(l3.evaluateClue2(7, 1), isFalse); // 7 - 1 = 6 != 2
    });
  });

  group('PairadiseProvider Unit Tests', () {
    test('initializes Discovery level and tracks assignments', () {
      final provider = PairadiseProvider();
      provider.initLevelProblem(1);

      expect(provider.currentProblem?.levelNumber, 1);
      expect(provider.isLevelPlayable, isTrue);
      expect(provider.isPairReady, isFalse);

      provider.assignX(4);
      expect(provider.assignedX, 4);
      expect(provider.isPairReady, isFalse);

      provider.assignY(3);
      expect(provider.assignedY, 3);
      expect(provider.isPairReady, isTrue);

      provider.clearAssignments();
      expect(provider.assignedX, isNull);
      expect(provider.assignedY, isNull);
      expect(provider.isPairReady, isFalse);
    });

    test('L1 solves directly on first try giving 3 stars (0 mistakes)', () async {
      final provider = PairadiseProvider();
      provider.initLevelProblem(1);
      provider.assignX(4);
      provider.assignY(3);

      final result = await provider.testPair();
      expect(result, isTrue);
      expect(provider.isSolved, isTrue);
      expect(provider.failedTests, 0);
      expect(provider.showReasoningCheck, isFalse);
      expect(provider.starRating, 3); // 0 mistakes = 3 stars!
    });

    test('1 mistake gives 2 stars, >1 mistakes give 1 star', () async {
      final provider = PairadiseProvider();
      provider.initLevelProblem(1);

      // Mistake 1
      provider.assignX(5);
      provider.assignY(2);
      await provider.testPair();
      expect(provider.failedTests, 1);
      provider.retryAfterFailure();

      // Mistake 2
      provider.assignX(6);
      provider.assignY(1);
      await provider.testPair();
      expect(provider.failedTests, 2);
      provider.retryAfterFailure();

      // Finally correct
      provider.assignX(4);
      provider.assignY(3);
      await provider.testPair();
      expect(provider.isSolved, isTrue);
      expect(provider.starRating, 1); // 2 mistakes = 1 star
    });

    test('L3 triggers reasoning checkpoint and calculates stars appropriately', () async {
      final provider = PairadiseProvider();
      provider.initLevelProblem(3);

      // Eliminate 4 wrong pairs
      provider.eliminatePair(0);
      provider.eliminatePair(1);
      provider.eliminatePair(2);
      provider.eliminatePair(4);

      // Confirm final correct pair (index 3)
      final result = await provider.confirmPair(3);
      expect(result, isTrue);
      expect(provider.isSolved, isTrue);
      expect(provider.showReasoningCheck, isTrue); // Checkpoint level shows checkpoint!

      // Correct reasoning -> 3 stars
      provider.setReasoningResult(true);
      expect(provider.starRating, 3);
    });

    test('tests incorrect pair and allows seamless re-assignment and testing', () async {
      final provider = PairadiseProvider();
      provider.initLevelProblem(1);
      provider.assignX(5);
      provider.assignY(2); // 5+2=7 (clue 1 pass), 5-2=3 != 1 (clue 2 fail)

      final result = await provider.testPair();
      expect(result, isFalse);
      expect(provider.isSolved, isFalse);
      expect(provider.clue1Passed, isTrue);
      expect(provider.clue2Passed, isFalse);
      expect(provider.phase, PairadisePhase.pairFailed);

      // Re-assigning x or y automatically clears error state and allows testing again
      provider.assignX(4);
      expect(provider.phase, PairadisePhase.exploring);
      expect(provider.clue1Passed, isFalse);
      expect(provider.assignedX, 4);

      provider.assignY(3);
      expect(provider.assignedY, 3);

      final secondResult = await provider.testPair();
      expect(secondResult, isTrue);
      expect(provider.isSolved, isTrue);
    });

    test('eliminates wrong pairs and rejects eliminating correct pair', () {
      final provider = PairadiseProvider();
      provider.initLevelProblem(3);

      // (2, 6) is index 0 -> should eliminate successfully
      expect(provider.eliminatePair(0), isTrue);
      expect(provider.eliminatedPairIndices.contains(0), isTrue);
      expect(provider.remainingPairCount, 5);

      // (5, 3) is index 3 (the correct solution) -> should NOT eliminate
      expect(provider.eliminatePair(3), isFalse);
      expect(provider.eliminatedPairIndices.contains(3), isFalse);
      expect(provider.remainingPairCount, 5);
    });
  });

  group('PairadiseScreen Widget Tests', () {
    Widget createWidgetUnderTest({int levelNumber = 1}) {
      final questRepo = _FakeQuestRepository();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PairadiseProvider()),
          ChangeNotifierProvider(
            create: (_) => QuestMapProvider(repository: questRepo),
          ),
        ],
        child: MaterialApp(
          home: PairadiseScreen(questLevelNumber: levelNumber),
        ),
      );
    }

    testWidgets('renders L1 Discovery screen with clues and value slots',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest(levelNumber: 1));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('PAIRADISE I'), findsOneWidget);
      expect(find.text('The Land of Pairs'), findsOneWidget);

      // Clues
      expect(find.text('x + y = 7'), findsOneWidget);
      expect(find.text('x - y = 1'), findsOneWidget);

      // Value Slots (Purple x and Teal y)
      expect(find.text('Mystery x'), findsOneWidget);
      expect(find.text('Mystery y'), findsOneWidget);

      // Test Pair Button
      expect(find.text('Test Pair'), findsOneWidget);
    });

    testWidgets('tapping value stones assigns them to x and y',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest(levelNumber: 1));
      await tester.pumpAndSettle();

      // Tap stone '4'
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      // Tap stone '3'
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      // Slots are filled with 4 and 3
      expect(find.text('4'), findsWidgets);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('renders L3 Elimination screen with candidate pair cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest(levelNumber: 3));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('PAIRADISE III'), findsOneWidget);
      expect(find.text('The Land of Pairs'), findsOneWidget);

      // Clues
      expect(find.text('x + y = 8'), findsOneWidget);
      expect(find.text('x - y = 2'), findsOneWidget);

      // Candidate pairs
      expect(find.text('(2, 6)'), findsOneWidget);
      expect(find.text('(3, 5)'), findsOneWidget);
      expect(find.text('(4, 4)'), findsOneWidget);
      expect(find.text('(5, 3)'), findsOneWidget);
      expect(find.text('(6, 2)'), findsOneWidget);
    });
  });
}
