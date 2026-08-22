import 'package:flutter_test/flutter_test.dart';
import 'package:algebrix/main.dart';

void main() {
  testWidgets('AlgebrixApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AlgebrixApp());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
    expect(find.byType(AlgebrixApp), findsOneWidget);
  });
}
