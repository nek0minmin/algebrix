import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/widgets/lesson/activities/classification_activity.dart';
import 'package:algebrix/widgets/lesson/activities/ordering_activity.dart';
import 'package:algebrix/widgets/lesson/activities/term_selection_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('classification reports a complete correct assignment', (
    tester,
  ) async {
    final answers = <bool>[];
    await tester.pumpWidget(
      _testApp(
        ClassificationActivity(
          data: const ClassificationActivityData(
            categories: [
              ActivityCategory(id: 'change', label: 'Can change'),
              ActivityCategory(id: 'stay', label: 'Stays fixed'),
            ],
            items: [
              ClassificationItem(id: 'x', label: 'x', categoryId: 'change'),
              ClassificationItem(id: '7', label: '7', categoryId: 'stay'),
            ],
          ),
          onAnswered: (correct) async => answers.add(correct),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Can change').first);
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Stays fixed').last);
    await tester.pump();
    expect(answers, [true]);
  });

  testWidgets('term selection keeps signed terms together and is responsive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final answers = <bool>[];

    await tester.pumpWidget(
      _testApp(
        TermSelectionActivity(
          data: const TermSelectionActivityData(
            tokens: [
              TermToken(id: 't1', label: '6x', isTerm: true),
              TermToken(id: 't2', label: '+4', isTerm: true),
              TermToken(id: 't3', label: '−2y', isTerm: true),
              TermToken(id: 't4', label: '+9', isTerm: true),
            ],
          ),
          onAnswered: (correct) async => answers.add(correct),
        ),
        textScale: 1.3,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('term-token-t1')));
    await tester.pump();
    await tester.tap(find.text('Check terms'));
    await tester.pump();
    expect(answers, [false]);

    for (final id in ['t2', 't3', 't4']) {
      await tester.tap(find.byKey(ValueKey('term-token-$id')));
      await tester.pump();
    }
    await tester.tap(find.text('Check terms'));
    await tester.pump();

    expect(answers, [false, true]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordering reports selected operation order', (tester) async {
    final answers = <bool>[];
    await tester.pumpWidget(
      _testApp(
        OrderingActivity(
          data: const OrderingActivityData(
            items: [
              OrderingItem(id: 'multiply', label: 'Multiply 2 × 5'),
              OrderingItem(id: 'add', label: 'Add 3'),
            ],
            correctOrderIds: ['multiply', 'add'],
          ),
          onAnswered: (correct) async => answers.add(correct),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('ordering-item-multiply')));
    await tester.tap(find.byKey(const ValueKey('ordering-item-add')));
    await tester.pump();
    expect(answers, [true]);
  });
}

Widget _testApp(Widget child, {double textScale = 1}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    ),
  );
}
