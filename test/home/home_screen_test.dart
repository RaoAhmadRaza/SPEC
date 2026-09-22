import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/home/home_card.dart';
import 'package:spec/home/home_empty.dart';
import 'package:spec/home/home_header.dart';
import 'package:spec/home/home_models.dart';
import 'package:spec/home/home_screen.dart';
import 'package:spec/home/home_tab_bar.dart';

import '../support/fonts.dart';
import '../support/responsive.dart';

/// The canvas every number in the design is measured against.
const _canvas = Size(402, 874);

/// The three objects screen 01 shows, verbatim from the design file.
const _designObjects = [
  HomeObject(
    id: 1,
    zone: 'HOME',
    spec: 'B22',
    name: 'Bedroom Bulb',
    subLines: ['LED · 9W', 'WARM WHITE'],
  ),
  HomeObject(
    id: 2,
    zone: 'CAR',
    spec: '205/55 R16',
    name: 'Car Tyres',
    subLines: ['91V · MICHELIN'],
  ),
  HomeObject(
    id: 3,
    zone: 'DEVICES',
    spec: '67XL',
    name: 'Printer Cartridge',
    subLines: ['BLACK', 'HP DESKJET 2700'],
  ),
];

const _designCategories = [
  HomeCategory(label: 'Home', count: 12, icon: HomeCategoryIcon.house),
  HomeCategory(label: 'Car', count: 4, icon: HomeCategoryIcon.car),
  HomeCategory(label: 'Devices', count: 9, icon: HomeCategoryIcon.monitor),
];

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  bool isMotionReduced = false,
}) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: _canvas, disableAnimations: isMotionReduced),
      child: Directionality(textDirection: TextDirection.ltr, child: screen),
    ),
  );
  // Past the 820ms entrance, in fixed frames like the rest of the suite.
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Two objects whose specs differ enough that one card wants more height.
const _unevenObjects = [
  HomeObject(id: 1, zone: 'HOME', spec: 'B22', name: 'Bulb', subLines: ['LED']),
  HomeObject(
    id: 2,
    zone: 'CAR',
    spec: '205/55 R16 91V EXTRA LOAD',
    name: 'Car Tyres',
    subLines: ['91V · MICHELIN', 'ALL SEASON'],
  ),
];

/// The page's own scroll view, which is the outermost of the two — the
/// category rail is a horizontal one nested inside it.
ScrollPosition _pageScroll(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

/// How many tiles share the top edge of the first one, which is the grid's
/// column count.
int _gridColumns(WidgetTester tester) {
  final tops = [
    for (final card in find.byType(ObjectCard).evaluate())
      tester.getRect(find.byWidget(card.widget)).top,
    tester.getRect(find.byType(AddCard)).top,
  ];
  return tops.where((top) => (top - tops.first).abs() < 1).length;
}

Future<void> _pumpResponsiveHome(
  WidgetTester tester,
  Widget screen, {
  required Size canvas,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1.0,
}) async {
  await pumpResponsive(
    tester,
    screen,
    canvas: canvas,
    padding: padding,
    textScale: textScale,
  );
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('grid uses two columns at the reference canvas', (tester) async {
    // Arrange / Act
    await _pumpResponsiveHome(
      tester,
      const HomeScreen(objects: _designObjects),
      canvas: specReferenceCanvas,
    );

    // Assert
    expect(_gridColumns(tester), 2);
  });

  testWidgets('grid uses four columns on a portrait tablet', (tester) async {
    // Arrange / Act
    await _pumpResponsiveHome(
      tester,
      const HomeScreen(objects: _designObjects),
      canvas: specCanvases['tabletPortrait']!,
    );

    // Assert
    expect(_gridColumns(tester), 4);
  });

  testWidgets('cards grow rather than clipping at text scale 1.5', (
    tester,
  ) async {
    // Arrange / Act
    await _pumpResponsiveHome(
      tester,
      const HomeScreen(objects: _designObjects),
      canvas: specCanvases['tiny']!,
      textScale: 1.5,
    );

    // Assert
    expect(
      tester.getSize(find.byType(ObjectCard).first).height,
      greaterThan(kCardHeight),
    );
    expectNoOverflow(tester);
  });

  testWidgets('both cards in a row share a height', (tester) async {
    // Arrange / Act
    await _pumpResponsiveHome(
      tester,
      const HomeScreen(objects: _unevenObjects),
      canvas: specCanvases['tiny']!,
      textScale: 1.5,
    );

    // Assert
    final heights = [
      for (var i = 0; i < 2; i++)
        tester.getSize(find.byType(ObjectCard).at(i)).height,
    ];
    expect(heights[0], heights[1]);
    expect(heights[0], greaterThan(kCardHeight));
  });

  testWidgets('wordmark fits the width at every canvas', (tester) async {
    for (final MapEntry(key: name, value: canvas) in specCanvases.entries) {
      // Arrange / Act
      await _pumpResponsiveHome(
        tester,
        const HomeScreen(objects: _designObjects),
        canvas: canvas,
        textScale: 1.5,
      );

      // Assert
      final wordmark = tester.getRect(
        find
            .descendant(
              of: find.byType(HomeWordmark),
              matching: find.byType(FittedBox),
            )
            .first,
      );
      expect(wordmark.left, greaterThanOrEqualTo(0.0), reason: name);
      expect(wordmark.right, lessThanOrEqualTo(canvas.width), reason: name);
      expectNoOverflow(tester);
    }
  });

  testWidgets('last tile scrolls clear of the shell chrome', (tester) async {
    for (final MapEntry(key: name, value: canvas) in specCanvases.entries) {
      // Arrange
      await _pumpResponsiveHome(
        tester,
        const HomeScreen(objects: _designObjects),
        canvas: canvas,
      );

      // Act
      final position = _pageScroll(tester);
      if (position.maxScrollExtent > 0) {
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
      }

      // Assert
      expect(
        tester.getRect(find.byType(AddCard)).bottom,
        lessThanOrEqualTo(
          canvas.height -
              specShellChromeHeight(tester.element(find.byType(HomeScreen))),
        ),
        reason: name,
      );
    }
  });

  testWidgets('content clears a 34pt home indicator and a 59pt Dynamic '
      'Island', (tester) async {
    // Arrange / Act
    await _pumpResponsiveHome(
      tester,
      const HomeScreen(objects: _designObjects),
      canvas: specReferenceCanvas,
      padding: const EdgeInsets.only(top: 59, bottom: 34),
    );

    // Assert: the header starts below the island.
    expect(
      tester.getRect(find.byType(HomeHeaderRow)).top,
      greaterThanOrEqualTo(59.0),
    );

    // And the last tile still ends above the chrome and the indicator.
    final position = _pageScroll(tester);
    if (position.maxScrollExtent > 0) {
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
    }
    expect(
      tester.getRect(find.byType(AddCard)).bottom,
      lessThanOrEqualTo(specReferenceCanvas.height - 34),
    );
  });

  testWidgets('the populated grid is three objects and the add card', (
    tester,
  ) async {
    // Arrange & Act
    await _pump(
      tester,
      const HomeScreen(objects: _designObjects, categories: _designCategories),
    );

    // Assert
    expect(find.byType(ObjectCard), findsNWidgets(3));
    expect(find.byType(AddCard), findsOneWidget);
    expect(find.text('RECENTLY REMEMBERED'), findsOneWidget);
    expect(find.text('SEE ALL ›'), findsOneWidget);
  });

  testWidgets('each tile cuts a different corner, in reading order', (
    tester,
  ) async {
    await _pump(
      tester,
      const HomeScreen(objects: _designObjects, categories: _designCategories),
    );

    final cards = tester.widgetList<ObjectCard>(find.byType(ObjectCard));
    expect(cards.map((c) => c.radius), [
      kCardRadii[0],
      kCardRadii[1],
      kCardRadii[2],
    ]);
  });

  testWidgets('a two-word spec drops to the shorter style', (tester) async {
    await _pump(tester, const HomeScreen(objects: _designObjects));

    expect(find.text('205/55\nR16'), findsOneWidget);
    expect(find.text('B22'), findsOneWidget);
  });

  testWidgets('only the three most recent objects reach the grid', (
    tester,
  ) async {
    const extra = HomeObject(id: 4, zone: 'HOME', spec: 'E27', name: 'Lamp');

    await _pump(tester, const HomeScreen(objects: [..._designObjects, extra]));

    expect(find.byType(ObjectCard), findsNWidgets(3));
    expect(find.text('E27'), findsNothing);
  });

  testWidgets('the empty state keeps the header and loses the grid', (
    tester,
  ) async {
    await _pump(tester, const HomeScreen(objects: []));

    // Byte-identical header is what makes filling the shelf feel continuous.
    // Both the pill and the wordmark read SPEC.
    expect(find.text('SPEC'), findsNWidgets(2));
    expect(
      find.text("REMEMBER THE THINGS\nYOU SHOULDN'T HAVE TO."),
      findsOneWidget,
    );

    expect(find.byType(ObjectCard), findsNothing);
    expect(find.byType(AddCard), findsNothing);
    expect(find.byType(HomeEmptyState), findsOneWidget);
    // No section rule at all: there is no section to head yet.
    expect(find.byType(HomeSectionRule), findsNothing);
    expect(find.text('SEE ALL ›'), findsNothing);
    expect(find.text('NO ZONES YET'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.text('Add Something'), findsOneWidget);
    expect(find.text('PHOTOGRAPH THE THING'), findsOneWidget);
  });

  testWidgets('the empty state offers exactly one action', (tester) async {
    var adds = 0;

    await _pump(tester, HomeScreen(objects: const [], onAdd: () => adds++));
    await tester.tap(find.text('ADD YOUR FIRST ITEM'));
    await tester.pump();

    expect(adds, 1);
  });

  testWidgets('the empty search pill cannot be tapped', (tester) async {
    var searches = 0;

    await _pump(
      tester,
      HomeScreen(objects: const [], onSearch: () => searches++),
    );
    await tester.tap(find.text('Nothing saved yet'), warnIfMissed: false);
    await tester.pump();

    expect(searches, 0);
  });

  testWidgets('tapping a card reports the object it belongs to', (
    tester,
  ) async {
    HomeObject? opened;

    await _pump(
      tester,
      HomeScreen(objects: _designObjects, onObject: (o) => opened = o),
    );
    await tester.tap(find.text('B22'));
    await tester.pump();

    expect(opened?.name, 'Bedroom Bulb');
  });

  testWidgets('the card menu is a separate target from the card', (
    tester,
  ) async {
    HomeObject? opened;
    HomeObject? menued;

    await _pump(
      tester,
      HomeScreen(
        objects: _designObjects,
        onObject: (o) => opened = o,
        onObjectMenu: (o) => menued = o,
      ),
    );
    final firstCard = find.byType(ObjectCard).first;
    await tester.tap(
      find.descendant(of: firstCard, matching: find.byType(HomeDots)),
    );
    await tester.pump();

    expect(menued?.name, 'Bedroom Bulb');
    expect(opened, isNull);
  });

  testWidgets('reduced motion still lands on the full layout', (tester) async {
    await _pump(
      tester,
      const HomeScreen(objects: _designObjects, categories: _designCategories),
      isMotionReduced: true,
    );

    expect(find.byType(ObjectCard), findsNWidgets(3));
  });

  testWidgets('draws no tab bar or orb of its own — the shell owns them', (
    tester,
  ) async {
    // Arrange & Act
    await _pump(
      tester,
      const HomeScreen(objects: _designObjects, categories: _designCategories),
    );

    // Assert
    expect(find.byType(HomeTabBar), findsNothing);
    expect(find.byType(HomeOrb), findsNothing);
  });

  testWidgets('only a card whose reminder has fallen due says DUE', (
    tester,
  ) async {
    const due = HomeObject(
      id: 1,
      zone: 'HOME · CEILING · BEDROOM',
      spec: 'B22',
      name: 'Bedroom Bulb',
      isDue: true,
    );

    await _pump(tester, HomeScreen(objects: [due, ..._designObjects.skip(1)]));

    expect(tester.takeException(), isNull);
    expect(find.text('DUE'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ObjectCard, 'B22'),
        matching: find.text('DUE'),
      ),
      findsOneWidget,
    );
  });
}
