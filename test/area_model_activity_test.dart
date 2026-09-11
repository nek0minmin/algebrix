import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/widgets/lesson/activities/area_model_activity.dart';

const _data = AreaModelActivityData(
  expression: '(x + 2)(x + 3)',
  topLabels: ['x', '3'],
  sideLabels: ['x', '2'],
  cells: ['x²', '3x', '2x', '6'],
  choices: ['x²', '3x', '2x', '6', '5x', 'x'],
  result: 'x² + 5x + 6',
);

Future<bool?> _pumpAndFill(
  WidgetTester tester,
  List<String> tilesInCellOrder,
) async {
  bool? reported;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AreaModelActivity(
            data: _data,
            onAnswered: (isCorrect) async => reported = isCorrect,
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  // No cell selected, so each tile drops into the first empty cell in order.
  for (final tile in tilesInCellOrder) {
    await tester.tap(find.byKey(Key('area-tile-$tile')));
    await tester.pump();
  }

  return reported;
}

void main() {
  testWidgets('renders the product, a cell per region and every tile',
      (tester) async {
    await _pumpAndFill(tester, const []);

    expect(find.text('(x + 2)(x + 3)'), findsOneWidget);

    for (var i = 0; i < _data.cells.length; i++) {
      expect(find.byKey(Key('area-cell-$i')), findsOneWidget);
    }
    expect(find.byKey(Key('area-cell-${_data.cells.length}')), findsNothing);

    for (final choice in _data.choices) {
      expect(find.byKey(Key('area-tile-$choice')), findsOneWidget);
    }
  });

  testWidgets('filling every region correctly reports a correct answer',
      (tester) async {
    final reported = await _pumpAndFill(tester, _data.cells);

    expect(reported, isTrue);
    expect(find.text('x² + 5x + 6'), findsOneWidget,
        reason: 'the combined result is revealed once the grid is complete');
  });

  testWidgets('adding the numbers instead of multiplying is marked wrong',
      (tester) async {
    // A learner who writes 5x in the bottom-right instead of 6.
    final reported =
        await _pumpAndFill(tester, const ['x²', '3x', '2x', '5x']);

    expect(reported, isFalse);
    expect(find.text('x² + 5x + 6'), findsNothing);
  });

  testWidgets('does not submit until every region is filled', (tester) async {
    final reported = await _pumpAndFill(tester, const ['x²', '3x', '2x']);

    expect(reported, isNull);
  });

  testWidgets('tapping a filled cell clears it so a wrong tile can be undone',
      (tester) async {
    bool? reported;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AreaModelActivity(
              data: _data,
              onAnswered: (isCorrect) async => reported = isCorrect,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Wrong tile in the first cell.
    await tester.tap(find.byKey(const Key('area-tile-5x')));
    await tester.pump();

    // Clear it and place the right one instead.
    await tester.tap(find.byKey(const Key('area-cell-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('area-tile-x²')));
    await tester.pump();

    for (final tile in _data.cells.skip(1)) {
      await tester.tap(find.byKey(Key('area-tile-$tile')));
      await tester.pump();
    }

    expect(reported, isTrue);
  });
}
