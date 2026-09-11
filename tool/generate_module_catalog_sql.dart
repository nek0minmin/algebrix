// ignore_for_file: avoid_print

// Generates the Supabase `learning_step_catalog` rows for a shipped module
// directly from the Dart lesson content, so the migration can never drift from
// what the app actually renders.
//
//   dart run tool/generate_module_catalog_sql.dart module5
//
// A second argument limits the output to specific lessons, which is what you
// want when a module's catalog is already applied and only new lessons need a
// follow-up migration:
//
//   dart run tool/generate_module_catalog_sql.dart module5 m5_l7,m5_l8
//
// Prints the VALUES block to stdout; paste it into the migration.
import 'package:algebrix/data/lesson_catalog.dart';

void main(List<String> args) {
  if (args.isEmpty || args.length > 2) {
    print(
      'usage: dart run tool/generate_module_catalog_sql.dart '
      '<moduleId> [lessonId,lessonId,...]',
    );
    return;
  }

  final module = LessonCatalog.moduleById(args.first);
  if (module == null) {
    print('unknown module: ${args.first}');
    return;
  }

  final only = args.length == 2
      ? args[1].split(',').map((id) => id.trim()).toSet()
      : null;

  final rows = <String>[];
  for (var l = 0; l < module.lessons.length; l++) {
    final lesson = module.lessons[l];
    if (only != null && !only.contains(lesson.lessonId)) continue;
    final number = '${LessonCatalog.moduleNumber(module.id)}.${l + 1}';
    rows.add(
      '  -- Lesson $number: ${lesson.title} (${lesson.steps.length} steps)',
    );
    for (var i = 0; i < lesson.steps.length; i++) {
      final step = lesson.steps[i];
      final isFinal = i == lesson.steps.length - 1;
      rows.add(
        "  ('${module.id}', '${lesson.lessonId}', '${step.id}', 1, $i, "
        '${step.isAnswerStep ? 'TRUE' : 'FALSE'}, 0, '
        '${isFinal ? 'TRUE' : 'FALSE'}),',
      );
    }
    rows.add('');
  }

  // Trim the trailing blank line and the final comma.
  while (rows.isNotEmpty && rows.last.isEmpty) {
    rows.removeLast();
  }
  rows[rows.length - 1] = rows.last.substring(0, rows.last.length - 1);

  print(rows.join('\n'));
}
