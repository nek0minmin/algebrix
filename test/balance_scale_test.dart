import 'package:algebrix/core/providers/balance_scale_provider.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/models/quest_map_model.dart';
import 'package:algebrix/screens/practice/balance_scale_screen.dart';
import 'package:algebrix/screens/practice/practice_screen.dart';
import 'package:algebrix/services/math_api_service.dart';
import 'package:algebrix/services/quest_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeQuestRepository implements QuestRepository {
  @override
  Future<List<QuestLand>> fetchAllLands() async => [
        const QuestLand(
          id: 'balands',
          name: 'Balands',
          subtitle: 'The Land of Balancing',
          sortOrder: 1,
          totalLevels: 10,
          unlockStarsRequired: 0,
        ),
      ];

  @override
  Future<List<QuestLevelProgress>> fetchLandProgress(String landId) async => [];

  @override
  Future<int> fetchTotalStars() async => 0;

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
  group('MathApiService Tests', () {
    test('local fallback simplifies step correctly', () async {
      final service = MathApiService();
      final result = await service.evaluateScaleOperation(
        leftExpr: '2x + 6',
        rightExpr: '18',
        op: '-',
        value: 6,
      );

      expect(result.leftSimplified, '2x');
      expect(result.rightSimplified, '12');
      expect(result.isSuccess, isTrue);
    });

    test('generates dynamic operations for a problem', () {
      final service = MathApiService();
      final problem = service.getRandomProblem();
      final ops = service.generateOpsForProblem(problem);

      expect(ops.length, greaterThanOrEqualTo(4));
      expect(ops.every((o) => o.containsKey('op') && o.containsKey('value')), isTrue);
    });

    test('problems have reasoning options and optimal moves', () {
      final service = MathApiService();
      final problem = service.getRandomProblem();

      expect(problem.optimalMoves, greaterThanOrEqualTo(2));
      expect(problem.reasoningOptions.length, 3);
      expect(problem.correctReasoningIndex, inInclusiveRange(0, 2));
    });
  });

  group('BalanceScaleProvider Tests', () {
    test('initializes problem and applies balance operation', () async {
      final provider = BalanceScaleProvider();
      expect(provider.currentProblem, isNotNull);
      expect(provider.isSolved, isFalse);
      expect(provider.moveCount, 0);
      expect(provider.dynamicOps, isNotEmpty);

      await provider.applyOperation('-', 6);
      expect(provider.moveCount, 1);
      expect(provider.history, hasLength(1));
    });

    test('solving Level 1 (x + 3 = 7) with -3 isolates x and triggers reasoning check', () async {
      final provider = BalanceScaleProvider();
      provider.initLevelProblem(1);

      expect(provider.leftExpr, 'x + 3');
      expect(provider.rightExpr, '7');
      expect(provider.isSolved, isFalse);
      expect(provider.showReasoningCheck, isFalse);

      // Apply -3 on both sides
      await provider.applyOperation('-', 3, targetSide: 'both');

      expect(provider.leftExpr, 'x');
      expect(provider.rightExpr, '4');
      expect(provider.isSolved, isTrue);
      expect(provider.showReasoningCheck, isTrue);
    });

    test('solving Level 4 (2x + 4 = 12) with -4 then /2 isolates x and triggers reasoning check', () async {
      final provider = BalanceScaleProvider();
      provider.initLevelProblem(4);

      expect(provider.leftExpr, '2x + 4');
      expect(provider.rightExpr, '12');

      // Step 1: -4
      await provider.applyOperation('-', 4, targetSide: 'both');
      expect(provider.leftExpr, '2x');
      expect(provider.rightExpr, '8');
      expect(provider.isSolved, isFalse);

      // Step 2: /2
      await provider.applyOperation('/', 2, targetSide: 'both');
      expect(provider.leftExpr, 'x');
      expect(provider.rightExpr, '4');
      expect(provider.isSolved, isTrue);
      expect(provider.showReasoningCheck, isTrue);
    });

    test('solving Level 8 (3x + 5 = 2x + 12) in 2 moves using numeric (-5) and variable (-2x) blocks', () async {
      final provider = BalanceScaleProvider();
      provider.initLevelProblem(8);

      expect(provider.leftExpr, '3x + 5');
      expect(provider.rightExpr, '2x + 12');
      expect(provider.isSolved, isFalse);

      // Verify that dynamicOps includes the -2x variable block
      final hasMinus2x = provider.dynamicOps.any(
        (op) => op['op'] == '-' && op['value'] == 2 && op['isVariable'] == true,
      );
      expect(hasMinus2x, isTrue);

      // Step 1: Subtract 5 from both sides
      await provider.applyOperation('-', 5, targetSide: 'both');
      expect(provider.leftExpr, '3x');
      expect(provider.rightExpr, '2x + 7');
      expect(provider.isSolved, isFalse);

      // Step 2: Subtract 2x from both sides (variable operation)
      await provider.applyOperation('-', 2, isVariable: true, targetSide: 'both');
      expect(provider.leftExpr, 'x');
      expect(provider.rightExpr, '7');
      expect(provider.isSolved, isTrue);
      expect(provider.moveCount, 2);
      expect(provider.showReasoningCheck, isTrue);
    });

    test('star rating tiers based on move count and reasoning', () async {
      // Case 1: Exceeded moves + wrong reasoning = 1 star & 10 XP
      final provider1 = BalanceScaleProvider();
      provider1.initLevelProblem(1); // optimal moves = 1
      await provider1.applyOperation('+', 2, targetSide: 'both'); // extra move 1
      await provider1.applyOperation('-', 2, targetSide: 'both'); // extra move 2
      await provider1.applyOperation('-', 3, targetSide: 'both'); // solve move
      expect(provider1.moveCount, 3);
      expect(provider1.isSolved, isTrue);
      final wrongIdx1 = (provider1.currentProblem!.correctReasoningIndex + 1) % 3;
      provider1.submitReasoningAnswer(wrongIdx1);
      expect(provider1.reasoningPassed, isFalse);
      expect(provider1.starRating, 1);
      expect(provider1.xpEarned, 10);

      // Case 2: Optimal moves + wrong reasoning = 2 stars & 20 XP
      final provider2 = BalanceScaleProvider();
      provider2.initLevelProblem(1);
      await provider2.applyOperation('-', 3, targetSide: 'both'); // optimal move 1
      expect(provider2.moveCount, 1);
      expect(provider2.isSolved, isTrue);
      final wrongIdx2 = (provider2.currentProblem!.correctReasoningIndex + 1) % 3;
      provider2.submitReasoningAnswer(wrongIdx2);
      expect(provider2.reasoningPassed, isFalse);
      expect(provider2.starRating, 2);
      expect(provider2.xpEarned, 20);

      // Case 3: Exceeded moves + correct reasoning = 2 stars & 20 XP
      final provider3 = BalanceScaleProvider();
      provider3.initLevelProblem(1);
      await provider3.applyOperation('+', 1, targetSide: 'both'); // extra move
      await provider3.applyOperation('-', 4, targetSide: 'both'); // solve move
      expect(provider3.moveCount, 2);
      expect(provider3.isSolved, isTrue);
      provider3.submitReasoningAnswer(provider3.currentProblem!.correctReasoningIndex);
      expect(provider3.reasoningPassed, isTrue);
      expect(provider3.starRating, 2);
      expect(provider3.xpEarned, 20);

      // Case 4: Optimal moves + correct reasoning = 3 stars & 30 XP
      final provider4 = BalanceScaleProvider();
      provider4.initLevelProblem(1);
      await provider4.applyOperation('-', 3, targetSide: 'both'); // optimal move 1
      expect(provider4.moveCount, 1);
      expect(provider4.isSolved, isTrue);
      provider4.submitReasoningAnswer(provider4.currentProblem!.correctReasoningIndex);
      expect(provider4.reasoningPassed, isTrue);
      expect(provider4.starRating, 3);
      expect(provider4.xpEarned, 30);
    });
  });

  group('PracticeScreen UI Tests', () {
    testWidgets('renders 3 practice mode cards and navigates to Quest Map', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final scaleProvider = BalanceScaleProvider();
      final questRepo = _FakeQuestRepository();
      final questProvider = QuestMapProvider(repository: questRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BalanceScaleProvider>.value(value: scaleProvider),
            ChangeNotifierProvider<QuestMapProvider>.value(value: questProvider),
          ],
          child: const MaterialApp(home: PracticeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Practice Arena'), findsOneWidget);
      expect(find.text('Explore Algebria'), findsOneWidget);
      expect(find.text('AI Module Quiz'), findsOneWidget);
      expect(find.text('Root Finder'), findsOneWidget);

      await tester.tap(find.byKey(const Key('practice-mode-balance-scale')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('BALANDS'), findsOneWidget);
      expect(find.text('The Land of Balancing'), findsOneWidget);
      expect(find.byKey(const Key('quest-level-node-1')), findsOneWidget);
    });

    testWidgets('BalanceScaleScreen celebration dialog renders Back, Retry, and Next Level buttons', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final scaleProvider = BalanceScaleProvider();
      final questRepo = _FakeQuestRepository();
      final questProvider = QuestMapProvider(repository: questRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BalanceScaleProvider>.value(value: scaleProvider),
            ChangeNotifierProvider<QuestMapProvider>.value(value: questProvider),
          ],
          child: const MaterialApp(
            home: BalanceScaleScreen(questLevelNumber: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Solve level 1: -3
      await scaleProvider.applyOperation('-', 3, targetSide: 'both');
      await tester.pumpAndSettle();

      // Answer reasoning check correctly (option 0 for level 1)
      scaleProvider.submitReasoningAnswer(0);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('celebration-btn-back')), findsOneWidget);
      expect(find.byKey(const Key('celebration-btn-retry')), findsOneWidget);
      expect(find.byKey(const Key('celebration-btn-next-level')), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Next Level ➔'), findsOneWidget);
    });
  });
}
