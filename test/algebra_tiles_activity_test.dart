import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/widgets/lesson/activities/algebra_tiles_activity.dart';

const _build = AlgebraTilesActivityData(
  mode: AlgebraTilesMode.build,
  prompt: 'Set the sides so the rectangle is (x + 2)(x + 3).',
  factorP: 2,
  factorQ: 3,
);

const _factor = AlgebraTilesActivityData(
  mode: AlgebraTilesMode.factor,
  prompt: 'Find the two sides whose rectangle is x² + 7x + 12.',
  factorP: 3,
  factorQ: 4,
);

Future<List<bool>> _pump(
  WidgetTester tester,
  AlgebraTilesActivityData data,
) async {
  final reported = <bool>[];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AlgebraTilesActivity(
            data: data,
            onAnswered: (isCorrect) async => reported.add(isCorrect),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  return reported;
}

Future<void> _bump(WidgetTester tester, String side, int times) async {
  final key = Key('tiles-$side-plus');
  for (var i = 0; i < times; i++) {
    final button = find.byKey(key);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
  }
}

Future<void> _check(WidgetTester tester) async {
  final button = find.byKey(const Key('tiles-check'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump();
}

void main() {
  test('the data model reads the rectangle both ways', () {
    expect(_build.xTiles, 5, reason: '2 + 3 strips along the edges');
    expect(_build.unitTiles, 6, reason: '2 × 3 units in the corner');
    expect(_build.factoredLabel, '(x + 2)(x + 3)');
    expect(_build.expandedLabel, 'x² + 5x + 6');

    expect(_factor.xTiles, 7);
    expect(_factor.unitTiles, 12);
    expect(_factor.expandedLabel, 'x² + 7x + 12');
  });

  testWidgets('shows its mode and prompt', (tester) async {
    await _pump(tester, _build);

    expect(find.text('BUILD'), findsOneWidget);
    expect(find.text('FACTOR'), findsNothing);
    expect(find.text(_build.prompt), findsOneWidget);
  });

  testWidgets('the tile tally follows the sides', (tester) async {
    await _pump(tester, _build);

    // An empty workspace is a bare x² square.
    expect(find.text('x²'), findsWidgets);

    await _bump(tester, 'width', 2);
    await _bump(tester, 'height', 3);

    expect(find.byKey(const Key('tiles-expression')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('tiles-expression'))).data,
      'x² + 5x + 6',
      reason: '2 across and 3 down gives 5 strips and 6 units',
    );
  });

  testWidgets('matching the factors completes the build', (tester) async {
    final reported = await _pump(tester, _build);

    await _bump(tester, 'width', 2);
    await _bump(tester, 'height', 3);
    await _check(tester);

    expect(reported, [true]);
    expect(find.byKey(const Key('tiles-result')), findsOneWidget);
    expect(find.text('(x + 2)(x + 3)'), findsOneWidget);
  });

  testWidgets('a rectangle does not care which side is which', (tester) async {
    final reported = await _pump(tester, _build);

    // Sides swapped: 3 across, 2 down.
    await _bump(tester, 'width', 3);
    await _bump(tester, 'height', 2);
    await _check(tester);

    expect(reported, [true]);
  });

  testWidgets('the wrong rectangle is refused and can be adjusted',
      (tester) async {
    final reported = await _pump(tester, _factor);

    // 2 and 6 multiply to 12 but add to 8, not 7.
    await _bump(tester, 'width', 2);
    await _bump(tester, 'height', 6);
    await _check(tester);

    expect(reported, [false]);
    expect(find.byKey(const Key('tiles-result')), findsNothing);
    expect(find.textContaining('adjust a side'), findsOneWidget);

    // Still interactive, so the learner fixes it rather than being stuck.
    await _bump(tester, 'width', 1);
    await tester.pump();
    expect(find.textContaining('adjust a side'), findsNothing,
        reason: 'the nudge clears once they start moving again');

    final factorFinder = find.byKey(const Key('tiles-height-value'));
    expect(tester.widget<Text>(factorFinder).data, '6');
  });

  testWidgets('does not submit before the learner checks', (tester) async {
    final reported = await _pump(tester, _build);

    await _bump(tester, 'width', 2);
    await _bump(tester, 'height', 3);

    expect(reported, isEmpty,
        reason: 'the sides are right, but nothing is claimed until they check');
  });

  testWidgets('a square trinomial is accepted with equal sides',
      (tester) async {
    const square = AlgebraTilesActivityData(
      mode: AlgebraTilesMode.factor,
      prompt: 'Find the two sides whose rectangle is x² + 6x + 9.',
      factorP: 3,
      factorQ: 3,
    );

    final reported = await _pump(tester, square);

    await _bump(tester, 'width', 3);
    await _bump(tester, 'height', 3);
    await _check(tester);

    expect(reported, [true]);
    expect(find.text('(x + 3)(x + 3)'), findsOneWidget);
  });
}
