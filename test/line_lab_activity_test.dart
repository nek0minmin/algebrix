import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:algebrix/widgets/lesson/activities/line_lab_activity.dart';

Future<List<bool>> _pump(
  WidgetTester tester,
  LineLabActivityData data,
) async {
  final reported = <bool>[];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LineLabActivity(
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

/// Drags a slider by setting its value the way a user's drag would resolve.
Future<void> _setSlider(WidgetTester tester, Key key, double value) async {
  final slider = tester.widget<Slider>(find.byKey(key));
  slider.onChanged!(value);
  await tester.pump();
}

void main() {
  testWidgets('shows the goal and the live equation', (tester) async {
    await _pump(
      tester,
      const LineLabActivityData(
        goal: 'Can you make the line horizontal?',
        targetSlope: 0,
        startSlope: 2,
        startIntercept: 1,
      ),
    );

    expect(find.text('Can you make the line horizontal?'), findsOneWidget);
    expect(find.text('y = 2x + 1'), findsOneWidget);
  });

  testWidgets('the equation follows the sliders', (tester) async {
    await _pump(
      tester,
      const LineLabActivityData(
        goal: 'Explore',
        startSlope: 1,
        startIntercept: 0,
      ),
    );

    expect(find.text('y = x'), findsOneWidget);

    await _setSlider(tester, const Key('line-lab-slope'), 3);
    expect(find.text('y = 3x'), findsOneWidget);

    await _setSlider(tester, const Key('line-lab-intercept'), -2);
    expect(find.text('y = 3x − 2'), findsOneWidget);

    // Slope zero drops the x term entirely rather than printing "0x".
    await _setSlider(tester, const Key('line-lab-slope'), 0);
    expect(find.text('y = −2'), findsOneWidget);
  });

  testWidgets('meeting a slope goal reports success', (tester) async {
    final reported = await _pump(
      tester,
      const LineLabActivityData(
        goal: 'Can you make the line horizontal?',
        targetSlope: 0,
        startSlope: 3,
        startIntercept: 1,
      ),
    );

    expect(reported, isEmpty);

    await _setSlider(tester, const Key('line-lab-slope'), 1);
    expect(reported, isEmpty, reason: 'not flat yet');

    await _setSlider(tester, const Key('line-lab-slope'), 0);
    expect(reported, [true]);
  });

  testWidgets('a goal needing both dials waits for both', (tester) async {
    final reported = await _pump(
      tester,
      const LineLabActivityData(
        goal: 'Build y = −x + 3',
        targetSlope: -1,
        targetIntercept: 3,
        startSlope: 2,
        startIntercept: -2,
      ),
    );

    await _setSlider(tester, const Key('line-lab-slope'), -1);
    expect(reported, isEmpty, reason: 'the intercept is still wrong');

    await _setSlider(tester, const Key('line-lab-intercept'), 3);
    expect(reported, [true]);
  });

  testWidgets('never reports a wrong answer — only "not yet"', (tester) async {
    final reported = await _pump(
      tester,
      const LineLabActivityData(
        goal: 'Can you make the line cross at 4?',
        targetIntercept: 4,
        startSlope: 1,
        startIntercept: 0,
      ),
    );

    for (final value in [-3.0, 1.0, 2.0, -5.0]) {
      await _setSlider(tester, const Key('line-lab-intercept'), value);
    }

    expect(reported, isEmpty,
        reason: 'a sandbox must never mark the learner wrong');

    await _setSlider(tester, const Key('line-lab-intercept'), 4);
    expect(reported, [true]);
  });

  testWidgets('an open-ended lab is finished by the learner', (tester) async {
    final reported = await _pump(
      tester,
      const LineLabActivityData(goal: 'Explore freely — there is no target.'),
    );

    // Moving the sliders alone must not end a free-play step.
    await _setSlider(tester, const Key('line-lab-slope'), 4);
    await _setSlider(tester, const Key('line-lab-intercept'), -1);
    expect(reported, isEmpty);

    final done = find.byKey(const Key('line-lab-done'));
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    await tester.tap(done);
    await tester.pump();
    expect(reported, [true]);
  });
}
