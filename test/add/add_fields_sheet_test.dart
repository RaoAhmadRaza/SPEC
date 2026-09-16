import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/add/add_draft.dart';
import 'package:spec/add/add_fields_sheet.dart';
import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_kinds.dart';
import 'package:spec/add/add_location_row.dart';
import 'package:spec/add/add_value_field.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/theme/spec_tokens.dart';

import '../support/fonts.dart';

const _canvas = Size(402, 874);

/// The sheet's box: `top: 96` to the bottom of the canvas.
const _sheetHeight = 874.0 - 96;

/// Past the entrance and the 320ms focus; short of anything that settles,
/// because a focused caret blinks forever.
const _settle = Duration(milliseconds: 1200);

Future<void> _pumpSheet(
  WidgetTester tester, {
  AddType type = AddType.device,
  ValueChanged<SpecDraft>? onSave,
  bool disableAnimations = false,
  String? name,
  String initialValue = '',
  String stepLabel = 'STEP 2 / 2',
  List<String> zones = starterZones,
  File? photo,
  Future<File?> Function()? pickPhoto,
}) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: _canvas, disableAnimations: disableAnimations),
      child: MaterialApp(
        home: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: _sheetHeight,
            child: AddFieldsSheet(
              type: type,
              zone: 'Kitchen',
              zones: zones,
              stepLabel: stepLabel,
              photo: photo,
              pickPhoto: pickPhoto,
              name: name,
              initialValue: initialValue,
              onSave: onSave ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

Finder _chip(String label) => find.text(label).first;

Finder get _valueField => find.descendant(
  of: find.byType(AddValueField),
  matching: find.byType(EditableText),
);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_valueField, text);
  await tester.pump();
}

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.tap(_chip(label));
  await _run(tester, const Duration(milliseconds: 600));
}

/// One frame to start the tickers a tap kicked off, then [duration] of them.
/// A single long pump is one frame, and a ticker's first frame is its zero.
Future<void> _run(WidgetTester tester, Duration duration) async {
  await tester.pump();
  await tester.pump(duration);
}

/// The NOTES row's field: the only editable text in that row.
Finder get _notesField => find.descendant(
  of: find.ancestor(of: find.text('NOTES'), matching: find.byType(Row)).first,
  matching: find.byType(EditableText),
);

String _value(WidgetTester tester) =>
    tester.widget<EditableText>(_valueField).controller.text;

/// The hand-drawn caret: the only 2pt-wide lime box.
Finder get _caret => find.byWidgetPredicate(
  (w) => w is ColoredBox && w.color == SpecColors.accent,
);

/// A real one-pixel PNG, so a photo tile has something it can decode.
File _pixelFile() {
  final directory = Directory.systemTemp.createTempSync('spec_sheet');
  addTearDown(() => directory.deleteSync(recursive: true));
  return File('${directory.path}/shot.png')..writeAsBytesSync(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
      'hQGAhKmMIQAAAABJRU5ErkJggg==',
    ),
  );
}

/// The product of every [Opacity] above [of] — what the eye actually gets.
double _visibility(WidgetTester tester, Finder of) => tester
    .widgetList<Opacity>(find.ancestor(of: of, matching: find.byType(Opacity)))
    .fold(1.0, (value, opacity) => value * opacity.opacity);

double _caretOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(of: _caret, matching: find.byType(Opacity)).first,
    )
    .opacity;

void main() {
  setUpAll(loadSpecFonts);

  group('layout', () {
    testWidgets('fills its box at 402pt with nothing overflowing', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      expect(tester.takeException(), isNull);
      final save = find
          .ancestor(of: find.text('SAVE'), matching: find.byType(Container))
          .first;
      expect(tester.getSize(save).height, 58);
      // SAVE pinned to the bottom, 46 above the sheet's edge.
      expect(tester.getBottomLeft(save).dy, closeTo(_canvas.height - 46, 0.5));
      expect(tester.getSize(find.byType(AddLocationRow)).height, 86);
    });

    testWidgets('the value is 42pt / 600 and the largest text by far', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      final style = tester.widget<EditableText>(_valueField).style;
      expect(style.fontSize, 42);
      expect(style.fontWeight, FontWeight.w600);
      final others = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.style?.fontSize ?? 0);
      expect(others.every((size) => size <= 18), isTrue);
    });

    testWidgets('exactly one lime text and one lime chip at rest', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      final limeTexts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.style?.color == SpecColors.accent)
          .map((t) => t.data);
      expect(limeTexts, ['WHAT DO YOU NEED TO REMEMBER?']);

      final limeChips = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where(
            (c) => (c.decoration! as BoxDecoration).color == SpecColors.accent,
          );
      expect(limeChips, hasLength(1));
    });

    testWidgets('the cut corners face each other across the gap', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      final slot = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AddLocationRow),
              matching: find.byType(Container),
            )
            .first,
      );
      final slotRadius = (slot.decoration! as BoxDecoration).borderRadius!
          .resolve(TextDirection.ltr);
      expect(slotRadius.bottomLeft, const Radius.circular(5));
      expect(slotRadius.bottomRight, const Radius.circular(18));
      // An empty slot is a flat tile: no image, no icon, no label.
      expect(slot.child, isNull);
    });

    testWidgets('the context row and chips follow the type', (tester) async {
      await _pumpSheet(tester, type: AddType.car);
      await tester.pump(_settle);

      expect(find.text('CAR · KITCHEN'), findsOneWidget);
      expect(find.text('STEP 2 / 2'), findsOneWidget);
      for (final label in ['TYRE', 'OIL', 'BULB', 'WIPER', 'OTHER']) {
        expect(find.text(label), findsWidgets);
      }
      expect(find.text('EVERY 2 YEARS'), findsOneWidget);
    });
  });

  group('value', () {
    testWidgets('autocorrect and predictive text are off', (tester) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      final field = tester.widget<EditableText>(_valueField);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.showCursor, isFalse);
    });

    testWidgets('the caret is a square 2 × 38 bar that blinks with a step', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      expect(tester.getSize(_caret), const Size(2, 38));
      final seen = <double>{};
      for (var i = 0; i < 22; i++) {
        await tester.pump(const Duration(milliseconds: 53));
        seen.add(_caretOpacity(tester));
      }
      expect(seen, {0.0, 1.0});
    });

    testWidgets('the caret hides when the field loses focus', (tester) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 600));

      expect(_caretOpacity(tester), 0);
    });

    testWidgets('a long value shrinks, and the caret shrinks with it', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      await _type(tester, 'LT1000P-REPLACEMENT-CARTRIDGE');

      final size = tester.widget<EditableText>(_valueField).style.fontSize!;
      expect(size, lessThan(42));
      expect(size, greaterThanOrEqualTo(24));
      expect(tester.getSize(_caret).height, closeTo(38 * size / 42, 0.01));
      expect(tester.takeException(), isNull);
    });
  });

  group('kinds', () {
    testWidgets('switching the chip never reflows the row', (tester) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);
      const labels = ['MODEL', 'SERIAL', 'FILTER', 'BATTERY', 'OTHER'];
      final before = [for (final l in labels) tester.getRect(_chip(l))];

      await _tapChip(tester, 'SERIAL');

      expect([for (final l in labels) tester.getRect(_chip(l))], before);
    });

    testWidgets('the field re-addresses itself to the new kind', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);
      await _type(tester, 'LT1000P');

      await _tapChip(tester, 'BATTERY');

      expect(find.text('BATTERY'), findsNWidgets(2));
      expect(_value(tester), isEmpty);
      expect(find.text('EVERY YEAR'), findsOneWidget);
    });

    testWidgets('values typed under one kind survive switching back', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);
      await _type(tester, 'LT1000P');
      await _tapChip(tester, 'MODEL');
      await _type(tester, 'RF28');

      await _tapChip(tester, 'FILTER');
      expect(_value(tester), 'LT1000P');

      await _tapChip(tester, 'MODEL');
      expect(_value(tester), 'RF28');
    });

    testWidgets('OTHER opens a field-name row, and closing it folds it away', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);
      expect(tester.getSize(find.byType(SizeTransition)).height, 0);

      await _tapChip(tester, 'OTHER');
      expect(tester.getSize(find.byType(SizeTransition)).height, 32);
      expect(find.text('FIELD NAME'), findsOneWidget);

      await _tapChip(tester, 'MODEL');
      expect(tester.getSize(find.byType(SizeTransition)).height, 0);
    });
  });

  group('controls', () {
    testWidgets('the reminder advances through the cycle on tap', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      await tester.tap(find.text('EVERY 6 MONTHS'));
      await _run(tester, const Duration(milliseconds: 300));
      expect(find.text('EVERY YEAR'), findsOneWidget);

      // A chosen reminder is no longer overridden by the kind's default.
      await _tapChip(tester, 'MODEL');
      expect(find.text('EVERY YEAR'), findsOneWidget);
    });

    testWidgets('the location card picks a zone in place', (tester) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);

      await tester.tap(find.text('LOCATION'));
      await _run(tester, const Duration(milliseconds: 400));
      expect(tester.getSize(find.byType(AddLocationRow)).height, 214);

      await tester.tap(find.text('Bedroom'));
      await _run(tester, const Duration(milliseconds: 400));

      expect(tester.getSize(find.byType(AddLocationRow)).height, 86);
      expect(find.text('DEVICE · BEDROOM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every zone in a long list is fully drawn once open', (
      tester,
    ) async {
      await _pumpSheet(
        tester,
        zones: zoneChoices(const ['Home', 'Car', 'Office', 'Loft', 'Shed']),
      );
      await tester.pump(_settle);

      await tester.tap(find.text('LOCATION'));
      await _run(tester, const Duration(milliseconds: 400));

      expect(_visibility(tester, find.text('Garage')), 1);
      expect(_visibility(tester, find.text('+ NEW ZONE')), 1);
    });

    testWidgets('the photo slot takes a photo, and SAVE carries it', (
      tester,
    ) async {
      final shot = _pixelFile();
      var picks = 0;
      SpecDraft? draft;
      await _pumpSheet(
        tester,
        pickPhoto: () async {
          picks++;
          return shot;
        },
        onSave: (d) => draft = d,
      );
      await tester.pump(_settle);

      await tester.tap(find.byKey(const ValueKey('add-photo-slot')));
      await tester.pump();
      expect(picks, 1);
      expect(find.byType(Image), findsOneWidget);

      await _type(tester, 'LT1000P');
      await tester.tap(find.text('SAVE'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(draft!.photo, shot);
    });

    testWidgets('a refused pick keeps the photo already there', (tester) async {
      final carried = _pixelFile();
      SpecDraft? draft;
      await _pumpSheet(
        tester,
        photo: carried,
        pickPhoto: () async => null,
        onSave: (d) => draft = d,
      );
      await tester.pump(_settle);

      await tester.tap(find.byKey(const ValueKey('add-photo-slot')));
      await tester.pump();
      await _type(tester, 'LT1000P');
      await tester.tap(find.text('SAVE'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(draft!.photo, carried);
    });
  });

  group('save', () {
    testWidgets('stays disabled until there is a value', (tester) async {
      var saves = 0;
      await _pumpSheet(tester, onSave: (_) => saves++);
      await tester.pump(_settle);

      await tester.tap(find.text('SAVE'));
      await tester.pump();
      expect(saves, 0);

      await _type(tester, '   ');
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      expect(saves, 0);
    });

    testWidgets('hands over the whole draft', (tester) async {
      SpecDraft? draft;
      await _pumpSheet(tester, onSave: (d) => draft = d);
      await tester.pump(_settle);
      await _type(tester, 'LT1000P');

      await tester.tap(find.text('SAVE'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(draft, isNotNull);
      expect(draft!.type, AddType.device);
      expect(draft!.kind, SpecKind.filter);
      expect(draft!.value, 'LT1000P');
      expect(draft!.zone, 'Kitchen');
      expect(draft!.remindEveryMonths, 6);
      expect(draft!.photo, isNull);
    });

    testWidgets('saving mid-wipe keeps each value with its own kind', (
      tester,
    ) async {
      SpecDraft? draft;
      await _pumpSheet(tester, onSave: (d) => draft = d);
      await tester.pump(_settle);
      await _type(tester, 'LT1000P');
      await _tapChip(tester, 'MODEL');
      await _type(tester, 'RF28');

      await tester.tap(_chip('FILTER'));
      await _run(tester, const Duration(milliseconds: 40));
      await tester.tap(find.text('SAVE'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(draft!.kind, SpecKind.filter);
      expect(draft!.value, 'LT1000P');
    });
  });

  group('carried in from an earlier step', () {
    testWidgets('a known name leads the context row beside the step', (
      tester,
    ) async {
      await _pumpSheet(tester, name: 'Tyre', stepLabel: 'STEP 2 / 3');
      await tester.pump(_settle);

      expect(find.text('TYRE · KITCHEN'), findsOneWidget);
      expect(find.text('STEP 2 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the value field opens with the spec already typed', (
      tester,
    ) async {
      await _pumpSheet(tester, initialValue: '205/55 R16');
      await tester.pump(_settle);

      expect(_value(tester), '205/55 R16');
    });

    testWidgets('SAVE hands over the name and the notes typed', (tester) async {
      SpecDraft? draft;
      await _pumpSheet(
        tester,
        name: 'Tyre',
        initialValue: '205/55 R16',
        onSave: (d) => draft = d,
      );
      await tester.pump(_settle);

      await tester.enterText(_notesField, 'Front left is worn');
      await tester.pump();
      await tester.tap(find.text('SAVE'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(draft!.name, 'Tyre');
      expect(draft!.value, '205/55 R16');
      expect(draft!.notes, 'Front left is worn');
    });

    testWidgets('notes are optional and capped at the stored length', (
      tester,
    ) async {
      await _pumpSheet(tester);
      await tester.pump(_settle);
      expect(find.text('OPTIONAL'), findsOneWidget);

      await tester.enterText(_notesField, 'x' * (kNotesMaxLength + 20));
      await tester.pump();

      expect(
        tester.widget<EditableText>(_notesField).controller.text,
        hasLength(kNotesMaxLength),
      );
      expect(find.text('OPTIONAL'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('SAVE mid-wipe onto an empty kind saves nothing', (tester) async {
    SpecDraft? draft;
    await _pumpSheet(tester, onSave: (d) => draft = d);
    await tester.pump(_settle);
    await _type(tester, 'LT1000P');

    await tester.tap(_chip('BATTERY'));
    await _run(tester, const Duration(milliseconds: 40));
    await tester.tap(find.text('SAVE'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(draft, isNull);
  });

  group('reduced motion', () {
    testWidgets('a 200ms fade, a solid caret, and chips that snap', (
      tester,
    ) async {
      await _pumpSheet(tester, disableAnimations: true);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 10));

      final save = tester.widget<Opacity>(
        find
            .ancestor(of: find.text('SAVE'), matching: find.byType(Opacity))
            .first,
      );
      expect(save.opacity, 1);

      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 90));
        expect(_caretOpacity(tester), 1);
      }

      await tester.tap(_chip('SERIAL'));
      await tester.pump();
      final selected = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where(
            (c) => (c.decoration! as BoxDecoration).color == SpecColors.accent,
          );
      expect(selected, hasLength(1));
      expect(find.text('SERIAL'), findsNWidgets(2));
    });
  });

  test('keeps the photo it was given', () {
    final photo = File('filter.jpg');
    final sheet = AddFieldsSheet(
      type: AddType.device,
      zone: 'Kitchen',
      zones: const ['Kitchen'],
      stepLabel: 'STEP 2 / 2',
      photo: photo,
      onSave: (_) {},
    );
    expect(sheet.photo, photo);
  });
}
