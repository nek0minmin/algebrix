import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/main.dart';

void main() {
  testWidgets('AlgebrixApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AlgebrixApp());
    // Basic smoke test - app should start without errors
    expect(find.byType(AlgebrixApp), findsOneWidget);
  });
}
