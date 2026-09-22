import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/splash/splash_screen.dart';

import '../support/fonts.dart';
import '../support/responsive.dart';

/// The four ghost strings, in the order they are stacked.
const _ghosts = ['B22', '205/55 R16', 'LT1000P', '67XL'];

/// Far enough into the master timeline that every letter has landed and the
/// ghosts are at their brightest, so nothing is measured mid-entrance.
const _midTimeline = Duration(milliseconds: 2250);

Future<void> _pumpSplash(
  WidgetTester tester, {
  Size canvas = specReferenceCanvas,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1.0,
}) async {
  await pumpResponsive(
    tester,
    SplashScreen(onDone: () {}),
    canvas: canvas,
    padding: padding,
    textScale: textScale,
  );
  // Never pumpAndSettle: the glow repeats forever.
  await tester.pump(_midTimeline);
}

/// The box the wordmark actually paints into, after any scale-down.
Rect _wordmarkRect(WidgetTester tester) => tester.getRect(
  find.ancestor(of: find.text('S'), matching: find.byType(FittedBox)).first,
);

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('wordmark fits the width at every canvas', (tester) async {
    for (final MapEntry(key: name, value: canvas) in specCanvases.entries) {
      // Arrange / Act
      await _pumpSplash(tester, canvas: canvas);

      // Assert
      expect(
        _wordmarkRect(tester).width,
        lessThanOrEqualTo(canvas.width),
        reason: name,
      );
      expectNoOverflow(tester);
    }
  });

  testWidgets('wordmark shrinks rather than clips at text scale 1.5', (
    tester,
  ) async {
    // Arrange / Act
    await _pumpSplash(tester, canvas: specCanvases['tiny']!, textScale: 1.5);

    // Assert
    expect(_wordmarkRect(tester).width, lessThanOrEqualTo(320));
    expectNoOverflow(tester);
  });

  testWidgets('ghost strings stay inside the canvas on a landscape tablet', (
    tester,
  ) async {
    // Arrange
    final canvas = specCanvases['tabletLandscape']!;

    // Act
    await _pumpSplash(tester, canvas: canvas);

    // Assert
    final rects = [
      for (final ghost in _ghosts) tester.getRect(find.text(ghost)),
    ];
    for (var i = 0; i < rects.length; i++) {
      expect(rects[i].left, greaterThanOrEqualTo(0.0), reason: _ghosts[i]);
      expect(rects[i].top, greaterThanOrEqualTo(0.0), reason: _ghosts[i]);
      expect(
        rects[i].right,
        lessThanOrEqualTo(canvas.width),
        reason: _ghosts[i],
      );
      expect(
        rects[i].bottom,
        lessThanOrEqualTo(canvas.height),
        reason: _ghosts[i],
      );
      for (var j = i + 1; j < rects.length; j++) {
        expect(
          rects[i].overlaps(rects[j]),
          isFalse,
          reason: '${_ghosts[i]} overlaps ${_ghosts[j]}',
        );
      }
    }
    expectNoOverflow(tester);
  });

  testWidgets('bottom block clears a 34pt home indicator', (tester) async {
    // Arrange / Act
    await _pumpSplash(tester, padding: const EdgeInsets.only(bottom: 34));

    // Assert
    final caption = tester.getRect(find.text('OPENING YOUR LOCAL ARCHIVE'));
    expect(
      specReferenceCanvas.height - caption.bottom,
      greaterThanOrEqualTo(34.0),
    );
    expectNoOverflow(tester);
  });
}
