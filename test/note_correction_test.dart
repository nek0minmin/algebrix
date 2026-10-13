import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/models/note_correction_model.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/screens/notes/note_form_screen.dart';
import 'package:algebrix/services/ai_tutor_service.dart';
import 'package:algebrix/services/note_correction_service.dart';
import 'package:algebrix/services/notes_repository.dart';
import 'package:algebrix/widgets/notes/correction_suggestion_card.dart';
import 'package:algebrix/widgets/notes/correction_text_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors the feedback in the reported screenshot.
AiFeedbackResult _distributiveFeedback() => const AiFeedbackResult(
      title: "Let's check step by step!",
      message: 'Your final expression 3x + 6 is correct! Just remember the '
          'rule you used is the distributive property, not the commutative '
          'property.',
      providerUsed: 'test',
    );

void main() {
  const service = NoteCorrectionService();

  group('NoteCorrectionService', () {
    test('locates the rejected term in the note body', () {
      final corrections = service.detect(
        title: 'My steps',
        body: 'Why each step works: commutative property',
        feedback: _distributiveFeedback(),
      );

      expect(corrections, hasLength(1));
      final correction = corrections.single;
      expect(correction.target, NoteCorrectionTarget.body);
      expect(correction.original, 'commutative');
      expect(correction.suggestions, contains('distributive'));
      expect(correction.isApplied, isFalse);
    });

    test('flags the same mistake in the title as well as the body', () {
      final corrections = service.detect(
        title: 'commutative',
        body: 'Why each step works: commutative property',
        feedback: _distributiveFeedback(),
      );

      expect(corrections, hasLength(2));
      expect(
        corrections.map((c) => c.target),
        containsAll([NoteCorrectionTarget.title, NoteCorrectionTarget.body]),
      );
    });

    test('offsets point at the flagged word', () {
      const body = 'Why each step works: commutative property';
      final correction = service
          .detect(title: '', body: body, feedback: _distributiveFeedback())
          .single;

      expect(body.substring(correction.start, correction.end), 'commutative');
      expect(correction.matches(body), isTrue);
    });

    test('matches the capitalisation of the word being replaced', () {
      final correction = service
          .detect(
            title: 'Commutative property',
            body: 'no terms here',
            feedback: _distributiveFeedback(),
          )
          .single;

      expect(correction.original, 'Commutative');
      expect(correction.suggestions, contains('Distributive'));
    });

    test('stays silent when the feedback rejects nothing', () {
      final corrections = service.detect(
        title: 'Distributive property',
        body: 'I used the distributive property to expand 3(x+2).',
        feedback: const AiFeedbackResult(
          title: 'Nice work!',
          message: 'Your use of the distributive property is spot on.',
          providerUsed: 'test',
        ),
      );

      expect(corrections, isEmpty);
    });

    test('never suggests a term from a different group', () {
      final corrections = service.detect(
        title: '',
        body: 'the coefficient is 3',
        feedback: const AiFeedbackResult(
          title: 'Almost',
          message: 'That is the constant, not the coefficient.',
          providerUsed: 'test',
        ),
      );

      expect(corrections, hasLength(1));
      expect(corrections.single.suggestions, ['constant']);
    });

    test('returns nothing without feedback', () {
      expect(
        service.detect(title: 'x', body: 'commutative', feedback: null),
        isEmpty,
      );
    });

    test('detects equation solution mistake (e.g. x = 2 when solution is x = 4)', () {
      const body = 'i solved 2x - 8 by putting 8 on the other side and dividing it by 4 to get x = 2';
      const feedback = AiFeedbackResult(
        title: "Let's check step by step!",
        message: 'To solve 2x - 8 = 0, first move the constant to the other side. The correct solution is x = 4.',
        steps: [
          'Add 8 to both sides to get 2x = 8',
          'Divide both sides by 2 to isolate x, giving x = 4',
        ],
        whyItWorks: 'Dividing by the coefficient isolates x.',
        providerUsed: 'test',
        isCorrect: false,
      );

      final corrections = service.detect(title: 'Solving 2x - 8', body: body, feedback: feedback);
      expect(corrections, isNotEmpty);
      expect(corrections.any((c) => c.original == 'x = 2' && c.suggestions.contains('x = 4')), isTrue);
    });

    test('detects operation mistake (e.g. dividing it by 4 when step says divide by 2)', () {
      const body = 'i solved 2x - 8 by putting 8 on the other side and dividing it by 4 to get x = 2';
      const feedback = AiFeedbackResult(
        title: "Let's check step by step!",
        message: 'Divide by the coefficient of x (2), not 4.',
        steps: [
          'Add 8 to both sides to get 2x = 8',
          'Divide both sides by 2 to isolate x, giving x = 4',
        ],
        whyItWorks: 'Dividing by 2 isolates x.',
        providerUsed: 'test',
        isCorrect: false,
      );

      final corrections = service.detect(title: 'Solving 2x - 8', body: body, feedback: feedback);
      expect(corrections.any((c) => c.original.contains('4') && c.suggestions.any((s) => s.contains('2'))), isTrue);
    });

    test('uses structured corrections returned by AI feedback directly', () {
      const body = 'I solved 3x + 12 = 0 and wrote x = 3 because 12 / 3 is 3.';
      const feedback = AiFeedbackResult(
        title: "Let's check step by step!",
        message: 'Close, but check the calculation.',
        corrections: [
          AiCorrectionItem(
            original: 'x = 3',
            replacement: 'x = -4',
            why: 'Subtracting 12 gives 3x = -12, so x = -4.',
          ),
          AiCorrectionItem(
            original: '12 / 3 is 3',
            replacement: '12 / 3 is 4',
            why: '12 divided by 3 equals 4.',
          ),
        ],
        providerUsed: 'test',
        isCorrect: false,
      );

      final corrections = service.detect(title: '', body: body, feedback: feedback);
      expect(corrections, hasLength(2));
      expect(corrections.first.original, 'x = 3');
      expect(corrections.first.suggestions, ['x = -4']);
      expect(corrections.last.original, '12 / 3 is 3');
      expect(corrections.last.suggestions, ['12 / 3 is 4']);
    });
  });

  group('applyNoteCorrection', () {
    test('replaces the word and marks the correction applied', () {
      const body = 'Why each step works: commutative property';
      final corrections =
          service.detect(title: '', body: body, feedback: _distributiveFeedback());

      final result = applyNoteCorrection(
        text: body,
        corrections: corrections,
        correction: corrections.single,
        replacement: 'distributive',
      );

      expect(result.text, 'Why each step works: distributive property');
      expect(result.applied.isApplied, isTrue);
      expect(result.applied.appliedReplacement, 'distributive');
      expect(result.text.substring(result.applied.start, result.applied.end),
          'distributive');
    });

    test('shifts later corrections in the same field', () {
      const body = 'commutative and commutative again';
      final corrections =
          service.detect(title: '', body: body, feedback: _distributiveFeedback());
      expect(corrections, hasLength(2));

      final result = applyNoteCorrection(
        text: body,
        corrections: corrections,
        correction: corrections.first,
        replacement: 'distributive',
      );

      final second = result.corrections[1];
      expect(
        result.text.substring(second.start, second.end),
        'commutative',
        reason: 'the untouched highlight must follow its word',
      );
    });

    test('is a no-op when the text has moved on', () {
      const body = 'commutative property';
      final correction = service
          .detect(title: '', body: body, feedback: _distributiveFeedback())
          .single;

      final result = applyNoteCorrection(
        text: 'totally different text',
        corrections: [correction],
        correction: correction,
        replacement: 'distributive',
      );

      expect(result.text, 'totally different text');
    });
  });

  group('CorrectionTextEditingController', () {
    NoteCorrection correction({
      int start = 0,
      int end = 11,
      String original = 'commutative',
      String? applied,
    }) {
      return NoteCorrection(
        id: 'c0',
        target: NoteCorrectionTarget.body,
        start: start,
        end: end,
        original: original,
        suggestions: const ['distributive'],
        appliedReplacement: applied,
      );
    }

    test('only reports corrections whose text still matches', () {
      final controller =
          CorrectionTextEditingController(text: 'commutative property');
      controller.corrections = [correction()];
      expect(controller.liveCorrections, hasLength(1));

      controller.text = 'associative property';
      expect(
        controller.liveCorrections,
        isEmpty,
        reason: 'a stale highlight on the wrong word is worse than none',
      );
    });

    test('finds the correction under a caret offset', () {
      final controller =
          CorrectionTextEditingController(text: 'commutative property');
      controller.corrections = [correction()];

      expect(controller.correctionAt(5)?.id, 'c0');
      expect(controller.correctionAt(17), isNull);
    });

    testWidgets('paints pending yellow and applied teal', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final pending =
          CorrectionTextEditingController(text: 'commutative property')
            ..corrections = [correction()];
      final pendingSpan = pending.buildTextSpan(
        context: ctx,
        withComposing: false,
      );
      final pendingChild = (pendingSpan.children!.first as TextSpan);
      expect(pendingChild.text, 'commutative');
      expect(pendingChild.style?.backgroundColor?.g, greaterThan(0.6));

      final applied =
          CorrectionTextEditingController(text: 'distributive property')
            ..corrections = [
              correction(end: 12, applied: 'distributive'),
            ];
      final appliedSpan = applied.buildTextSpan(
        context: ctx,
        withComposing: false,
      );
      final appliedChild = (appliedSpan.children!.first as TextSpan);
      expect(appliedChild.text, 'distributive');
      // Teal reads high on blue; the pending yellow does not.
      expect(appliedChild.style?.backgroundColor?.b, greaterThan(0.6));
    });

    testWidgets('leaves text untouched when there is nothing to correct',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final controller = CorrectionTextEditingController(text: 'plain note');
      final span =
          controller.buildTextSpan(context: ctx, withComposing: false);

      expect(span.toPlainText(), 'plain note');
    });
  });

  group('CorrectionSuggestionCard', () {
    testWidgets('offers each suggestion and reports the chosen one',
        (tester) async {
      String? chosen;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CorrectionSuggestionCard(
              correction: NoteCorrection(
                id: 'c0',
                target: NoteCorrectionTarget.body,
                start: 0,
                end: 11,
                original: 'commutative',
                suggestions: const ['distributive', 'associative'],
                why: 'Xy says this should be the distributive one.',
              ),
              onApply: (value) => chosen = value,
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('Xy thinks "commutative" is not right here'),
        findsOneWidget,
      );
      expect(find.text('distributive'), findsOneWidget);
      expect(find.text('associative'), findsOneWidget);

      await tester.tap(find.byKey(const Key('correction-suggestion-distributive')));
      await tester.pump();

      expect(chosen, 'distributive');
    });

    testWidgets('switches to a confirmation once applied', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CorrectionSuggestionCard(
              correction: const NoteCorrection(
                id: 'c0',
                target: NoteCorrectionTarget.title,
                start: 0,
                end: 12,
                original: 'commutative',
                suggestions: ['distributive'],
                appliedReplacement: 'distributive',
              ),
              onApply: (_) {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Changed to "distributive"'), findsOneWidget);
      expect(
        find.byKey(const Key('correction-suggestion-distributive')),
        findsNothing,
        reason: 'nothing left to choose once the fix is in',
      );
    });
  });

  group('NoteFormScreen unapplied corrections confirmation dialog', () {
    late _TestNotesRepository repository;
    late NotesProvider notesProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = _TestNotesRepository();
      notesProvider = NotesProvider(repository: repository);
      notesProvider.bindAccount('student-1');
    });

    Widget buildTestApp(StudyNote note) {
      return ChangeNotifierProvider<NotesProvider>.value(
        value: notesProvider,
        child: MaterialApp(
          home: Scaffold(
            body: NoteFormScreen(note: note),
          ),
        ),
      );
    }

    testWidgets(
        'shows confirmation dialog when saving with unapplied corrections, cancels on "Review & fix"',
        (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final note = StudyNote(
        id: 'note-1',
        userId: 'student-1',
        moduleId: 'module1',
        lessonId: 'm1_l1',
        title: 'Linear equation steps',
        content: StudyNote.encodeContentWithAiFeedback(
          'I solved 2x = 8 by dividing it by 4 to get x = 2.',
          const AiFeedbackResult(
            title: 'Equation Check',
            message: 'You should divide by 2, not 4, giving x = 4.',
            providerUsed: 'test',
            corrections: [
              AiCorrectionItem(
                original: 'x = 2',
                replacement: 'x = 4',
                why: 'The solution is x = 4.',
              ),
            ],
          ),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      repository.notes.add(note);

      await tester.pumpWidget(buildTestApp(note));
      await tester.pumpAndSettle();

      // Tap "Save note"
      await tester.ensureVisible(find.byKey(const Key('save-note-button')));
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pumpAndSettle();

      // Verify the confirmation dialog is displayed
      expect(find.text('Uncorrected Mistakes in Note'), findsOneWidget);
      expect(
        find.text(
          'Do you want to review and fix them first, or save the note without changing?',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('cancel-save-for-corrections-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('confirm-save-uncorrected-button')),
        findsOneWidget,
      );

      // Tap "Review & fix"
      await tester.tap(find.byKey(const Key('cancel-save-for-corrections-button')));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Uncorrected Mistakes in Note'), findsNothing);
      // Correction suggestion card remains visible
      expect(find.byType(CorrectionSuggestionCard), findsOneWidget);
      // Note still contains original text
      expect(repository.notes.single.displayContent, contains('x = 2'));
    });

    testWidgets('proceeds with save when user taps "Save anyway"',
        (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final note = StudyNote(
        id: 'note-1',
        userId: 'student-1',
        moduleId: 'module1',
        lessonId: 'm1_l1',
        title: 'Linear equation steps',
        content: StudyNote.encodeContentWithAiFeedback(
          'I solved 2x = 8 by dividing it by 4 to get x = 2.',
          const AiFeedbackResult(
            title: 'Equation Check',
            message: 'You should divide by 2, not 4, giving x = 4.',
            providerUsed: 'test',
            corrections: [
              AiCorrectionItem(
                original: 'x = 2',
                replacement: 'x = 4',
                why: 'The solution is x = 4.',
              ),
            ],
          ),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      repository.notes.add(note);

      await tester.pumpWidget(buildTestApp(note));
      await tester.pumpAndSettle();

      // Tap "Save note"
      await tester.ensureVisible(find.byKey(const Key('save-note-button')));
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pumpAndSettle();

      // Verify confirmation dialog is displayed
      expect(find.text('Uncorrected Mistakes in Note'), findsOneWidget);

      // Tap "Save anyway"
      await tester.tap(find.byKey(const Key('confirm-save-uncorrected-button')));
      await tester.pumpAndSettle();

      // Dialog is gone
      expect(find.text('Uncorrected Mistakes in Note'), findsNothing);
      expect(repository.notes.single.displayContent, contains('x = 2'));
    });
  });
}

class _TestNotesRepository implements NotesRepository {
  final List<StudyNote> notes = [];

  @override
  Future<List<StudyNote>> fetchNotes({String? moduleId, String? lessonId}) async => notes;

  @override
  Future<StudyNote?> fetchNoteById(String noteId) async {
    for (final note in notes) {
      if (note.id == noteId) return note;
    }
    return null;
  }

  @override
  Future<StudyNote> createNote({
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    final note = StudyNote(
      id: 'note-${notes.length + 1}',
      userId: 'student-1',
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notes.add(note);
    return note;
  }

  @override
  Future<StudyNote> updateNote({
    required String noteId,
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    final idx = notes.indexWhere((n) => n.id == noteId);
    if (idx < 0) throw StateError('Missing note');
    final updated = notes[idx].copyWith(
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
      updatedAt: DateTime.now(),
    );
    notes[idx] = updated;
    return updated;
  }

  @override
  Future<bool> deleteNote(String noteId) async {
    notes.removeWhere((n) => n.id == noteId);
    return true;
  }
}
