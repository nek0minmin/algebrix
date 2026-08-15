import 'package:algebrix/models/study_note_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.parse('2026-08-15T08:00:00.000Z');
  final updatedAt = DateTime.parse('2026-08-15T09:00:00.000Z');

  Map<String, dynamic> noteJson() => <String, dynamic>{
    'id': 'f0d639b5-af30-49fc-9b19-9b774af78d91',
    'user_id': 'c5f08fe4-a7ad-40f0-a952-ecf31b930f25',
    'module_id': 'module1',
    'lesson_id': 'm1_l2',
    'title': 'Understanding constants',
    'content': 'A constant keeps the same value.',
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  test('maps a complete Supabase row and serializes it back', () {
    final note = StudyNote.fromJson(noteJson());

    expect(note.id, 'f0d639b5-af30-49fc-9b19-9b774af78d91');
    expect(note.userId, 'c5f08fe4-a7ad-40f0-a952-ecf31b930f25');
    expect(note.moduleId, 'module1');
    expect(note.lessonId, 'm1_l2');
    expect(note.title, 'Understanding constants');
    expect(note.content, 'A constant keeps the same value.');
    expect(note.createdAt, createdAt);
    expect(note.updatedAt, updatedAt);
    expect(note.toJson(), noteJson());
  });

  test('copyWith creates a distinct immutable value', () {
    final original = StudyNote.fromJson(noteJson());
    final edited = original.copyWith(
      title: 'Constants explained',
      content: 'Constants do not change inside an expression.',
      updatedAt: updatedAt.add(const Duration(minutes: 5)),
    );

    expect(edited, isNot(original));
    expect(edited.id, original.id);
    expect(edited.userId, original.userId);
    expect(edited.title, 'Constants explained');
    expect(original.title, 'Understanding constants');
  });

  test('equal notes have equal hash codes', () {
    final first = StudyNote.fromJson(noteJson());
    final second = StudyNote.fromJson(noteJson());

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('rejects missing, empty, and malformed fields', () {
    final missingTitle = noteJson()..remove('title');
    final emptyContent = noteJson()..['content'] = '';
    final invalidTimestamp = noteJson()..['updated_at'] = 'not-a-date';

    expect(() => StudyNote.fromJson(missingTitle), throwsFormatException);
    expect(() => StudyNote.fromJson(emptyContent), throwsFormatException);
    expect(() => StudyNote.fromJson(invalidTimestamp), throwsFormatException);
  });
}
