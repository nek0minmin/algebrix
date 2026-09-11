import 'dart:convert';

import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/screens/notes/notes_screen.dart';
import 'package:algebrix/services/note_draft_store.dart';
import 'package:algebrix/services/notes_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers the round trip a learner actually makes: type, lose the app or the
/// network, come back, and find the writing still there.
void main() {
  const store = NoteDraftStore();
  const accountId = 'student-1';

  void sizeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<NotesProvider> pumpNotes(
    WidgetTester tester,
    _MemoryNotesRepository repository,
  ) async {
    final provider = NotesProvider(repository: repository);
    provider.bindAccount(accountId);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: NotesScreen())),
      ),
    );
    await tester.pumpAndSettle();
    return provider;
  }

  /// Lets the debounce fire and the storage write actually land.
  Future<void> settleDraft(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 900));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('typing a new note leaves a draft on the device', (tester) async {
    sizeScreen(tester);
    await pumpNotes(tester, _MemoryNotesRepository());

    await tester.tap(find.byKey(const Key('new-note-button-compact')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      'Why constants stay fixed',
    );
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'A constant represents a value that does not change.',
    );
    await settleDraft(tester);

    final draft = await tester.runAsync(
      () => store.read(accountId: accountId),
    );

    expect(draft, isNotNull);
    expect(draft!.title, 'Why constants stay fixed');
    expect(draft.content, contains('does not change'));
    expect(draft.noteId, isNull, reason: 'this note has never been saved');
  });

  testWidgets('a draft is restored when the editor reopens', (tester) async {
    sizeScreen(tester);
    SharedPreferences.setMockInitialValues({
      'algebrix_note_draft_${accountId}_new': jsonEncode({
        'noteId': null,
        'title': 'Half a thought',
        'content': 'I was in the middle of explaining like terms when',
        'lessonId': 'm1_l2',
        'savedAt': DateTime.now().toIso8601String(),
      }),
    });

    await pumpNotes(tester, _MemoryNotesRepository());
    await tester.tap(find.byKey(const Key('new-note-button-compact')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('restored-draft-banner')), findsOneWidget);
    expect(find.text('Picked up where you left off'), findsOneWidget);
    expect(find.text('Half a thought'), findsOneWidget);
    expect(
      find.textContaining('in the middle of explaining like terms'),
      findsOneWidget,
    );
  });

  testWidgets('the banner can be dismissed without losing the text',
      (tester) async {
    sizeScreen(tester);
    SharedPreferences.setMockInitialValues({
      'algebrix_note_draft_${accountId}_new': jsonEncode({
        'title': 'Half a thought',
        'content': 'Something I was writing earlier.',
        'lessonId': 'm1_l2',
        'savedAt': DateTime.now().toIso8601String(),
      }),
    });

    await pumpNotes(tester, _MemoryNotesRepository());
    await tester.tap(find.byKey(const Key('new-note-button-compact')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('restored-draft-dismiss')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('restored-draft-banner')), findsNothing);
    expect(find.text('Half a thought'), findsOneWidget);
  });

  testWidgets('saving the note clears its draft', (tester) async {
    sizeScreen(tester);
    final repository = _MemoryNotesRepository();
    await pumpNotes(tester, repository);

    await tester.tap(find.byKey(const Key('new-note-button-compact')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('note-lesson-selector-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesson-option-m1_l2')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      'Why constants stay fixed',
    );
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'A constant represents a value that does not change.',
    );
    await settleDraft(tester);

    expect(
      await tester.runAsync(() => store.read(accountId: accountId)),
      isNotNull,
      reason: 'the draft should exist right up until the save lands',
    );

    await tester.ensureVisible(find.byKey(const Key('save-note-button')));
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(repository.notes, hasLength(1));
    expect(
      await tester.runAsync(() => store.read(accountId: accountId)),
      isNull,
      reason: 'Supabase has it now, so the device copy is redundant',
    );
  });

  testWidgets('discarding an unsaved note also drops its draft',
      (tester) async {
    sizeScreen(tester);
    await pumpNotes(tester, _MemoryNotesRepository());

    await tester.tap(find.byKey(const Key('new-note-button-compact')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      'Never mind',
    );
    await settleDraft(tester);

    await tester.tap(find.byKey(const Key('secondary-page-back-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-discard-confirm')));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(
      await tester.runAsync(() => store.read(accountId: accountId)),
      isNull,
      reason: 'discard means discard, on the device too',
    );
  });

  testWidgets('an edit draft offers a way back to the saved note',
      (tester) async {
    sizeScreen(tester);
    final repository = _MemoryNotesRepository();
    final provider = NotesProvider(repository: repository);
    provider.bindAccount(accountId);
    await provider.createNote(
      moduleId: 'module1',
      lessonId: 'm1_l2',
      title: 'Why constants stay fixed',
      content: 'A constant represents a value that does not change.',
    );

    final noteId = repository.notes.single.id;
    SharedPreferences.setMockInitialValues({
      'algebrix_note_draft_${accountId}_$noteId': jsonEncode({
        'noteId': noteId,
        'title': 'Constants, rewritten',
        'content': 'I was rewriting this and never finished the thought',
        'lessonId': 'm1_l2',
        'savedAt': DateTime.now().toIso8601String(),
      }),
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: NotesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('study-note-$noteId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit study note'));
    await tester.pumpAndSettle();

    expect(find.text('Restored your unsaved edits'), findsOneWidget);
    expect(find.text('Constants, rewritten'), findsOneWidget);

    await tester.tap(find.byKey(const Key('restored-draft-revert')));
    await tester.pumpAndSettle();

    expect(find.text('Why constants stay fixed'), findsOneWidget);
    expect(find.text('Constants, rewritten'), findsNothing);
    expect(find.byKey(const Key('restored-draft-banner')), findsNothing);
  });

  testWidgets('one learner never sees another learner\'s draft',
      (tester) async {
    sizeScreen(tester);
    SharedPreferences.setMockInitialValues({
      'algebrix_note_draft_someone-else_new': jsonEncode({
        'title': 'Not yours',
        'content': 'This belongs to a different account entirely.',
        'savedAt': DateTime.now().toIso8601String(),
      }),
    });

    await pumpNotes(tester, _MemoryNotesRepository());
    await tester.tap(find.byKey(const Key('new-note-button-compact')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('restored-draft-banner')), findsNothing);
    expect(find.text('Not yours'), findsNothing);
  });
}

class _MemoryNotesRepository implements NotesRepository {
  final List<StudyNote> notes = [];
  int _nextId = 1;

  @override
  Future<StudyNote> createNote({
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    final now = DateTime.utc(2026, 8, 15, 12, _nextId);
    final note = StudyNote(
      id: 'note-${_nextId++}',
      userId: accountIdForTests,
      moduleId: moduleId,
      lessonId: lessonId,
      title: title.trim(),
      content: content.trim(),
      createdAt: now,
      updatedAt: now,
    );
    notes.add(note);
    return note;
  }

  static const accountIdForTests = 'student-1';

  @override
  Future<bool> deleteNote(String noteId) async {
    final before = notes.length;
    notes.removeWhere((note) => note.id == noteId);
    return notes.length != before;
  }

  @override
  Future<StudyNote?> fetchNoteById(String noteId) async {
    for (final note in notes) {
      if (note.id == noteId) return note;
    }
    return null;
  }

  @override
  Future<List<StudyNote>> fetchNotes({
    String? moduleId,
    String? lessonId,
  }) async {
    return notes
        .where(
          (note) =>
              (moduleId == null || note.moduleId == moduleId) &&
              (lessonId == null || note.lessonId == lessonId),
        )
        .toList(growable: false);
  }

  @override
  Future<StudyNote> updateNote({
    required String noteId,
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    final index = notes.indexWhere((note) => note.id == noteId);
    if (index < 0) throw StateError('Missing note');
    final updated = notes[index].copyWith(
      moduleId: moduleId,
      lessonId: lessonId,
      title: title.trim(),
      content: content.trim(),
      updatedAt: DateTime.utc(2026, 8, 15, 13),
    );
    notes[index] = updated;
    return updated;
  }
}
