import 'dart:async';

import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/services/notes_repository.dart';
import 'package:flutter/foundation.dart';

enum NoteSortOption { newest, oldest, title, lesson }

/// Account-scoped state for the My Study Notes CRUD feature.
///
/// Supabase remains authoritative: the in-memory list is changed only after a
/// repository operation succeeds. Account generations prevent a response
/// started for one learner from appearing after logout or an account switch.
class NotesProvider extends ChangeNotifier {
  NotesProvider({required NotesRepository repository})
    : _repository = repository;

  final NotesRepository _repository;

  String? _accountId;
  int _accountGeneration = 0;
  int _loadRequestId = 0;
  int _detailRequestId = 0;
  int _mutationVersion = 0;
  List<StudyNote> _notes = const [];
  StudyNote? _selectedNote;
  bool _isLoading = false;
  bool _isLoadingNote = false;
  bool _isSaving = false;
  final Set<String> _deletingNoteIds = <String>{};
  String? _errorMessage;
  String _searchQuery = '';
  NoteSortOption _sortOption = NoteSortOption.newest;

  String? get accountId => _accountId;
  String get searchQuery => _searchQuery;
  NoteSortOption get sortOption => _sortOption;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(NoteSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  List<StudyNote> get filteredNotes {
    final query = _searchQuery.trim().toLowerCase();
    var list = _notes.where((note) {
      if (query.isEmpty) return true;
      final titleMatch = note.title.toLowerCase().contains(query);
      final contentMatch = note.displayContent.toLowerCase().contains(query);
      final lessonMatch = note.lessonId.toLowerCase().contains(query);
      return titleMatch || contentMatch || lessonMatch;
    }).toList();

    switch (_sortOption) {
      case NoteSortOption.newest:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case NoteSortOption.oldest:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case NoteSortOption.title:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case NoteSortOption.lesson:
        list.sort((a, b) => a.lessonId.compareTo(b.lessonId));
        break;
    }
    return list;
  }

  List<StudyNote> get notes => List<StudyNote>.unmodifiable(_notes);
  StudyNote? get selectedNote => _selectedNote;
  bool get isLoading => _isLoading;
  bool get isLoadingNote => _isLoadingNote;
  bool get isSaving => _isSaving;
  bool get isDeleting => _deletingNoteIds.isNotEmpty;
  Set<String> get deletingNoteIds => Set<String>.unmodifiable(_deletingNoteIds);
  String? get errorMessage => _errorMessage;
  bool get isBusy => isLoading || isLoadingNote || isSaving || isDeleting;

  bool isDeletingNote(String noteId) => _deletingNoteIds.contains(noteId);

  /// Clears prior-account state immediately and hydrates the new account.
  void bindAccount(String? accountId) {
    if (_accountId == accountId) return;

    _accountGeneration++;
    _loadRequestId++;
    _detailRequestId++;
    _mutationVersion = 0;
    _accountId = accountId;
    _notes = const [];
    _selectedNote = null;
    _isLoading = false;
    _isLoadingNote = false;
    _isSaving = false;
    _deletingNoteIds.clear();
    _errorMessage = null;

    if (accountId == null) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    unawaited(
      _loadNotes(
        accountId: accountId,
        generation: _accountGeneration,
        requestId: _loadRequestId,
        mutationVersion: _mutationVersion,
      ),
    );
  }

  /// Reloads notes for the active account, optionally scoped to a lesson.
  Future<bool> loadNotes({String? moduleId, String? lessonId}) async {
    final accountId = _accountId;
    if (accountId == null) {
      _setSignedOutError();
      return false;
    }

    final requestId = ++_loadRequestId;
    _invalidateDetailRequest();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    return _loadNotes(
      accountId: accountId,
      generation: _accountGeneration,
      requestId: requestId,
      mutationVersion: _mutationVersion,
      moduleId: moduleId,
      lessonId: lessonId,
    );
  }

  Future<bool> _loadNotes({
    required String accountId,
    required int generation,
    required int requestId,
    required int mutationVersion,
    String? moduleId,
    String? lessonId,
  }) async {
    try {
      final results = await _repository.fetchNotes(
        moduleId: moduleId,
        lessonId: lessonId,
      );
      if (!_isCurrentRequest(accountId, generation, requestId)) return false;

      for (final note in results) {
        _requireOwnedNote(note, accountId);
      }

      // A create/update/delete completed while this read was in flight. Keep
      // the newer mutation rather than replacing it with an older snapshot.
      if (_mutationVersion != mutationVersion) return false;

      _notes = _sorted(results);
      _selectedNote = _findNote(_selectedNote?.id);
      _errorMessage = null;
      return true;
    } catch (error) {
      if (!_isCurrentRequest(accountId, generation, requestId)) return false;
      _errorMessage = _friendlyError(error, action: 'load');
      return false;
    } finally {
      if (_isCurrentRequest(accountId, generation, requestId)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Selects a note already present in the account-scoped list.
  StudyNote? selectNote(String? noteId) {
    final cancelledPendingLoad = _invalidateDetailRequest();
    final nextSelection = _findNote(noteId);
    if (identical(_selectedNote, nextSelection)) {
      if (cancelledPendingLoad) notifyListeners();
      return nextSelection;
    }
    _selectedNote = nextSelection;
    _errorMessage = null;
    notifyListeners();
    return nextSelection;
  }

  /// Fetches a note directly, useful for a deep-linked detail route.
  Future<bool> loadAndSelectNote(String noteId) async {
    final accountId = _accountId;
    if (accountId == null) {
      _setSignedOutError();
      return false;
    }
    if (noteId.trim().isEmpty) {
      _setError('Choose a study note to open.');
      return false;
    }

    final generation = _accountGeneration;
    final requestId = ++_detailRequestId;
    final mutationVersion = _mutationVersion;
    _isLoadingNote = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final note = await _repository.fetchNoteById(noteId);
      if (!_isCurrentDetailRequest(accountId, generation, requestId) ||
          _mutationVersion != mutationVersion) {
        return false;
      }
      if (note == null) {
        _errorMessage = 'This study note could not be found.';
        return false;
      }

      _requireOwnedNote(note, accountId);
      _selectedNote = note;
      _upsert(note);
      _errorMessage = null;
      return true;
    } catch (error) {
      if (!_isCurrentDetailRequest(accountId, generation, requestId)) {
        return false;
      }
      _errorMessage = _friendlyError(error, action: 'load');
      return false;
    } finally {
      if (_isCurrentDetailRequest(accountId, generation, requestId)) {
        _isLoadingNote = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createNote({
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    final accountId = _accountId;
    if (accountId == null) {
      _setSignedOutError();
      return false;
    }
    if (_hasMutationInFlight) return false;

    final normalized = _normalizeAndValidate(
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
    );
    if (normalized == null) return false;

    final generation = _accountGeneration;
    _invalidateDetailRequest();
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final note = await _repository.createNote(
        moduleId: normalized.moduleId,
        lessonId: normalized.lessonId,
        title: normalized.title,
        content: normalized.content,
      );
      if (!_isCurrentAccount(accountId, generation)) return false;

      _requireOwnedNote(note, accountId);
      _mutationVersion++;
      _upsert(note);
      _selectedNote = note;
      _errorMessage = null;
      return true;
    } catch (error) {
      if (!_isCurrentAccount(accountId, generation)) return false;
      _errorMessage = _friendlyError(error, action: 'save');
      return false;
    } finally {
      if (_isCurrentAccount(accountId, generation)) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<bool> updateNote({
    required String noteId,
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    final accountId = _accountId;
    if (accountId == null) {
      _setSignedOutError();
      return false;
    }
    if (_hasMutationInFlight) return false;
    if (noteId.trim().isEmpty) {
      _setError('Choose a study note to update.');
      return false;
    }

    final normalized = _normalizeAndValidate(
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
    );
    if (normalized == null) return false;

    final generation = _accountGeneration;
    _invalidateDetailRequest();
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final note = await _repository.updateNote(
        noteId: noteId,
        moduleId: normalized.moduleId,
        lessonId: normalized.lessonId,
        title: normalized.title,
        content: normalized.content,
      );
      if (!_isCurrentAccount(accountId, generation)) return false;

      _requireOwnedNote(note, accountId);
      if (note.id != noteId) {
        throw StateError('The updated note did not match the requested note.');
      }
      _mutationVersion++;
      _upsert(note);
      if (_selectedNote?.id == noteId) _selectedNote = note;
      _errorMessage = null;
      return true;
    } catch (error) {
      if (!_isCurrentAccount(accountId, generation)) return false;
      _errorMessage = _friendlyError(error, action: 'save');
      return false;
    } finally {
      if (_isCurrentAccount(accountId, generation)) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteNote(String noteId) async {
    final accountId = _accountId;
    if (accountId == null) {
      _setSignedOutError();
      return false;
    }
    if (noteId.trim().isEmpty) {
      _setError('Choose a study note to delete.');
      return false;
    }
    if (_hasMutationInFlight) return false;

    final generation = _accountGeneration;
    _invalidateDetailRequest();
    _deletingNoteIds.add(noteId);
    _errorMessage = null;
    notifyListeners();

    try {
      final deleted = await _repository.deleteNote(noteId);
      if (!_isCurrentAccount(accountId, generation)) return false;
      if (!deleted) {
        _errorMessage = 'This study note could not be deleted. Try again.';
        return false;
      }

      _mutationVersion++;
      _notes = _notes
          .where((note) => note.id != noteId)
          .toList(growable: false);
      if (_selectedNote?.id == noteId) _selectedNote = null;
      _errorMessage = null;
      return true;
    } catch (error) {
      if (!_isCurrentAccount(accountId, generation)) return false;
      _errorMessage = _friendlyError(error, action: 'delete');
      return false;
    } finally {
      if (_isCurrentAccount(accountId, generation)) {
        _deletingNoteIds.remove(noteId);
        notifyListeners();
      }
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  bool _isCurrentAccount(String accountId, int generation) =>
      _accountId == accountId && _accountGeneration == generation;

  bool _isCurrentRequest(String accountId, int generation, int requestId) =>
      _isCurrentAccount(accountId, generation) && _loadRequestId == requestId;

  bool _isCurrentDetailRequest(
    String accountId,
    int generation,
    int requestId,
  ) =>
      _isCurrentAccount(accountId, generation) && _detailRequestId == requestId;

  bool get _hasMutationInFlight => _isSaving || _deletingNoteIds.isNotEmpty;

  bool _invalidateDetailRequest() {
    _detailRequestId++;
    final wasLoading = _isLoadingNote;
    _isLoadingNote = false;
    return wasLoading;
  }

  StudyNote? _findNote(String? noteId) {
    if (noteId == null) return null;
    for (final note in _notes) {
      if (note.id == noteId) return note;
    }
    return null;
  }

  void _upsert(StudyNote note) {
    final next = _notes.where((item) => item.id != note.id).toList()..add(note);
    _notes = _sorted(next);
  }

  List<StudyNote> _sorted(Iterable<StudyNote> notes) {
    final sorted = notes.toList(growable: false);
    sorted.sort((left, right) {
      final updated = right.updatedAt.compareTo(left.updatedAt);
      if (updated != 0) return updated;
      return right.id.compareTo(left.id);
    });
    return List<StudyNote>.unmodifiable(sorted);
  }

  void _requireOwnedNote(StudyNote note, String accountId) {
    if (note.userId != accountId) {
      throw StateError('Study note data belongs to a different account.');
    }
  }

  _NormalizedNoteInput? _normalizeAndValidate({
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) {
    final normalized = _NormalizedNoteInput(
      moduleId: moduleId.trim(),
      lessonId: lessonId.trim(),
      title: title.trim(),
      content: content.trim(),
    );

    if (normalized.moduleId.isEmpty) {
      _setError('This lesson is missing its module information.');
      return null;
    }
    if (normalized.lessonId.isEmpty) {
      _setError('Choose a lesson for this note.');
      return null;
    }
    if (normalized.title.length < 3 || normalized.title.length > 100) {
      _setError('Note title must be between 3 and 100 characters.');
      return null;
    }
    if (normalized.content.length < 3 || normalized.content.length > 2000) {
      _setError('Your explanation must be between 3 and 2000 characters.');
      return null;
    }
    return normalized;
  }

  void _setSignedOutError() {
    _setError('Sign in to manage your study notes.');
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  String _friendlyError(Object error, {required String action}) {
    if (error is NotesRepositoryException) return error.message;
    final raw = error.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('authenticated') || lower.contains('sign in')) {
      return 'Sign in to manage your study notes.';
    }
    if (lower.contains('row-level security') ||
        lower.contains('permission denied') ||
        lower.contains('42501')) {
      return 'You don\u2019t have permission to change this study note.';
    }
    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('connection')) {
      return 'We couldn\u2019t reach your study notes. Check your connection and try again.';
    }
    if (error is ArgumentError || error is FormatException) {
      return raw
          .replaceFirst(RegExp(r'^Invalid argument(?:\(s\))?:?\s*'), '')
          .replaceFirst(RegExp(r'^FormatException:\s*'), '');
    }
    return switch (action) {
      'load' => 'Your study notes could not be loaded. Please try again.',
      'delete' => 'This study note could not be deleted. Please try again.',
      _ => 'Your study note could not be saved. Please try again.',
    };
  }
}

class _NormalizedNoteInput {
  const _NormalizedNoteInput({
    required this.moduleId,
    required this.lessonId,
    required this.title,
    required this.content,
  });

  final String moduleId;
  final String lessonId;
  final String title;
  final String content;
}
