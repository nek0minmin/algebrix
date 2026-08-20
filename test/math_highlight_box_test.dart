import 'package:algebrix/widgets/lesson/math_highlight_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  group('MathHighlightBox Widget Tests', () {
    testWidgets('renders hero formula card mode', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const MathHighlightBox(
            expression: '3(x + 2) = 3x + 6',
            annotation: 'Distribute 3 to everything inside!',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EQUATION'), findsOneWidget);
      expect(find.text('Distribute 3 to everything inside!'), findsOneWidget);
      expect(find.byType(MathHighlightBox), findsOneWidget);
    });

    testWidgets('renders comparison board mode for expressions with bullets',
        (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const MathHighlightBox(
            expression: '3x and 3y   •   5x and 5x²',
            annotation: 'Different variables or exponents = Unlike Terms.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COMPARISON'), findsOneWidget);
      expect(
        find.text('Different variables or exponents = Unlike Terms.'),
        findsOneWidget,
      );
    });

    testWidgets('renders step flow mode for transformations', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const MathHighlightBox(
            expression: '3x + 2x + 4  →  5x + 4  →  5(2) + 4 = 14',
            annotation: 'Simplify → Substitute → Evaluate!',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STEP-BY-STEP'), findsOneWidget);
      expect(find.text('Simplify → Substitute → Evaluate!'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNWidgets(2));
    });
  });
}
