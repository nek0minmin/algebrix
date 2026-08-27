import 'package:algebrix/data/module3_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Module 3 lesson content', () {
    const expectedStepCounts = <String, int>{
      'm3_l1': 6,
      'm3_l2': 7,
      'm3_l3': 7,
      'm3_l4': 8,
      'm3_l5': 6,
      'm3_l6': 6,
      'm3_l7': 6,
      'm3_l8': 12,
    };

    const expectedAnswerSteps = <String, Set<String>>{
      'm3_l1': {'m3_l1_s05'},
      'm3_l2': {'m3_l2_s06'},
      'm3_l3': {'m3_l3_s06'},
      'm3_l4': {'m3_l4_s07'},
      'm3_l5': <String>{},
      'm3_l6': {'m3_l6_s05'},
      'm3_l7': {'m3_l7_s05'},
      'm3_l8': {
        'm3_l8_s02',
        'm3_l8_s03',
        'm3_l8_s04',
        'm3_l8_s05',
        'm3_l8_s06',
        'm3_l8_s07',
        'm3_l8_s08',
        'm3_l8_s09',
        'm3_l8_s10',
        'm3_l8_s11',
      },
    };

    test('contains all 8 approved lessons and exact step counts', () {
      expect(
        module3.lessons.map((lesson) => lesson.lessonId),
        expectedStepCounts.keys,
      );
      for (final lesson in module3.lessons) {
        expect(
          lesson.steps,
          hasLength(expectedStepCounts[lesson.lessonId]!),
          reason: 'Step count mismatch in ${lesson.lessonId}',
        );
      }
    });

    test('uses stable, unique step IDs across all Module 3 lessons', () {
      final allIds = <String>{};
      for (final lesson in module3.lessons) {
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
      for (final lesson in module3.lessons) {
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

    test('validates core mathematical content across Module 3', () {
      final steps = {
        for (final lesson in module3.lessons)
          for (final step in lesson.steps) step.id: step,
      };

      // 3.1 Understanding Equations
      expect(steps['m3_l1_s01']!.xyDialogue, contains('3x + 2 = 11'));
      expect(steps['m3_l1_s05']!.choices![2].label, '6');
      expect(steps['m3_l1_s05']!.correctChoiceIndex, 2);

      // 3.2 Inverse Operations
      expect(steps['m3_l2_s06']!.correctChoiceIndex, 1);
      expect(steps['m3_l2_s06']!.choices![1].label, '+7');

      // 3.3 One-Step Equations
      expect(steps['m3_l3_s06']!.choices![0].label, '+9');
      expect(steps['m3_l3_s06']!.correctChoiceIndex, 0);

      // 3.4 Two-Step Equations
      expect(steps['m3_l4_s07']!.choices![1].label, 'x = 4');
      expect(steps['m3_l4_s07']!.correctChoiceIndex, 1);

      // 3.5 Variables on Both Sides
      expect(steps['m3_l5_s02']!.mathExpression, contains('2x + 2 = 10'));

      // 3.6 Equations with Parentheses
      expect(steps['m3_l6_s05']!.choices![1].label, 'x = 5');
      expect(steps['m3_l6_s05']!.correctChoiceIndex, 1);

      // 3.7 Checking Solutions
      expect(steps['m3_l7_s05']!.correctChoiceIndex, 0);
      expect(steps['m3_l7_s05']!.choices![0].label, contains('Yes'));

      // 3.8 Module 3 Challenge — Equation Quest (10 Challenges)
      expect(steps['m3_l8_s02']!.correctChoiceIndex, 2); // 3x + 2 = 11
      expect(steps['m3_l8_s03']!.correctChoiceIndex, 1); // −8
      expect(steps['m3_l8_s04']!.correctChoiceIndex, 1); // x = 15
      expect(steps['m3_l8_s05']!.correctChoiceIndex, 1); // x = 6
      expect(steps['m3_l8_s06']!.correctChoiceIndex, 0); // x = 5
      expect(steps['m3_l8_s07']!.correctChoiceIndex, 1); // preserve equality
      expect(steps['m3_l8_s08']!.correctChoiceIndex, 1); // x = 4
      expect(steps['m3_l8_s09']!.correctChoiceIndex, 0); // x = 5
      expect(steps['m3_l8_s10']!.correctChoiceIndex, 1); // x = 3
      expect(steps['m3_l8_s11']!.correctChoiceIndex, 1); // 4(6) - 5 = 19
    });
  });
}
