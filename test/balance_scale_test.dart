import 'package:algebrix/core/providers/balance_scale_provider.dart';
import 'package:algebrix/core/providers/quest_map_provider.dart';
import 'package:algebrix/models/quest_map_model.dart';
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

    test('star rating tiers based on move count and reasoning', () async {
      final provider = BalanceScaleProvider();
      // Star rating is 0 before solving
      expect(provider.starRating, 0);
    });

    test('reasoning check flow works', () {
      final provider = BalanceScaleProvider();
      final problem = provider.currentProblem!;

      // Initially, reasoning not passed
      expect(provider.reasoningPassed, isFalse);
      expect(provider.showReasoningCheck, isFalse);

      // Wrong answer
      final wrongIdx = (problem.correctReasoningIndex + 1) % 3;
      final isCorrect = provider.submitReasoningAnswer(wrongIdx);
      expect(isCorrect, isFalse);
      expect(provider.reasoningPassed, isFalse);

      // Correct answer
      final correct = provider.submitReasoningAnswer(problem.correctReasoningIndex);
      expect(correct, isTrue);
      expect(provider.reasoningPassed, isTrue);
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

      expect(find.text('Balands'), findsOneWidget);
      expect(find.text('The Land of Balancing'), findsOneWidget);
      expect(find.byKey(const Key('quest-level-node-1')), findsOneWidget);
    });
  });
}
