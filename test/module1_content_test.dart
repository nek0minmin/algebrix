import 'package:algebrix/data/module1_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Module 1 lesson content', () {
    const expectedStepCounts = <String, int>{
      'm1_l1': 7,
      'm1_l2': 9,
      'm1_l3': 8,
      'm1_l4': 9,
      'm1_l5': 10,
      'm1_l6': 10,
    };

    const expectedAnswerSteps = <String, Set<String>>{
      'm1_l1': {'step4', 'step5', 'step6'},
      'm1_l2': {'m1_l2_s05', 'm1_l2_s07', 'm1_l2_s08'},
      'm1_l3': {'m1_l3_s05', 'm1_l3_s06'},
      'm1_l4': {'m1_l4_s06', 'm1_l4_s07', 'm1_l4_s08'},
      'm1_l5': {'m1_l5_s06', 'm1_l5_s07', 'm1_l5_s08'},
      'm1_l6': {'m1_l6_s03', 'm1_l6_s07', 'm1_l6_s08', 'm1_l6_s09'},
    };

    test('contains the approved lessons and step counts', () {
      expect(
        module1.lessons.map((lesson) => lesson.lessonId),
        expectedStepCounts.keys,
      );
      for (final lesson in module1.lessons) {
        expect(lesson.steps, hasLength(expectedStepCounts[lesson.lessonId]!));
      }
    });

    test('uses stable, unique step IDs', () {
      final allIds = <String>{};
      for (final lesson in module1.lessons) {
        for (final step in lesson.steps) {
          expect(
            allIds.add(step.id),
            isTrue,
            reason: 'Duplicate step ID: ${step.id}',
          );
        }
      }
      for (final lesson in module1.lessons.skip(1)) {
        for (var index = 0; index < lesson.steps.length; index++) {
          final expected =
              '${lesson.lessonId}_s${(index + 1).toString().padLeft(2, '0')}';
          expect(lesson.steps[index].id, expected);
        }
      }
    });

    test('marks only approved answer-bearing steps', () {
      for (final lesson in module1.lessons) {
        final actual = lesson.steps
            .where((step) => step.isAnswerStep)
            .map((step) => step.id)
            .toSet();
        expect(actual, expectedAnswerSteps[lesson.lessonId]);
      }
    });

    test('attaches the approved typed activities', () {
      final steps = {
        for (final lesson in module1.lessons)
          for (final step in lesson.steps) step.id: step,
      };

      expect(steps['m1_l2_s05']!.activity, isA<ClassificationActivityData>());
      expect(steps['m1_l3_s05']!.activity, isA<TermSelectionActivityData>());
      expect(steps['m1_l4_s06']!.activity, isA<ClassificationActivityData>());
      expect(steps['m1_l6_s07']!.activity, isA<OrderingActivityData>());
      expect(steps.values.where((step) => step.activity != null), hasLength(4));
    });

    test('keeps the approved instruction-critical examples', () {
      final steps = {
        for (final lesson in module1.lessons)
          for (final step in lesson.steps) step.id: step,
      };

      final constantDefinition = steps['m1_l2_s02']!.bodyText!;
      for (final example in ['5', '12', '100', '−3', '½']) {
        expect(constantDefinition, contains(example));
      }
      final constants =
          steps['m1_l2_s05']!.activity! as ClassificationActivityData;
      expect(constants.items.map((item) => item.label), [
        'x',
        '7',
        'y',
        '15',
        'a',
        '−4',
      ]);
      expect(steps['m1_l2_s08']!.question, contains('x changes from 2 to 10'));
      expect(steps['m1_l3_s06']!.question, contains('3x + 5 − y'));
      expect(
        steps['m1_l4_s07']!.choices!
            .singleWhere((choice) => choice.isCorrect)
            .label,
        'x + 5',
      );
      expect(steps['m1_l4_s08']!.question, contains('3x + 5 = 20'));
      expect(steps['m1_l6_s02']!.mathExpression, '2 + 3 × 4');
      expect(steps['m1_l6_s03']!.question, contains('6 + 4 × 3'));
      expect(
        steps['m1_l6_s06']!.mathExpression,
        '2 + 3 × 4 = 14     (2 + 3) × 4 = 20',
      );
      final ordering = steps['m1_l6_s07']!.activity! as OrderingActivityData;
      expect(ordering.items.map((item) => item.label), [
        '13',
        '3 + 10',
        '2 × 5',
      ]);
      expect(ordering.correctOrderIds, ['multiply', 'add', 'answer']);
    });
  });
}
