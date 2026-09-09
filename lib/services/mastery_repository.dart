import 'package:algebrix/models/lesson_mistake_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Outcome fed into the spaced-review ladder.
enum ReviewOutcome {
  /// The learner got it wrong — demote and make it due now.
  missed,

  /// The learner got it right on a review — promote and push it out.
  reviewed;

  String get wireValue => name;
}

/// Persistence boundary for lesson mistakes and the spaced-review schedule.
///
/// Every mutation goes through a SECURITY DEFINER RPC: the tables carry no
/// INSERT or UPDATE grant, so `miss_count`, `strength`, and `due_at` are all
/// computed server-side and a client cannot fabricate mastery.
abstract interface class MasteryRepository {
  /// Every retained lesson mistake, open and resolved.
  Future<List<LessonMistake>> fetchLessonMistakes();

  /// The learner's full spaced-review schedule.
  Future<List<ConceptReviewSchedule>> fetchReviewSchedule();

  /// Records (or re-counts) a missed lesson answer.
  Future<void> recordLessonMiss({
    required String moduleId,
    required String lessonId,
    required String stepId,
    required int stepIndex,
    required String question,
    required List<String> options,
    required int correctIndex,
    required int selectedIndex,
    required String explanation,
  });

  /// Marks a lesson mistake resolved.
  ///
  /// Returns true only if a mistake was actually open, so the caller can tell
  /// a genuine recovery from a first-time correct answer.
  Future<bool> resolveLessonMiss({
    required String lessonId,
    required String stepId,
  });

  /// Advances or demotes a concept in the review ladder.
  Future<void> scheduleReview({
    required String moduleId,
    required String lessonId,
    required ReviewOutcome outcome,
  });

  /// Forgets every mistake and schedule row for one lesson.
  Future<void> clearConceptHistory(String lessonId);
}

/// Supabase-backed implementation of [MasteryRepository].
class SupabaseMasteryRepository implements MasteryRepository {
  SupabaseMasteryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<LessonMistake>> fetchLessonMistakes() async {
    final userId = _requireAuthenticatedUser();

    final rows = await _client
        .from('lesson_answer_reviews')
        .select()
        .eq('user_id', userId)
        .order('last_missed_at', ascending: false);

    return rows.map((row) => LessonMistake.fromJson(row)).toList();
  }

  @override
  Future<List<ConceptReviewSchedule>> fetchReviewSchedule() async {
    final userId = _requireAuthenticatedUser();

    final rows = await _client
        .from('concept_review_schedule')
        .select()
        .eq('user_id', userId)
        .order('due_at', ascending: true);

    return rows.map((row) => ConceptReviewSchedule.fromJson(row)).toList();
  }

  @override
  Future<void> recordLessonMiss({
    required String moduleId,
    required String lessonId,
    required String stepId,
    required int stepIndex,
    required String question,
    required List<String> options,
    required int correctIndex,
    required int selectedIndex,
    required String explanation,
  }) async {
    _requireAuthenticatedUser();

    await _client.rpc('record_lesson_miss', params: {
      'p_module_id': moduleId,
      'p_lesson_id': lessonId,
      'p_step_id': stepId,
      'p_step_index': stepIndex,
      'p_question': question,
      'p_options': options,
      'p_correct_index': correctIndex,
      'p_selected_index': selectedIndex,
      'p_explanation': explanation,
    });
  }

  @override
  Future<bool> resolveLessonMiss({
    required String lessonId,
    required String stepId,
  }) async {
    _requireAuthenticatedUser();

    final result = await _client.rpc('resolve_lesson_miss', params: {
      'p_lesson_id': lessonId,
      'p_step_id': stepId,
    });

    return result == true;
  }

  @override
  Future<void> scheduleReview({
    required String moduleId,
    required String lessonId,
    required ReviewOutcome outcome,
  }) async {
    _requireAuthenticatedUser();

    await _client.rpc('schedule_concept_review', params: {
      'p_module_id': moduleId,
      'p_lesson_id': lessonId,
      'p_outcome': outcome.wireValue,
    });
  }

  @override
  Future<void> clearConceptHistory(String lessonId) async {
    _requireAuthenticatedUser();

    await _client.rpc('clear_concept_history', params: {
      'p_lesson_id': lessonId,
    });
  }

  String _requireAuthenticatedUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User must be authenticated to access mastery data.');
    }
    return user.id;
  }
}

/// In-memory implementation for tests and offline mode.
///
/// Mirrors the server rules exactly: miss counts increment, resolving only
/// succeeds on an open mistake, and the Leitner ladder uses the same
/// 0/1/3/7/14/30-day intervals.
class MemoryMasteryRepository implements MasteryRepository {
  static const List<int> ladderDays = [0, 1, 3, 7, 14, 30];

  final Map<String, LessonMistake> _mistakes = {};
  final Map<String, ConceptReviewSchedule> _schedule = {};
  int _sequence = 0;

  /// When set, every call throws this instead of succeeding.
  Object? failure;

  /// Injectable clock so schedule assertions do not depend on wall time.
  DateTime Function() clock = DateTime.now;

  String _mistakeKey(String lessonId, String stepId) => '$lessonId::$stepId';

  @override
  Future<List<LessonMistake>> fetchLessonMistakes() async {
    if (failure != null) throw failure!;
    final list = _mistakes.values.toList()
      ..sort((a, b) => b.lastMissedAt.compareTo(a.lastMissedAt));
    return list;
  }

  @override
  Future<List<ConceptReviewSchedule>> fetchReviewSchedule() async {
    if (failure != null) throw failure!;
    final list = _schedule.values.toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return list;
  }

  @override
  Future<void> recordLessonMiss({
    required String moduleId,
    required String lessonId,
    required String stepId,
    required int stepIndex,
    required String question,
    required List<String> options,
    required int correctIndex,
    required int selectedIndex,
    required String explanation,
  }) async {
    if (failure != null) throw failure!;

    final key = _mistakeKey(lessonId, stepId);
    final existing = _mistakes[key];

    _mistakes[key] = LessonMistake(
      id: existing?.id ?? 'mistake_${_sequence++}',
      moduleId: moduleId,
      lessonId: lessonId,
      stepId: stepId,
      stepIndex: stepIndex,
      question: question,
      options: options,
      correctIndex: correctIndex,
      selectedIndex: selectedIndex,
      explanation: explanation,
      missCount: (existing?.missCount ?? 0) + 1,
      resolved: false,
      lastMissedAt: clock(),
    );
  }

  @override
  Future<bool> resolveLessonMiss({
    required String lessonId,
    required String stepId,
  }) async {
    if (failure != null) throw failure!;

    final key = _mistakeKey(lessonId, stepId);
    final existing = _mistakes[key];
    if (existing == null || existing.resolved) return false;

    _mistakes[key] = LessonMistake(
      id: existing.id,
      moduleId: existing.moduleId,
      lessonId: existing.lessonId,
      stepId: existing.stepId,
      stepIndex: existing.stepIndex,
      question: existing.question,
      options: existing.options,
      correctIndex: existing.correctIndex,
      selectedIndex: existing.selectedIndex,
      explanation: existing.explanation,
      missCount: existing.missCount,
      resolved: true,
      lastMissedAt: existing.lastMissedAt,
    );
    return true;
  }

  @override
  Future<void> scheduleReview({
    required String moduleId,
    required String lessonId,
    required ReviewOutcome outcome,
  }) async {
    if (failure != null) throw failure!;

    final existing = _schedule[lessonId];
    final int nextStrength;

    if (existing == null) {
      nextStrength = outcome == ReviewOutcome.reviewed ? 1 : 0;
    } else if (outcome == ReviewOutcome.reviewed) {
      nextStrength = (existing.strength + 1).clamp(0, 5);
    } else {
      nextStrength = (existing.strength - 1).clamp(0, 5);
    }

    final now = clock();
    _schedule[lessonId] = ConceptReviewSchedule(
      moduleId: moduleId,
      lessonId: lessonId,
      strength: nextStrength,
      dueAt: now.add(Duration(days: ladderDays[nextStrength])),
      lastOutcome: outcome.wireValue,
      lastReviewedAt: outcome == ReviewOutcome.reviewed
          ? now
          : existing?.lastReviewedAt,
    );
  }

  @override
  Future<void> clearConceptHistory(String lessonId) async {
    if (failure != null) throw failure!;
    _mistakes.removeWhere((_, mistake) => mistake.lessonId == lessonId);
    _schedule.remove(lessonId);
  }
}
