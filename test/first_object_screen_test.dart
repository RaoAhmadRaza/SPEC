import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/onboarding/capture_frame.dart';
import 'package:spec/onboarding/first_object_screen.dart';

const _enter = Duration(milliseconds: 760);

/// The canvas every number in the design brief is measured against.
const _canvas = Size(402, 874);
const _chips = ['BULB', 'TYRE', 'CARTRIDGE', 'FILTER'];

Future<void> _pumpScreen(
  WidgetTester tester, {
  ValueChanged<String>? onAdd,
  VoidCallback? onLater,
  VoidCallback? onCapture,
  bool disableAnimations = false,
}) {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FirstObjectScreen(
          onAdd: onAdd ?? (_) {},
          onLater: onLater ?? () {},
          onCapture: onCapture,
        ),
      ),
    ),
  );
}

/// Every ring outline currently in the frame.
Finder get _rings => find.descendant(
  of: find.byType(CaptureFrame),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).shape == BoxShape.circle,
  ),
);

double _opacityAbove(WidgetTester tester, Finder of) {
  final finder = find.ancestor(of: of, matching: find.byType(Opacity)).first;
  return tester.widget<Opacity>(finder).opacity;
}

double _bobOf(WidgetTester tester, String chip) {
  final finder = find
      .ancestor(of: find.text(chip), matching: find.byType(Transform))
      .first;
  return tester.widget<Transform>(finder).transform.getTranslation().y;
}

Size _chipSize(WidgetTester tester, String chip) => tester.getSize(
  find.ancestor(of: find.text(chip), matching: find.byType(Container)).first,
);

void main() {
  testWidgets('two rings are in flight, half a cycle apart', (tester) async {
    await _pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 700));

    expect(_rings, findsNWidgets(2));

    final scales = [
      for (var i = 0; i < 2; i++)
        tester
            .widget<Transform>(
              find
                  .ancestor(of: _rings.at(i), matching: find.byType(Transform))
                  .first,
            )
            .transform
            .getMaxScaleOnAxis(),
    ];
    expect(scales[0], isNot(closeTo(scales[1], 0.01)));
    for (final scale in scales) {
      expect(scale, inInclusiveRange(0.82, 1.5));
    }
  });

  testWidgets('the four chips never bob in unison', (tester) async {
    await _pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 900));

    final offsets = [for (final chip in _chips) _bobOf(tester, chip)];

    expect(offsets.toSet(), hasLength(_chips.length));
    for (final offset in offsets) {
      expect(offset, inInclusiveRange(-9.0, 0.0));
    }
  });

  testWidgets('selecting a chip recolours it without reflowing the row', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await tester.pump(_enter);

    final before = [for (final chip in _chips) _chipSize(tester, chip)];

    await tester.tap(find.text('CARTRIDGE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect([for (final chip in _chips) _chipSize(tester, chip)], before);
  });

  testWidgets('the button reports the selected suggestion', (tester) async {
    String? added;
    await _pumpScreen(tester, onAdd: (chip) => added = chip);
    await tester.pump(_enter);

    await tester.tap(find.text('FILTER'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('ADD MY FIRST OBJECT'));

    expect(added, 'FILTER');
  });

  testWidgets('tapping the frame opens the camera', (tester) async {
    var captures = 0;
    await _pumpScreen(tester, onCapture: () => captures++);
    await tester.pump(_enter);

    await tester.tap(find.byType(CaptureFrame));
    await tester.pump(const Duration(milliseconds: 300));

    expect(captures, 1);
  });

  testWidgets('reduced motion leaves one still ring and flat chips', (
    tester,
  ) async {
    await _pumpScreen(tester, disableAnimations: true);
    await tester.pump(const Duration(milliseconds: 200));

    expect(_rings, findsOneWidget);
    expect(_opacityAbove(tester, _rings), closeTo(0.35, 0.001));

    for (final chip in _chips) {
      expect(_bobOf(tester, chip), 0.0, reason: chip);
    }

    // Still still, once the loops would otherwise have moved.
    await tester.pump(const Duration(seconds: 2));
    expect(_bobOf(tester, 'BULB'), 0.0);
  });
}
