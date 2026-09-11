import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A note as it stood on the device, before it reached Supabase.
class NoteDraft {
  const NoteDraft({
    this.noteId,
    required this.title,
    required this.content,
    this.lessonId,
    required this.savedAt,
  });

  /// The note being edited, or null when this is a new note.
  final String? noteId;

  final String title;
  final String content;
  final String? lessonId;
  final DateTime savedAt;

  /// Whether there is anything here worth restoring.
  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'noteId': noteId,
        'title': title,
        'content': content,
        'lessonId': lessonId,
        'savedAt': savedAt.toIso8601String(),
      };

  static NoteDraft? fromJson(Map<String, dynamic> json) {
    final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
    if (savedAt == null) return null;

    return NoteDraft(
      noteId: json['noteId'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      lessonId: json['lessonId'] as String?,
      savedAt: savedAt,
    );
  }
}

/// On-device holding area for notes that have not reached Supabase yet.
///
/// Supabase stays authoritative for saved notes; this only covers the gap
/// between typing something and the save succeeding. Without it, a save that
/// fails on bad wifi — or an app the OS kills in the background — takes the
/// learner's writing with it.
///
/// Drafts are keyed by account so nothing leaks between learners sharing a
/// device, and by note id so editing one note cannot clobber the draft of
/// another.
class NoteDraftStore {
  const NoteDraftStore();

  static const _prefix = 'algebrix_note_draft';

  /// Drafts older than this are ignored and swept up on the next read. A month
  /// is long enough that nothing real is lost and short enough that a
  /// forgotten draft does not resurface a year later.
  static const Duration maxAge = Duration(days: 30);

  String _key(String accountId, String? noteId) =>
      '${_prefix}_${accountId}_${noteId ?? 'new'}';

  /// The draft for [noteId], or null when there is none worth restoring.
  Future<NoteDraft?> read({
    required String accountId,
    String? noteId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(accountId, noteId));
      if (raw == null) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await clear(accountId: accountId, noteId: noteId);
        return null;
      }

      final draft = NoteDraft.fromJson(decoded);
      if (draft == null || draft.isEmpty) {
        await clear(accountId: accountId, noteId: noteId);
        return null;
      }

      if (DateTime.now().difference(draft.savedAt) > maxAge) {
        await clear(accountId: accountId, noteId: noteId);
        return null;
      }

      return draft;
    } catch (_) {
      // Storage being unavailable must never block writing a note.
      return null;
    }
  }

  /// Records [draft]. An empty draft clears the slot instead of storing blanks.
  Future<void> write(NoteDraft draft, {required String accountId}) async {
    try {
      if (draft.isEmpty) {
        await clear(accountId: accountId, noteId: draft.noteId);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(accountId, draft.noteId),
        jsonEncode(draft.toJson()),
      );
    } catch (_) {
      // Best effort. The learner still has the text on screen.
    }
  }

  Future<void> clear({required String accountId, String? noteId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(accountId, noteId));
    } catch (_) {
      // Nothing to do; a stale draft is harmless and expires on its own.
    }
  }

  /// Drops every draft belonging to [accountId].
  ///
  /// Used when an account is deleted, so a shared device keeps nothing of the
  /// learner who left.
  Future<void> clearAll(String accountId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = '${_prefix}_${accountId}_';
      final keys = prefs.getKeys().where((key) => key.startsWith(prefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Best effort.
    }
  }
}
