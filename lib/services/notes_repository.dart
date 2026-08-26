import 'package:algebrix/models/study_note_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persistence boundary for the signed-in learner's study notes.
abstract interface class NotesRepository {
  Future<StudyNote> createNote({
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  });

  Future<List<StudyNote>> fetchNotes({String? moduleId, String? lessonId});

  Future<StudyNote?> fetchNoteById(String noteId);

  Future<StudyNote> updateNote({
    required String noteId,
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  });

  /// Returns `true` when a note was deleted and `false` when it did not exist.
  Future<bool> deleteNote(String noteId);
}

/// A user-safe repository failure that does not expose database internals.
class NotesRepositoryException implements Exception {
  const NotesRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class SupabaseNotesRepository implements NotesRepository {
  SupabaseNotesRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<StudyNote> createNote({
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    _requireAuthenticatedUser();
    final draft = _validatedDraft(
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
    );

    try {
      // user_id is deliberately omitted. Its database default is auth.uid(),
      // and RLS independently requires the resulting row to belong to it.
      final row = await _client
          .from('study_notes')
          .insert(draft)
          .select()
          .single();
      return StudyNote.fromJson(row);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error, action: 'create');
    } on FormatException catch (error) {
      throw NotesRepositoryException(
        'The saved note returned invalid data.',
        cause: error,
      );
    }
  }

  @override
  Future<List<StudyNote>> fetchNotes({
    String? moduleId,
    String? lessonId,
  }) async {
    final userId = _requireAuthenticatedUser();
    final normalizedModuleId = _optionalIdentifier(moduleId, 'moduleId');
    final normalizedLessonId = _optionalIdentifier(lessonId, 'lessonId');

    try {
      return await _queryNotes(userId, normalizedModuleId, normalizedLessonId);
    } on PostgrestException catch (error) {
      // Auto-retry once after a brief delay for transient connection or JWT sync
      try {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        return await _queryNotes(userId, normalizedModuleId, normalizedLessonId);
      } catch (_) {
        throw _mapPostgrestError(error, action: 'load');
      }
    } on FormatException catch (error) {
      throw NotesRepositoryException(
        'One of your saved notes contains invalid data.',
        cause: error,
      );
    }
  }

  Future<List<StudyNote>> _queryNotes(
    String userId,
    String? moduleId,
    String? lessonId,
  ) async {
    var query = _client.from('study_notes').select().eq('user_id', userId);
    if (moduleId != null) {
      query = query.eq('module_id', moduleId);
    }
    if (lessonId != null) {
      query = query.eq('lesson_id', lessonId);
    }
    final rows = await query.order('updated_at', ascending: false);
    return rows.map((row) => StudyNote.fromJson(row)).toList(growable: false);
  }

  @override
  Future<StudyNote?> fetchNoteById(String noteId) async {
    final userId = _requireAuthenticatedUser();
    final normalizedNoteId = _requiredValue(noteId, 'noteId', maxLength: 64);

    try {
      final row = await _client
          .from('study_notes')
          .select()
          .eq('id', normalizedNoteId)
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? null : StudyNote.fromJson(row);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error, action: 'load');
    } on FormatException catch (error) {
      throw NotesRepositoryException(
        'The saved note contains invalid data.',
        cause: error,
      );
    }
  }

  @override
  Future<StudyNote> updateNote({
    required String noteId,
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) async {
    final userId = _requireAuthenticatedUser();
    final normalizedNoteId = _requiredValue(noteId, 'noteId', maxLength: 64);
    final changes = _validatedDraft(
      moduleId: moduleId,
      lessonId: lessonId,
      title: title,
      content: content,
    );

    try {
      final row = await _client
          .from('study_notes')
          .update(changes)
          .eq('id', normalizedNoteId)
          .eq('user_id', userId)
          .select()
          .maybeSingle();
      if (row == null) {
        throw const NotesRepositoryException(
          'That study note could not be found.',
        );
      }
      return StudyNote.fromJson(row);
    } on NotesRepositoryException {
      rethrow;
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error, action: 'update');
    } on FormatException catch (error) {
      throw NotesRepositoryException(
        'The updated note returned invalid data.',
        cause: error,
      );
    }
  }

  @override
  Future<bool> deleteNote(String noteId) async {
    final userId = _requireAuthenticatedUser();
    final normalizedNoteId = _requiredValue(noteId, 'noteId', maxLength: 64);

    try {
      final deleted = await _client
          .from('study_notes')
          .delete()
          .eq('id', normalizedNoteId)
          .eq('user_id', userId)
          .select('id')
          .maybeSingle();
      return deleted != null;
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error, action: 'delete');
    }
  }

  String _requireAuthenticatedUser() {
    final user = _client.auth.currentUser ?? _client.auth.currentSession?.user;
    if (user == null) {
      throw const NotesRepositoryException(
        'Please sign in to access your study notes.',
      );
    }
    return user.id;
  }

  static Map<String, String> _validatedDraft({
    required String moduleId,
    required String lessonId,
    required String title,
    required String content,
  }) {
    return <String, String>{
      'module_id': _identifier(moduleId, 'moduleId'),
      'lesson_id': _identifier(lessonId, 'lessonId'),
      'title': _requiredValue(title, 'title', minLength: 3, maxLength: 100),
      'content': _requiredValue(
        content,
        'content',
        minLength: 3,
        maxLength: 2000,
      ),
    };
  }

  static String _identifier(String value, String fieldName) {
    final normalized = _requiredValue(value, fieldName, maxLength: 64);
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(normalized)) {
      throw ArgumentError.value(
        value,
        fieldName,
        'Use only letters, numbers, underscores, or hyphens.',
      );
    }
    return normalized;
  }

  static String? _optionalIdentifier(String? value, String fieldName) {
    if (value == null) return null;
    return _identifier(value, fieldName);
  }

  static String _requiredValue(
    String value,
    String fieldName, {
    int minLength = 1,
    required int maxLength,
  }) {
    final normalized = value.trim();
    if (normalized.length < minLength || normalized.length > maxLength) {
      throw ArgumentError.value(
        value,
        fieldName,
        'Must contain $minLength-$maxLength characters.',
      );
    }
    return normalized;
  }

  static NotesRepositoryException _mapPostgrestError(
    PostgrestException error, {
    required String action,
  }) {
    final message = switch (error.code) {
      '23514' => 'Please check the note title and content.',
      '23503' => 'The selected account or lesson is no longer available.',
      '42501' ||
      'PGRST301' => 'You do not have permission to change this study note.',
      _ => 'We could not $action your study note. Please try again.',
    };
    return NotesRepositoryException(message, cause: error);
  }
}
