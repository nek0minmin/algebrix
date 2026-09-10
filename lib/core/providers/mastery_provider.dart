import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:algebrix/data/lesson_catalog.dart';
import 'package:algebrix/models/concept_mastery_model.dart';
import 'package:algebrix/models/lesson_mistake_model.dart';
import 'package:algebrix/models/quiz_attempt_review_model.dart';
import 'package:algebrix/services/concept_resolver.dart';
import 'package:algebrix/services/mastery_repository.dart';

/// Aggregates three signals into per-concept mastery, and owns the spaced
/// review queue.
///
/// Sources:
///   - quiz questions from [QuizReviewProvider]'s retained attempts, attributed
///     to a lesson by [ConceptResolver]
///   - missed lesson answers from `lesson_answer_reviews`
///   - the Leitner schedule from `concept_review_schedule`
///
/// Reads quiz attempts rather than owning them, so nothing here can affect
/// quiz scoring or module unlocks.
class MasteryProvider extends ChangeNotifier {
  MasteryProvider({
    required MasteryRepository repository,
    ConceptResolver resolver = const ConceptResolver(),
  })  : _repository = repository,
        _resolver = resolver;

  final MasteryRepository _repository;
  final ConceptResolver _resolver;

  String? _accountId;
  int _accountGeneration = 0;

  List<LessonMistake> _mistakes = [];
  List<ConceptReviewSchedule> _schedule = [];
  List<QuizAttemptReview> _quizAttempts = [];

  bool _isLoading = false;
  String? _errorMessage;

  /// Injectable clock so due-date logic is testable.
  DateTime Function() clock = DateTime.now;

  String? get accountId => _accountId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<LessonMistake> get lessonMistakes => List.unmodifiable(_mistakes);

  /// Lesson mistakes the learner has not since corrected, worst first.
  List<LessonMistake> get openLessonMistakes {
    final open = _mistakes.where((m) => m.isOpen).toList()
      ..sort((a, b) {
        final byCount = b.missCount.compareTo(a.missCount);
        if (byCount != 0) return byCount;
        return b.lastMissedAt.compareTo(a.lastMissedAt);
      });
    return List.unmodifiable(open);
  }

  bool get hasOpenLessonMistakes => _mistakes.any((m) => m.isOpen);

  // ---------------------------------------------------------------------------
  // Wiring
  // ---------------------------------------------------------------------------

  void bindAccount(String? accountId) {
    if (_accountId == accountId) return;

    _accountGeneration++;
    _accountId = accountId;
    _mistakes = [];
    _schedule = [];
    _invalidateConcepts();
    _errorMessage = null;

    if (accountId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    unawaited(_hydrate(accountId, _accountGeneration));
  }

  /// Feeds in the retained quiz attempts owned by `QuizReviewProvider`.
  ///
  /// Called from the provider graph on every rebuild, so it must be cheap and
  /// must not notify unless the data actually changed.
  void syncQuizAttempts(List<QuizAttemptReview> attempts) {
    if (_sameAttempts(attempts)) return;
    _quizAttempts = List.of(attempts);
    _invalidateConcepts();
    notifyListeners();
  }

  bool _sameAttempts(List<QuizAttemptReview> next) {
    if (next.length != _quizAttempts.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (next[i].id != _quizAttempts[i].id) return false;
    }
    return true;
  }

  Future<void> _hydrate(String accountId, int generation) async {
    try {
      final results = await Future.wait([
        _repository.fetchLessonMistakes(),
        _repository.fetchReviewSchedule(),
      ]);
      if (_accountId != accountId || _accountGeneration != generation) return;

      _mistakes = results[0] as List<LessonMistake>;
      _schedule = results[1] as List<ConceptReviewSchedule>;
      _invalidateConcepts();
      _errorMessage = null;
    } catch (e) {
      if (_accountId != accountId || _accountGeneration != generation) return;
      _errorMessage = 'Could not load your mastery data.';
      debugPrint('Mastery hydration failed: $e');
    } finally {
      if (_accountId == accountId && _accountGeneration == generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> reload() async {
    final accountId = _accountId;
    if (accountId == null) return;
    final generation = ++_accountGeneration;
    _isLoading = true;
    notifyListeners();
    await _hydrate(accountId, generation);
  }

  // ---------------------------------------------------------------------------
  // Aggregation
  // ---------------------------------------------------------------------------

  /// Memoized result of [_computeConcepts].
  ///
  /// A single rebuild reads `concepts` through several getters, and each pass
  /// resolves every retained quiz question against every lesson — worth doing
  /// once per data change rather than once per read.
  List<ConceptMastery>? _cachedConcepts;

  void _invalidateConcepts() => _cachedConcepts = null;

  /// Per-concept mastery for every shipped lesson, in curriculum order.
  List<ConceptMastery> get concepts =>
      _cachedConcepts ??= _computeConcepts();

  List<ConceptMastery> _computeConcepts() {
    final quizSeen = <String, int>{};
    final quizCorrect = <String, int>{};

    for (final attempt in _quizAttempts) {
      for (final item in attempt.items) {
        final lessonId = _resolver.resolveLessonId(
          item.subLessonTitle,
          moduleId: attempt.moduleId,
        );
        if (lessonId == null) continue;

        quizSeen[lessonId] = (quizSeen[lessonId] ?? 0) + 1;
        if (item.isCorrect) {
          quizCorrect[lessonId] = (quizCorrect[lessonId] ?? 0) + 1;
        }
      }
    }

    final openByLesson = <String, int>{};
    final missTotalByLesson = <String, int>{};
    final lastMissByLesson = <String, DateTime>{};

    for (final mistake in _mistakes) {
      missTotalByLesson[mistake.lessonId] =
          (missTotalByLesson[mistake.lessonId] ?? 0) + mistake.missCount;
      if (mistake.isOpen) {
        openByLesson[mistake.lessonId] =
            (openByLesson[mistake.lessonId] ?? 0) + 1;
      }
      final previous = lastMissByLesson[mistake.lessonId];
      if (previous == null || mistake.lastMissedAt.isAfter(previous)) {
        lastMissByLesson[mistake.lessonId] = mistake.lastMissedAt;
      }
    }

    final scheduleByLesson = {
      for (final entry in _schedule) entry.lessonId: entry,
    };

    return List.unmodifiable([
      for (final lesson in LessonCatalog.lessons)
        ConceptMastery(
          moduleId: lesson.moduleId,
          moduleTitle:
              LessonCatalog.moduleById(lesson.moduleId)?.title ??
                  lesson.moduleTitle,
          lessonId: lesson.lessonId,
          lessonTitle: lesson.title,
          lessonNumberLabel: LessonCatalog.lessonNumberLabel(lesson.lessonId),
          quizQuestionsSeen: quizSeen[lesson.lessonId] ?? 0,
          quizQuestionsCorrect: quizCorrect[lesson.lessonId] ?? 0,
          openMisses: openByLesson[lesson.lessonId] ?? 0,
          totalMissCount: missTotalByLesson[lesson.lessonId] ?? 0,
          reviewStrength: scheduleByLesson[lesson.lessonId]?.strength ?? 0,
          lastMissedAt: lastMissByLesson[lesson.lessonId],
          reviewDueAt: scheduleByLesson[lesson.lessonId]?.dueAt,
          isScheduled: scheduleByLesson.containsKey(lesson.lessonId),
        ),
    ]);
  }

  /// Concepts with any evidence at all, strongest first.
  List<ConceptMastery> get strongestFirst {
    final assessed = concepts.where((c) => c.hasEvidence).toList()
      ..sort((a, b) => b.weaknessScore.compareTo(a.weaknessScore));
    return List.unmodifiable(assessed);
  }

  /// Concepts with any evidence at all, weakest first.
  List<ConceptMastery> get weakestFirst {
    final assessed = concepts.where((c) => c.hasEvidence).toList()
      ..sort((a, b) => a.weaknessScore.compareTo(b.weaknessScore));
    return List.unmodifiable(assessed);
  }

  /// Assessed concepts bucketed by band, weakest band first.
  ///
  /// Groups are disjoint by construction. The previous "least mastered" and
  /// "most mastered" lists were the same set in opposite orders, so a concept
  /// could — and did — appear in both.
  Map<MasteryBand, List<ConceptMastery>> get conceptsByBand {
    final grouped = <MasteryBand, List<ConceptMastery>>{
      MasteryBand.needsWork: [],
      MasteryBand.shaky: [],
      MasteryBand.solid: [],
      MasteryBand.mastered: [],
    };

    for (final concept in weakestFirst) {
      grouped[concept.band]?.add(concept);
    }

    grouped.removeWhere((_, list) => list.isEmpty);
    return Map.unmodifiable(grouped);
  }

  /// The practice queue: concepts due for review, weakest first.
  List<ConceptMastery> get needsReview {
    final now = clock();
    final due = concepts.where((c) => c.needsReview(now: now)).toList()
      ..sort((a, b) => a.weaknessScore.compareTo(b.weaknessScore));
    return List.unmodifiable(due);
  }

  /// The single concept most worth practising right now, if any.
  ConceptMastery? get topPriority {
    final queue = needsReview;
    return queue.isEmpty ? null : queue.first;
  }

  MasterySummary get summary =>
      MasterySummary.from(concepts, now: clock());

  /// Mastery for one lesson, even if it has no evidence yet.
  ConceptMastery? conceptFor(String lessonId) {
    for (final concept in concepts) {
      if (concept.lessonId == lessonId) return concept;
    }
    return null;
  }

  /// Open mistakes belonging to one lesson.
  List<LessonMistake> mistakesForLesson(String lessonId) => List.unmodifiable(
        openLessonMistakes.where((m) => m.lessonId == lessonId),
      );

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Records a missed lesson answer and demotes that concept.
  ///
  /// Never throws: this fires mid-lesson and must not interrupt the learner.
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
    try {
      await _repository.recordLessonMiss(
        moduleId: moduleId,
        lessonId: lessonId,
        stepId: stepId,
        stepIndex: stepIndex,
        question: question,
        options: options,
        correctIndex: correctIndex,
        selectedIndex: selectedIndex,
        explanation: explanation,
      );
      await _repository.scheduleReview(
        moduleId: moduleId,
        lessonId: lessonId,
        outcome: ReviewOutcome.missed,
      );
      await _refreshQuietly();
    } catch (e) {
      debugPrint('Recording lesson miss failed: $e');
    }
  }

  /// Marks a lesson answer correct.
  ///
  /// Only promotes the concept when this actually closed an open mistake —
  /// otherwise every first-time correct answer would inflate the ladder.
  Future<void> recordLessonSuccess({
    required String moduleId,
    required String lessonId,
    required String stepId,
  }) async {
    try {
      final wasOpen = await _repository.resolveLessonMiss(
        lessonId: lessonId,
        stepId: stepId,
      );
      if (!wasOpen) return;

      await _repository.scheduleReview(
        moduleId: moduleId,
        lessonId: lessonId,
        outcome: ReviewOutcome.reviewed,
      );
      await _refreshQuietly();
    } catch (e) {
      debugPrint('Resolving lesson miss failed: $e');
    }
  }

  /// Demotes every concept the learner missed in a finished quiz attempt.
  ///
  /// Called once as the results screen appears. Concepts answered correctly are
  /// deliberately not promoted here: a quiz is an assessment, and promotion is
  /// reserved for a deliberate review.
  Future<void> registerQuizAttempt(QuizAttemptReview attempt) async {
    final missedLessonIds = <String>{};

    for (final item in attempt.missedQuestions) {
      final lessonId = _resolver.resolveLessonId(
        item.subLessonTitle,
        moduleId: attempt.moduleId,
      );
      if (lessonId != null) missedLessonIds.add(lessonId);
    }

    if (missedLessonIds.isEmpty) return;

    try {
      for (final lessonId in missedLessonIds) {
        final lesson = LessonCatalog.lessonById(lessonId);
        await _repository.scheduleReview(
          moduleId: lesson?.moduleId ?? attempt.moduleId,
          lessonId: lessonId,
          outcome: ReviewOutcome.missed,
        );
      }
      await _refreshQuietly();
    } catch (e) {
      debugPrint('Registering quiz attempt failed: $e');
    }
  }

  /// Records that the learner deliberately revisited a concept.
  Future<bool> markConceptReviewed({
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      await _repository.scheduleReview(
        moduleId: moduleId,
        lessonId: lessonId,
        outcome: ReviewOutcome.reviewed,
      );
      await _refreshQuietly();
      return true;
    } catch (e) {
      _errorMessage = 'Could not update your review schedule.';
      debugPrint('Marking concept reviewed failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// Forgets every mistake and schedule row for one lesson.
  Future<bool> clearConcept(String lessonId) async {
    final previousMistakes = _mistakes;
    final previousSchedule = _schedule;

    _mistakes = _mistakes.where((m) => m.lessonId != lessonId).toList();
    _schedule = _schedule.where((s) => s.lessonId != lessonId).toList();
    _invalidateConcepts();
    notifyListeners();

    try {
      await _repository.clearConceptHistory(lessonId);
      return true;
    } catch (e) {
      _mistakes = previousMistakes;
      _schedule = previousSchedule;
      _invalidateConcepts();
      _errorMessage = 'Could not clear this concept.';
      debugPrint('Clearing concept failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// Re-reads mistakes and schedule without flipping the loading flag, so
  /// mid-lesson writes do not flash a spinner over the UI.
  Future<void> _refreshQuietly() async {
    final accountId = _accountId;
    if (accountId == null) return;
    final generation = _accountGeneration;

    try {
      final results = await Future.wait([
        _repository.fetchLessonMistakes(),
        _repository.fetchReviewSchedule(),
      ]);
      if (_accountId != accountId || _accountGeneration != generation) return;

      _mistakes = results[0] as List<LessonMistake>;
      _schedule = results[1] as List<ConceptReviewSchedule>;
      _invalidateConcepts();
      notifyListeners();
    } catch (e) {
      debugPrint('Quiet mastery refresh failed: $e');
    }
  }
}
