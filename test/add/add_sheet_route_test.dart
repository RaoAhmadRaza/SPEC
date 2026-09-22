import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/add/add_flow_sheet.dart';
import 'package:spec/add/add_sheet_route.dart';
import 'package:spec/add/add_sheet_shell.dart';
import 'package:spec/add/add_tokens.dart';
import 'package:spec/add/add_what_sheet.dart';
import 'package:spec/theme/spec_layout.dart';

import '../support/fonts.dart';
import '../support/responsive.dart';

const _canvas = Size(402, 874);
const _settle = Duration(milliseconds: 1200);

/// Where the question sits once risen: a drag from here never lands on a tile.
Finder get _question => find.text('What are you\nremembering?');

/// A plain page under the one that opens the sheet, so a stray second pop has
/// something visible to take.
Future<void> _pumpHome(
  WidgetTester tester, {
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
        home: const Text('ROOT'),
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => ColoredBox(
            color: const Color(0xFF203040),
            // Only the label opens the sheet, so a tap that falls through a
            // closing sheet onto the page lands on nothing.
            child: Center(
              child: Builder(
                builder: (context) => GestureDetector(
                  onTap: () => showAddFlow(context, onSave: (_) {}),
                  child: const Text('HOME'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  unawaited(
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/home'),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('HOME'));
  await tester.pump();
}

/// The backdrop's dim, which ramps on the same value as its blur. Zero when
/// no sheet is up.
double _dim(WidgetTester tester) {
  final opaque = AddColors.backdropDim.withValues(alpha: 1);
  final boxes = tester
      .widgetList<ColoredBox>(find.byType(ColoredBox))
      .where((box) => box.color.withValues(alpha: 1) == opaque);
  return boxes.isEmpty ? 0 : boxes.first.color.a;
}

double _sheetTop(WidgetTester tester) =>
    tester.getTopLeft(find.byType(AddWhatSheet)).dy;

/// Opens the flow on an arbitrary canvas and returns the sheet's box.
Future<Rect> _openOn(WidgetTester tester, Size canvas) async {
  tester.view
    ..physicalSize = canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: canvas),
      child: MaterialApp(
        home: Builder(
          builder: (context) => GestureDetector(
            onTap: () => showAddFlow(context, onSave: (_) {}),
            child: const Center(child: Text('HOME')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('HOME'));
  await tester.pump();
  await tester.pump(_settle);
  return tester.getRect(find.byType(AddSheetShell).first);
}

/// The height step 05 asks for on [canvas], read through a real element.
Future<double> _fieldsHeightOn(WidgetTester tester, Size canvas) async {
  late double height;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: canvas),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            height = addFieldsSheetHeight(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return height;
}

void main() {
  setUpAll(loadSpecFonts);

  group('responsive', () {
    testWidgets('sheet height is unchanged at the reference canvas', (
      tester,
    ) async {
      // Arrange / Act / Assert: the clamp is a no-op at 874.
      expect(await _fieldsHeightOn(tester, specReferenceCanvas), 874.0 - 96);
    });

    testWidgets('sheet height never exceeds 92% of a landscape tablet', (
      tester,
    ) async {
      // Arrange
      final canvas = specCanvases['tabletLandscape']!;

      // Act
      final height = await _fieldsHeightOn(tester, canvas);

      // Assert
      expect(height, greaterThan(0));
      expect(height, lessThanOrEqualTo(canvas.height * 0.92));
    });

    testWidgets('sheet is full-bleed on a phone', (tester) async {
      // Arrange / Act
      final sheet = await _openOn(tester, specReferenceCanvas);

      // Assert: the cap is infinite below the expanded breakpoint.
      expect(sheet.width, specReferenceCanvas.width);
    });

    testWidgets('sheet is capped and centred on a landscape tablet', (
      tester,
    ) async {
      // Arrange
      final canvas = specCanvases['tabletLandscape']!;

      // Act
      final sheet = await _openOn(tester, canvas);

      // Assert
      expect(sheet.width, lessThanOrEqualTo(SpecLayout.maxContentWidth));
      expect(sheet.center.dx, closeTo(canvas.width / 2, 0.5));
    });
  });

  testWidgets('the sheet rises over the live page, which stays mounted', (
    tester,
  ) async {
    await _pumpHome(tester);
    await _openSheet(tester);
    await tester.pump(_settle);

    expect(find.byType(AddWhatSheet), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(tester.getBottomLeft(find.byType(AddWhatSheet)).dy, _canvas.height);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the backdrop blurs and dims with the rise, not before it', (
    tester,
  ) async {
    await _pumpHome(tester);
    await _openSheet(tester);

    expect(_dim(tester), closeTo(0, 0.01));

    await tester.pump(const Duration(milliseconds: 210));
    final midway = _dim(tester);
    expect(midway, greaterThan(0.05));
    expect(midway, lessThan(AddColors.backdropDim.a));

    await tester.pump(_settle);
    expect(_dim(tester), closeTo(AddColors.backdropDim.a, 0.01));
  });

  testWidgets('tapping the exposed backdrop dismisses to the page', (
    tester,
  ) async {
    await _pumpHome(tester);
    await _openSheet(tester);
    await tester.pump(_settle);

    await tester.tapAt(const Offset(201, 80));
    await tester.pumpAndSettle();

    expect(find.byType(AddWhatSheet), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('a second tap mid-dismiss never pops the page underneath', (
    tester,
  ) async {
    await _pumpHome(tester);
    await _openSheet(tester);
    await tester.pump(_settle);

    await tester.tapAt(const Offset(201, 80));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(const Offset(201, 80));
    await tester.pumpAndSettle();

    expect(find.byType(AddWhatSheet), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('dragging past 35% of the sheet dismisses it', (tester) async {
    await _pumpHome(tester);
    await _openSheet(tester);
    await tester.pump(_settle);

    final height = tester.getSize(find.byType(AddWhatSheet)).height;
    await tester.timedDrag(
      _question,
      Offset(0, height * 0.45),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AddWhatSheet), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('a short, slow drag springs back to rest', (tester) async {
    await _pumpHome(tester);
    await _openSheet(tester);
    await tester.pump(_settle);
    final rest = _sheetTop(tester);

    final height = tester.getSize(find.byType(AddWhatSheet)).height;
    await tester.timedDrag(
      _question,
      Offset(0, height * 0.20),
      const Duration(milliseconds: 800),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AddWhatSheet), findsOneWidget);
    expect(_sheetTop(tester), closeTo(rest, 0.5));
    expect(_dim(tester), closeTo(AddColors.backdropDim.a, 0.01));
  });

  testWidgets('the backdrop unwinds under the finger', (tester) async {
    await _pumpHome(tester);
    await _openSheet(tester);
    await tester.pump(_settle);
    final rest = _sheetTop(tester);
    final height = tester.getSize(find.byType(AddWhatSheet)).height;

    final gesture = await tester.startGesture(tester.getCenter(_question));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(0, height * 0.03));
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Sheet follows the finger one-for-one; backdrop tracks it in reverse.
    final travelled = _sheetTop(tester) - rest;
    expect(travelled, greaterThan(height * 0.2));
    expect(
      _dim(tester),
      closeTo(AddColors.backdropDim.a * (1 - travelled / height), 0.02),
    );

    await gesture.moveBy(Offset(0, -height * 0.3));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(AddWhatSheet), findsOneWidget);
  });

  testWidgets('reduced motion: the sheet is fully up in 200ms', (tester) async {
    await _pumpHome(tester, disableAnimations: true);
    await _openSheet(tester);
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.getBottomLeft(find.byType(AddWhatSheet)).dy, _canvas.height);
    expect(_dim(tester), closeTo(AddColors.backdropDim.a, 0.01));
  });
}
