import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/widgets/lesson/activities/number_line_activity.dart';

const _data = NumberLineActivityData(
  inequality: 'x ≥ −2',
  minValue: -5,
  maxValue: 3,
  correctBoundary: -2,
  correctMarker: NumberLineBoundary.closed,
  correctDirection: NumberLineDirection.right,
);

Future<bool?> _pumpAndSolve(
  WidgetTester tester, {
  required int boundary,
  required Key markerKey,
  required Key directionKey,
  NumberLineActivityData data = _data,
}) async {
  bool? reported;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: NumberLineActivity(
            data: data,
            onAnswered: (isCorrect) async => reported = isCorrect,
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.byKey(Key('number-line-tick-$boundary')));
  await tester.pump();

  await tester.tap(find.byKey(markerKey));
  await tester.pump();

  await tester.tap(find.byKey(directionKey));
  await tester.pump();

  return reported;
}

void main() {
  testWidgets('shows the inequality and every tick on the line', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NumberLineActivity(data: _data, onAnswered: _noop),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('x ≥ −2'), findsOneWidget);
    for (var value = -5; value <= 3; value++) {
      expect(
        find.byKey(Key('number-line-tick-$value')),
        findsOneWidget,
        reason: '$value must be tappable',
      );
    }
  });

  testWidgets('reveals each stage only after the previous one', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NumberLineActivity(data: _data, onAnswered: _noop),
          ),
        ),
      ),
    );
    await tester.pump();

    // Nothing but the line until a boundary is placed.
    expect(find.byKey(const Key('number-line-closed')), findsNothing);
    expect(find.byKey(const Key('number-line-right')), findsNothing);

    await tester.tap(find.byKey(const Key('number-line-tick--2')));
    await tester.pump();

    expect(find.byKey(const Key('number-line-closed')), findsOneWidget);
    expect(
      find.byKey(const Key('number-line-right')),
      findsNothing,
      reason: 'direction waits until inclusion is decided',
    );

    await tester.tap(find.byKey(const Key('number-line-closed')));
    await tester.pump();

    expect(find.byKey(const Key('number-line-right')), findsOneWidget);
  });

  testWidgets('accepts a fully correct graph', (tester) async {
    final result = await _pumpAndSolve(
      tester,
      boundary: -2,
      markerKey: const Key('number-line-closed'),
      directionKey: const Key('number-line-right'),
    );

    expect(result, isTrue);
  });

  testWidgets('rejects the right boundary with the wrong marker',
      (tester) async {
    final result = await _pumpAndSolve(
      tester,
      boundary: -2,
      markerKey: const Key('number-line-open'),
      directionKey: const Key('number-line-right'),
    );

    expect(
      result,
      isFalse,
      reason: 'x ≥ −2 includes the boundary, so an open circle is wrong',
    );
  });

  testWidgets('rejects the wrong direction', (tester) async {
    final result = await _pumpAndSolve(
      tester,
      boundary: -2,
      markerKey: const Key('number-line-closed'),
      directionKey: const Key('number-line-left'),
    );

    expect(result, isFalse);
  });

  testWidgets('rejects the wrong boundary value', (tester) async {
    final result = await _pumpAndSolve(
      tester,
      boundary: 2,
      markerKey: const Key('number-line-closed'),
      directionKey: const Key('number-line-right'),
    );

    expect(result, isFalse);
  });

  testWidgets('re-placing the boundary clears the later choices',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NumberLineActivity(data: _data, onAnswered: _noop),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('number-line-tick--2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('number-line-closed')));
    await tester.pump();
    expect(find.byKey(const Key('number-line-right')), findsOneWidget);

    // Moving the boundary must not leave a stale inclusion answer behind.
    await tester.tap(find.byKey(const Key('number-line-tick-1')));
    await tester.pump();

    expect(find.byKey(const Key('number-line-right')), findsNothing);
  });

  testWidgets('a wrong answer can be retried', (tester) async {
    final reports = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NumberLineActivity(
              data: _data,
              onAnswered: (isCorrect) async => reports.add(isCorrect),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('number-line-tick--2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('number-line-open')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('number-line-right')));
    await tester.pump();

    expect(reports, [false]);

    // Still interactive, so the learner can correct the marker.
    await tester.tap(find.byKey(const Key('number-line-closed')));
    await tester.pump();

    expect(reports, [false, true]);
  });

  testWidgets('ignores taps once solved', (tester) async {
    final reports = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NumberLineActivity(
              data: _data,
              onAnswered: (isCorrect) async => reports.add(isCorrect),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('number-line-tick--2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('number-line-closed')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('number-line-right')));
    await tester.pump();
    expect(reports, [true]);

    await tester.tap(find.byKey(const Key('number-line-left')));
    await tester.pump();

    expect(reports, [true], reason: 'a solved graph is locked');
  });

  testWidgets('does nothing while disabled', (tester) async {
    final reports = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NumberLineActivity(
              data: _data,
              enabled: false,
              onAnswered: (isCorrect) async => reports.add(isCorrect),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('number-line-tick--2')));
    await tester.pump();

    expect(find.byKey(const Key('number-line-closed')), findsNothing);
    expect(reports, isEmpty);
  });
}

Future<void> _noop(bool isCorrect) async {}
