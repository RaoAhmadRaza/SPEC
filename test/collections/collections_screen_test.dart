import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/collections/collections_chips.dart';
import 'package:spec/collections/collections_header.dart';
import 'package:spec/collections/collections_models.dart';
import 'package:spec/collections/collections_screen.dart';
import 'package:spec/collections/square_caret_field.dart';
import 'package:spec/collections/zone_row.dart';
import 'package:spec/data/zone_repository.dart';
import 'package:spec/theme/spec_layout.dart';
import 'package:spec/theme/spec_tokens.dart';

import '../support/fonts.dart';
import '../support/responsive.dart';

const _canvas = Size(402, 874);

/// The five rows of screen 06, verbatim from the design file.
const _designZones = [
  CollectionZone(
    id: 1,
    name: 'Home',
    count: 18,
    specs: ['B22', 'E27', 'LT1000P'],
  ),
  CollectionZone(
    id: 2,
    name: 'Car',
    count: 4,
    specs: ['205/55 R16', 'H7', '5W-30'],
  ),
  CollectionZone(
    id: 3,
    name: 'Devices',
    count: 9,
    specs: ['67XL', '12V 2A', '32GB'],
  ),
  CollectionZone(
    id: 4,
    name: 'Clothing',
    count: 7,
    specs: ['42', '32/34', 'UK 9'],
  ),
  CollectionZone(
    id: 5,
    name: 'Other',
    count: 3,
    specs: ['M10 × 1.5', '120 × 60 CM'],
  ),
];

/// Pumps [screen] and returns a handle that swaps in a rebuilt one.
///
/// The swap goes through a notifier because an Overlay only reads its
/// initial entries once: pumping a new frame would keep the old screen.
Future<ValueNotifier<Widget>> _pump(
  WidgetTester tester,
  Widget screen, {
  bool isMotionReduced = false,
  ValueListenable<double>? keyboard,
}) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final current = ValueNotifier<Widget>(screen);
  addTearDown(current.dispose);

  // The app supplies the Overlay a reorderable list lifts rows into and the
  // localizations it labels them with; a bare test frame supplies both.
  await tester.pumpWidget(
    ValueListenableBuilder<double>(
      valueListenable: keyboard ?? ValueNotifier(0),
      builder: (context, inset, child) => MediaQuery(
        data: MediaQueryData(
          size: _canvas,
          disableAnimations: isMotionReduced,
          viewInsets: EdgeInsets.only(bottom: inset),
        ),
        child: child!,
      ),
      child: Localizations(
        locale: const Locale('en'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => ValueListenableBuilder<Widget>(
                  valueListenable: current,
                  builder: (context, value, _) => value,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return current;
}

Text _text(WidgetTester tester, String data) =>
    tester.widget<Text>(find.text(data));

/// One zone whose name is exactly at the input cap, which is the longest a
/// row ever has to render.
final _maxNameZone = CollectionZone(
  id: 1,
  name: 'Z' * kZoneNameMaxLength,
  count: 4,
  specs: const ['B22'],
);

/// The same frame [_pump] builds — an Overlay for the reorderable list and
/// the localizations it labels rows with — on an arbitrary canvas.
Future<void> _pumpResponsiveCollections(
  WidgetTester tester,
  Widget screen, {
  required Size canvas,
  EdgeInsets padding = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
  double textScale = 1.0,
}) async {
  await pumpResponsive(
    tester,
    Localizations(
      locale: const Locale('en'),
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: Overlay(initialEntries: [OverlayEntry(builder: (_) => screen)]),
    ),
    canvas: canvas,
    padding: padding,
    viewInsets: viewInsets,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

Rect _chipRect(WidgetTester tester, String label) =>
    tester.getRect(find.text(label));

/// The chip row is the last sliver, so on a short canvas it is not built
/// until the list has been scrolled to its end.
Future<void> _scrollToEnd(WidgetTester tester) async {
  final position = tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSpecFonts);

  group('responsive', () {
    testWidgets('title row does not overflow at text scale 1.5', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveCollections(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Assert
      expect(find.text('MY\nSTUFF'), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('chip row lays out identically to the reference at 402x874', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveCollections(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
        canvas: specReferenceCanvas,
      );

      // Assert: same line, 8pt apart, starting at the 18pt gutter — what the
      // Row produced before the Wrap.
      await _scrollToEnd(tester);
      final newZone = _chipRect(tester, '+ NEW ZONE');
      final export = _chipRect(tester, 'EXPORT');
      expect(newZone.top, export.top, reason: 'one line');
      // 8pt of Wrap spacing, plus each chip's 13pt inner padding and 1pt
      // border — exactly what the SizedBox(width: 8) inside the Row gave.
      expect(export.left - newZone.right, closeTo(8 + 2 * (13 + 1), 0.01));
    });

    testWidgets('chips still fit one line at text scale 1.5 on a tiny '
        'screen', (tester) async {
      // Arrange / Act
      await _pumpResponsiveCollections(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Assert: 212pt of the 284pt line, so the Wrap has nothing to do yet.
      await _scrollToEnd(tester);
      expect(
        _chipRect(tester, 'EXPORT').top,
        _chipRect(tester, '+ NEW ZONE').top,
      );
      expectNoOverflow(tester);
    });

    testWidgets('chips wrap to a second line past the scale ceiling on a '
        'tiny screen', (tester) async {
      // Arrange / Act: 2.0 is past what the app clamps to, which is the case
      // the Wrap exists for. A Row would have overflowed here.
      await _pumpResponsiveCollections(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
        canvas: specCanvases['tiny']!,
        textScale: 2.0,
      );

      // Assert
      await _scrollToEnd(tester);
      expect(
        _chipRect(tester, 'EXPORT').top,
        greaterThanOrEqualTo(_chipRect(tester, '+ NEW ZONE').bottom),
      );
      expectNoOverflow(tester);
    });

    testWidgets('a maximum-length zone name never paints over the row '
        'controls', (tester) async {
      // Arrange / Act
      await _pumpResponsiveCollections(
        tester,
        CollectionsScreen(zones: [_maxNameZone], objects: 41, photos: 96),
        canvas: specCanvases['tiny']!,
      );

      // Assert: Hero-ready state, which used to paint with visible overflow.
      expect(
        _chipRect(tester, _maxNameZone.name).overlaps(_chipRect(tester, '04')),
        isFalse,
        reason: 'hero-ready',
      );

      // Act: edit mode swaps in the resting label.
      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        _chipRect(tester, _maxNameZone.name).overlaps(_chipRect(tester, '04')),
        isFalse,
        reason: 'resting',
      );
    });

    testWidgets('keyboard shrinks the scroll region', (tester) async {
      // Arrange
      await _pumpResponsiveCollections(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
        canvas: specReferenceCanvas,
      );
      final open = tester.getRect(find.byType(Scrollable).first).height;

      // Act
      await _pumpResponsiveCollections(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
        canvas: specReferenceCanvas,
        viewInsets: const EdgeInsets.only(bottom: 300),
      );

      // Assert: the viewport shrank rather than padding around the keyboard.
      expect(
        open - tester.getRect(find.byType(Scrollable).first).height,
        300.0,
      );
    });

    testWidgets('content is capped and centred on a landscape tablet', (
      tester,
    ) async {
      // Arrange
      final canvas = specCanvases['tabletLandscape']!;

      // Act
      await _pumpResponsiveCollections(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
        canvas: canvas,
      );

      // Assert
      final row = tester.getRect(find.byType(ZoneRow).first);
      expect(row.width, lessThanOrEqualTo(SpecLayout.maxContentWidth));
      expect(row.center.dx, closeTo(canvas.width / 2, 0.5));
    });

    testWidgets('content clears a 34pt home indicator and a 59pt Dynamic '
        'Island', (tester) async {
      // Arrange / Act
      await _pumpResponsiveCollections(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
        canvas: specReferenceCanvas,
        padding: const EdgeInsets.only(top: 59, bottom: 34),
      );

      // Assert
      expect(
        tester.getRect(find.byType(CollectionsHeaderRow)).top,
        greaterThanOrEqualTo(59.0),
      );
    });
  });

  group('populated', () {
    testWidgets('lays out five rows with padded counts and live samples', (
      tester,
    ) async {
      // Arrange & Act
      await _pump(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
      );

      // Assert
      expect(tester.takeException(), isNull, reason: 'no overflow');
      expect(find.byType(ZoneRow), findsNWidgets(5));
      expect(find.text('B22 · E27 · LT1000P'), findsOneWidget);
      expect(find.text('04'), findsOneWidget);
      expect(find.text('41 OBJECTS'), findsOneWidget);
      expect(find.text('96 PHOTOS'), findsOneWidget);
      expect(find.text('EDIT'), findsOneWidget);
      expect(find.text('EXPORT'), findsOneWidget);
    });

    testWidgets('only the strictly largest count is lime', (tester) async {
      // Arrange & Act
      await _pump(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
      );

      // Assert
      expect(_text(tester, '18').style!.color, SpecColors.accent);
      for (final count in ['04', '09', '07', '03']) {
        expect(_text(tester, count).style!.color, SpecColors.ink60);
      }
    });

    testWidgets('a tie for largest leaves every count ink', (tester) async {
      // Arrange
      const tied = [
        CollectionZone(id: 1, name: 'Home', count: 9),
        CollectionZone(id: 2, name: 'Car', count: 9),
      ];

      // Act
      await _pump(
        tester,
        const CollectionsScreen(zones: tied, objects: 18, photos: 0),
      );

      // Assert
      for (final element in find.text('09').evaluate()) {
        expect((element.widget as Text).style!.color, SpecColors.ink60);
      }
    });

    testWidgets('ON DEVICE is lime text and EXPORT is outline, not fill', (
      tester,
    ) async {
      // Arrange & Act
      await _pump(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
      );

      // Assert
      expect(_text(tester, 'ON DEVICE').style!.color, SpecColors.accent);
      final exportBox = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('EXPORT'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = exportBox.decoration! as BoxDecoration;
      expect(decoration.color!.a, lessThan(0.5));
      expect((decoration.border! as Border).top.color.r, SpecColors.accent.r);
    });

    testWidgets('the thumb cut corner rotates down the list', (tester) async {
      // Arrange & Act
      await _pump(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
      );

      // Assert
      final radii = tester
          .widgetList<ClipRRect>(
            find.descendant(
              of: find.byType(ZoneRow),
              matching: find.byType(ClipRRect),
            ),
          )
          .map((clip) => clip.borderRadius)
          .toList();
      expect(radii, [for (var i = 0; i < 5; i++) zoneThumbRadius(i)]);
    });

    testWidgets('tapping a row opens that zone', (tester) async {
      // Arrange
      CollectionZone? opened;
      await _pump(
        tester,
        CollectionsScreen(
          zones: _designZones,
          objects: 41,
          photos: 96,
          onOpenZone: (zone) => opened = zone,
        ),
      );

      // Act
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();

      // Assert
      expect(opened?.id, 2);
    });

    testWidgets('scrolling past 8pt shows the hairline and nothing else', (
      tester,
    ) async {
      // Arrange: enough zones that the list outgrows the canvas.
      final many = [
        for (var i = 0; i < 10; i++)
          CollectionZone(id: i + 1, name: 'Zone $i', count: i),
      ];
      await _pump(
        tester,
        CollectionsScreen(zones: many, objects: 45, photos: 0),
      );
      final titleBefore = tester.getSize(find.text('MY\nSTUFF'));
      AnimatedOpacity hairline() => tester.widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.byWidgetPredicate(
                (w) => w is ColoredBox && w.color == const Color(0x1AFFFFFF),
              ),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      final isHiddenAtRest = hairline().opacity == 0;

      // Act
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -60));
      await tester.pumpAndSettle();

      // Assert
      expect(isHiddenAtRest, isTrue);
      expect(hairline().opacity, 1);
      expect(tester.getSize(find.text('MY\nSTUFF')), titleBefore);
    });
  });

  group('empty', () {
    testWidgets('ghosts the five default zones, with no EDIT and no EXPORT', (
      tester,
    ) async {
      // Arrange & Act
      await _pump(
        tester,
        const CollectionsScreen(zones: [], objects: 0, photos: 0),
      );

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.text('NO ZONES\nYET.'), findsOneWidget);
      expect(find.byType(ZoneRow), findsNWidgets(5));
      expect(find.text('00'), findsNWidgets(5));
      expect(find.text('0 OBJECTS'), findsOneWidget);
      expect(find.textContaining('PHOTO'), findsNothing);
      expect(find.text('EDIT'), findsNothing);
      expect(find.text('EXPORT'), findsNothing);
      expect(find.text('+ NEW ZONE'), findsOneWidget);
    });

    testWidgets('objects with every zone deleted show no placeholder rows', (
      tester,
    ) async {
      // Arrange & Act
      await _pump(
        tester,
        const CollectionsScreen(zones: [], objects: 3, photos: 0),
      );

      // Assert
      expect(find.byType(ZoneRow), findsNothing);
      expect(find.text('NO ZONES\nYET.'), findsNothing);
    });

    testWidgets('ghost rows do not open anything', (tester) async {
      // Arrange
      var opened = 0;
      await _pump(
        tester,
        CollectionsScreen(
          zones: const [],
          objects: 0,
          photos: 0,
          onOpenZone: (_) => opened++,
        ),
      );

      // Act
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Assert
      expect(opened, 0);
    });

    testWidgets('a ghost row becoming real keeps its height', (tester) async {
      // Arrange
      const seeded = [
        CollectionZone(id: 1, name: 'Home', count: 0),
        CollectionZone(id: 2, name: 'Car', count: 0),
      ];
      final screen = await _pump(
        tester,
        const CollectionsScreen(zones: seeded, objects: 0, photos: 0),
      );
      final ghostHeight = tester.getSize(find.byType(ZoneRow).first).height;

      // Act
      screen.value = const CollectionsScreen(
        zones: [
          CollectionZone(id: 1, name: 'Home', count: 1, specs: ['B22']),
          CollectionZone(id: 2, name: 'Car', count: 0),
        ],
        objects: 1,
        photos: 0,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(tester.getSize(find.byType(ZoneRow).first).height, ghostHeight);
      await tester.pumpAndSettle();
      expect(find.text('B22'), findsOneWidget);
    });
  });

  group('edit mode', () {
    testWidgets('EDIT becomes DONE in place and rename opens inline', (
      tester,
    ) async {
      // Arrange
      await _pump(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
      );

      // Act
      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('DONE'), findsOneWidget);
      expect(find.byType(SquareCaretField), findsOneWidget);
    });

    testWidgets('deleting a zone with objects confirms inside the row', (
      tester,
    ) async {
      // Arrange
      int? deleted;
      await _pump(
        tester,
        CollectionsScreen(
          zones: _designZones,
          objects: 41,
          photos: 96,
          onDeleteZone: (id) => deleted = id,
        ),
      );
      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('×').first);
      await tester.pumpAndSettle();
      final isAskedFirst = deleted == null;
      await tester.tap(find.text('DELETE?'));
      await tester.pumpAndSettle();

      // Assert
      expect(isAskedFirst, isTrue);
      expect(deleted, 1);
    });

    testWidgets('an empty zone deletes without asking', (tester) async {
      // Arrange
      int? deleted;
      await _pump(
        tester,
        CollectionsScreen(
          zones: const [
            CollectionZone(id: 1, name: 'Home', count: 3),
            CollectionZone(id: 2, name: 'Car', count: 0),
          ],
          objects: 3,
          photos: 0,
          onDeleteZone: (id) => deleted = id,
        ),
      );
      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('×').last);
      await tester.pumpAndSettle();

      // Assert
      expect(deleted, 2);
      expect(find.text('DELETE?'), findsNothing);
    });

    testWidgets('a removed row fades and collapses out of the list', (
      tester,
    ) async {
      // Arrange
      final screen = await _pump(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
      );

      // Act
      screen.value = CollectionsScreen(
        zones: _designZones.sublist(0, 4),
        objects: 38,
        photos: 96,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final isStillShown = find.text('Other').evaluate().isNotEmpty;
      await tester.pumpAndSettle();

      // Assert
      expect(isStillShown, isTrue);
      expect(find.text('Other'), findsNothing);
    });
  });

  testWidgets('+ NEW ZONE opens a field that creates the zone', (tester) async {
    // Arrange
    String? created;
    await _pump(
      tester,
      CollectionsScreen(
        zones: _designZones,
        objects: 41,
        photos: 96,
        onCreateZone: (name) async {
          created = name;
          return true;
        },
      ),
    );

    // Act
    await tester.tap(find.text('+ NEW ZONE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Garage');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Assert
    expect(created, 'Garage');
    expect(find.text('+ NEW ZONE'), findsOneWidget, reason: 'collapsed back');
  });

  testWidgets('reduced motion lands on the same layout', (tester) async {
    // Arrange & Act
    await _pump(
      tester,
      const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
      isMotionReduced: true,
    );

    // Assert
    expect(tester.takeException(), isNull);
    expect(find.byType(CollectionsHeaderRow), findsOneWidget);
    expect(find.byType(CollectionsChips), findsOneWidget);
    expect(find.byType(ZoneRow), findsNWidgets(5));
  });

  group('refused names', () {
    EditableText field(WidgetTester tester, String text) =>
        tester.widget<EditableText>(
          find.byWidgetPredicate(
            (w) => w is EditableText && w.controller.text == text,
          ),
        );

    testWidgets('a taken new-zone name on done stays open and says why', (
      tester,
    ) async {
      // Arrange
      await _pump(
        tester,
        CollectionsScreen(
          zones: _designZones,
          objects: 41,
          photos: 96,
          onCreateZone: (name) async => false,
        ),
      );
      await tester.tap(find.text('+ NEW ZONE'));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(EditableText), 'Car');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(field(tester, 'Car').focusNode.hasFocus, isTrue);
      expect(find.text('ALREADY A ZONE'), findsOneWidget);
    });

    testWidgets('a taken new-zone name refused on blur lets focus go', (
      tester,
    ) async {
      // Arrange
      await _pump(
        tester,
        CollectionsScreen(
          zones: _designZones,
          objects: 41,
          photos: 96,
          onCreateZone: (name) async => false,
        ),
      );
      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ NEW ZONE'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Car');

      // Act: tapping a zone name to rename it blurs the new-zone field.
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Assert
      expect(field(tester, 'Home').focusNode.hasFocus, isTrue);
      expect(field(tester, 'Car').focusNode.hasFocus, isFalse);
      expect(find.text('ALREADY A ZONE'), findsOneWidget);
    });

    testWidgets('typing again clears the reason', (tester) async {
      // Arrange
      await _pump(
        tester,
        CollectionsScreen(
          zones: _designZones,
          objects: 41,
          photos: 96,
          onCreateZone: (name) async => false,
        ),
      );
      await tester.tap(find.text('+ NEW ZONE'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Car');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(EditableText), 'Cars');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ALREADY A ZONE'), findsNothing);
    });

    testWidgets('a taken rename on done stays open and says why', (
      tester,
    ) async {
      // Arrange
      await _pump(
        tester,
        CollectionsScreen(
          zones: _designZones,
          objects: 41,
          photos: 96,
          onRenameZone: (id, name) async => false,
        ),
      );
      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(EditableText), 'Home');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(field(tester, 'Home').focusNode.hasFocus, isTrue);
      expect(find.text('ALREADY A ZONE'), findsOneWidget);
    });

    testWidgets('a taken rename refused on blur lets focus go', (tester) async {
      // Arrange
      await _pump(
        tester,
        CollectionsScreen(
          zones: _designZones,
          objects: 41,
          photos: 96,
          onRenameZone: (id, name) async => false,
        ),
      );
      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Home');

      // Act
      await tester.tap(find.text('+ NEW ZONE'));
      await tester.pumpAndSettle();

      // Assert
      expect(field(tester, '').focusNode.hasFocus, isTrue);
      expect(field(tester, 'Home').focusNode.hasFocus, isFalse);
      expect(find.text('ALREADY A ZONE'), findsOneWidget);
    });

    testWidgets('DONE while renaming keeps the typed name', (tester) async {
      // Arrange
      String? renamedTo;
      await _pump(
        tester,
        CollectionsScreen(
          zones: _designZones,
          objects: 41,
          photos: 96,
          onRenameZone: (id, name) async {
            renamedTo = name;
            return true;
          },
        ),
      );
      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Garage');

      // Act
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      // Assert
      expect(renamedTo, 'Garage');
    });
  });

  group('export', () {
    testWidgets('says BACKUP READY once the backup is shared', (tester) async {
      // Arrange
      await _pump(
        tester,
        CollectionsScreen(
          zones: _designZones,
          objects: 41,
          photos: 96,
          onExport: () async => true,
        ),
      );

      // Act
      await tester.tap(find.text('EXPORT'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('BACKUP READY'), findsOneWidget);
    });

    testWidgets('says nothing when the share sheet is dismissed', (
      tester,
    ) async {
      // Arrange
      var isCalled = false;
      await _pump(
        tester,
        CollectionsScreen(
          zones: _designZones,
          objects: 41,
          photos: 96,
          onExport: () async {
            isCalled = true;
            return false;
          },
        ),
      );

      // Act
      await tester.tap(find.text('EXPORT'));
      await tester.pumpAndSettle();

      // Assert
      expect(isCalled, isTrue);
      expect(find.text('BACKUP READY'), findsNothing);
    });
  });

  group('keyboard', () {
    const keyboardHeight = 336.0;
    final keyboardTop = _canvas.height - keyboardHeight;

    /// Raises the keyboard the way a device does: the view's insets change,
    /// and MediaQuery follows.
    Future<void> raiseKeyboard(
      WidgetTester tester,
      ValueNotifier<double> keyboard,
    ) async {
      keyboard.value = keyboardHeight;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight * 3);
      await tester.pumpAndSettle();
    }

    testWidgets('the new-zone field scrolls clear of the keyboard', (
      tester,
    ) async {
      // Arrange
      final keyboard = ValueNotifier<double>(0);
      addTearDown(keyboard.dispose);
      await _pump(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
        keyboard: keyboard,
      );
      await tester.tap(find.text('+ NEW ZONE'));
      await tester.pumpAndSettle();

      // Act
      await raiseKeyboard(tester, keyboard);

      // Assert
      expect(
        tester.getRect(find.byType(SquareCaretField)).bottom,
        lessThanOrEqualTo(keyboardTop),
      );
    });

    testWidgets('the rename field scrolls clear of the keyboard', (
      tester,
    ) async {
      // Arrange
      final keyboard = ValueNotifier<double>(0);
      addTearDown(keyboard.dispose);
      await _pump(
        tester,
        const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
        keyboard: keyboard,
      );
      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      // Act
      await raiseKeyboard(tester, keyboard);

      // Assert
      expect(
        tester.getRect(find.byType(SquareCaretField)).bottom,
        lessThanOrEqualTo(keyboardTop),
      );
    });
  });

  testWidgets('scrolled content is clipped below the status bar', (
    tester,
  ) async {
    // Arrange
    final many = [
      for (var i = 0; i < 10; i++)
        CollectionZone(id: i + 1, name: 'Zone $i', count: i),
    ];
    await _pump(tester, CollectionsScreen(zones: many, objects: 45, photos: 0));
    final pillTopAtRest = tester.getTopLeft(find.text('SPEC')).dy;

    // Act
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();

    // Assert: the resting layout is unchanged, and the viewport that clips
    // the scrolled rows starts below the status bar.
    expect(pillTopAtRest, greaterThanOrEqualTo(56));
    expect(tester.getTopLeft(find.byType(CustomScrollView)).dy, 56);
  });

  testWidgets('a new-zone request opens the name field focused', (
    tester,
  ) async {
    // Arrange
    final screen = await _pump(
      tester,
      const CollectionsScreen(zones: _designZones, objects: 41, photos: 96),
    );

    // Act
    screen.value = const CollectionsScreen(
      zones: _designZones,
      objects: 41,
      photos: 96,
      newZoneRequest: 1,
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('+ NEW ZONE'), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });
}
