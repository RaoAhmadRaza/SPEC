import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/add/add_draft.dart';
import 'package:spec/add/add_entry.dart';
import 'package:spec/add/add_fields_sheet.dart';
import 'package:spec/add/add_flow_sheet.dart';
import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_sheet_route.dart';
import 'package:spec/add/add_sheet_shell.dart';
import 'package:spec/add/add_tokens.dart';
import 'package:spec/add/add_value_field.dart';
import 'package:spec/add/add_what_sheet.dart';
import 'package:spec/add/not_in_library_screen.dart';
import 'package:spec/add/type_tile.dart';
import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/library/library_models.dart';
import 'package:spec/library/library_pick_screen.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/library.dart';

import '../support/fonts.dart';

const _canvas = Size(402, 874);

/// Long enough for any single transition; never pumpAndSettle while step 05
/// is up, because its focused caret blinks forever.
const _settle = Duration(milliseconds: 1200);

Future<void> _openFlow(
  WidgetTester tester, {
  ValueChanged<SpecDraft>? onSave,
  bool disableAnimations = false,
}) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: _canvas, disableAnimations: disableAnimations),
      child: MaterialApp(
        home: Builder(
          builder: (context) => ColoredBox(
            color: const Color(0xFF203040),
            child: Center(
              child: GestureDetector(
                onTap: () => showAddFlow(context, onSave: onSave ?? (_) {}),
                child: const Text('HOME'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('HOME'));
  await tester.pump();
  await tester.pump(_settle);
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.text('CONTINUE'));
  await tester.pump();
  await tester.pump(_settle);
}

double _sheetTop(WidgetTester tester) =>
    tester.getTopLeft(find.byType(AddSheetShell)).dy;

double _dim(WidgetTester tester) {
  final opaque = AddColors.backdropDim.withValues(alpha: 1);
  final boxes = tester
      .widgetList<ColoredBox>(find.byType(ColoredBox))
      .where((box) => box.color.withValues(alpha: 1) == opaque);
  return boxes.isEmpty ? 0 : boxes.first.color.a;
}

double _whatOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.byType(AddWhatSheet),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

int _routeDepth(WidgetTester tester) {
  var depth = 0;
  tester.state<NavigatorState>(find.byType(Navigator)).popUntil((route) {
    depth++;
    return true;
  });
  return depth;
}

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('CONTINUE grows the same sheet to top: 96, never a new one', (
    tester,
  ) async {
    await _openFlow(tester);
    final shell = tester.element(find.byType(AddSheetShell));
    final depth = _routeDepth(tester);

    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 190));
    final midway = _sheetTop(tester);
    // The top edge is travelling; the bottom edge never leaves the screen's.
    expect(midway, lessThan(_canvas.height - 200));
    expect(midway, greaterThan(kFieldsSheetTop));
    expect(tester.getBottomLeft(find.byType(AddSheetShell)).dy, _canvas.height);

    await tester.pump(_settle);
    expect(_sheetTop(tester), kFieldsSheetTop);
    expect(tester.element(find.byType(AddSheetShell)), same(shell));
    expect(_routeDepth(tester), depth);
    expect(find.byType(AddFieldsSheet), findsOneWidget);
    expect(_whatOpacity(tester), 0);
    expect(find.text('STEP 2 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the backdrop dims deeper as the sheet grows', (tester) async {
    await _openFlow(tester);
    expect(_dim(tester), closeTo(AddColors.backdropDim.a, 0.01));

    await _continue(tester);

    expect(_dim(tester), closeTo(AddColors.fieldsBackdropDim.a, 0.01));
  });

  testWidgets('the value field takes focus once the sheet has grown', (
    tester,
  ) async {
    await _openFlow(tester);
    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_valueFocus(tester).hasFocus, isFalse);

    await tester.pump(const Duration(milliseconds: 200));
    expect(_valueFocus(tester).hasFocus, isTrue);
  });

  testWidgets('back reverses to step 04 with its choice intact', (
    tester,
  ) async {
    await _openFlow(tester);
    await tester.tap(find.widgetWithText(TypeTile, 'Car'));
    await tester.pump(_settle);
    final restingTop = _sheetTop(tester);
    await _continue(tester);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(navigator.maybePop());
    await tester.pump();
    await tester.pump(_settle);

    expect(find.byType(AddFieldsSheet), findsNothing);
    expect(_sheetTop(tester), closeTo(restingTop, 0.5));
    expect(_whatOpacity(tester), 1);
    expect(
      tester.widget<TypeTile>(find.widgetWithText(TypeTile, 'Car')).isSelected,
      isTrue,
    );
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('SAVE hands over the draft and the sheet falls away', (
    tester,
  ) async {
    SpecDraft? saved;
    await _openFlow(tester, onSave: (draft) => saved = draft);
    await _continue(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AddValueField),
        matching: find.byType(EditableText),
      ),
      'LT1000P',
    );
    await tester.pump();

    await tester.tap(find.text('SAVE'));
    await tester.pump();
    expect(saved?.value, 'LT1000P');

    await tester.pump(const Duration(milliseconds: 210));
    expect(find.byType(AddFlowSheet), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byType(AddFlowSheet), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('tapping above step 05 abandons the flow without saving', (
    tester,
  ) async {
    var saves = 0;
    await _openFlow(tester, onSave: (_) => saves++);
    await _continue(tester);

    await tester.tapAt(const Offset(201, 40));
    await tester.pump();
    await tester.pump(_settle);

    expect(find.byType(AddFlowSheet), findsNothing);
    expect(saves, 0);
  });

  testWidgets('dragging step 05 down past 35% abandons the flow', (
    tester,
  ) async {
    var saves = 0;
    await _openFlow(tester, onSave: (_) => saves++);
    await _continue(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    final height = tester.getSize(find.byType(AddSheetShell)).height;
    await tester.timedDrag(
      find.text('WHAT DO YOU NEED TO REMEMBER?'),
      Offset(0, height * 0.45),
      const Duration(milliseconds: 600),
    );
    await tester.pump();
    await tester.pump(_settle);

    expect(find.byType(AddFlowSheet), findsNothing);
    expect(saves, 0);
  });

  group('step 05 on its own', () {
    testWidgets(
      'rises at full height with its zone matched and SAVE drops it',
      (tester) async {
        tester.view
          ..physicalSize = _canvas * 3
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        SpecDraft? saved;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  final navigator = Navigator.of(context)..push(_middleRoute());
                  showAddFields(
                    navigator.context,
                    type: AddType.car,
                    zones: const ['Kitchen', 'Garage'],
                    zone: 'GARAGE',
                    name: 'Tyre',
                    initialKind: SpecKind.tyre,
                    onSave: (draft) {
                      saved = draft;
                      navigator.popUntil((route) => route.isFirst);
                    },
                  );
                },
                child: const ColoredBox(
                  color: Color(0xFF203040),
                  child: Center(child: Text('HOME')),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('HOME'));
        await tester.pump();
        await tester.pump(_settle);

        expect(_sheetTop(tester), kFieldsSheetTop);
        expect(find.text('TYRE · GARAGE'), findsOneWidget);
        expect(find.text('STEP 2 / 3'), findsOneWidget);
        expect(_dim(tester), closeTo(AddColors.fieldsBackdropDim.a, 0.01));
        expect(tester.takeException(), isNull);

        await tester.enterText(
          find.descendant(
            of: find.byType(AddValueField),
            matching: find.byType(EditableText),
          ),
          '205/55 R16',
        );
        await tester.pump();
        await tester.tap(find.text('SAVE'));
        await tester.pump();
        await tester.pump(_settle);

        expect(saved?.name, 'Tyre');
        expect(saved?.zone, 'Garage');
        expect(find.byType(AddFieldsSheet), findsNothing);
        expect(find.text('MIDDLE'), findsNothing);
        expect(find.text('HOME'), findsOneWidget);
      },
    );
  });

  group('the add entry', () {
    testWidgets('a library pick saves by name and returns to where it began', (
      tester,
    ) async {
      final container = await _pumpEntry(tester);
      expect(find.byType(LibraryPickScreen), findsOneWidget);

      await tester.tap(find.text('Tyre'));
      await _frames(tester);
      expect(find.text('TYRE · GARAGE'), findsOneWidget);
      expect(find.text('STEP 2 / 3'), findsOneWidget);

      await _typeValueAndSave(tester, '205/55 R16');

      expect(find.byType(AddFieldsSheet), findsNothing);
      expect(find.byType(LibraryPickScreen), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
      final objects = await tester.runAsync(
        () => container.read(objectRepositoryProvider).all(),
      );
      expect(objects!.single.name, 'Tyre');
      expect(objects.single.specKind, SpecKind.tyre);
      expect(objects.single.specValue, '205/55 R16');
      expect(objects.single.zoneName, 'Garage');
    });

    testWidgets('a miss goes through 08 and still returns to the start', (
      tester,
    ) async {
      final container = await _pumpEntry(tester, query: 'moka pot');
      expect(find.text('PHOTOGRAPH IT'), findsOneWidget);

      await tester.tap(find.text('PHOTOGRAPH IT'));
      await _frames(tester);
      expect(find.byType(NotInLibraryScreen), findsOneWidget);

      await tester.tap(find.text('ADD MANUALLY'));
      await _frames(tester);
      expect(find.text('MOKA POT · GARAGE'), findsOneWidget);

      await _typeValueAndSave(tester, '6 cup');

      expect(find.byType(NotInLibraryScreen), findsNothing);
      expect(find.byType(LibraryPickScreen), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
      final objects = await tester.runAsync(
        () => container.read(objectRepositoryProvider).all(),
      );
      expect(objects!.single.name, 'Moka pot');
      expect(objects.single.specValue, '6 cup');
    });
  });

  testWidgets('reduced motion: the rect snaps and content cross-fades', (
    tester,
  ) async {
    await _openFlow(tester, disableAnimations: true);

    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_sheetTop(tester), kFieldsSheetTop);

    await tester.pump(const Duration(milliseconds: 200));
    expect(_whatOpacity(tester), 0);
    expect(tester.takeException(), isNull);
  });
}

/// A plain page pushed over the origin, so returning to the origin has
/// something to pop through.
Route<void> _middleRoute() => PageRouteBuilder<void>(
  pageBuilder: (context, _, _) => const ColoredBox(
    color: Color(0xFF102030),
    child: Center(child: Text('MIDDLE')),
  ),
);

/// Pumps a page that can open the whole add flow, backed by an in-memory
/// database and the bundled library read straight from disk.
Future<ProviderContainer> _pumpEntry(
  WidgetTester tester, {
  String query = '',
}) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final database = SpecDatabase.memory();
  addTearDown(database.close);
  final library = parseLibrary(File('assets/library.json').readAsStringSync());
  final container = ProviderContainer(
    overrides: [
      specDatabaseProvider.overrideWith((ref) async => database),
      libraryItemsProvider.overrideWith((ref) async => library),
    ],
  );
  addTearDown(container.dispose);
  await container.read(specDatabaseProvider.future);
  await container.read(libraryItemsProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => ColoredBox(
            color: const Color(0xFF203040),
            child: Center(
              child: GestureDetector(
                onTap: () =>
                    openAddEntry(context, query: query, zone: 'garage'),
                child: const Text('HOME'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    await tester.tap(find.text('HOME'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await _frames(tester);
  return container;
}

/// Fixed frames rather than a settle: carets blink forever.
Future<void> _frames(WidgetTester tester, {int count = 90}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _typeValueAndSave(WidgetTester tester, String value) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(AddValueField),
      matching: find.byType(EditableText),
    ),
    value,
  );
  await tester.pump();
  await tester.runAsync(() async {
    await tester.tap(find.text('SAVE'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await _frames(tester);
}

FocusNode _valueFocus(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byType(AddValueField),
        matching: find.byType(EditableText),
      ),
    )
    .focusNode;
