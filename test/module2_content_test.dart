import 'package:algebrix/data/module2_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Module 2 lesson content', () {
    const expectedStepCounts = <String, int>{
      'm2_l1': 7,
      'm2_l2': 7,
      'm2_l3': 7,
      'm2_l4': 8,
      'm2_l5': 7,
      'm2_l6': 7,
      'm2_l7': 12,
    };

    const expectedAnswerSteps = <String, Set<String>>{
      'm2_l1': {'m2_l1_s05', 'm2_l1_s06'},
      'm2_l2': {'m2_l2_s05'},
      'm2_l3': {'m2_l3_s05'},
      'm2_l4': {'m2_l4_s07'},
      'm2_l5': {'m2_l5_s06'},
      'm2_l6': {'m2_l6_s05'},
      'm2_l7': {
        'm2_l7_s02',
        'm2_l7_s03',
        'm2_l7_s04',
        'm2_l7_s05',
        'm2_l7_s06',
        'm2_l7_s07',
        'm2_l7_s08',
        'm2_l7_s09',
        'm2_l7_s10',
        'm2_l7_s11',
      },
    };

    test('contains all 7 approved lessons and exact step counts', () {
      expect(
        module2.lessons.map((lesson) => lesson.lessonId),
        expectedStepCounts.keys,
      );
      for (final lesson in module2.lessons) {
        expect(
          lesson.steps,
          hasLength(expectedStepCounts[lesson.lessonId]!),
          reason: 'Step count mismatch in ${lesson.lessonId}',
        );
      }
    });

    test('uses stable, unique step IDs across all Module 2 lessons', () {
      final allIds = <String>{};
      for (final lesson in module2.lessons) {
        for (var index = 0; index < lesson.steps.length; index++) {
          final step = lesson.steps[index];
          expect(
            allIds.add(step.id),
            isTrue,
            reason: 'Duplicate step ID: ${step.id}',
          );
          final expectedId =
              '${lesson.lessonId}_s${(index + 1).toString().padLeft(2, '0')}';
          expect(step.id, expectedId);
        }
      }
    });

    test('marks all answer-bearing steps correctly with valid choices', () {
      for (final lesson in module2.lessons) {
        final actual = lesson.steps
            .where((step) => step.isAnswerStep)
            .map((step) => step.id)
            .toSet();
        expect(actual, expectedAnswerSteps[lesson.lessonId]);

        for (final step in lesson.steps.where((s) => s.isAnswerStep)) {
          expect(step.choices, isNotNull);
          expect(step.choices!.length, greaterThanOrEqualTo(2));
          expect(step.correctChoiceIndex, isNotNull);
          expect(
            step.correctChoiceIndex!,
            inInclusiveRange(0, step.choices!.length - 1),
          );
          expect(
            step.choices![step.correctChoiceIndex!].isCorrect,
            isTrue,
            reason: 'Choice at correctChoiceIndex must be marked isCorrect: true',
          );
        }
      }
    });

    test('validates core mathematical content and student-friendly formatting', () {
      final steps = {
        for (final lesson in module2.lessons)
          for (final step in lesson.steps) step.id: step,
      };

      // 2.1 Like terms
      expect(steps['m2_l1_s02']!.mathExpression, contains('3x  and  7x  ✓'));
      expect(steps['m2_l1_s05']!.choices![1].label, '3x and 8x');
      expect(steps['m2_l1_s06']!.choices![2].label, '4a² and 7a²');

      // 2.2 Combining
      expect(steps['m2_l2_s04']!.mathExpression, contains('7x − 2x'));
      expect(steps['m2_l2_s05']!.choices![1].label, '7y');

      // 2.3 Distributive property
      expect(steps['m2_l3_s04']!.mathExpression, contains('3x + 6'));
      expect(steps['m2_l3_s05']!.choices![1].label, '4x + 12');

      // 2.4 Properties
      expect(steps['m2_l4_s02']!.mathExpression, contains('a + b = b + a'));
      expect(steps['m2_l4_s07']!.choices![1].label, 'Commutative Property');

      // 2.5 Simplifying
      expect(steps['m2_l5_s04']!.mathExpression, contains('5x + 9'));
      expect(steps['m2_l5_s06']!.choices![0].label, '8x + 6');

      // 2.6 Evaluating
      expect(steps['m2_l6_s04']!.mathExpression, contains('14'));
      expect(steps['m2_l6_s05']!.choices![1].label, '13');

      // 2.7 Challenge
      expect(steps['m2_l7_s02']!.choices![1].label, '5x and 2x');
      expect(steps['m2_l7_s03']!.choices![1].label, '9x');
      expect(steps['m2_l7_s05']!.choices![1].label, '3x + 12');
      expect(steps['m2_l7_s06']!.choices![0].label, '6x + 8');
      expect(steps['m2_l7_s11']!.choices![0].label, '15');
      expect(steps['m2_l7_s12']!.bodyText, contains('+200 XP'));
    });
  });
}
