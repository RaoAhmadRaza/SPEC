import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/reminder_schedule.dart';
import 'package:spec/object/object_hero.dart';
import 'package:spec/object/object_inline_edit.dart';
import 'package:spec/object/object_models.dart';
import 'package:spec/object/object_page_route.dart';
import 'package:spec/object/object_parts.dart';
import 'package:spec/object/object_photos.dart';
import 'package:spec/object/object_screen.dart';
import 'package:spec/object/object_tags.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

import '../support/fonts.dart';
import '../support/responsive.dart';

/// The canvas every number in the design is measured against.
const _canvas = Size(402, 874);

/// Screen 03, verbatim from the design file.
const _bulb = ObjectView(
  id: 7,
  zone: 'BEDROOM',
  subZone: 'CEILING',
  spec: 'B22',
  subtitle: 'Ceiling bulb · 2 fittings',
  fields: [
    SpecAttribute(label: 'BASE', value: 'Bayonet'),
    SpecAttribute(label: 'POWER', value: '9W'),
    SpecAttribute(label: 'TEMP', value: '2700K'),
  ],
  lastReplaced: '2026-08-14',
  purchasedFrom: 'IKEA',
);

const _tileSpec = TextStyle(
  fontFamily: SpecFonts.display,
  fontWeight: FontWeight.w600,
  fontSize: 32,
  height: 0.9,
  letterSpacing: -1.28,
  color: SpecColors.ink,
);

const _tileRadius = BorderRadius.all(Radius.circular(20));

/// A 1 × 1 transparent PNG, so a photo slot has something to fly.
final _onePixelPng = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

Future<void> _pump(
  WidgetTester tester, {
  ObjectView object = _bulb,
  bool isMotionReduced = false,
  Size canvas = _canvas,
  ValueChanged<DateTime>? onReplaced,
  ValueChanged<ObjectEdits>? onSave,
  ValueChanged<int>? onRemovePhoto,
}) async {
  tester.view
    ..physicalSize = canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: isMotionReduced),
        child: child!,
      ),
      home: ObjectScreen(
        object: object,
        sourceSpecStyle: _tileSpec,
        sourcePhotoRadius: _tileRadius,
        onReplaced: onReplaced,
        onSave: onSave,
        onRemovePhoto: onRemovePhoto,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

/// The field inside the metadata row labelled [label], while editing.
Finder _editorOf(String label) => find.descendant(
  of: find.widgetWithText(MetaRow, label),
  matching: find.byType(EditableText),
);

/// [_bulb] with a note, rebuilt by hand because the design's has none.
ObjectView _bulbWithNotes(String notes) => ObjectView(
  id: _bulb.id,
  zone: _bulb.zone,
  subZone: _bulb.subZone,
  spec: _bulb.spec,
  subtitle: _bulb.subtitle,
  fields: _bulb.fields,
  lastReplaced: _bulb.lastReplaced,
  purchasedFrom: _bulb.purchasedFrom,
  notes: notes,
);

/// Same frame as [_pump] but on an arbitrary canvas, with real insets and a
/// real text scale.
Future<void> _pumpResponsiveObject(
  WidgetTester tester, {
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
    MediaQuery(
      data: MediaQueryData(
        size: canvas,
        padding: padding,
        viewPadding: padding,
        viewInsets: viewInsets,
        textScaler: TextScaler.linear(textScale),
      ),
      child: const MaterialApp(
        home: ObjectScreen(
          object: _bulb,
          sourceSpecStyle: _tileSpec,
          sourcePhotoRadius: _tileRadius,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The floating action bar's box.
Rect _actionBar(WidgetTester tester) => tester.getRect(
  find
      .byWidgetPredicate(
        (w) => w is SizedBox && w.height == objectBarHeightOf(tester),
      )
      .first,
);

double objectBarHeightOf(WidgetTester tester) =>
    objectBarHeight(tester.element(find.byType(ObjectScreen)));

void main() {
  setUpAll(loadSpecFonts);

  group('responsive', () {
    testWidgets('action bar does not overflow at text scale 1.5', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveObject(
        tester,
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Assert
      expect(find.text('Edit'), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('last content row clears the action bar at text scale 1.5', (
      tester,
    ) async {
      // Arrange
      await _pumpResponsiveObject(
        tester,
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Act
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();

      // Assert: the reserve and the bar read one function, so the last row
      // always stops above it.
      final rows = find.byType(MetaRow);
      final last = tester.getRect(rows.at(rows.evaluate().length - 1));
      expect(last.bottom, lessThanOrEqualTo(_actionBar(tester).top));
    });

    testWidgets('photo pair is 158pt tall at the reference canvas', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveObject(tester, canvas: specReferenceCanvas);

      // Assert: the AspectRatio conversion is exact at 402pt.
      expect(
        tester.getSize(find.byType(PhotoPair)).height,
        ObjectMetrics.photoRowHeight,
      );
    });

    testWidgets('photo pair keeps its aspect ratio on a portrait tablet', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveObject(
        tester,
        canvas: specCanvases['tabletPortrait']!,
      );

      // Assert
      final pair = tester.getSize(find.byType(PhotoPair));
      expect(
        pair.width / pair.height,
        closeTo(ObjectMetrics.photoPairRatio, 0.01),
      );
    });

    testWidgets('content is capped at maxContentWidth on a landscape tablet', (
      tester,
    ) async {
      // Arrange
      final canvas = specCanvases['tabletLandscape']!;

      // Act
      await _pumpResponsiveObject(tester, canvas: canvas);

      // Assert
      final pair = tester.getRect(find.byType(PhotoPair));
      expect(pair.width, lessThanOrEqualTo(ObjectMetrics.maxContentWidth));
      expect(pair.center.dx, closeTo(canvas.width / 2, 0.5));
    });

    testWidgets('spec text still shrinks toward the floor at text scale 1.5', (
      tester,
    ) async {
      // Arrange / Act: a spec long enough to need shrinking on a tiny canvas.
      await _pumpResponsiveObject(
        tester,
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Assert: fitSpecStyle still runs against the capped width.
      final spec = tester.widget<Text>(find.text('B22'));
      final size = spec.style?.fontSize ?? ObjectText.spec.fontSize!;
      expect(size, greaterThanOrEqualTo(ObjectMetrics.specFloor));
      expect(size, lessThanOrEqualTo(ObjectText.spec.fontSize!));
    });

    testWidgets('header circles clear a 59pt Dynamic Island', (tester) async {
      // Arrange / Act
      await _pumpResponsiveObject(
        tester,
        canvas: specReferenceCanvas,
        padding: const EdgeInsets.only(top: 59),
      );

      // Assert
      expect(
        tester.getRect(find.byType(GlassCircle).first).top,
        greaterThanOrEqualTo(59.0),
      );
    });

    testWidgets('inline edit field clears the action bar when the keyboard '
        'is up', (tester) async {
      // Arrange / Act
      await _pumpResponsiveObject(
        tester,
        canvas: specReferenceCanvas,
        viewInsets: const EdgeInsets.only(bottom: 300),
      );

      // Assert: the bar rides above the keyboard rather than under it.
      expect(
        _actionBar(tester).bottom,
        lessThanOrEqualTo(specReferenceCanvas.height - 300),
      );
    });
  });

  group('layout', () {
    testWidgets('lands on the design with no overflow', (tester) async {
      await _pump(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('B22'), findsOneWidget);
      expect(find.text('BEDROOM'), findsOneWidget);
      expect(find.text('CEILING'), findsOneWidget);
      expect(find.text('Ceiling bulb · 2 fittings'), findsOneWidget);
      for (final label in ['BASE', 'POWER', 'TEMP', 'Bayonet', '9W', '2700K']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('14 AUG 2026'), findsOneWidget);
      expect(find.text('IKEA'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('REPLACED'), findsOneWidget);
    });

    testWidgets('the spec is 108pt and nothing else passes 19pt', (
      tester,
    ) async {
      await _pump(tester);

      final texts = tester.widgetList<Text>(find.byType(Text));
      final spec = texts.singleWhere((t) => t.data == 'B22');
      expect(spec.style!.fontSize, 108);
      expect(spec.style!.letterSpacing, -6.48);
      expect(spec.style!.height, 0.82);

      for (final text in texts.where((t) => t.data != 'B22')) {
        expect(
          text.style?.fontSize ?? 14,
          lessThanOrEqualTo(19),
          reason: '"${text.data}" competes with the spec',
        );
      }
    });

    testWidgets('circles, chips, bar sit on the design grid', (tester) async {
      await _pump(tester);

      // The back circle's visual is 40pt inside its 44pt touch target.
      final back = _rectOf(
        tester,
        find
            .byWidgetPredicate(
              (w) => w is SizedBox && w.width == 40 && w.height == 40,
            )
            .first,
      );
      expect(back.topLeft, const Offset(22, 62));
      expect(back.size, const Size(40, 40));

      // 62 + 40 + 24. The glass chip's 1pt border makes it the taller of the
      // two, so — as in the CSS, where the row centres them — the lime chip
      // sits a point lower.
      final subZone = _rectOf(tester, find.byType(SubZoneChip));
      final zone = _rectOf(tester, find.byType(ZoneChipFrame));
      expect(subZone.top, 126);
      expect(zone.center.dy, subZone.center.dy);
      expect(zone.left, 22);
      expect(subZone.left - zone.right, 8);

      final bar = _rectOf(
        tester,
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == ObjectMetrics.barHeight,
        ),
      );
      expect(bar.bottom, _canvas.height - 44);
      expect(bar.left, 22);
      expect(bar.right, _canvas.width - 22);
    });

    testWidgets('exactly two lime fills: the zone chip and REPLACED', (
      tester,
    ) async {
      await _pump(tester);

      final lime = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where(
            (box) =>
                box.decoration is BoxDecoration &&
                (box.decoration as BoxDecoration).color == SpecColors.accent,
          );
      expect(lime, hasLength(2));
    });

    testWidgets('the photo cuts face each other across the gap', (
      tester,
    ) async {
      await _pump(tester);

      final slots = tester.widgetList<PhotoSlot>(find.byType(PhotoSlot));
      expect(slots.first.radius, ObjectMetrics.mainPhotoRadius);
      expect(slots.first.radius.bottomRight, const Radius.circular(6));
      expect(slots.last.radius, ObjectMetrics.detailPhotoRadius);
      expect(slots.last.radius.topRight, const Radius.circular(6));

      final main = tester.getRect(find.byType(PhotoSlot).first);
      final detail = tester.getRect(find.byType(PhotoSlot).last);
      expect(main.height, 158);
      expect(detail.left - main.right, closeTo(9, 0.01));
      expect(main.width, closeTo(detail.width * 2, 0.01));
    });

    testWidgets('an empty photo slot is a flat tile and nothing else', (
      tester,
    ) async {
      await _pump(tester);

      for (final slot in find.byType(PhotoSlot).evaluate()) {
        final inside = find.descendant(
          of: find.byWidget(slot.widget),
          matching: find.byWidgetPredicate(
            (w) => w is Image || w is Text || w is Icon,
          ),
        );
        expect(inside, findsNothing);
      }
    });

    testWidgets('table columns are equal and long values ellipsize', (
      tester,
    ) async {
      await _pump(
        tester,
        object: const ObjectView(
          id: 7,
          zone: 'BEDROOM',
          spec: 'B22',
          fields: [
            SpecAttribute(label: 'BASE', value: 'Bayonet cap, double contact'),
            SpecAttribute(label: 'POWER', value: '9W'),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      final labels = [
        'BASE',
        'POWER',
      ].map((l) => tester.getTopLeft(find.text(l)).dx);
      final first = labels.first;
      final second = labels.last;
      // Cell two starts one third of the way across, plus its 16pt inset.
      expect(second - first, closeTo((402 - 44) / 3 + 16, 0.5));

      final long = tester.widget<Text>(
        find.text('Bayonet cap, double contact'),
      );
      expect(long.maxLines, 1);
      expect(long.overflow, TextOverflow.ellipsis);
    });

    testWidgets('a two-line spec sets at 72pt and keeps both lines', (
      tester,
    ) async {
      await _pump(
        tester,
        object: const ObjectView(id: 2, zone: 'CAR', spec: '205/55 R16'),
      );

      final spec = tester.widget<Text>(find.text('205/55\nR16'));
      expect(spec.style!.fontSize, 72);
      expect(spec.style!.height, 0.88);
      expect(spec.maxLines, 2);
    });

    testWidgets('a long object scrolls with the bar pinned', (tester) async {
      await _pump(
        tester,
        canvas: const Size(402, 700),
        object: const ObjectView(
          id: 9,
          zone: 'KITCHEN',
          spec: 'MWF',
          subtitle: 'Fridge water filter',
          fields: [
            SpecAttribute(label: 'A', value: '1'),
            SpecAttribute(label: 'B', value: '2'),
            SpecAttribute(label: 'C', value: '3'),
            SpecAttribute(label: 'D', value: '4'),
            SpecAttribute(label: 'E', value: '5'),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      final bar = find.byWidgetPredicate(
        (w) => w is SizedBox && w.height == ObjectMetrics.barHeight,
      );
      final before = tester.getRect(bar);
      await tester.drag(find.text('MWF'), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.getRect(bar), before);
      expect(before.bottom, 700 - 44);
    });
  });

  testWidgets('every control has a name a screen reader can say', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    for (final label in [
      'Back',
      'More options',
      'Edit',
      'Share',
      'Mark replaced today',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    semantics.dispose();
  });

  group('REPLACED', () {
    testWidgets('stamps today, rings once, and pushes nothing', (tester) async {
      DateTime? stamped;
      await _pump(tester, onReplaced: (day) => stamped = day);
      final routes = find.byType(ObjectScreen);

      // The pill's label sits under SAVE's transparent twin; the bar's own
      // detector takes the tap either way.
      await tester.tap(find.text('REPLACED'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // Mid-ring: a lime outline exists while it expands.
      final ring = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border != null &&
            ((w.decoration as BoxDecoration).border! as Border).top.color ==
                SpecColors.accent,
      );
      expect(ring, findsOneWidget);

      await tester.pumpAndSettle();
      expect(ring, findsNothing);
      expect(stamped, isNotNull);
      expect(
        find.text(formatSpecDate(toIsoDate(DateTime.now()))),
        findsOneWidget,
      );
      expect(routes, findsOneWidget);
    });

    testWidgets('under Reduce Motion the date changes but no ring draws', (
      tester,
    ) async {
      await _pump(tester, isMotionReduced: true);

      // The pill's label sits under SAVE's transparent twin; the bar's own
      // detector takes the tap either way.
      await tester.tap(find.text('REPLACED'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final ring = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border != null &&
            ((w.decoration as BoxDecoration).border! as Border).top.color ==
                SpecColors.accent,
      );
      expect(ring, findsNothing);
      await tester.pumpAndSettle();
      expect(
        find.text(formatSpecDate(toIsoDate(DateTime.now()))),
        findsOneWidget,
      );
    });
  });

  group('Edit', () {
    testWidgets('edits in place and SAVE hands back the edits', (tester) async {
      ObjectEdits? saved;
      await _pump(tester, onSave: (edits) => saved = edits);
      await tester.tap(find.text('Edit'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // In place: the same screen, now with editable fields and new labels.
      expect(find.byType(ObjectScreen), findsOneWidget);
      expect(find.byType(EditableText), findsWidgets);
      expect(find.byType(InlineValue), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, 'E27');
      await tester.enterText(_editorOf('PURCHASED'), 'Screwfix');
      await tester.tap(find.text('SAVE'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.spec, 'E27');
      expect(saved!.purchasedFrom, 'Screwfix');
      expect(saved!.fields.map((f) => f.value), ['Bayonet', '9W', '2700K']);
      expect(saved!.lastReplaced, '2026-08-14');
      expect(saved!.notes, isNull);
      expect(find.byType(EditableText), findsNothing);
      expect(find.text('E27'), findsOneWidget);
    });

    testWidgets('Cancel restores what was there', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Edit'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'XXX');
      await tester.tap(find.text('Cancel'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('B22'), findsOneWidget);
      expect(find.text('XXX'), findsNothing);
    });
  });

  group('arrival', () {
    testWidgets('interpolates one spec text rather than cross-fading two', (
      tester,
    ) async {
      tester.view
        ..physicalSize = _canvas * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => GestureDetector(
              onTap: () => Navigator.of(context).push(
                ObjectPageRoute<void>(
                  isMotionReduced: false,
                  builder: (_) => const ObjectScreen(
                    object: _bulb,
                    sourceSpecStyle: _tileSpec,
                    sourcePhotoRadius: _tileRadius,
                  ),
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Hero(
                  tag: objectSpecTag(_bulb.id),
                  child: const Text('B22', style: _tileSpec),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('B22'));
      await tester.pump();
      await tester.pump(kArrivalDuration * 0.5);

      final inFlight = tester
          .widgetList<Text>(find.text('B22'))
          .map((t) => t.style?.fontSize)
          .whereType<double>()
          .where((size) => size > 32 && size < 108)
          .toList();
      expect(inFlight, hasLength(1));

      await tester.pumpAndSettle();
      final landed = tester.widget<Text>(find.text('B22'));
      expect(landed.style!.fontSize, 108);
    });

    testWidgets('Reduce Motion drops the flights entirely', (tester) async {
      await _pump(
        tester,
        isMotionReduced: true,
        object: ObjectView(
          id: _bulb.id,
          zone: _bulb.zone,
          spec: _bulb.spec,
          mainPhoto: MemoryImage(_onePixelPng),
        ),
      );

      expect(find.byType(Hero), findsNothing);
      expect(find.text('B22'), findsOneWidget);
    });
  });

  group('fitSpecStyle', () {
    test('leaves a spec that fits at its full size', () {
      final style = fitSpecStyle(
        text: 'B22',
        base: ObjectText.spec,
        maxWidth: 358,
        textScaler: TextScaler.noScaling,
      );
      expect(style, ObjectText.spec);
    });

    test('shrinks a long spec but never below 56pt', () {
      final style = fitSpecStyle(
        text: 'LT1000P-XL-2026',
        base: ObjectText.spec,
        maxWidth: 358,
        textScaler: TextScaler.noScaling,
      );
      expect(style.fontSize, 56);
      expect(style.letterSpacing, closeTo(-6.48 * 56 / 108, 0.001));
    });
  });

  group('NOTES', () {
    testWidgets('is the last metadata row and reads a dash when empty', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('NOTES'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('NOTES')).dy,
        greaterThan(tester.getTopLeft(find.text('PURCHASED')).dy),
      );
      expect(
        find.descendant(
          of: find.widgetWithText(MetaRow, 'NOTES'),
          matching: find.text(kMissingValue),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a long note keeps to two lines with no overflow', (
      tester,
    ) async {
      final long = 'Warm white only, never daylight. ' * 9;
      await _pump(tester, object: _bulbWithNotes(long));

      expect(tester.takeException(), isNull);
      final note = tester.widget<Text>(find.text(long));
      expect(note.maxLines, 2);
      expect(note.overflow, TextOverflow.ellipsis);
      // Two note lines under four metadata rows outgrow the canvas, so the
      // page scrolls; at its end the clearance above the bar belongs to the
      // last row.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      final bar = find.byWidgetPredicate(
        (w) => w is SizedBox && w.height == ObjectMetrics.barHeight,
      );
      expect(
        tester.getRect(find.widgetWithText(MetaRow, 'NOTES')).bottom,
        lessThanOrEqualTo(tester.getRect(bar).top),
      );
    });

    testWidgets('SAVE hands back the note as written, trimmed', (tester) async {
      ObjectEdits? saved;
      await _pump(tester, onSave: (edits) => saved = edits);
      await tester.tap(find.text('Edit'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(_editorOf('NOTES'), '  Warm white only  ');
      await tester.tap(find.text('SAVE'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(saved!.notes, 'Warm white only');
      expect(find.text('Warm white only'), findsOneWidget);
    });

    testWidgets('clearing the note saves null', (tester) async {
      ObjectEdits? saved;
      await _pump(
        tester,
        object: _bulbWithNotes('Warm white only'),
        onSave: (edits) => saved = edits,
      );
      await tester.tap(find.text('Edit'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(_editorOf('NOTES'), '');
      await tester.tap(find.text('SAVE'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(saved!.notes, isNull);
    });

    testWidgets('typing stops at the length limit', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('Edit'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(_editorOf('NOTES'), 'x' * (kNotesMaxLength + 5));

      final editor = tester.widget<EditableText>(_editorOf('NOTES'));
      expect(editor.controller.text, hasLength(kNotesMaxLength));
    });

    testWidgets('stamping REPLACED keeps the note on screen', (tester) async {
      await _pump(tester, object: _bulbWithNotes('Warm white only'));

      await tester.tap(find.text('REPLACED'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Warm white only'), findsOneWidget);
    });
  });

  group('NEXT DUE', () {
    ObjectView bulbDue({
      required String? lastReplaced,
      int? every = 6,
      DateTime? createdAt,
    }) => ObjectView(
      id: _bulb.id,
      zone: _bulb.zone,
      spec: _bulb.spec,
      fields: _bulb.fields,
      lastReplaced: lastReplaced,
      purchasedFrom: _bulb.purchasedFrom,
      remindEveryMonths: every,
      createdAt: createdAt,
    );

    Finder valueOf(String label) => find.descendant(
      of: find.widgetWithText(MetaRow, label),
      matching: find.byType(Text),
    );

    Text nextDueText(WidgetTester tester) =>
        tester.widgetList<Text>(valueOf('NEXT DUE')).last;

    testWidgets('sits under LAST REPLACED and reads a dash with no reminder', (
      tester,
    ) async {
      await _pump(tester);

      expect(tester.takeException(), isNull);
      final top = tester.getTopLeft(find.text('NEXT DUE')).dy;
      expect(
        top,
        greaterThan(tester.getTopLeft(find.text('LAST REPLACED')).dy),
      );
      expect(top, lessThan(tester.getTopLeft(find.text('PURCHASED')).dy));
      expect(nextDueText(tester).data, kMissingValue);
    });

    testWidgets('counts months on from the last replacement', (tester) async {
      await _pump(
        tester,
        object: bulbDue(lastReplaced: '2090-01-31', every: 1),
      );

      expect(nextDueText(tester).data, '28 FEB 2090');
      expect(nextDueText(tester).style?.color, SpecColors.ink);
    });

    testWidgets('counts from the day it was added when never replaced', (
      tester,
    ) async {
      await _pump(
        tester,
        object: bulbDue(lastReplaced: null, createdAt: DateTime(2090, 1, 10)),
      );

      expect(nextDueText(tester).data, '10 JUL 2090');
    });

    testWidgets('an overdue date is lime', (tester) async {
      await _pump(tester, object: bulbDue(lastReplaced: '2020-01-15'));

      expect(nextDueText(tester).data, '15 JUL 2020');
      expect(nextDueText(tester).style?.color, SpecColors.accent);
    });

    testWidgets('REPLACED moves it on at once', (tester) async {
      await _pump(tester, object: bulbDue(lastReplaced: '2020-01-15'));

      await tester.tap(find.text('REPLACED'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        nextDueText(tester).data,
        formatSpecDate(toIsoDate(addMonths(DateTime.now(), 6))),
      );
      expect(nextDueText(tester).style?.color, SpecColors.ink);
    });

    testWidgets('SAVE with a new replacement date moves it too', (
      tester,
    ) async {
      await _pump(tester, object: bulbDue(lastReplaced: '2090-03-01'));

      await tester.tap(find.text('Edit'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(_editorOf('LAST REPLACED'), '01 MAY 2090');
      await tester.tap(find.text('SAVE'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(nextDueText(tester).data, '01 NOV 2090');
    });
  });

  group('identity', () {
    testWidgets('names the object under the spec', (tester) async {
      await _pump(
        tester,
        object: const ObjectView(
          id: 3,
          zone: 'HOME',
          spec: 'B22',
          name: 'Bulb',
        ),
      );

      final name = tester.widget<Text>(find.text('Bulb'));
      expect(name.style, ObjectText.subtitle);
      expect(
        tester.getTopLeft(find.text('Bulb')).dy,
        greaterThan(tester.getBottomLeft(find.text('B22')).dy),
      );
    });

    testWidgets('joins the name and a subtitle on one line', (tester) async {
      await _pump(
        tester,
        object: const ObjectView(
          id: 3,
          zone: 'HOME',
          spec: 'B22',
          name: 'Bulb',
          subtitle: '2 fittings',
        ),
      );

      expect(find.text('Bulb · 2 fittings'), findsOneWidget);
    });
  });

  group('REMIND ME', () {
    testWidgets('shows the interval above NOTES when one is set', (
      tester,
    ) async {
      await _pump(
        tester,
        object: const ObjectView(
          id: 3,
          zone: 'HOME',
          spec: 'B22',
          remindEveryMonths: 6,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('EVERY 6 MONTHS'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('REMIND ME')).dy,
        lessThan(tester.getTopLeft(find.text('NOTES')).dy),
      );
    });

    testWidgets('is absent when the reminder is NEVER', (tester) async {
      await _pump(tester);

      expect(find.text('REMIND ME'), findsNothing);
    });
  });

  group('keyboard', () {
    for (final label in ['LAST REPLACED', 'PURCHASED', 'NOTES']) {
      testWidgets('keeps $label above the keyboard and the bar', (
        tester,
      ) async {
        await _pump(tester);
        await tester.tap(find.text('Edit'), warnIfMissed: false);
        await tester.pumpAndSettle();

        await tester.showKeyboard(_editorOf(label));
        await tester.enterText(_editorOf(label), 'x');
        tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();

        final bar = find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == ObjectMetrics.barHeight,
        );
        expect(tester.takeException(), isNull);
        expect(tester.getRect(bar).bottom, _canvas.height - 336 - 44);
        expect(
          tester.getRect(_editorOf(label)).bottom,
          lessThanOrEqualTo(tester.getRect(bar).top),
        );
        expect(tester.getRect(_editorOf(label)).top, greaterThanOrEqualTo(0));
      });
    }
  });

  group('photo menu', () {
    testWidgets('an empty slot has no menu', (tester) async {
      await _pump(tester);

      await tester.longPress(find.byType(PhotoSlot).first);
      await tester.pumpAndSettle();

      expect(find.text('Replace'), findsNothing);
    });

    testWidgets('Remove asks once before it removes', (tester) async {
      int? removed;
      await _pump(
        tester,
        object: ObjectView(
          id: 3,
          zone: 'HOME',
          spec: 'B22',
          mainPhoto: MemoryImage(_onePixelPng),
        ),
        onRemovePhoto: (slot) => removed = slot,
      );

      await tester.longPress(find.byType(PhotoSlot).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(removed, isNull);

      await tester.tap(find.text('Yes, remove'));
      await tester.pumpAndSettle();
      expect(removed, kMainSlot);
    });
  });

  group('dates', () {
    test('format as DD MMM YYYY with no comma', () {
      expect(formatSpecDate('2026-08-14'), '14 AUG 2026');
      expect(formatSpecDate('2026-01-05'), '05 JAN 2026');
      expect(formatSpecDate(null), kMissingValue);
      expect(formatSpecDate('not a date'), kMissingValue);
    });

    test('read back, and refuse what is not a real day', () {
      expect(parseSpecDate('14 aug 2026'), '2026-08-14');
      expect(parseSpecDate(' 5 JAN 2026 '), '2026-01-05');
      expect(parseSpecDate('31 FEB 2026'), isNull);
      expect(parseSpecDate('14 AUGUST 2026'), isNull);
      expect(parseSpecDate(''), isNull);
    });
  });
}
