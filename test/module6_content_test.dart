import 'dart:io';

import 'package:algebrix/data/lesson_catalog.dart';
import 'package:algebrix/data/module6_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Module 6 lesson content', () {
    const expectedStepCounts = <String, int>{
      'm6_l1': 9,
      'm6_l2': 7,
      'm6_l3': 8,
      'm6_l4': 10,
      'm6_l5': 10,
      'm6_l6': 12,
      'm6_l7': 9,
    };

    const expectedAnswerSteps = <String, Set<String>>{
      'm6_l1': {'m6_l1_s06', 'm6_l1_s07', 'm6_l1_s08'},
      'm6_l2': {'m6_l2_s05', 'm6_l2_s06'},
      'm6_l3': {'m6_l3_s05', 'm6_l3_s06', 'm6_l3_s07'},
      'm6_l4': {'m6_l4_s04', 'm6_l4_s08', 'm6_l4_s09'},
      'm6_l5': {'m6_l5_s04', 'm6_l5_s07', 'm6_l5_s08', 'm6_l5_s09'},
      'm6_l6': {
        'm6_l6_s02', 'm6_l6_s03', 'm6_l6_s04', 'm6_l6_s05', 'm6_l6_s06',
        'm6_l6_s07', 'm6_l6_s08', 'm6_l6_s09', 'm6_l6_s10', 'm6_l6_s11',
      },
      'm6_l7': {
        'm6_l7_s04', 'm6_l7_s05', 'm6_l7_s06', 'm6_l7_s07', 'm6_l7_s08',
      },
    };

    test('ships the seven approved lessons with exact step counts', () {
      expect(module6.id, 'module6');
      expect(module6.title, 'Polynomials');
      expect(
        module6.lessons.map((l) => l.lessonId).toList(),
        expectedStepCounts.keys.toList(),
      );

      for (final lesson in module6.lessons) {
        expect(
          lesson.steps.length,
          expectedStepCounts[lesson.lessonId],
          reason: '${lesson.lessonId} step count changed',
        );
      }
    });

    test('answer steps match the catalog migration', () {
      for (final lesson in module6.lessons) {
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
      for (final lesson in module6.lessons) {
        for (final step in lesson.steps) {
          expect(step.id.startsWith('${lesson.lessonId}_s'), isTrue,
              reason: '${step.id} does not belong to ${lesson.lessonId}');
          expect(seen.add(step.id), isTrue, reason: 'duplicate ${step.id}');
        }
      }
    });

    test('every lesson belongs to module6 and ends on a summary', () {
      for (final lesson in module6.lessons) {
        expect(lesson.moduleId, 'module6');
        expect(lesson.steps.last.type, LessonStepType.summary);
        expect(lesson.objective, isNotEmpty);
      }
    });

    test('every answer step can actually be answered', () {
      for (final lesson in module6.lessons) {
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

    test('area models are rectangular and every cell is reachable', () {
      final grids = module6.lessons
          .expand((lesson) => lesson.steps)
          .map((step) => step.activity)
          .whereType<AreaModelActivityData>()
          .toList();

      expect(grids, isNotEmpty,
          reason: '6.4 teaches multiplication through the area model');

      for (final grid in grids) {
        expect(grid.cells, hasLength(grid.rows * grid.columns),
            reason: '${grid.expression} has the wrong number of cells');
        expect(grid.result, isNotEmpty);

        for (final cell in grid.cells) {
          expect(
            grid.choices,
            contains(cell),
            reason: '"$cell" is a correct answer that is never offered',
          );
        }

        expect(grid.choices.toSet(), hasLength(grid.choices.length),
            reason: '${grid.expression} offers the same tile twice');
        expect(grid.choices.length, greaterThan(grid.cells.length),
            reason: '${grid.expression} needs at least one distractor');
      }
    });

    test('the area model is taught before FOIL is named', () {
      final multiplying =
          module6.lessons.firstWhere((l) => l.lessonId == 'm6_l4');

      final firstGrid = multiplying.steps
          .indexWhere((step) => step.activity is AreaModelActivityData);
      final firstFoil = multiplying.steps.indexWhere(
        (step) => [step.bodyText, step.xyDialogue, step.title]
            .whereType<String>()
            .any((text) => text.toUpperCase().contains('FOIL')),
      );

      expect(firstGrid, greaterThanOrEqualTo(0));
      expect(firstFoil, greaterThanOrEqualTo(0),
          reason: 'FOIL should still be named, just later');
      expect(firstFoil, greaterThan(firstGrid),
          reason: 'FOIL must arrive as a shortcut, after the area model');
    });

    test('classification activities have a home for every item', () {
      final sorts = module6.lessons
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

  group('Module 6 registration', () {
    test('is registered in the catalog after module 5', () {
      final ids = LessonCatalog.modules.map((m) => m.id).toList();
      expect(ids.last, 'module6');
      expect(ids.indexOf('module6'), ids.indexOf('module5') + 1);
    });

    test('lesson lookups and labels resolve', () {
      expect(LessonCatalog.lessonById('m6_l5')?.title, 'Factoring Polynomials');
      expect(LessonCatalog.moduleForLesson('m6_l1')?.id, 'module6');
      expect(LessonCatalog.lessonNumberLabel('m6_l4'), '6.4');
    });

    test('practice can drop a learner on the first question step', () {
      for (final lesson in module6.lessons) {
        final index = LessonCatalog.firstAnswerStepIndex(lesson.lessonId);
        expect(index, isNotNull,
            reason: '${lesson.lessonId} has no question step');
      }
    });
  });

  group('Module 6 Supabase catalog', () {
    test('migration lists exactly the shipped steps', () {
      // 6.6 and 6.7 arrived after the first catalog was applied, so their
      // rows live in an additive follow-up migration.
      final files = [
        File('supabase/migrations/202609110002_module6_lessons_catalog.sql'),
        File('supabase/migrations/202609120003_module6_challenge_catalog.sql'),
      ];
      for (final file in files) {
        expect(file.existsSync(), isTrue,
            reason: '${file.path} is missing');
      }

      final sql = files.map((f) => f.readAsStringSync()).join('\n');

      for (final lesson in module6.lessons) {
        for (var i = 0; i < lesson.steps.length; i++) {
          final step = lesson.steps[i];
          final row = "('module6', '${lesson.lessonId}', '${step.id}', 1, $i, "
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
