import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/library/library_cell.dart';
import 'package:spec/library/library_chrome.dart';
import 'package:spec/library/library_models.dart';
import 'package:spec/library/library_pick_route.dart';
import 'package:spec/library/library_pick_screen.dart';
import 'package:spec/search/search_pill.dart';
import 'package:spec/search/search_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';
import 'package:spec/widgets/keyed_reflow.dart';
import 'package:spec/widgets/square_caret_field.dart';

import '../support/fonts.dart';
import '../support/responsive.dart';

const _canvas = Size(402, 874);

/// The nine the design shows, in order.
const _designNine = [
  ('Bulb', 'B22 · E27', 'HOME'),
  ('Tyre', '205/55 R16', 'CAR'),
  ('Cartridge', '67XL · 305', 'DEVICES'),
  ('Water filter', 'LT1000P', 'HOME'),
  ('Battery', 'CR2032 · AA', 'DEVICES'),
  ('Adapter', '12V 2A', 'DEVICES'),
  ('SD card', '32GB · V30', 'DEVICES'),
  ('Bolt', 'M10 × 1.5', 'OTHER'),
  ('Paint', '#2E2A26', 'HOME'),
];

final List<LibraryItem> _bundled = parseLibrary(
  File('assets/library.json').readAsStringSync(),
);

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
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: isMotionReduced),
          child: Material(color: SpecColors.bg, child: screen),
        ),
      ),
    ),
  );
  await _settle(tester);
}

/// The caret blinks forever, so pumpAndSettle would never return.
Future<void> _settle(WidgetTester tester, {int frames = 70}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _type(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await _settle(tester, frames: 40);
}

LibraryPickScreen _screen({
  List<LibraryItem>? items,
  ValueChanged<LibraryItem>? onPick,
  ValueChanged<String>? onAddOwn,
  VoidCallback? onCancel,
  String stepLabel = 'STEP 1 / 3',
  String initialQuery = '',
}) => LibraryPickScreen(
  items: items ?? _bundled,
  onPick: onPick ?? (_) {},
  onAddOwn: onAddOwn,
  onCancel: onCancel,
  stepLabel: stepLabel,
  initialQuery: initialQuery,
);

/// The chip whose label is [label], and whether it wears the lime fill.
bool _isChipLit(WidgetTester tester, String label) {
  final container = tester.widget<Container>(
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
  );
  return (container.decoration! as BoxDecoration).color == SpecColors.accent;
}

/// Same frame as [_pump] on an arbitrary canvas, with real insets and scale.
Future<void> _pumpResponsiveLibrary(
  WidgetTester tester,
  Widget screen, {
  required Size canvas,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1.0,
}) async {
  tester.view
    ..physicalSize = canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: MediaQueryData(
          size: canvas,
          padding: padding,
          viewPadding: padding,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Material(color: SpecColors.bg, child: screen),
      ),
    ),
  );
  await _settle(tester);
}

/// How many cells share the top edge of the first one, which is the grid's
/// column count.
int _gridColumns(WidgetTester tester) {
  final cells = find.byType(LibraryCell);
  final tops = [
    for (var i = 0; i < cells.evaluate().length; i++)
      tester.getRect(cells.at(i)).top,
  ];
  return tops.where((top) => (top - tops.first).abs() < 1).length;
}

void main() {
  setUpAll(loadSpecFonts);

  group('responsive', () {
    testWidgets('grid uses three columns at the reference canvas', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveLibrary(
        tester,
        _screen(),
        canvas: specReferenceCanvas,
      );

      // Assert
      expect(_gridColumns(tester), 3);
    });

    testWidgets('grid uses six columns on a portrait tablet', (tester) async {
      // Arrange / Act
      await _pumpResponsiveLibrary(
        tester,
        _screen(),
        canvas: specCanvases['tabletPortrait']!,
      );

      // Assert
      expect(_gridColumns(tester), 6);
    });

    testWidgets('rule row does not overflow at text scale 1.5', (tester) async {
      // Arrange / Act
      await _pumpResponsiveLibrary(
        tester,
        _screen(),
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Assert
      expect(find.byType(LibraryRuleRow), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('bottom bar does not overflow at text scale 1.5', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveLibrary(
        tester,
        _screen(),
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Assert
      expect(find.byType(LibraryBottomBar), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('last grid row scrolls clear of the bottom bar', (
      tester,
    ) async {
      for (final canvas in [specCanvases['tiny']!, specReferenceCanvas]) {
        // Arrange
        await _pumpResponsiveLibrary(tester, _screen(), canvas: canvas);

        // Act
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        position.jumpTo(position.maxScrollExtent);
        await _settle(tester, frames: 10);

        // Assert
        final cells = find.byType(LibraryCell);
        final last = tester.getRect(cells.at(cells.evaluate().length - 1));
        expect(
          last.bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(LibraryBottomBar)).top),
          reason: '${canvas.width}x${canvas.height}',
        );
      }
    });

    testWidgets('cell height already grows with text scale', (tester) async {
      // Arrange: the function is measured on its own rather than through the
      // screen. Changing the scale on a live grid tweens every cell between
      // the two heights, and a frame mid-tween is briefly shorter than its
      // content — an artifact of the reflow animation, not of the geometry.
      Future<double> heightAt(double scale) async {
        late double height;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Builder(
                builder: (context) {
                  height = libraryCellHeight(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        return height;
      }

      // Act / Assert: the measured-height mechanism still works.
      final atOne = await heightAt(1.0);
      expect(await heightAt(1.5), greaterThan(atOne));
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets('bottom bar centres its label and button at scale $scale', (
        tester,
      ) async {
        // Arrange / Act
        await _pumpResponsiveLibrary(
          tester,
          _screen(),
          canvas: specReferenceCanvas,
          textScale: scale,
        );

        // Assert: `GlassSurface` lays its child out in a Stack, so a loose
        // height leaves the row pinned to the top edge while the bar paints
        // full size. Both pieces sit on the bar's centre line or neither does.
        final bar = tester.getRect(find.byType(LibraryBottomBar));
        for (final finder in [
          find.text('Not in the list?'),
          find.text('ADD YOUR OWN'),
        ]) {
          expect(
            tester.getRect(finder).center.dy,
            closeTo(bar.center.dy, 0.5),
            reason: 'scale $scale',
          );
        }
      });
    }

    testWidgets('bottom bar clears a 34pt home indicator', (tester) async {
      // Arrange / Act
      await _pumpResponsiveLibrary(
        tester,
        _screen(),
        canvas: specReferenceCanvas,
        padding: const EdgeInsets.only(bottom: 34),
      );

      // Assert
      expect(
        specReferenceCanvas.height -
            tester.getRect(find.byType(LibraryBottomBar)).bottom,
        greaterThanOrEqualTo(34.0),
      );
    });
  });

  group('the bundled library', () {
    test('holds 100 objects with unique ids', () {
      expect(_bundled, hasLength(100));
      expect({for (final item in _bundled) item.id}, hasLength(100));
    });

    test('opens with the design\'s nine, in order', () {
      for (final (index, (name, spec, category)) in _designNine.indexed) {
        expect(_bundled[index].name, name);
        expect(_bundled[index].exampleSpec, spec);
        expect(_bundled[index].category, category);
      }
    });

    test('files 34 objects under HOME', () {
      final home = filterLibrary(_bundled, category: 'HOME', query: '');
      expect(home, hasLength(34));
    });

    test('has something in every bundled category', () {
      for (final category in kLibraryCategories.skip(1)) {
        expect(
          filterLibrary(_bundled, category: category, query: ''),
          isNotEmpty,
          reason: category,
        );
      }
    });

    test('refuses a malformed entry rather than guessing', () {
      expect(
        () => parseLibrary('[{"id": "x", "name": "X", "category": "ALL"}]'),
        throwsFormatException,
      );
      expect(() => parseLibrary('{}'), throwsFormatException);
    });

    test('ranks a name hit first and drops what does not match', () {
      final bulbs = filterLibrary(
        _bundled,
        category: kLibraryAll,
        query: 'bulb',
      );
      expect(bulbs.first.name, 'Bulb');
      expect(
        filterLibrary(_bundled, category: kLibraryAll, query: 'moka pot'),
        isEmpty,
      );
    });

    List<String> names(String query, {String category = kLibraryAll}) => [
      for (final item in filterLibrary(
        _bundled,
        category: category,
        query: query,
      ))
        item.name,
    ];

    test('a typo in a field label never passes for the name', () {
      // `tyre` is one edit from the `TYPE` label half the library carries.
      expect(names('tyre'), ['Tyre', 'Bike tyre']);
      expect(names('tyre', category: 'CAR'), ['Tyre']);
    });

    test('bulb finds the bulbs and what takes one, nothing else', () {
      expect(names('bulb'), [
        'Bulb',
        'Indicator bulb',
        'Smart bulb',
        'Number plate bulb',
        'Headlight',
      ]);
    });

    test('a one-letter slip in the name still finds it', () {
      expect(names('tyer').first, 'Tyre');
      expect(names('bubl').first, 'Bulb');
    });
  });

  group('browsing', () {
    testWidgets('draws the header, headline, rule and the design nine', (
      tester,
    ) async {
      await _pump(tester, _screen());

      expect(find.text('STEP 1 / 3'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('WHAT\nIS IT?'), findsOneWidget);
      expect(find.text('LIBRARY · 100 OBJECTS'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
      for (final (name, spec, _) in _designNine) {
        expect(find.text(name), findsOneWidget);
        expect(find.text(spec), findsOneWidget);
      }
      expect(find.text('Not in the list?'), findsOneWidget);
      expect(find.text('ADD YOUR OWN'), findsOneWidget);
    });

    testWidgets('the step label follows the branch', (tester) async {
      await _pump(tester, _screen(stepLabel: 'STEP 1 / 2'));
      expect(find.text('STEP 1 / 2'), findsOneWidget);
    });

    testWidgets('lays out three equal tracks a long name cannot widen', (
      tester,
    ) async {
      const long = LibraryItem(
        id: 'long',
        name: 'An extraordinarily long library object name that runs on',
        category: 'HOME',
        specLabel: 'SIZE',
        exampleSpec: 'A VERY LONG EXAMPLE SPEC THAT RUNS PAST ITS TRACK',
      );
      await _pump(tester, _screen(items: [long, ..._bundled.take(5)]));

      final widths = [
        for (final cell in find.byType(LibraryCell).evaluate().take(3))
          (cell.renderObject! as RenderBox).size.width,
      ];
      // 366 wide, two 9pt gaps, three equal tracks.
      for (final width in widths) {
        expect(width, closeTo((366 - 18) / 3, 0.01));
      }
      final name = tester.widget<Text>(find.textContaining('extraordinarily'));
      expect(name.maxLines, 1);
      expect(name.overflow, TextOverflow.ellipsis);
    });

    testWidgets('the cut corner walks around the thumb by index', (
      tester,
    ) async {
      await _pump(tester, _screen());

      final cells = tester
          .widgetList<LibraryCell>(find.byType(LibraryCell))
          .take(4)
          .toList();
      for (final (index, cell) in cells.indexed) {
        expect(cell.index, index);
        expect(libraryCutFor(cell.index), kLibraryCuts[index]);
      }
      expect(kLibraryCuts[0].bottomLeft, const Radius.circular(5));
      expect(kLibraryCuts[1].bottomRight, const Radius.circular(5));
      expect(kLibraryCuts[2].topRight, const Radius.circular(5));
      expect(kLibraryCuts[3].topLeft, const Radius.circular(5));
      expect(libraryCutFor(4), kLibraryCuts[0]);
    });

    testWidgets('exactly one filter chip is lit at all times', (tester) async {
      await _pump(tester, _screen());

      final lit = [
        for (final category in kLibraryCategories)
          if (_isChipLit(tester, category)) category,
      ];
      expect(lit, [kLibraryAll]);

      await tester.tap(find.text('HOME'));
      await _settle(tester, frames: 30);
      expect(_isChipLit(tester, 'HOME'), isTrue);
      expect(_isChipLit(tester, kLibraryAll), isFalse);
      expect(find.text('LIBRARY · 34 OBJECTS'), findsOneWidget);

      // Tapping the lit chip again never leaves the row with none.
      await tester.tap(find.text('HOME'));
      await _settle(tester, frames: 30);
      expect(_isChipLit(tester, 'HOME'), isTrue);
    });

    testWidgets('only two lime fills: the lit chip and ADD YOUR OWN', (
      tester,
    ) async {
      await _pump(tester, _screen());

      final limeFills = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color == SpecColors.accent,
          );
      expect(limeFills, hasLength(2));
    });

    testWidgets('a cell that survives a filter travels to its new slot', (
      tester,
    ) async {
      await _pump(tester, _screen());
      final before = tester.getTopLeft(find.text('Water filter'));

      await tester.tap(find.text('HOME'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final during = tester.getTopLeft(find.text('Water filter'));

      await _settle(tester, frames: 30);
      final after = tester.getTopLeft(find.text('Water filter'));

      // Index 3 of ALL (row 2, column 1) becomes index 1 of HOME (row 1,
      // column 2): it moves up and right, and is caught part-way.
      expect(after.dy, lessThan(before.dy));
      expect(after.dx, greaterThan(before.dx));
      expect(during.dy, lessThan(before.dy));
      expect(during.dy, greaterThan(after.dy));
    });
  });

  group('the search pill', () {
    testWidgets('arrives white and turns lime on focus', (tester) async {
      await _pump(tester, _screen());

      SearchPillShell shell() =>
          tester.widget<SearchPillShell>(find.byType(SearchPillShell));
      expect(shell().borderColor, SearchColors.pillBorderBlurred);

      await tester.tap(find.byType(TextField));
      await _settle(tester, frames: 20);
      expect(shell().borderColor, SearchColors.pillBorderFocused);
    });

    testWidgets('draws its own square caret, and only while focused', (
      tester,
    ) async {
      await _pump(tester, _screen());

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.showCursor, isFalse);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(find.byKey(const ValueKey('square-caret')), findsNothing);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      final caret = tester.getSize(find.byKey(const ValueKey('square-caret')));
      expect(caret, const Size(2, 20));
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byKey(const ValueKey('square-caret')),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        SpecColors.accent,
      );
    });

    testWidgets('the caret blinks on a hard step', (tester) async {
      await _pump(tester, _screen());
      await tester.tap(find.byType(TextField));
      await tester.pump();

      double opacity() => tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byKey(const ValueKey('square-caret')),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;

      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(), 1);
      await tester.pump(const Duration(milliseconds: 400));
      expect(opacity(), 0);
    });

    testWidgets('has no waveform — that is the app search', (tester) async {
      await _pump(tester, _screen());
      expect(find.byType(SquareCaretField), findsOneWidget);
      expect(find.text('Bulb, filter, tyre, cartridge...'), findsOneWidget);
    });
  });

  group('empty states', () {
    testWidgets('no match bridges to the manual path with one action', (
      tester,
    ) async {
      String? added;
      await _pump(tester, _screen(onAddOwn: (query) => added = query));
      await _type(tester, 'moka pot');

      expect(find.text('LIBRARY · 0 MATCHES'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('NOT IN\nTHE LIST.'), findsOneWidget);
      expect(
        find.text(
          'The library has 100 common things. Yours isn\'t one of them — '
          'photograph it instead.',
        ),
        findsOneWidget,
      );
      expect(find.text('PHOTOGRAPH IT'), findsOneWidget);
      expect(find.textContaining('spelling'), findsNothing);

      // The bar steps aside so only one escape is on screen.
      final bar = tester.widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.byType(LibraryBottomBar),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(bar.opacity, 0);

      await tester.tap(find.text('PHOTOGRAPH IT'));
      await _settle(tester, frames: 20);
      expect(added, 'moka pot');
    });

    testWidgets('a query carried in from search opens already filtered', (
      tester,
    ) async {
      final bulbs = filterLibrary(
        _bundled,
        category: kLibraryAll,
        query: 'bulb',
      );

      await _pump(tester, _screen(initialQuery: 'bulb'));

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'bulb',
      );
      expect(find.byType(LibraryCell), findsNWidgets(bulbs.length));
      expect(find.text('LIBRARY · ${bulbs.length} OBJECTS'), findsOneWidget);
    });

    testWidgets('a carried-in query with no match opens on PHOTOGRAPH IT', (
      tester,
    ) async {
      String? added;
      await _pump(
        tester,
        _screen(initialQuery: 'moka pot', onAddOwn: (query) => added = query),
      );

      expect(find.text('LIBRARY · 0 MATCHES'), findsOneWidget);
      await tester.tap(find.text('PHOTOGRAPH IT'));
      await _settle(tester, frames: 20);
      expect(added, 'moka pot');
    });

    testWidgets('deleting back to a match brings the bar back', (tester) async {
      await _pump(tester, _screen());
      await _type(tester, 'moka pot');
      await _type(tester, 'bulb');

      expect(find.text('NOT IN\nTHE LIST.'), findsNothing);
      final bar = tester.widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.byType(LibraryBottomBar),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(bar.opacity, 1);
    });

    testWidgets('an empty category offers SHOW ALL and keeps the bar', (
      tester,
    ) async {
      final noClothing = [
        for (final item in _bundled)
          if (item.category != 'CLOTHING') item,
      ];
      await _pump(tester, _screen(items: noClothing));

      await tester.tap(find.text('CLOTHING'));
      await _settle(tester, frames: 40);
      expect(find.text('LIBRARY · 0 OBJECTS'), findsOneWidget);
      expect(find.text('NOTHING\nIN HERE.'), findsOneWidget);
      expect(find.text('No library objects in this category.'), findsOneWidget);
      expect(find.byType(LibraryBottomBar), findsOneWidget);

      await tester.tap(find.text('SHOW ALL'));
      await _settle(tester, frames: 40);
      expect(_isChipLit(tester, kLibraryAll), isTrue);
      expect(find.text('LIBRARY · 88 OBJECTS'), findsOneWidget);
    });

    testWidgets('missing images leave flat tiles and an unchanged grid', (
      tester,
    ) async {
      const broken = [
        LibraryItem(
          id: 'ghost',
          name: 'Ghost',
          category: 'HOME',
          specLabel: 'SIZE',
          exampleSpec: 'NONE',
          asset: 'assets/library/does-not-exist.png',
        ),
        LibraryItem(
          id: 'plain',
          name: 'Plain',
          category: 'HOME',
          specLabel: 'SIZE',
          exampleSpec: 'NONE',
        ),
      ];
      await _pump(tester, _screen(items: broken));

      expect(tester.takeException(), isNull);
      expect(find.byType(Icon), findsNothing);
      expect(find.text('Ghost'), findsOneWidget);
      expect(find.text('Plain'), findsOneWidget);
      expect(
        tester.getSize(find.byType(LibraryCell).first),
        tester.getSize(find.byType(LibraryCell).last),
      );
    });
  });

  group('picking', () {
    testWidgets('hands over the shape and clears the example spec in place', (
      tester,
    ) async {
      LibraryItem? picked;
      await _pump(tester, _screen(onPick: (item) => picked = item));

      await tester.tap(find.text('Bulb'));
      await _settle(tester, frames: 12);

      expect(picked?.id, 'bulb');
      final spec = tester.widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.text('B22 · E27'),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(spec.opacity, 0);
    });

    testWidgets('flies the thumb and the name, never the example spec', (
      tester,
    ) async {
      await _pump(tester, _screen());

      final tags = {
        for (final hero in tester.widgetList<Hero>(find.byType(Hero))) hero.tag,
      };
      expect(tags, containsAll(['lib-bulb-photo', 'lib-bulb-name']));
      expect(
        find.ancestor(of: find.text('B22 · E27'), matching: find.byType(Hero)),
        findsNothing,
      );
    });
  });

  group('the route', () {
    testWidgets('rises over the caller, which recedes to 0.96', (tester) async {
      tester.view
        ..physicalSize = _canvas * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Material(child: Center(child: Text('CALLER'))),
        ),
      );

      navigator.currentState!.push(
        LibraryPickPageRoute(builder: (_) => _screen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final scales = [
        for (final transform in tester.widgetList<Transform>(
          find.ancestor(
            of: find.text('CALLER'),
            matching: find.byType(Transform),
          ),
        ))
          transform.transform.entry(0, 0),
      ];
      expect(scales.any((s) => s < 1 && s >= 0.96), isTrue);

      final screenTop = tester.getTopLeft(find.byType(LibraryPickScreen)).dy;
      expect(screenTop, greaterThan(0));

      await _settle(tester, frames: 40);
      expect(tester.getTopLeft(find.byType(LibraryPickScreen)).dy, 0);
    });

    testWidgets('CANCEL drops it with no confirmation', (tester) async {
      tester.view
        ..physicalSize = _canvas * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Material(child: Center(child: Text('CALLER'))),
        ),
      );
      navigator.currentState!.push(
        LibraryPickPageRoute(
          builder: (_) =>
              _screen(onCancel: () => navigator.currentState!.pop()),
        ),
      );
      await _settle(tester, frames: 60);

      await tester.tap(find.text('CANCEL'));
      await _settle(tester, frames: 40);
      expect(find.byType(LibraryPickScreen), findsNothing);
      expect(find.text('CALLER'), findsOneWidget);
    });
  });

  group('reduce motion', () {
    testWidgets('keeps the layout and holds the caret solid', (tester) async {
      await _pump(tester, _screen(), isMotionReduced: true);

      expect(find.text('LIBRARY · 100 OBJECTS'), findsOneWidget);
      expect(
        tester.getSize(find.byType(LibraryCell).first).width,
        closeTo((366 - 18) / 3, 0.01),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      final caretOpacity = tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byKey(const ValueKey('square-caret')),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      expect(caretOpacity, 1);

      await tester.tap(find.text('HOME'));
      await tester.pump();
      await tester.pump();
      expect(find.text('LIBRARY · 34 OBJECTS'), findsOneWidget);
    });
  });

  group('the reflow', () {
    testWidgets('a cell that returns mid-exit is revived, not doubled', (
      tester,
    ) async {
      Widget build(List<int> items) => Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: _canvas),
          child: KeyedReflow<int>(
            items: items,
            keyOf: (item) => item,
            cellHeight: 20,
            motion: const ReflowMotion(
              move: Duration(milliseconds: 260),
              enter: Duration(milliseconds: 220),
              exit: Duration(milliseconds: 160),
              stagger: Duration(milliseconds: 25),
              enterOffset: 12,
              exitScale: 0.96,
            ),
            itemBuilder: (context, item, index, isLeaving) => Text('$item'),
          ),
        ),
      );

      await tester.pumpWidget(build([1, 2, 3]));
      await tester.pumpWidget(build([1, 3]));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpWidget(build([1, 2, 3]));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('2'), findsOneWidget);
    });
  });
}
