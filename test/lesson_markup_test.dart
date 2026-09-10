import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/data/lesson_catalog.dart';
import 'package:algebrix/widgets/lesson/lesson_rich_text.dart';

const _base = TextStyle(color: AppColors.text);
const _emphasis = TextStyle(color: AppColors.darkPink);

/// Flattens the rendered spans back to the text a learner actually sees.
String _rendered(List<InlineSpan> spans) {
  final buffer = StringBuffer();
  for (final span in spans) {
    if (span is TextSpan) buffer.write(span.text ?? '');
  }
  return buffer.toString();
}

void main() {
  group('buildLessonSpans', () {
    test('consumes bold markers instead of showing them', () {
      final spans = buildLessonSpans(
        'If x < 6, which value does **not** belong?',
        base: _base,
        emphasis: _emphasis,
      );

      final text = _rendered(spans);
      expect(text, 'If x < 6, which value does not belong?');
      expect(text, isNot(contains('*')));
    });

    test('styles the emphasised run and leaves the rest plain', () {
      final spans = buildLessonSpans(
        'the **wide side** opens toward the greater value',
        base: _base,
        emphasis: _emphasis,
      ).whereType<TextSpan>().toList();

      final emphasised =
          spans.where((s) => s.style?.color == AppColors.darkPink).toList();
      expect(emphasised, hasLength(1));
      expect(emphasised.single.text, 'wide side');
    });

    test('renders code ticks as a widget, not as backticks', () {
      final spans = buildLessonSpans(
        'Undo it: `x + 4 − 4 > 9 − 4`',
        base: _base,
        emphasis: _emphasis,
      );

      expect(_rendered(spans), isNot(contains('`')));
      expect(spans.whereType<WidgetSpan>(), hasLength(1));
    });

    test('handles bold and code together', () {
      final spans = buildLessonSpans(
        'Solve **x + 3 < 8**.\n\nSubtract: `x + 3 − 3 < 8 − 3`',
        base: _base,
        emphasis: _emphasis,
      );

      final text = _rendered(spans);
      expect(text, isNot(contains('*')));
      expect(text, isNot(contains('`')));
      expect(text, contains('x + 3 < 8'));
    });

    test('leaves unmarked text untouched', () {
      final spans = buildLessonSpans(
        'Plain copy with no markup at all.',
        base: _base,
        emphasis: _emphasis,
      );
      expect(_rendered(spans), 'Plain copy with no markup at all.');
    });

    test('never renders an empty widget for stray markers', () {
      final spans = buildLessonSpans('**', base: _base, emphasis: _emphasis);
      expect(spans, isNotEmpty);
    });
  });

  group('LessonRichText widget', () {
    testWidgets('shows the word, never the asterisks', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LessonRichText(
              'Multiply both sides by **−1**.',
              base: _base,
              emphasis: _emphasis,
            ),
          ),
        ),
      );
      await tester.pump();

      final richText = tester.widget<Text>(find.byType(Text));
      final shown = richText.textSpan!.toPlainText();

      expect(shown, contains('−1'));
      expect(
        shown,
        isNot(contains('*')),
        reason: 'a learner must never see a raw bold marker',
      );
    });
  });

  group('Lesson content markup is balanced', () {
    // An odd number of ** markers means one of them has no partner, which
    // renders the rest of the line in the wrong style.
    test('every content string has paired bold markers', () {
      final offenders = <String>[];

      for (final lesson in LessonCatalog.lessons) {
        for (final step in lesson.steps) {
          final strings = <String?>[
            step.bodyText,
            step.xyDialogue,
            step.question,
            step.explanation,
            step.incorrectExplanation,
            step.mathAnnotation,
            step.title,
          ];

          for (final value in strings) {
            if (value == null) continue;
            final count = '**'.allMatches(value).length;
            if (count.isOdd) offenders.add('${step.id}: $value');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'unpaired ** markers:\n${offenders.join('\n')}',
      );
    });

    test('every content string has paired code ticks', () {
      final offenders = <String>[];

      for (final lesson in LessonCatalog.lessons) {
        for (final step in lesson.steps) {
          for (final value in <String?>[
            step.bodyText,
            step.xyDialogue,
            step.question,
            step.explanation,
            step.incorrectExplanation,
          ]) {
            if (value == null) continue;
            if ('`'.allMatches(value).length.isOdd) {
              offenders.add('${step.id}: $value');
            }
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'unpaired backticks:\n${offenders.join('\n')}',
      );
    });

    test('bullet chips stay short enough to read', () {
      final offenders = <String>[];

      for (final lesson in LessonCatalog.lessons) {
        for (final step in lesson.steps) {
          for (final point in step.bulletPoints ?? const <String>[]) {
            // Longer than this and the chip becomes a paragraph in a pill;
            // that copy belongs in bodyText or the annotation instead.
            if (point.length > 12) offenders.add('${step.id}: "$point"');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'bullet chips too long to render legibly:\n'
            '${offenders.join('\n')}',
      );
    });
  });
}
