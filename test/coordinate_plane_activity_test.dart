import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/widgets/lesson/activities/coordinate_plane_activity.dart';

const _single = CoordinatePlaneActivityData(
  targets: [GridPoint(3, 2)],
  minX: -1,
  maxX: 4,
  minY: -1,
  maxY: 4,
  prompt: 'Plot the point (3, 2)',
);

const _line = CoordinatePlaneActivityData(
  targets: [GridPoint(0, 1), GridPoint(1, 3), GridPoint(2, 5)],
  minX: -1,
  maxX: 3,
  minY: 0,
  maxY: 6,
  prompt: 'Plot the first three rows of the table',
  connectWhenComplete: true,
);

Future<bool?> _pump(
  WidgetTester tester,
  CoordinatePlaneActivityData data,
  List<GridPoint> taps,
) async {
  bool? reported;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CoordinatePlaneActivity(
            data: data,
            onAnswered: (isCorrect) async => reported = isCorrect,
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  for (final point in taps) {
    await tester.tap(find.byKey(Key('grid-point-${point.x}_${point.y}')));
    await tester.pump();
  }

  return reported;
}

void main() {
  testWidgets('renders the prompt and a tap target per lattice point',
      (tester) async {
    await _pump(tester, _single, const []);

    expect(find.text('Plot the point (3, 2)'), findsOneWidget);

    // 6 x-ticks by 6 y-ticks.
    expect(find.byKey(const Key('grid-point-3_2')), findsOneWidget);
    expect(find.byKey(const Key('grid-point--1_-1')), findsOneWidget);
    expect(find.byKey(const Key('grid-point-4_4')), findsOneWidget);

    // Never asks for a point outside its own range.
    expect(find.byKey(const Key('grid-point-5_0')), findsNothing);
  });

  testWidgets('plotting the target point reports a correct answer',
      (tester) async {
    final reported = await _pump(tester, _single, const [GridPoint(3, 2)]);

    expect(reported, isTrue);
    expect(find.text('(3, 2)'), findsOneWidget);
  });

  testWidgets('swapping x and y reports an incorrect answer', (tester) async {
    final reported = await _pump(tester, _single, const [GridPoint(2, 3)]);

    expect(reported, isFalse, reason: '(2, 3) is not (3, 2)');
  });

  testWidgets('tapping a plotted point removes it before submission',
      (tester) async {
    bool? reported;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CoordinatePlaneActivity(
              data: _line,
              onAnswered: (isCorrect) async => reported = isCorrect,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('grid-point-0_1')));
    await tester.pump();
    expect(find.text('(0, 1)'), findsOneWidget);
    expect(reported, isNull, reason: 'the set is not complete yet');

    await tester.tap(find.byKey(const Key('grid-point-0_1')));
    await tester.pump();
    expect(find.text('(0, 1)'), findsNothing);
    expect(reported, isNull);
  });

  testWidgets('a full set of points submits only once complete',
      (tester) async {
    bool? reported;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CoordinatePlaneActivity(
              data: _line,
              onAnswered: (isCorrect) async => reported = isCorrect,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (final point in _line.targets.take(2)) {
      await tester.tap(find.byKey(Key('grid-point-${point.x}_${point.y}')));
      await tester.pump();
    }
    expect(reported, isNull);

    await tester.tap(find.byKey(const Key('grid-point-2_5')));
    await tester.pump();
    expect(reported, isTrue);
  });

  testWidgets('order does not matter when orderMatters is false',
      (tester) async {
    final reported = await _pump(tester, _line, const [
      GridPoint(2, 5),
      GridPoint(0, 1),
      GridPoint(1, 3),
    ]);

    expect(reported, isTrue);
  });
}
