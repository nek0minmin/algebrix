import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/animations/app_page_route.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/data/lesson_catalog.dart';
import 'package:algebrix/screens/lessons/lesson_screen.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';

/// Opens the lesson behind a weak concept, landing on the step it came from.
///
/// This is the link that turns the mastery list from a report into a loop: a
/// learner taps "Distributive Property · Needs work" and arrives at the
/// question they got wrong, not at the module overview.
///
/// Step choice, most specific first:
///   1. [stepId] — the exact step, when the concept came from a lesson mistake
///   2. the lesson's first question step — when the concept came from a quiz,
///      so the learner lands on practice rather than the intro
///   3. the lesson's normal resume point
Future<void> openConceptPractice(
  BuildContext context, {
  required String lessonId,
  String? stepId,
}) async {
  final lesson = LessonCatalog.lessonById(lessonId);
  final module = LessonCatalog.moduleForLesson(lessonId);

  if (lesson == null || module == null) {
    showAlgebrixSnackBar(
      context,
      message: 'That lesson is not available in this version yet.',
      isError: true,
    );
    return;
  }

  final targetIndex = (stepId == null
          ? null
          : LessonCatalog.stepIndexOf(lessonId, stepId)) ??
      LessonCatalog.firstAnswerStepIndex(lessonId);

  final lessonProvider = context.read<LessonProvider>();
  lessonProvider.startModule(module);

  final navigator = Navigator.of(context);
  final started = await lessonProvider.startLesson(
    lesson,
    startAtStepIndex: targetIndex,
  );

  if (!context.mounted) return;

  if (!started) {
    showAlgebrixSnackBar(
      context,
      message: lessonProvider.errorMessage ?? 'Could not open that lesson.',
      isError: true,
    );
    return;
  }

  navigator.push(AppPageRoute(child: const LessonScreen()));
}
