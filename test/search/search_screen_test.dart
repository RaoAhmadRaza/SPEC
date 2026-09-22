import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/collections/zone_hero.dart';
import 'package:spec/home/home_header.dart';
import 'package:spec/search/search_chips.dart';
import 'package:spec/search/search_empty.dart';
import 'package:spec/search/search_header.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/search/search_pill.dart';
import 'package:spec/search/search_result_row.dart';
import 'package:spec/search/search_screen.dart';
import 'package:spec/search/search_tokens.dart';
import 'package:spec/theme/spec_layout.dart';
import 'package:spec/theme/spec_tokens.dart';

import '../support/fonts.dart';
import '../support/responsive.dart';

/// The canvas every number in the design is measured against.
const _canvas = Size(402, 874);

/// The three results screen 02 shows, verbatim from the design file.
const _designResults = [
  SearchResult(
    id: 1,
    name: 'Bedroom bulb',
    zoneLine: 'HOME · CEILING',
    spec: 'B22',
  ),
  SearchResult(
    id: 2,
    name: 'Desk lamp bulb',
    zoneLine: 'HOME · STUDY',
    spec: 'E27',
  ),
  SearchResult(
    id: 3,
    name: 'Headlight',
    zoneLine: 'CAR · LOW BEAM',
    spec: 'H7',
  ),
];

const _designRecents = ['BULB', 'BEDROOM', 'FILTER'];

const _designZones = [
  SearchZone(name: 'Home', count: 18),
  SearchZone(name: 'Car', count: 4),
  SearchZone(name: 'Devices', count: 9),
  SearchZone(name: 'Clothing', count: 7),
  SearchZone(name: 'Other', count: 3),
];

/// The design's `0.004S`.
const _designElapsed = Duration(microseconds: 4000);

/// A runner with a stable identity, so rebuilds do not re-trigger the query.
class _FakeRunner {
  _FakeRunner(this.results, {this.elapsed = _designElapsed});

  List<SearchResult> results;
  Duration elapsed;
  final queries = <String>[];

  Future<SearchResults> run(String query) async {
    queries.add(query);
    return SearchResults(matches: results, elapsed: elapsed);
  }
}

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
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SpecColors.bg,
      ),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: isMotionReduced),
          child: Material(color: SpecColors.bg, child: screen),
        ),
      ),
    ),
  );
  // The waveform ripples forever, so pumpAndSettle would never return.
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Types into the pill and lets the debounce, the query and the settle land.
Future<void> _type(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

SearchScreen _screen(
  _FakeRunner runner, {
  String? scope,
  bool isListingAll = false,
  String initialQuery = '',
  List<String> recents = _designRecents,
  List<SearchZone> zones = _designZones,
  ArchiveCounts counts = const ArchiveCounts(objects: 41, photos: 96),
  ValueChanged<String>? onAdd,
  ValueChanged<String>? onQueryRun,
}) => SearchScreen(
  runSearch: runner.run,
  scope: scope,
  isListingAll: isListingAll,
  initialQuery: initialQuery,
  recents: recents,
  zones: zones,
  counts: counts,
  onAdd: onAdd,
  onQueryRun: onQueryRun,
);

Rect _rectOf(Finder finder) {
  final box = finder.evaluate().first.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// A spec long enough to squeeze the name column and overflow the row.
const _longSpec = 'MAINS-VOLTAGE DIMMABLE FILAMENT 2700K EXTRA WARM WHITE B22';

/// Same frame as [_pump] on an arbitrary canvas, with real insets and scale.
Future<void> _pumpResponsiveSearch(
  WidgetTester tester,
  Widget screen, {
  required Size canvas,
  EdgeInsets padding = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
  double textScale = 1.0,
}) async {
  tester.view
    ..physicalSize = canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SpecColors.bg,
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: canvas,
          padding: padding,
          viewPadding: padding,
          viewInsets: viewInsets,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Material(color: SpecColors.bg, child: screen),
      ),
    ),
  );
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUpAll(loadSpecFonts);

  group('responsive', () {
    testWidgets('row height is 83 at scale 1.0', (tester) async {
      // Arrange / Act
      await _pumpResponsiveSearch(
        tester,
        _screen(_FakeRunner(_designResults), isListingAll: true),
        canvas: specReferenceCanvas,
      );

      // Assert: the computed height is a no-op at the reference scale.
      expect(
        searchRowHeight(tester.element(find.byType(SearchResultRow).first)),
        kSearchRowHeight,
      );
      expect(
        tester.getSize(find.byType(SearchResultRow).first).height,
        kSearchRowHeight,
      );
    });

    testWidgets('rows do not overlap at text scale 1.5', (tester) async {
      // Arrange / Act
      await _pumpResponsiveSearch(
        tester,
        _screen(_FakeRunner(_designResults), isListingAll: true),
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Assert: the list positions rows by index, so a height that lies
      // makes them overlap rather than pushing each other down.
      final rows = find.byType(SearchResultRow);
      final rects = [
        for (var i = 0; i < rows.evaluate().length; i++)
          tester.getRect(rows.at(i)),
      ];
      expect(rects.length, greaterThan(1));
      for (var i = 0; i + 1 < rects.length; i++) {
        expect(
          rects[i].bottom,
          lessThanOrEqualTo(rects[i + 1].top),
          reason: 'row $i overlaps row ${i + 1}',
        );
      }
    });

    testWidgets('a long spec never overflows the result row', (tester) async {
      // Arrange / Act
      await _pumpResponsiveSearch(
        tester,
        _screen(
          _FakeRunner(const [
            SearchResult(
              id: 1,
              name: 'Bedroom bulb',
              zoneLine: 'HOME · CEILING',
              spec: _longSpec,
            ),
          ]),
          isListingAll: true,
        ),
        canvas: specCanvases['tiny']!,
      );

      // Assert
      expect(find.byType(SearchResultRow), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('the pill stays visible when the keyboard is up', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveSearch(
        tester,
        _screen(_FakeRunner(_designResults), isListingAll: true),
        canvas: specCanvases['tiny']!,
        viewInsets: const EdgeInsets.only(bottom: 300),
      );

      // Assert: the whole region shrank, so the pill is above the keyboard
      // and results still have somewhere to be.
      expect(
        tester.getRect(find.byType(SearchPillShell)).bottom,
        lessThanOrEqualTo(268.0),
      );
      expect(find.byType(SearchResultRow), findsWidgets);
    });

    testWidgets('a long scoped zone name does not overflow the pill', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveSearch(
        tester,
        _screen(
          _FakeRunner(_designResults),
          isListingAll: true,
          scope: 'Z' * 40,
        ),
        canvas: specCanvases['tiny']!,
      );

      // Assert
      expect(find.byType(SearchPillShell), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('content is capped and centred on a landscape tablet', (
      tester,
    ) async {
      // Arrange
      final canvas = specCanvases['tabletLandscape']!;

      // Act
      await _pumpResponsiveSearch(
        tester,
        _screen(_FakeRunner(_designResults), isListingAll: true),
        canvas: canvas,
      );

      // Assert
      final row = tester.getRect(find.byType(SearchResultRow).first);
      expect(row.width, lessThanOrEqualTo(SpecLayout.maxContentWidth));
      expect(row.center.dx, closeTo(canvas.width / 2, 0.5));
    });

    testWidgets('ADD TO ZONE button does not clip a long zone name at scale '
        '1.5', (tester) async {
      // Arrange / Act: an empty scoped zone is what shows the button.
      await _pumpResponsiveSearch(
        tester,
        _screen(_FakeRunner(const []), scope: 'Z' * 40, isListingAll: true),
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Assert
      expect(find.byType(SearchLimeButton), findsOneWidget);
      expectNoOverflow(tester);
    });
  });

  group('results', () {
    testWidgets('draws the three design rows with their specs and zones', (
      tester,
    ) async {
      final runner = _FakeRunner([..._designResults]);
      await _pump(tester, _screen(runner));
      await _type(tester, 'bulb');

      expect(find.byType(SearchResultRow), findsNWidgets(3));
      for (final result in _designResults) {
        expect(find.text(result.name), findsOneWidget);
        expect(find.text(result.zoneLine), findsOneWidget);
        expect(find.text(result.spec), findsOneWidget);
      }
    });

    testWidgets('counts the matches and reports the measured query time', (
      tester,
    ) async {
      final runner = _FakeRunner([..._designResults]);
      await _pump(tester, _screen(runner));
      await _type(tester, 'bulb');

      expect(find.text('3 MATCHES'), findsOneWidget);
      expect(find.text('0.004S'), findsOneWidget);
    });

    testWidgets('says 1 MATCH rather than 1 MATCHES', (tester) async {
      final runner = _FakeRunner([_designResults.first]);
      await _pump(tester, _screen(runner));
      await _type(tester, 'bedroom');

      expect(find.text('1 MATCH'), findsOneWidget);
    });

    testWidgets('the timing figure is the elapsed value, not a tween', (
      tester,
    ) async {
      final runner = _FakeRunner([
        ..._designResults,
      ], elapsed: const Duration(microseconds: 12500));
      await _pump(tester, _screen(runner));
      await _type(tester, 'bulb');

      expect(find.text('0.013S'), findsOneWidget);
    });

    testWidgets('only the best match wears the lime spec', (tester) async {
      final runner = _FakeRunner([..._designResults]);
      await _pump(tester, _screen(runner));
      await _type(tester, 'bulb');

      final limeSpecs = tester
          .widgetList<Text>(find.textContaining(RegExp(r'^(B22|E27|H7)$')))
          .where((text) => text.style?.color == SpecColors.accent);
      expect(limeSpecs, hasLength(1));
      expect(
        tester.widgetList<Text>(find.text('B22')).single.style?.color,
        SpecColors.accent,
      );
    });

    testWidgets('every thumb cuts its bottom-left corner and nothing else', (
      tester,
    ) async {
      final runner = _FakeRunner([..._designResults]);
      await _pump(tester, _screen(runner));
      await _type(tester, 'bulb');

      final thumbs = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(SearchResultRow),
          matching: find.byType(Container),
        ),
      );
      final radii = [
        for (final thumb in thumbs)
          if (thumb.decoration case final BoxDecoration box)
            if (box.borderRadius case final BorderRadius radius) radius,
      ];
      expect(radii, isNotEmpty);
      for (final radius in radii) {
        expect(radius.bottomLeft, const Radius.circular(5));
        expect(radius.topLeft, const Radius.circular(16));
        expect(radius.topRight, const Radius.circular(16));
        expect(radius.bottomRight, const Radius.circular(16));
      }
    });

    testWidgets('a thumb with no photo is a flat tile, with no icon or label', (
      tester,
    ) async {
      final runner = _FakeRunner([_designResults.first]);
      await _pump(tester, _screen(runner));
      await _type(tester, 'bulb');

      final thumb = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(SearchResultRow),
              matching: find.byType(Container),
            ),
          )
          .firstWhere(
            (container) =>
                (container.decoration as BoxDecoration?)?.color ==
                SpecColors.tile,
          );
      expect(thumb.child, isNull);
      expect(
        find.descendant(
          of: find.byType(SearchResultRow),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
    });

    testWidgets('a row that survives a re-query travels to its new index', (
      tester,
    ) async {
      final runner = _FakeRunner([..._designResults]);
      await _pump(tester, _screen(runner));
      await _type(tester, 'bulb');

      final before = tester.getTopLeft(find.text('Headlight')).dy;

      // The same three objects come back in a new order.
      runner.results = [
        _designResults[2],
        _designResults[0],
        _designResults[1],
      ];
      await tester.enterText(find.byType(TextField), 'bulbs');
      await tester.pump(const Duration(milliseconds: 140));

      // One frame into the move, the row has started travelling but has not
      // arrived: a rebuilt column would already be at the destination.
      await tester.pump(const Duration(milliseconds: 60));
      final during = tester.getTopLeft(find.text('Headlight')).dy;
      expect(during, lessThan(before));
      expect(during, greaterThan(0));

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.getTopLeft(find.text('Headlight')).dy, lessThan(during));
    });

    testWidgets('recent chips sit under the list', (tester) async {
      final runner = _FakeRunner([..._designResults]);
      await _pump(tester, _screen(runner));
      await _type(tester, 'bulb');

      expect(find.byType(RecentChips), findsOneWidget);
      for (final recent in _designRecents) {
        expect(find.text(recent), findsOneWidget);
      }
    });

    testWidgets('tapping a recent chip re-runs the search with its text', (
      tester,
    ) async {
      final runner = _FakeRunner([..._designResults]);
      await _pump(tester, _screen(runner));
      await _type(tester, 'bulb');

      await tester.tap(find.text('BEDROOM'));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(runner.queries.last, 'BEDROOM');
    });

    testWidgets('typing remembers nothing until the query is used', (
      tester,
    ) async {
      final runner = _FakeRunner([..._designResults]);
      final remembered = <String>[];
      await _pump(tester, _screen(runner, onQueryRun: remembered.add));

      // Each prefix settles long enough to run its own query.
      for (final prefix in ['b', 'bu', 'bul', 'bulb']) {
        await _type(tester, prefix);
      }
      expect(runner.queries, containsAll(['b', 'bu', 'bul', 'bulb']));
      expect(remembered, isEmpty);

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(remembered, ['bulb']);
    });
  });

  group('see all', () {
    testWidgets('lists everything on arrival under the archive counts', (
      tester,
    ) async {
      // Arrange
      final runner = _FakeRunner([..._designResults]);

      // Act
      await _pump(tester, _screen(runner, isListingAll: true));

      // Assert
      expect(runner.queries, ['']);
      expect(find.byType(SearchResultRow), findsNWidgets(3));
      expect(find.text('41 OBJECTS · 96 PHOTOS'), findsOneWidget);
      expect(find.text('BROWSE BY ZONE'), findsNothing);
    });

    testWidgets('typing filters like any other search', (tester) async {
      // Arrange
      final runner = _FakeRunner([..._designResults]);
      await _pump(tester, _screen(runner, isListingAll: true));
      runner.results = [_designResults.last];

      // Act
      await _type(tester, 'headlight');

      // Assert
      expect(runner.queries.last, 'headlight');
      expect(find.byType(SearchResultRow), findsOneWidget);
      expect(find.text('1 MATCH'), findsOneWidget);
    });
  });

  group('empty states', () {
    testWidgets('resting shows the archive counts, recents and the zones', (
      tester,
    ) async {
      final runner = _FakeRunner(const []);
      await _pump(tester, _screen(runner));

      expect(find.text('41 OBJECTS · 96 PHOTOS'), findsOneWidget);
      expect(find.text('RECENT'), findsOneWidget);
      expect(find.text('BROWSE BY ZONE'), findsOneWidget);
      for (final zone in _designZones) {
        expect(find.text(zone.name), findsOneWidget);
        expect(find.text('${zone.count}'), findsOneWidget);
      }
    });

    testWidgets('resting carries no timing and no failure copy', (
      tester,
    ) async {
      final runner = _FakeRunner(const []);
      await _pump(tester, _screen(runner));

      expect(find.textContaining('0.00'), findsNothing);
      expect(find.textContaining('NOTHING'), findsNothing);
    });

    testWidgets('no match offers one action and no spelling hint', (
      tester,
    ) async {
      final runner = _FakeRunner(const []);
      await _pump(tester, _screen(runner));
      await _type(tester, 'moka pot');

      expect(find.text('0 MATCHES'), findsOneWidget);
      expect(find.text('0.004S'), findsOneWidget);
      expect(find.text('NOTHING\nMATCHES.'), findsOneWidget);
      expect(
        find.text(
          'No object in your archive matches "moka pot". You can add it now.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SearchLimeButton), findsOneWidget);
      expect(find.text('ADD IT INSTEAD'), findsOneWidget);
      expect(find.textContaining('spelling'), findsNothing);
      expect(find.textContaining('try a different'), findsNothing);
    });

    testWidgets('no match quotes a long query elided inside the quotes', (
      tester,
    ) async {
      final runner = _FakeRunner(const []);
      await _pump(tester, _screen(runner));
      await _type(tester, 'a stovetop moka pot with a burnt handle');

      expect(
        find.textContaining('"a stovetop moka pot with…"'),
        findsOneWidget,
      );
    });

    testWidgets('the add button carries the query up', (tester) async {
      final runner = _FakeRunner(const []);
      String? added;
      await _pump(tester, _screen(runner, onAdd: (query) => added = query));
      await _type(tester, 'moka pot');

      await tester.tap(find.byType(SearchLimeButton));
      expect(added, 'moka pot');
    });

    testWidgets('a scoped empty zone names itself and drops the chips', (
      tester,
    ) async {
      final runner = _FakeRunner(const []);
      await _pump(tester, _screen(runner, scope: 'Clothing'));

      expect(find.text('0 IN THIS ZONE'), findsOneWidget);
      expect(find.text('NOTHING\nHERE YET.'), findsOneWidget);
      expect(find.text('ADD TO CLOTHING'), findsOneWidget);
      expect(find.text('CLOTHING'), findsOneWidget);
      expect(find.byType(RecentChips), findsNothing);
      expect(find.text('0.004S'), findsNothing);
    });

    testWidgets('a scoped search hints at its own zone', (tester) async {
      final runner = _FakeRunner(const []);
      await _pump(tester, _screen(runner, scope: 'Clothing'));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.hintText, 'Search clothing...');
    });
  });

  group('the pill', () {
    testWidgets('a scoped pill flies the zone name, not the pill itself', (
      tester,
    ) async {
      // Arrange
      final runner = _FakeRunner(const []);

      // Act
      await _pump(tester, _screen(runner, scope: 'Kitchen'));

      // Assert
      final tags = tester
          .widgetList<Hero>(find.byType(Hero))
          .map((hero) => hero.tag);
      expect(tags, contains(zoneHeroTag('Kitchen')));
      expect(tags, isNot(contains(kSearchPillTag)));
    });

    testWidgets('an unscoped pill is the shared pill Hero', (tester) async {
      // Arrange
      final runner = _FakeRunner(const []);

      // Act
      await _pump(tester, _screen(runner));

      // Assert
      final tags = tester
          .widgetList<Hero>(find.byType(Hero))
          .map((hero) => hero.tag);
      expect(tags, contains(kSearchPillTag));
    });

    testWidgets('the caret is a square lime bar, not the iOS default', (
      tester,
    ) async {
      final runner = _FakeRunner(const []);
      await _pump(tester, _screen(runner));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.cursorColor, SpecColors.accent);
      expect(field.cursorWidth, 2);
      expect(field.cursorHeight, 20);
      expect(field.cursorRadius, Radius.zero);
    });

    testWidgets('is the shared element, and lands lime', (tester) async {
      final runner = _FakeRunner(const []);
      await _pump(tester, _screen(runner));

      final hero = tester.widget<Hero>(find.byType(Hero).first);
      expect(hero.tag, kSearchPillTag);
      final shell = tester.widget<SearchPillShell>(
        find.byType(SearchPillShell),
      );
      expect(shell.borderColor, SearchColors.pillBorderFocused);
    });

    testWidgets("Home's copy of the pill is the same element, in white", (
      tester,
    ) async {
      await _pump(
        tester,
        HomeSearchPill(hint: 'Search your stuff...', onTap: () {}),
      );

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, kSearchPillTag);
      expect(
        tester
            .widget<SearchPillShell>(find.byType(SearchPillShell))
            .borderColor,
        SearchColors.pillBorderBlurred,
      );
    });

    testWidgets('flies from Home with its border lerping white to lime', (
      tester,
    ) async {
      tester.view
        ..physicalSize = _canvas * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final navigator = GlobalKey<NavigatorState>();
      final runner = _FakeRunner(const []);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: Material(
            color: SpecColors.bg,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 300, 18, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: HomeSearchPill(
                  hint: 'Search your stuff...',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      navigator.currentState!.push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (_, _, _) =>
              Material(color: SpecColors.bg, child: _screen(runner)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 210));

      // Mid-flight there is one pill in the overlay, and it is neither end.
      final shells = tester
          .widgetList<SearchPillShell>(find.byType(SearchPillShell))
          .map((shell) => shell.borderColor)
          .toList();
      final between = shells.where(
        (color) =>
            color != SearchColors.pillBorderBlurred &&
            color != SearchColors.pillBorderFocused,
      );
      expect(between, isNotEmpty);

      final mid = between.first;
      // Lime's green channel is the lerp's clearest witness: white sits at
      // 255 with alpha 0x33, lime at 255 with alpha 0x80, and red falls from
      // 255 to 215 on the way.
      expect(mid.r * 255, lessThan(255));
      expect(mid.r * 255, greaterThan(215));

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    });

    testWidgets('holds its place in every state', (tester) async {
      final runner = _FakeRunner(const []);
      await _pump(tester, _screen(runner));
      final resting = _rectOf(find.byType(SearchPillShell));
      final header = _rectOf(find.byType(SearchHeaderRow));

      await _type(tester, 'moka pot');
      expect(_rectOf(find.byType(SearchPillShell)), resting);
      expect(_rectOf(find.byType(SearchHeaderRow)), header);

      runner.results = [..._designResults];
      await _type(tester, 'bulb');
      expect(_rectOf(find.byType(SearchPillShell)), resting);
      expect(_rectOf(find.byType(SearchHeaderRow)), header);
    });
  });

  group('the screen', () {
    testWidgets('builds as a bare route, with no Material above it', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigator, home: const SizedBox()),
      );
      navigator.currentState!.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => _screen(_FakeRunner(const [])),
        ),
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('carries no tab bar — it is a pushed route', (tester) async {
      final runner = _FakeRunner([..._designResults]);
      await _pump(tester, _screen(runner));
      await _type(tester, 'bulb');

      expect(find.text('Home'), findsNothing);
      expect(find.text('Collections'), findsNothing);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('SPEC'), findsOneWidget);
    });

    testWidgets('under reduce motion the layout is unchanged', (tester) async {
      final runner = _FakeRunner([..._designResults]);
      await _pump(tester, _screen(runner), isMotionReduced: true);
      await _type(tester, 'bulb');

      expect(find.byType(SearchResultRow), findsNWidgets(3));
      expect(find.text('3 MATCHES'), findsOneWidget);
      expect(_rectOf(find.byType(SearchPillShell)).left, 18);
      expect(_rectOf(find.byType(SearchPillShell)).right, 402 - 18);
    });
  });

  group('formatting', () {
    test('elides a long query inside the quotes', () {
      expect(elideQuery('moka pot'), 'moka pot');
      expect(
        elideQuery('a stovetop moka pot with a burnt handle'),
        'a stovetop moka pot with…',
      );
    });

    test('a timing is always three decimals and an uppercase S', () {
      expect(
        const SearchResults(
          matches: [],
          elapsed: Duration(microseconds: 4000),
        ).timing,
        '0.004S',
      );
      expect(
        const SearchResults(matches: [], elapsed: Duration.zero).timing,
        '0.000S',
      );
    });

    test('the archive line pluralises both halves', () {
      expect(
        const ArchiveCounts(objects: 41, photos: 96).label,
        '41 OBJECTS · 96 PHOTOS',
      );
      expect(
        const ArchiveCounts(objects: 1, photos: 1).label,
        '1 OBJECT · 1 PHOTO',
      );
    });
  });
}
