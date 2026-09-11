import 'dart:io';

import 'package:algebrix/data/lesson_catalog.dart';
import 'package:algebrix/data/module4_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Module 4 lesson content', () {
    const expectedStepCounts = <String, int>{
      'm4_l1': 9,
      'm4_l2': 10,
      'm4_l3': 9,
      'm4_l4': 10,
      'm4_l5': 11,
    };

    const expectedAnswerSteps = <String, Set<String>>{
      'm4_l1': {'m4_l1_s06', 'm4_l1_s08'},
      'm4_l2': {'m4_l2_s07', 'm4_l2_s09'},
      'm4_l3': {'m4_l3_s04', 'm4_l3_s08'},
      'm4_l4': {'m4_l4_s06', 'm4_l4_s08', 'm4_l4_s09'},
      'm4_l5': {
        'm4_l5_s06',
        'm4_l5_s07',
        'm4_l5_s08',
        'm4_l5_s09',
        'm4_l5_s10',
      },
    };

    test('ships the five approved lessons with exact step counts', () {
      expect(module4.id, 'module4');
      expect(module4.title, 'Inequalities');
      expect(
        module4.lessons.map((l) => l.lessonId).toList(),
        expectedStepCounts.keys.toList(),
      );

      for (final lesson in module4.lessons) {
        expect(
          lesson.steps.length,
          expectedStepCounts[lesson.lessonId],
          reason: '${lesson.lessonId} step count changed',
        );
      }
    });

    test('answer steps match the catalog migration', () {
      for (final lesson in module4.lessons) {
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
      for (final lesson in module4.lessons) {
        for (final step in lesson.steps) {
          expect(step.id.startsWith('${lesson.lessonId}_s'), isTrue,
              reason: '${step.id} does not belong to ${lesson.lessonId}');
          expect(seen.add(step.id), isTrue, reason: 'duplicate ${step.id}');
        }
      }
    });

    test('every lesson belongs to module4 and ends on a summary', () {
      for (final lesson in module4.lessons) {
        expect(lesson.moduleId, 'module4');
        expect(lesson.steps.last.type, LessonStepType.summary);
        expect(lesson.objective, isNotEmpty);
      }
    });

    test('every answer step can actually be answered', () {
      for (final lesson in module4.lessons) {
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
            expect(correct, 1, reason: '${step.id} needs exactly one correct choice');
            expect(
              step.choices![step.correctChoiceIndex!].isCorrect,
              isTrue,
              reason: '${step.id} correctChoiceIndex points at a wrong option',
            );
          }

          expect(step.explanation, isNotNull, reason: '${step.id} has no explanation');
          expect(
            step.incorrectExplanation,
            isNotNull,
            reason: '${step.id} has no guidance for a wrong answer',
          );
        }
      }
    });

    test('graphing activities describe a solvable number line', () {
      final graphs = module4.lessons
          .expand((lesson) => lesson.steps)
          .map((step) => step.activity)
          .whereType<NumberLineActivityData>()
          .toList();

      expect(graphs, hasLength(3), reason: '4.5 ships three graphing tasks');

      for (final graph in graphs) {
        expect(graph.minValue, lessThan(graph.maxValue));
        expect(graph.correctBoundary, greaterThanOrEqualTo(graph.minValue));
        expect(graph.correctBoundary, lessThanOrEqualTo(graph.maxValue));
        expect(graph.inequality, isNotEmpty);
        expect(
          graph.ticks,
          contains(graph.correctBoundary),
          reason: 'the boundary must be tappable on the line',
        );
      }
    });

    test('classification activities have a home for every item', () {
      final sorts = module4.lessons
          .expand((lesson) => lesson.steps)
          .map((step) => step.activity)
          .whereType<ClassificationActivityData>()
          .toList();

      expect(sorts, isNotEmpty);
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
  });

  group('Module 4 registration', () {
    test('is registered in the catalog after module 3', () {
      expect(LessonCatalog.modules.map((m) => m.id).toList(),
          ['module1', 'module2', 'module3', 'module4', 'module5', 'module6']);
      expect(LessonCatalog.totalLessons, 41);
    });

    test('lesson lookups and labels resolve', () {
      expect(LessonCatalog.lessonById('m4_l5')?.title, 'Graphing Inequalities');
      expect(LessonCatalog.moduleForLesson('m4_l1')?.id, 'module4');
      expect(LessonCatalog.lessonNumberLabel('m4_l3'), '4.3');
    });

    test('practice can drop a learner on the first question step', () {
      for (final lesson in module4.lessons) {
        final index = LessonCatalog.firstAnswerStepIndex(lesson.lessonId);
        expect(index, isNotNull, reason: '${lesson.lessonId} has no question step');
      }
    });
  });

  group('Module 4 Supabase catalog', () {
    // The catalog migration was generated from this content. If they drift,
    // record_lesson_step rejects the step and lesson progress silently stops
    // saving, so this pins them together.
    test('migration lists exactly the shipped steps', () {
      final file = File(
        'supabase/migrations/202609100001_module4_lessons_catalog.sql',
      );
      expect(file.existsSync(), isTrue, reason: 'catalog migration missing');

      final sql = file.readAsStringSync();

      for (final lesson in module4.lessons) {
        for (var i = 0; i < lesson.steps.length; i++) {
          final step = lesson.steps[i];
          final row = "('module4', '${lesson.lessonId}', '${step.id}', 1, $i, "
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
