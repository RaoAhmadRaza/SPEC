import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/onboarding/capture_frame.dart';
import 'package:spec/onboarding/first_object_screen.dart';
import 'package:spec/onboarding/shine_button.dart';

import 'support/fonts.dart';
import 'support/responsive.dart';

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

ScrollPosition _pageScroll(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

Future<void> _pumpResponsiveScreen(
  WidgetTester tester, {
  required Size canvas,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1.0,
}) async {
  await pumpResponsive(
    tester,
    FirstObjectScreen(onAdd: (_) {}, onLater: () {}),
    canvas: canvas,
    padding: padding,
    textScale: textScale,
  );
  await tester.pump(_enter);
}

/// Scrolls the page to its end, where the last chip is closest to the button.
Future<void> _scrollToBottom(WidgetTester tester) async {
  final position = _pageScroll(tester);
  if (position.maxScrollExtent == 0) return;
  position.jumpTo(position.maxScrollExtent);
  await tester.pump();
}

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('suggestion chips are never hidden behind the action button', (
    tester,
  ) async {
    for (final textScale in [1.0, 1.5]) {
      for (final MapEntry(key: name, value: canvas) in specCanvases.entries) {
        // Arrange / Act
        await _pumpResponsiveScreen(
          tester,
          canvas: canvas,
          textScale: textScale,
        );
        await _scrollToBottom(tester);

        // Assert
        final button = tester.getRect(find.byType(ShineButton));
        for (final chip in _chips) {
          expect(
            tester.getRect(find.text(chip)).overlaps(button),
            isFalse,
            reason: '$chip on $name at $textScale',
          );
        }
      }
    }
  });

  testWidgets('page scrolls at 320x568', (tester) async {
    // Arrange / Act
    await _pumpResponsiveScreen(tester, canvas: specCanvases['tiny']!);

    // Assert
    expect(_pageScroll(tester).maxScrollExtent, greaterThan(0.0));
  });

  testWidgets('page does not scroll at the reference canvas', (tester) async {
    // Arrange / Act
    await _pumpResponsiveScreen(tester, canvas: specReferenceCanvas);

    // Assert
    expect(_pageScroll(tester).maxScrollExtent, 0.0);
    expectNoOverflow(tester);
  });

  testWidgets('headline shrinks rather than clipping at text scale 1.5', (
    tester,
  ) async {
    // Arrange / Act
    await _pumpResponsiveScreen(
      tester,
      canvas: specCanvases['tiny']!,
      textScale: 1.5,
    );

    // Assert
    final headline = tester.getRect(
      find
          .ancestor(
            of: find.text('REMEMBER\nONE THING.'),
            matching: find.byType(FittedBox),
          )
          .first,
    );
    expect(headline.width, lessThanOrEqualTo(320.0));
    expectNoOverflow(tester);
  });

  testWidgets('capture frame is fully visible at every canvas', (tester) async {
    for (final MapEntry(key: name, value: canvas) in specCanvases.entries) {
      // Arrange / Act
      await _pumpResponsiveScreen(tester, canvas: canvas);

      // Assert
      final frame = tester.getRect(find.byType(CaptureFrame));
      expect(frame.top, greaterThanOrEqualTo(0.0), reason: name);
      expect(frame.left, greaterThanOrEqualTo(0.0), reason: name);
      expect(frame.right, lessThanOrEqualTo(canvas.width), reason: name);
      expect(frame.bottom, lessThanOrEqualTo(canvas.height), reason: name);
    }
  });

  testWidgets('action button clears a 34pt home indicator', (tester) async {
    // Arrange / Act
    await _pumpResponsiveScreen(
      tester,
      canvas: specReferenceCanvas,
      padding: const EdgeInsets.only(bottom: 34),
    );

    // Assert
    final button = tester.getRect(find.byType(ShineButton));
    expect(
      specReferenceCanvas.height - button.bottom,
      greaterThanOrEqualTo(34.0),
    );
  });

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
