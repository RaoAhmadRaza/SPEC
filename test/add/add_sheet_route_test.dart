import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/add/add_sheet_route.dart';
import 'package:spec/add/add_tokens.dart';
import 'package:spec/add/add_what_sheet.dart';

import '../support/fonts.dart';

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

void main() {
  setUpAll(loadSpecFonts);

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
