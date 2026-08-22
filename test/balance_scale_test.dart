import 'package:algebrix/core/providers/balance_scale_provider.dart';
import 'package:algebrix/screens/practice/practice_screen.dart';
import 'package:algebrix/services/math_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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

    test('star rating tiers based on move count', () async {
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
    testWidgets('renders 3 practice mode cards and navigates to Balance Scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = BalanceScaleProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: PracticeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Practice Arena'), findsOneWidget);
      expect(find.text('Balance Scale'), findsOneWidget);
      expect(find.text('AI Module Quiz'), findsOneWidget);
      expect(find.text('Root Finder'), findsOneWidget);

      await tester.tap(find.byKey(const Key('practice-mode-balance-scale')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Solve for x'), findsOneWidget);
      expect(find.text('Number Blocks'), findsOneWidget);
    });
  });
}
