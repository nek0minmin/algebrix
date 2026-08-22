import 'dart:io';

import 'package:algebrix/widgets/page_headers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder xyImages() => find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName.contains('assets/mascot/xy'),
  );

  Future<void> pumpRootHeader(
    WidgetTester tester, {
    required double width,
    double textScale = 1,
    String? searchPlaceholder,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 400));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(
            size: Size(width, 400),
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: RootPageHeader(
            title: 'Notes',
            subtitle: 'Keep your algebra ideas close.',
            searchPlaceholder: searchPlaceholder,
            trailing: FilledButton(
              key: const Key('wide-action'),
              onPressed: () {},
              child: const Text('New note'),
            ),
            compactTrailing: IconButton(
              key: const Key('compact-action'),
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('root header uses one responsive Xy and exact title styles', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpRootHeader(tester, width: 720);

    expect(xyImages(), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('page-header-xy'))), const Size.square(80));
    final title = tester.widget<Text>(find.text('Notes'));
    final subtitle = tester.widget<Text>(
      find.text('Keep your algebra ideas close.'),
    );
    expect(title.style?.fontSize, 24);
    expect(title.style?.fontWeight, FontWeight.w900);
    expect(subtitle.style?.fontSize, 14);
    expect(subtitle.style?.fontWeight, FontWeight.w600);

    await pumpRootHeader(tester, width: 320, textScale: 1.3);
    expect(xyImages(), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('page-header-xy'))), const Size.square(64));
    expect(tester.takeException(), isNull);
  });

  testWidgets('root header with search bar displays bigger mascot and search input', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpRootHeader(tester, width: 720, searchPlaceholder: 'Search Lessons');

    expect(xyImages(), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('page-header-xy'))), const Size.square(100));
    expect(find.text('Search Lessons'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });

  testWidgets('root header changes Notes action at 560px', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpRootHeader(tester, width: 559);
    expect(find.byKey(const Key('compact-action')), findsOneWidget);
    expect(find.byKey(const Key('wide-action')), findsNothing);

    await pumpRootHeader(tester, width: 560);
    expect(find.byKey(const Key('wide-action')), findsOneWidget);
    expect(find.byKey(const Key('compact-action')), findsNothing);
  });

  testWidgets('secondary header matches the family at regular and narrow widths', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> pumpSecondary(double width, {double textScale = 1}) async {
      await tester.binding.setSurfaceSize(Size(width, 400));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(
              size: Size(width, 400),
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: const Scaffold(
            appBar: SecondaryPageAppBar(
              title: 'New note',
              supportingText: 'Explain one idea in your own words.',
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpSecondary(390);
    expect(xyImages(), findsOneWidget);
    expect(tester.getSize(find.byType(AppBar)), const Size(390, 96));
    expect(tester.getSize(find.byKey(const Key('secondary-page-back-button'))), const Size.square(44));
    expect(tester.getSize(find.byKey(const Key('page-header-xy'))), const Size.square(64));
    expect(find.bySemanticsLabel('Back to Notes'), findsWidgets);

    final title = tester.widget<Text>(find.text('New note'));
    final support = tester.widget<Text>(
      find.text('Explain one idea in your own words.'),
    );
    expect(title.style?.fontSize, 22);
    expect(title.style?.fontWeight, FontWeight.w900);
    expect(support.style?.fontSize, 13);
    expect(support.style?.fontWeight, FontWeight.w600);

    await pumpSecondary(320, textScale: 1.3);
    expect(xyImages(), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('page-header-xy'))), const Size.square(52));
    expect(find.text('Explain one idea in your own words.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    semantics.dispose();
  });

  test('scoped root bodies leave Xy artwork to their shared header', () {
    const paths = [
      'lib/screens/home/home_screen.dart',
      'lib/screens/lessons/lessons_screen.dart',
      'lib/screens/practice/quiz_screen.dart',
      'lib/screens/notes/notes_screen.dart',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('AppAssets.xy')), reason: path);
      expect(source, isNot(contains('XyDialog')), reason: path);
      expect(
        RegExp(r'RootPageHeader\s*\(').allMatches(source),
        hasLength(1),
        reason: path,
      );
    }
  });
}
