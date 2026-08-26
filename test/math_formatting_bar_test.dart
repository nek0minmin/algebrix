import 'package:algebrix/widgets/notes/math_formatting_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MathFormattingBar Widget Tests', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders quick math chips and inserts exponent into controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MathFormattingBar(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick bar elements should be visible
      expect(find.text('MATH'), findsOneWidget);
      expect(find.byKey(const Key('math-chip-x²')), findsOneWidget);
      expect(find.byKey(const Key('math-chip-y²')), findsOneWidget);
      expect(find.byKey(const Key('math-chip-x')), findsOneWidget);
      expect(find.byKey(const Key('math-chip-y')), findsOneWidget);
      expect(find.byKey(const Key('math-chip-+')), findsOneWidget);
      expect(find.byKey(const Key('math-chip-=')), findsOneWidget);

      // Tap x² chip
      await tester.tap(find.byKey(const Key('math-chip-x²')));
      await tester.pumpAndSettle();

      expect(controller.text, 'x²');
      expect(controller.selection.baseOffset, 2);

      // Tap y² chip
      await tester.tap(find.byKey(const Key('math-chip-y²')));
      await tester.pumpAndSettle();

      expect(controller.text, 'x²y²');

      // Tap = chip
      await tester.tap(find.byKey(const Key('math-chip-=')));
      await tester.pumpAndSettle();

      expect(controller.text, 'x²y² = ');
    });

    testWidgets('smart cursor offset places cursor inside squared groups from expanded palette', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathFormattingBar(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open palette
      await tester.tap(find.byKey(const Key('math-palette-toggle-button')));
      await tester.pumpAndSettle();

      // Tap ()²
      final groupFinder = find.byKey(const Key('math-chip-()²'));
      await tester.tap(groupFinder);
      await tester.pumpAndSettle();

      expect(controller.text, '()²');
      // Cursor should be inside parentheses: offset 1
      expect(controller.selection.baseOffset, 1);
    });

    testWidgets('smart exponent wrapping attaches superscript to highlighted text', (
      tester,
    ) async {
      controller.value = const TextEditingValue(
        text: 'x + 3',
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathFormattingBar(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open palette
      await tester.tap(find.byKey(const Key('math-palette-toggle-button')));
      await tester.pumpAndSettle();

      // Tap ² in expanded category
      await tester.tap(find.byKey(const Key('math-chip-²')));
      await tester.pumpAndSettle();

      expect(controller.text, 'x + 3²');
    });

    testWidgets('toggling More opens and closes categorized mini-palette', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathFormattingBar(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Palette is closed initially
      expect(find.byKey(const Key('math-cat-exponents')), findsNothing);

      // Open palette
      await tester.tap(find.byKey(const Key('math-palette-toggle-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('math-cat-exponents')), findsOneWidget);
      expect(find.byKey(const Key('math-cat-variables')), findsOneWidget);
      expect(find.byKey(const Key('math-cat-operators')), findsOneWidget);
      // Structures category was removed
      expect(find.byKey(const Key('math-cat-structures')), findsNothing);

      // Switch to Variables tab
      await tester.tap(find.byKey(const Key('math-cat-variables')));
      await tester.pumpAndSettle();

      // Close palette
      await tester.tap(find.byKey(const Key('math-palette-toggle-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('math-cat-variables')), findsNothing);
    });

    testWidgets('does not insert chips when enabled is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MathFormattingBar(
              controller: controller,
              enabled: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('math-chip-x²')));
      await tester.pumpAndSettle();

      expect(controller.text, '');
    });
  });
}
