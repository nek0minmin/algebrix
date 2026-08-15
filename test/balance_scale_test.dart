import 'package:algebrix/core/providers/balance_scale_provider.dart';
import 'package:algebrix/screens/practice/balance_scale_screen.dart';
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
  });

  group('BalanceScaleProvider Tests', () {
    test('initializes problem and applies balance operation', () async {
      final provider = BalanceScaleProvider();
      expect(provider.currentProblem, isNotNull);
      expect(provider.isSolved, isFalse);

      await provider.applyOperation('-', 6);
      expect(provider.history, hasLength(1));
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
      expect(find.text('Quiz Challenge'), findsOneWidget);
      expect(find.text('Root Finder'), findsOneWidget);

      await tester.tap(find.byKey(const Key('practice-mode-balance-scale')));
      await tester.pumpAndSettle();

      expect(find.text('Goal: Solve for x'), findsOneWidget);
      expect(find.text('Perform Equal Operation on Both Sides'), findsOneWidget);
    });
  });
}
