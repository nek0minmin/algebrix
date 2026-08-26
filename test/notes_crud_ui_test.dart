import 'dart:io';

import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/screens/notes/note_lesson_options.dart';
import 'package:algebrix/screens/notes/notes_screen.dart';
import 'package:algebrix/services/notes_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('student can create, read, update, and delete a study note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _MemoryNotesRepository();
    final provider = NotesProvider(repository: repository);
    provider.bindAccount('student-1');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: NotesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your ideas belong here'), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-note-button-compact')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('save-note-button')));
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pump();
    expect(find.text('Choose a lesson for this note.'), findsOneWidget);
    expect(find.text('Enter at least 3 characters.'), findsOneWidget);
    expect(
      find.text('Write at least 20 characters explaining your idea.'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('note-lesson-selector-button')),
    );
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
    await tester.ensureVisible(find.byKey(const Key('save-note-button')));
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();

    expect(find.text('Study note created.'), findsOneWidget);
    expect(find.text('Why constants stay fixed'), findsOneWidget);
    expect(repository.notes, hasLength(1));

    final noteId = repository.notes.single.id;
    await tester.tap(find.byKey(Key('study-note-$noteId')));
    await tester.pumpAndSettle();

    expect(find.text('Note details'), findsOneWidget);
    expect(
      find.text('A constant represents a value that does not change.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Edit study note'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      'Constants in expressions',
    );
    await tester.ensureVisible(find.byKey(const Key('save-note-button')));
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();

    expect(find.text('Constants in expressions'), findsOneWidget);
    expect(repository.notes.single.title, 'Constants in expressions');

    await tester.tap(find.byTooltip('Delete study note'));
    await tester.pumpAndSettle();
    expect(find.text('Delete study note?'), findsOneWidget);
    expect(find.textContaining('will be permanently deleted'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-delete-note-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Your ideas belong here'), findsOneWidget);
    expect(repository.notes, isEmpty);
  });

  testWidgets(
    'thinking prompts add math-focused structure without overwriting',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = NotesProvider(repository: _MemoryNotesRepository());
      provider.bindAccount('student-1');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: Scaffold(body: NotesScreen())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('new-note-button-compact')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('note-prompt-explain-why')),
      );
      await tester.tap(find.byKey(const Key('note-prompt-explain-why')));
      await tester.pump();

      final content = tester.widget<TextFormField>(
        find.byKey(const Key('note-content-field')),
      );
      expect(content.controller!.text, contains('Why it works:'));

      content.controller!.text = '${content.controller!.text}\nMy own idea';
      await tester.ensureVisible(find.byKey(const Key('note-prompt-question')));
      await tester.tap(find.byKey(const Key('note-prompt-question')));
      await tester.pump();
      expect(content.controller!.text, contains('My own idea'));
      expect(content.controller!.text, contains('Where I got stuck:'));
    },
  );

  testWidgets('secondary notes header has branded back navigation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = NotesProvider(repository: _MemoryNotesRepository());
    provider.bindAccount('student-1');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: NotesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('new-note-button-compact')));
    await tester.pumpAndSettle();

    expect(find.text('NOTES'), findsNothing);
    expect(find.text('Explain one idea in your own words.'), findsOneWidget);
    expect(find.byTooltip('Back to Notes'), findsOneWidget);
    expect(find.bySemanticsLabel('Back to Notes'), findsWidgets);

    await tester.tap(find.byKey(const Key('secondary-page-back-button')));
    await tester.pumpAndSettle();
    expect(find.text('Notes'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('thinking prompts respond at the 380px content breakpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = NotesProvider(repository: _MemoryNotesRepository());
    provider.bindAccount('student-1');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: NotesScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-note-button-compact')));
    await tester.pumpAndSettle();

    final explainWhy = find.byKey(const Key('note-prompt-explain-why'));
    final workedExample = find.byKey(const Key('note-prompt-worked-example'));
    expect(
      tester.getTopLeft(explainWhy).dy,
      tester.getTopLeft(workedExample).dy,
    );
    expect(
      tester.getTopLeft(explainWhy).dx,
      lessThan(tester.getTopLeft(workedExample).dx),
    );
    expect(tester.getSize(explainWhy).height, 52);
    expect(find.bySemanticsLabel('Insert Explain why prompt'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(390, 900));
    tester.view.physicalSize = const Size(390, 900);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(explainWhy).dx,
      tester.getTopLeft(workedExample).dx,
    );
    expect(
      tester.getTopLeft(explainWhy).dy,
      lessThan(tester.getTopLeft(workedExample).dy),
    );
    expect(tester.getSize(explainWhy).height, 52);
  });

  testWidgets('notes and form remain usable at a narrow phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = NotesProvider(repository: _MemoryNotesRepository());
    provider.bindAccount('student-1');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const Scaffold(body: NotesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsOneWidget);
    expect(find.byKey(const Key('new-note-button-compact')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('new-note-button-compact')));
    await tester.pumpAndSettle();
    expect(find.text('New note'), findsOneWidget);
    expect(find.text('Explain one idea in your own words.'), findsOneWidget);
    expect(find.byTooltip('Back to Notes'), findsOneWidget);
    expect(find.byKey(const Key('note-prompt-explain-why')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('new Study Notes source contains no mojibake markers', () {
    const paths = [
      'lib/screens/notes/note_lesson_options.dart',
      'lib/screens/notes/note_form_screen.dart',
      'lib/screens/notes/note_detail_screen.dart',
      'lib/screens/notes/notes_screen.dart',
    ];
    const markers = ['â', 'Ã', 'ðŸ', '�', 'Â'];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      for (final marker in markers) {
        expect(
          source,
          isNot(contains(marker)),
          reason: '$path contains $marker',
        );
      }
    }
  });

  testWidgets('lesson picker displays module groupings and selects completed lesson', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _MemoryNotesRepository();
    final provider = NotesProvider(repository: repository);
    provider.bindAccount('student-1');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: NotesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('new-note-button-compact')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('note-lesson-selector-button')));
    await tester.tap(find.byKey(const Key('note-lesson-selector-button')));
    await tester.pumpAndSettle();

    expect(find.text('Module 1 • Foundations of Algebra'), findsOneWidget);
    expect(find.text('Module 2 • Operations & Simplification'), findsOneWidget);
    expect(find.byKey(const Key('lesson-option-m1_l4')), findsOneWidget);

    await tester.tap(find.byKey(const Key('lesson-option-m1_l4')));
    await tester.pumpAndSettle();

    expect(find.text('1.4 • Expressions'), findsOneWidget);
  });

  test('smart lesson detection identifies expressions topic from content', () {
    final match = detectBestFittingLesson(
      title: 'Math phrases',
      content: 'An algebraic expression combines terms and operations like 3x + 5 without an equal sign.',
    );
    expect(match?.lessonId, 'm1_l4');
    expect(match?.title, 'Expressions');
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
      userId: 'student-1',
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

  @override
  Future<bool> deleteNote(String noteId) async {
    final originalLength = notes.length;
    notes.removeWhere((note) => note.id == noteId);
    return notes.length != originalLength;
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
