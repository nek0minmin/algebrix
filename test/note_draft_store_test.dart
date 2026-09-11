import 'package:algebrix/services/note_draft_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = NoteDraftStore();

  NoteDraft draft({
    String? noteId,
    String title = 'Why constants stay fixed',
    String content = 'A constant does not change.',
    String? lessonId = 'm1_l2',
    DateTime? savedAt,
  }) {
    return NoteDraft(
      noteId: noteId,
      title: title,
      content: content,
      lessonId: lessonId,
      savedAt: savedAt ?? DateTime.now(),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('round-trips a new-note draft', () async {
    await store.write(draft(), accountId: 'student-1');

    final restored = await store.read(accountId: 'student-1');

    expect(restored, isNotNull);
    expect(restored!.title, 'Why constants stay fixed');
    expect(restored.content, 'A constant does not change.');
    expect(restored.lessonId, 'm1_l2');
    expect(restored.noteId, isNull);
  });

  test('returns null when there is no draft', () async {
    expect(await store.read(accountId: 'student-1'), isNull);
  });

  test('keeps one draft per note without clobbering the new-note slot',
      () async {
    await store.write(draft(title: 'Brand new'), accountId: 'student-1');
    await store.write(
      draft(noteId: 'note-7', title: 'Editing seven'),
      accountId: 'student-1',
    );
    await store.write(
      draft(noteId: 'note-9', title: 'Editing nine'),
      accountId: 'student-1',
    );

    expect((await store.read(accountId: 'student-1'))!.title, 'Brand new');
    expect(
      (await store.read(accountId: 'student-1', noteId: 'note-7'))!.title,
      'Editing seven',
    );
    expect(
      (await store.read(accountId: 'student-1', noteId: 'note-9'))!.title,
      'Editing nine',
    );
  });

  test('one learner cannot see another learner\'s draft', () async {
    await store.write(draft(title: 'Mine'), accountId: 'student-1');

    expect(await store.read(accountId: 'student-2'), isNull);
    expect((await store.read(accountId: 'student-1'))!.title, 'Mine');
  });

  test('clear removes only the draft it names', () async {
    await store.write(draft(title: 'New one'), accountId: 'student-1');
    await store.write(
      draft(noteId: 'note-7', title: 'Edit'),
      accountId: 'student-1',
    );

    await store.clear(accountId: 'student-1', noteId: 'note-7');

    expect(await store.read(accountId: 'student-1', noteId: 'note-7'), isNull);
    expect((await store.read(accountId: 'student-1'))!.title, 'New one');
  });

  test('clearAll drops every draft for that account and no others', () async {
    await store.write(draft(title: 'Mine new'), accountId: 'student-1');
    await store.write(
      draft(noteId: 'note-7', title: 'Mine edit'),
      accountId: 'student-1',
    );
    await store.write(draft(title: 'Theirs'), accountId: 'student-2');

    await store.clearAll('student-1');

    expect(await store.read(accountId: 'student-1'), isNull);
    expect(await store.read(accountId: 'student-1', noteId: 'note-7'), isNull);
    expect((await store.read(accountId: 'student-2'))!.title, 'Theirs');
  });

  test('an empty draft is not stored', () async {
    await store.write(
      draft(title: '   ', content: '  '),
      accountId: 'student-1',
    );

    expect(await store.read(accountId: 'student-1'), isNull);
  });

  test('writing an empty draft clears an existing one', () async {
    await store.write(draft(title: 'Something'), accountId: 'student-1');
    await store.write(
      draft(title: '', content: ''),
      accountId: 'student-1',
    );

    expect(await store.read(accountId: 'student-1'), isNull);
  });

  test('a draft older than the cutoff is dropped rather than restored',
      () async {
    await store.write(
      draft(savedAt: DateTime.now().subtract(const Duration(days: 31))),
      accountId: 'student-1',
    );

    expect(await store.read(accountId: 'student-1'), isNull);

    // And it is swept, not merely hidden.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((k) => k.contains('note_draft')),
      isEmpty,
    );
  });

  test('a draft just inside the cutoff still restores', () async {
    await store.write(
      draft(savedAt: DateTime.now().subtract(const Duration(days: 29))),
      accountId: 'student-1',
    );

    expect(await store.read(accountId: 'student-1'), isNotNull);
  });

  test('corrupt stored data is discarded instead of crashing', () async {
    SharedPreferences.setMockInitialValues({
      'algebrix_note_draft_student-1_new': 'not json at all',
    });

    expect(await store.read(accountId: 'student-1'), isNull);
  });
}
