import 'dart:io';

import 'package:algebrix/data/lesson_catalog.dart';
import 'package:algebrix/data/module5_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Module 5 lesson content', () {
    const expectedStepCounts = <String, int>{
      'm5_l1': 11,
      'm5_l2': 11,
      'm5_l3': 8,
      'm5_l4': 12,
      'm5_l5': 8,
      'm5_l6': 8,
    };

    const expectedAnswerSteps = <String, Set<String>>{
      'm5_l1': {'m5_l1_s05', 'm5_l1_s08', 'm5_l1_s09', 'm5_l1_s10'},
      'm5_l2': {'m5_l2_s05', 'm5_l2_s06', 'm5_l2_s08', 'm5_l2_s10'},
      'm5_l3': {'m5_l3_s03', 'm5_l3_s05', 'm5_l3_s07'},
      'm5_l4': {'m5_l4_s06', 'm5_l4_s07', 'm5_l4_s09', 'm5_l4_s11'},
      'm5_l5': {'m5_l5_s04', 'm5_l5_s06', 'm5_l5_s07'},
      'm5_l6': {'m5_l6_s04', 'm5_l6_s05', 'm5_l6_s06', 'm5_l6_s07'},
    };

    test('ships the six approved lessons with exact step counts', () {
      expect(module5.id, 'module5');
      expect(module5.title, 'Linear Relationships');
      expect(
        module5.lessons.map((l) => l.lessonId).toList(),
        expectedStepCounts.keys.toList(),
      );

      for (final lesson in module5.lessons) {
        expect(
          lesson.steps.length,
          expectedStepCounts[lesson.lessonId],
          reason: '${lesson.lessonId} step count changed',
        );
      }
    });

    test('answer steps match the catalog migration', () {
      for (final lesson in module5.lessons) {
        final answerSteps = lesson.steps
            .where((step) => step.isAnswerStep)
            .map((step) => step.id)
            .toSet();
        expect(
          answerSteps,
          expectedAnswerSteps[lesson.lessonId],
          reason: '${lesson.lessonId} answer steps changed; the Supabase '
              'catalog migration must be regenerated to match',
        );
      }
    });

    test('every step id is unique and correctly prefixed', () {
      final seen = <String>{};
      for (final lesson in module5.lessons) {
        for (final step in lesson.steps) {
          expect(step.id.startsWith('${lesson.lessonId}_s'), isTrue,
              reason: '${step.id} does not belong to ${lesson.lessonId}');
          expect(seen.add(step.id), isTrue, reason: 'duplicate ${step.id}');
        }
      }
    });

    test('every lesson belongs to module5 and ends on a summary', () {
      for (final lesson in module5.lessons) {
        expect(lesson.moduleId, 'module5');
        expect(lesson.steps.last.type, LessonStepType.summary);
        expect(lesson.objective, isNotEmpty);
      }
    });

    test('every answer step can actually be answered', () {
      for (final lesson in module5.lessons) {
        for (final step in lesson.steps.where((s) => s.isAnswerStep)) {
          final hasChoices = (step.choices?.isNotEmpty ?? false);
          final hasActivity = step.activity != null;
          expect(
            hasChoices || hasActivity,
            isTrue,
            reason: '${step.id} is an answer step with nothing to answer',
          );

          if (hasChoices) {
            final correct = step.choices!.where((c) => c.isCorrect).length;
            expect(correct, 1,
                reason: '${step.id} needs exactly one correct choice');
            expect(
              step.choices![step.correctChoiceIndex!].isCorrect,
              isTrue,
              reason: '${step.id} correctChoiceIndex points at a wrong option',
            );
          }

          expect(step.explanation, isNotNull,
              reason: '${step.id} has no explanation');
          expect(
            step.incorrectExplanation,
            isNotNull,
            reason: '${step.id} has no guidance for a wrong answer',
          );
        }
      }
    });

    test('every plotting target sits inside its own grid', () {
      final planes = module5.lessons
          .expand((lesson) => lesson.steps)
          .map((step) => step.activity)
          .whereType<CoordinatePlaneActivityData>()
          .toList();

      expect(planes, isNotEmpty, reason: 'Module 5 is built around plotting');

      for (final plane in planes) {
        expect(plane.minX, lessThan(plane.maxX));
        expect(plane.minY, lessThan(plane.maxY));
        expect(plane.targets, isNotEmpty);

        for (final target in plane.targets) {
          expect(target.x, greaterThanOrEqualTo(plane.minX),
              reason: 'target (${target.x}, ${target.y}) is off the grid');
          expect(target.x, lessThanOrEqualTo(plane.maxX),
              reason: 'target (${target.x}, ${target.y}) is off the grid');
          expect(target.y, greaterThanOrEqualTo(plane.minY),
              reason: 'target (${target.x}, ${target.y}) is off the grid');
          expect(target.y, lessThanOrEqualTo(plane.maxY),
              reason: 'target (${target.x}, ${target.y}) is off the grid');
        }

        final unique = plane.targets.map((t) => '${t.x},${t.y}').toSet();
        expect(unique, hasLength(plane.targets.length),
            reason: 'the same point is asked for twice');
      }
    });

    test('classification activities have a home for every item', () {
      final sorts = module5.lessons
          .expand((lesson) => lesson.steps)
          .map((step) => step.activity)
          .whereType<ClassificationActivityData>()
          .toList();

      for (final sort in sorts) {
        final categoryIds = sort.categories.map((c) => c.id).toSet();
        for (final item in sort.items) {
          expect(
            categoryIds,
            contains(item.categoryId),
            reason: '${item.label} points at a category that does not exist',
          );
        }
      }
    });

    test('ordering activities list every item exactly once', () {
      final orders = module5.lessons
          .expand((lesson) => lesson.steps)
          .map((step) => step.activity)
          .whereType<OrderingActivityData>()
          .toList();

      for (final order in orders) {
        expect(
          order.correctOrderIds.toSet(),
          order.items.map((i) => i.id).toSet(),
          reason: 'the correct order does not cover exactly the offered items',
        );
        expect(order.correctOrderIds, hasLength(order.items.length));
      }
    });
  });

  group('Module 5 registration', () {
    test('is registered in the catalog after module 4', () {
      final ids = LessonCatalog.modules.map((m) => m.id).toList();
      expect(ids.indexOf('module5'), ids.indexOf('module4') + 1);
    });

    test('lesson lookups and labels resolve', () {
      expect(LessonCatalog.lessonById('m5_l1')?.title,
          'Exploring the Coordinate Plane');
      expect(LessonCatalog.moduleForLesson('m5_l6')?.id, 'module5');
      expect(LessonCatalog.lessonNumberLabel('m5_l4'), '5.4');
    });

    test('practice can drop a learner on the first question step', () {
      for (final lesson in module5.lessons) {
        final index = LessonCatalog.firstAnswerStepIndex(lesson.lessonId);
        expect(index, isNotNull,
            reason: '${lesson.lessonId} has no question step');
      }
    });
  });

  group('Module 5 Supabase catalog', () {
    // The catalog migration was generated from this content. If they drift,
    // record_lesson_step rejects the step and lesson progress silently stops
    // saving, so this pins them together.
    test('migration lists exactly the shipped steps', () {
      final file = File(
        'supabase/migrations/202609110001_module5_lessons_catalog.sql',
      );
      expect(file.existsSync(), isTrue, reason: 'catalog migration missing');

      final sql = file.readAsStringSync();

      for (final lesson in module5.lessons) {
        for (var i = 0; i < lesson.steps.length; i++) {
          final step = lesson.steps[i];
          final row = "('module5', '${lesson.lessonId}', '${step.id}', 1, $i, "
              "${step.isAnswerStep ? 'TRUE' : 'FALSE'}, 0, "
              "${i == lesson.steps.length - 1 ? 'TRUE' : 'FALSE'})";
          expect(
            sql,
            contains(row),
            reason: 'catalog migration is missing or disagrees about ${step.id}',
          );
        }
      }
    });
  });
}
