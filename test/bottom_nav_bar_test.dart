import 'package:algebrix/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bottom navigation exposes the four requested destinations', (
    tester,
  ) async {
    var selectedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            currentIndex: 0,
            onTap: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Lessons'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Quiz'), findsNothing);

    await tester.tap(find.text('Practice'));
    expect(selectedIndex, 2);

    await tester.tap(find.text('Notes'));
    expect(selectedIndex, 3);
  });
}
