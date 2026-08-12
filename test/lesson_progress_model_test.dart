import 'package:algebrix/models/lesson_progress_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LearningProfileSnapshot maps authoritative profile totals', () {
    final profile = LearningProfileSnapshot.fromJson({
      'id': 'user-1',
      'xp': 1055,
      'level': 2,
      'level_title': 'Math Explorer',
      'streak': 4,
    });

    expect(profile.userId, 'user-1');
    expect(profile.xp, 1055);
    expect(profile.level, 2);
    expect(profile.levelTitle, 'Math Explorer');
    expect(profile.streak, 4);
  });

  group('LessonProgress', () {
    test('parses an in-progress resume row', () {
      final progress = LessonProgress.fromJson({
        'user_id': 'user-1',
        'module_id': 'module1',
        'lesson_id': 'm1_l1',
        'content_version': 1,
        'last_step_id': 'step5',
        'last_step_index': 4,
        'status': 'in_progress',
        'started_at': '2026-08-12T01:00:00Z',
        'updated_at': '2026-08-12T01:05:00Z',
        'completed_at': null,
      });

      expect(progress.userId, 'user-1');
      expect(progress.contentVersion, 1);
      expect(progress.lastStepId, 'step5');
      expect(progress.lastStepIndex, 4);
      expect(progress.status, LessonProgressStatus.inProgress);
      expect(progress.completedAt, isNull);
    });

    test('rejects an unknown persisted status', () {
      expect(
        () => LessonProgress.fromJson({
          'user_id': 'user-1',
          'module_id': 'module1',
          'lesson_id': 'm1_l1',
          'content_version': 1,
          'last_step_id': null,
          'last_step_index': null,
          'status': 'unknown',
          'started_at': '2026-08-12T01:00:00Z',
          'updated_at': '2026-08-12T01:00:00Z',
          'completed_at': null,
        }),
        throwsFormatException,
      );
    });
  });

  test('RecordLessonStepResult parses authoritative XP deltas', () {
    final result = RecordLessonStepResult.fromJson({
      'progress': {
        'user_id': 'user-1',
        'module_id': 'module1',
        'lesson_id': 'm1_l1',
        'content_version': 1,
        'last_step_id': 'step7',
        'last_step_index': 6,
        'status': 'completed',
        'started_at': '2026-08-12T01:00:00Z',
        'updated_at': '2026-08-12T01:10:00Z',
        'completed_at': '2026-08-12T01:10:00Z',
      },
      'xp_awarded': 25,
      'step_xp_awarded': 0,
      'completion_xp_awarded': 25,
      'total_xp': 55,
      'level': 1,
      'level_title': 'Math Beginner',
      'completion_requirements_met': true,
    });

    expect(result.progress.status, LessonProgressStatus.completed);
    expect(result.xpAwarded, 25);
    expect(result.stepXpAwarded, 0);
    expect(result.completionXpAwarded, 25);
    expect(result.totalXp, 55);
    expect(result.completionRequirementsMet, isTrue);
  });
}
