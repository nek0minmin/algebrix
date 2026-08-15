import 'dart:async';

import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/services/notes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotesProvider', () {
    test('loads immutable, newest-first notes for the bound account', () async {
      final repository = _MemoryNotesRepository(activeUser: 'user_1')
        ..seed([
          _note(id: 'older', userId: 'user_1', updatedAt: DateTime(2026, 1)),
          _note(id: 'newer', userId: 'user_1', updatedAt: DateTime(2026, 2)),
        ]);
      final provider = NotesProvider(repository: repository);

      provider.bindAccount('user_1');
      await _waitUntil(() => !provider.isLoading);

      expect(provider.notes.map((note) => note.id), ['newer', 'older']);
      expect(
        () => provider.notes.add(_note(id: 'other', userId: 'user_1')),
        throwsUnsupportedError,
      );
      expect(provider.errorMessage, isNull);
    });

    test(
      'create, select, update, and delete synchronize after success',
      () async {
        final repository = _MemoryNotesRepository(activeUser: 'user_1');
        final provider = NotesProvider(repository: repository);
        provider.bindAccount('user_1');
        await _waitUntil(() => !provider.isLoading);

        expect(
          await provider.createNote(
            moduleId: ' module1 ',
            lessonId: ' m1_l2 ',
            title: ' Understanding constants ',
            content: ' A constant keeps the same value. ',
          ),
          isTrue,
        );
        expect(provider.notes, hasLength(1));
        expect(provider.selectedNote?.title, 'Understanding constants');
        expect(repository.lastCreatedModuleId, 'module1');
        expect(repository.lastCreatedLessonId, 'm1_l2');

        final noteId = provider.notes.single.id;
        provider.selectNote(null);
        expect(provider.selectedNote, isNull);
        expect(provider.selectNote(noteId)?.id, noteId);

        expect(
          await provider.updateNote(
            noteId: noteId,
            moduleId: 'module1',
            lessonId: 'm1_l2',
            title: 'Constants in expressions',
            content: 'The number without a variable is the constant.',
          ),
          isTrue,
        );
        expect(provider.notes.single.title, 'Constants in expressions');
        expect(provider.selectedNote?.title, 'Constants in expressions');

        expect(await provider.deleteNote(noteId), isTrue);
        expect(provider.notes, isEmpty);
        expect(provider.selectedNote, isNull);
      },
    );

    test(
      'local validation is friendly and does not call the repository',
      () async {
        final repository = _MemoryNotesRepository(activeUser: 'user_1');
        final provider = NotesProvider(repository: repository);
        provider.bindAccount('user_1');
        await _waitUntil(() => !provider.isLoading);

        expect(
          await provider.createNote(
            moduleId: 'module1',
            lessonId: 'm1_l1',
            title: '  x ',
            content: 'A useful explanation',
          ),
          isFalse,
        );
        expect(provider.errorMessage, contains('between 3 and 100'));
        expect(repository.createCalls, 0);
        expect(provider.notes, isEmpty);

        expect(
          await provider.createNote(
            moduleId: 'module1',
            lessonId: '',
            title: 'Variables',
            content: 'A useful explanation',
          ),
          isFalse,
        );
        expect(provider.errorMessage, 'Choose a lesson for this note.');
        expect(repository.createCalls, 0);
      },
    );

    test(
      'repository validation errors propagate without changing local data',
      () async {
        final original = _note(id: 'note_1', userId: 'user_1');
        final repository = _MemoryNotesRepository(activeUser: 'user_1')
          ..seed([original])
          ..updateError = ArgumentError('The title is not allowed.');
        final provider = NotesProvider(repository: repository);
        provider.bindAccount('user_1');
        await _waitUntil(() => !provider.isLoading);

        expect(
          await provider.updateNote(
            noteId: original.id,
            moduleId: original.moduleId,
            lessonId: original.lessonId,
            title: 'A valid local title',
            content: original.content,
          ),
          isFalse,
        );
        expect(provider.notes.single.title, original.title);
        expect(provider.errorMessage, 'The title is not allowed.');
        expect(provider.isSaving, isFalse);
      },
    );

    test('rejects notes returned for a different account', () async {
      final repository = _MemoryNotesRepository(activeUser: 'user_1')
        ..fetchOverride = () async => [
          _note(id: 'private_note', userId: 'user_2'),
        ];
      final provider = NotesProvider(repository: repository);

      provider.bindAccount('user_1');
      await _waitUntil(() => !provider.isLoading);

      expect(provider.notes, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });

    test('late account load cannot overwrite the active account', () async {
      final oldLoad = Completer<List<StudyNote>>();
      var fetchCalls = 0;
      final repository = _MemoryNotesRepository(activeUser: 'user_1')
        ..fetchOverride = () {
          fetchCalls++;
          if (fetchCalls == 1) return oldLoad.future;
          return Future.value([_note(id: 'new_account', userId: 'user_2')]);
        };
      final provider = NotesProvider(repository: repository);

      provider.bindAccount('user_1');
      repository.activeUser = 'user_2';
      provider.bindAccount('user_2');
      await _waitUntil(() => !provider.isLoading && provider.notes.isNotEmpty);
      expect(provider.notes.single.id, 'new_account');

      oldLoad.complete([_note(id: 'old_account', userId: 'user_1')]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.accountId, 'user_2');
      expect(provider.notes.single.id, 'new_account');
    });

    test('late create cannot leak into a switched account', () async {
      final create = Completer<StudyNote>();
      final repository = _MemoryNotesRepository(activeUser: 'user_1')
        ..createOverride =
            ({
              required moduleId,
              required lessonId,
              required title,
              required content,
            }) => create.future;
      final provider = NotesProvider(repository: repository);
      provider.bindAccount('user_1');
      await _waitUntil(() => !provider.isLoading);

      final result = provider.createNote(
        moduleId: 'module1',
        lessonId: 'm1_l1',
        title: 'Variables note',
        content: 'Variables can represent values.',
      );
      await Future<void>.delayed(Duration.zero);
      expect(provider.isSaving, isTrue);

      repository.activeUser = 'user_2';
      repository.fetchOverride = () async => [];
      provider.bindAccount('user_2');
      create.complete(_note(id: 'created_for_old', userId: 'user_1'));

      expect(await result, isFalse);
      await _waitUntil(() => !provider.isLoading);
      expect(provider.accountId, 'user_2');
      expect(provider.notes, isEmpty);
      expect(provider.isSaving, isFalse);
    });

    test('late detail load cannot overwrite a newer selection', () async {
      final first = _note(id: 'note_1', userId: 'user_1');
      final second = _note(id: 'note_2', userId: 'user_1');
      final detailLoad = Completer<StudyNote?>();
      final repository = _MemoryNotesRepository(activeUser: 'user_1')
        ..seed([first, second])
        ..fetchByIdOverride = (_) => detailLoad.future;
      final provider = NotesProvider(repository: repository);
      provider.bindAccount('user_1');
      await _waitUntil(() => !provider.isLoading);

      final result = provider.loadAndSelectNote(first.id);
      await Future<void>.delayed(Duration.zero);
      expect(provider.isLoadingNote, isTrue);

      provider.selectNote(second.id);
      expect(provider.selectedNote?.id, second.id);
      expect(provider.isLoadingNote, isFalse);

      detailLoad.complete(first);
      expect(await result, isFalse);
      expect(provider.selectedNote?.id, second.id);
    });

    test(
      'reselecting the same note reports cancellation of a detail load',
      () async {
        final original = _note(id: 'note_1', userId: 'user_1');
        final detailLoad = Completer<StudyNote?>();
        final repository = _MemoryNotesRepository(activeUser: 'user_1')
          ..seed([original])
          ..fetchByIdOverride = (_) => detailLoad.future;
        final provider = NotesProvider(repository: repository);
        provider.bindAccount('user_1');
        await _waitUntil(() => !provider.isLoading);
        provider.selectNote(original.id);

        var notifications = 0;
        provider.addListener(() => notifications++);
        final result = provider.loadAndSelectNote(original.id);
        await Future<void>.delayed(Duration.zero);
        final beforeCancel = notifications;
        expect(provider.isLoadingNote, isTrue);

        provider.selectNote(original.id);
        expect(provider.isLoadingNote, isFalse);
        expect(notifications, beforeCancel + 1);

        detailLoad.complete(original);
        expect(await result, isFalse);
        expect(provider.selectedNote?.id, original.id);
      },
    );

    test(
      'late detail load cannot resurrect a successfully deleted note',
      () async {
        final original = _note(id: 'note_1', userId: 'user_1');
        final detailLoad = Completer<StudyNote?>();
        final repository = _MemoryNotesRepository(activeUser: 'user_1')
          ..seed([original])
          ..fetchByIdOverride = (_) => detailLoad.future;
        final provider = NotesProvider(repository: repository);
        provider.bindAccount('user_1');
        await _waitUntil(() => !provider.isLoading);

        final detailResult = provider.loadAndSelectNote(original.id);
        await Future<void>.delayed(Duration.zero);
        expect(await provider.deleteNote(original.id), isTrue);
        expect(provider.notes, isEmpty);

        detailLoad.complete(original);
        expect(await detailResult, isFalse);
        expect(provider.notes, isEmpty);
        expect(provider.selectedNote, isNull);
      },
    );

    test(
      'failed and in-flight deletion retain the note until success',
      () async {
        final original = _note(id: 'note_1', userId: 'user_1');
        final deleteResult = Completer<bool>();
        final repository = _MemoryNotesRepository(activeUser: 'user_1')
          ..seed([original])
          ..deleteOverride = (_) => deleteResult.future;
        final provider = NotesProvider(repository: repository);
        provider.bindAccount('user_1');
        await _waitUntil(() => !provider.isLoading);
        provider.selectNote(original.id);

        final failedDelete = provider.deleteNote(original.id);
        await Future<void>.delayed(Duration.zero);
        expect(provider.isDeletingNote(original.id), isTrue);
        expect(provider.notes.single.id, original.id);

        deleteResult.complete(false);
        expect(await failedDelete, isFalse);
        expect(provider.notes.single.id, original.id);
        expect(provider.selectedNote?.id, original.id);

        repository.deleteOverride = (_) async => true;
        expect(await provider.deleteNote(original.id), isTrue);
        expect(provider.notes, isEmpty);
        expect(provider.selectedNote, isNull);
      },
    );

    test(
      'delete and update are serialized so a note cannot be resurrected',
      () async {
        final original = _note(id: 'note_1', userId: 'user_1');
        final deleteResult = Completer<bool>();
        final repository = _MemoryNotesRepository(activeUser: 'user_1')
          ..seed([original])
          ..deleteOverride = (_) => deleteResult.future;
        final provider = NotesProvider(repository: repository);
        provider.bindAccount('user_1');
        await _waitUntil(() => !provider.isLoading);

        final pendingDelete = provider.deleteNote(original.id);
        await Future<void>.delayed(Duration.zero);
        expect(
          await provider.updateNote(
            noteId: original.id,
            moduleId: original.moduleId,
            lessonId: original.lessonId,
            title: 'An update that must wait',
            content: original.content,
          ),
          isFalse,
        );
        expect(repository.updateCalls, 0);

        deleteResult.complete(true);
        expect(await pendingDelete, isTrue);
        expect(provider.notes, isEmpty);
      },
    );
  });
}

typedef _CreateOverride =
    Future<StudyNote> Function({
      required String moduleId,
      required String lessonId,
      required String title,
      required String content,
    });

class _MemoryNotesRepository implements NotesRepository {
  _MemoryNotesRepository({required this.activeUser});

  String activeUser;
  final List<StudyNote> _notes = [];
  int createCalls = 0;
  int updateCalls = 0;
  String? lastCreatedModuleId;
  String? lastCreatedLessonId;
  Object? updateError;
  Future<List<StudyNote>> Function()? fetchOverride;
  Future<StudyNote?> Function(String noteId)? fetchByIdOverride;
  _CreateOverride? createOverride;
  Future<bool> Function(String noteId)? deleteOverride;

  void seed(Iterable<StudyNote> notes) {
    _notes
      ..clear()
      ..addAll(notes);
  }

  @override
  Future<StudyNote> createNote({
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    createCalls++;
    lastCreatedModuleId = moduleId;
    lastCreatedLessonId = lessonId;
    final override = createOverride;
    if (override != null) {
      return override(
        moduleId: moduleId,
        lessonId: lessonId,
        title: title,
        content: content,
      );
    }

    final now = DateTime(2026, 8, 15, createCalls);
    final note = StudyNote(
      id: 'note_$createCalls',
      userId: activeUser,
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    _notes.add(note);
    return note;
  }

  @override
  Future<bool> deleteNote(String noteId) async {
    final override = deleteOverride;
    if (override != null) return override(noteId);
    final before = _notes.length;
    _notes.removeWhere(
      (note) => note.id == noteId && note.userId == activeUser,
    );
    return before != _notes.length;
  }

  @override
  Future<StudyNote?> fetchNoteById(String noteId) async {
    final override = fetchByIdOverride;
    if (override != null) return override(noteId);
    for (final note in _notes) {
      if (note.id == noteId && note.userId == activeUser) return note;
    }
    return null;
  }

  @override
  Future<List<StudyNote>> fetchNotes({
    String? moduleId,
    String? lessonId,
  }) async {
    final override = fetchOverride;
    if (override != null) return override();
    return _notes
        .where(
          (note) =>
              note.userId == activeUser &&
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
    updateCalls++;
    final error = updateError;
    if (error != null) throw error;
    final index = _notes.indexWhere(
      (note) => note.id == noteId && note.userId == activeUser,
    );
    if (index == -1) throw StateError('Note not found.');
    final current = _notes[index];
    final updated = StudyNote(
      id: current.id,
      userId: current.userId,
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt.add(const Duration(minutes: 1)),
    );
    _notes[index] = updated;
    return updated;
  }
}

StudyNote _note({
  required String id,
  required String userId,
  DateTime? updatedAt,
}) {
  final createdAt = DateTime(2026, 1, 1);
  return StudyNote(
    id: id,
    userId: userId,
    moduleId: 'module1',
    lessonId: 'm1_l1',
    title: 'Why variables work',
    content: 'A variable stands in for a value that may change.',
    createdAt: createdAt,
    updatedAt: updatedAt ?? createdAt,
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100 && !condition(); attempt++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue, reason: 'Asynchronous provider state timed out.');
}
