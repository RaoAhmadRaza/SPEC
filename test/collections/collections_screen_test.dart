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
import 'package:spec/theme/spec_tokens.dart';

import '../support/fonts.dart';

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

void main() {
  setUpAll(loadSpecFonts);

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
