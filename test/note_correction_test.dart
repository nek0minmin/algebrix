import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/models/note_correction_model.dart';
import 'package:algebrix/services/ai_tutor_service.dart';
import 'package:algebrix/services/note_correction_service.dart';
import 'package:algebrix/widgets/notes/correction_suggestion_card.dart';
import 'package:algebrix/widgets/notes/correction_text_controller.dart';

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
}
