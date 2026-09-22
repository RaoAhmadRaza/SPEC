import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/onboarding/shine_button.dart';
import 'package:spec/onboarding/welcome_screen.dart';

import 'support/fonts.dart';
import 'support/responsive.dart';

const _enter = Duration(milliseconds: 700);
const _chipLabels = [
  'B22',
  '205/55 R16',
  '67XL',
  'LT1000P',
  'M10 × 1.5',
  '32GB',
];

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}

Future<void> _pumpWelcome(
  WidgetTester tester, {
  VoidCallback? onStart,
  VoidCallback? onSkip,
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    _wrap(
      WelcomeScreen(onStart: onStart ?? () {}, onSkip: onSkip ?? () {}),
      disableAnimations: disableAnimations,
    ),
  );
}

/// The drift offset currently applied to a chip. The innermost [Transform]
/// around a chip's text is its float translation.
Offset _driftOf(WidgetTester tester, String label) {
  final finder = find
      .ancestor(of: find.text(label), matching: find.byType(Transform))
      .first;
  final translation = tester
      .widget<Transform>(finder)
      .transform
      .getTranslation();
  return Offset(translation.x, translation.y);
}

double _opacityOf(WidgetTester tester, String label) {
  final finder = find
      .ancestor(of: find.text(label), matching: find.byType(Opacity))
      .first;
  return tester.widget<Opacity>(finder).opacity;
}

/// The scroll position of the content column, or null if it never scrolled.
ScrollPosition _scrollPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

Future<void> _pumpResponsiveWelcome(
  WidgetTester tester, {
  required Size canvas,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1.0,
}) async {
  await pumpResponsive(
    tester,
    WelcomeScreen(onStart: () {}, onSkip: () {}),
    canvas: canvas,
    padding: padding,
    textScale: textScale,
  );
  await tester.pump(_enter);
}

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('message block fits without overflow at every canvas', (
    tester,
  ) async {
    for (final MapEntry(key: name, value: canvas) in specCanvases.entries) {
      // Arrange / Act
      await _pumpResponsiveWelcome(tester, canvas: canvas);

      // Assert
      expect(find.text('GET STARTED'), findsOneWidget, reason: name);
      expectNoOverflow(tester);
    }
  });

  testWidgets('fits without scrolling at the 1.5 scale ceiling on a tiny '
      'screen', (tester) async {
    // Arrange / Act
    await _pumpResponsiveWelcome(
      tester,
      canvas: specCanvases['tiny']!,
      textScale: 1.5,
    );

    // Assert: the wordmark's FittedBox absorbs most of the growth, so the
    // block still fits and the scroll view stays parked.
    expect(_scrollPosition(tester).maxScrollExtent, 0.0);
    expectNoOverflow(tester);
  });

  testWidgets('scrolls instead of overflowing past the scale ceiling on a '
      'tiny screen', (tester) async {
    // Arrange / Act: 2.0 is past what the app clamps to, which is exactly the
    // case the scroll view exists to survive.
    await _pumpResponsiveWelcome(
      tester,
      canvas: specCanvases['tiny']!,
      textScale: 2.0,
    );

    // Assert
    expect(_scrollPosition(tester).maxScrollExtent, greaterThan(0.0));
    expectNoOverflow(tester);
  });

  testWidgets('does not scroll at the reference canvas', (tester) async {
    // Arrange / Act
    await _pumpResponsiveWelcome(tester, canvas: specReferenceCanvas);

    // Assert
    expect(_scrollPosition(tester).maxScrollExtent, 0.0);
    expectNoOverflow(tester);
  });

  testWidgets('GET STARTED clears a 34pt home indicator', (tester) async {
    // Arrange / Act
    await _pumpResponsiveWelcome(
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

  testWidgets('ShineButton label does not clip at scale 1.5', (tester) async {
    // Arrange / Act
    await pumpResponsive(
      tester,
      Center(
        child: SizedBox(
          width: 284,
          child: ShineButton(
            label: 'ADD MY FIRST OBJECT',
            shine: const AlwaysStoppedAnimation(0.0),
            onPressed: () {},
          ),
        ),
      ),
      canvas: specCanvases['tiny']!,
      textScale: 1.5,
    );

    // Assert
    expect(
      tester.getRect(find.text('ADD MY FIRST OBJECT')).width,
      lessThanOrEqualTo(284.0),
    );
    expectNoOverflow(tester);
  });

  testWidgets('no two chips sit at the same point in their float', (
    tester,
  ) async {
    await _pumpWelcome(tester);
    await tester.pump(const Duration(milliseconds: 1200));

    final drifts = [for (final label in _chipLabels) _driftOf(tester, label)];

    expect(drifts.toSet(), hasLength(drifts.length));
  });

  testWidgets('the entrance settles every element at full opacity', (
    tester,
  ) async {
    await _pumpWelcome(tester);

    expect(_opacityOf(tester, 'SKIP'), lessThan(1.0));

    await tester.pump(_enter);

    for (final label in [..._chipLabels, 'SKIP', 'GET STARTED']) {
      expect(_opacityOf(tester, label), 1.0, reason: label);
    }
  });

  testWidgets('reduced motion holds the chips still and skips the entrance', (
    tester,
  ) async {
    await _pumpWelcome(tester, disableAnimations: true);

    for (final label in _chipLabels) {
      expect(_driftOf(tester, label), Offset.zero, reason: label);
      expect(_opacityOf(tester, label), 1.0, reason: label);
    }

    // Still held after time passes, rather than merely starting from rest.
    await tester.pump(const Duration(seconds: 3));
    expect(_driftOf(tester, 'B22'), Offset.zero);
  });

  testWidgets('the two exits report separately', (tester) async {
    var started = 0;
    var skipped = 0;
    await _pumpWelcome(
      tester,
      onStart: () => started++,
      onSkip: () => skipped++,
    );
    await tester.pump(_enter);

    await tester.tap(find.text('GET STARTED'));
    await tester.tap(find.text('SKIP'));

    expect([started, skipped], [1, 1]);
  });

  testWidgets('the shine sweeps in the first 60% then dwells off screen', (
    tester,
  ) async {
    const width = 366.0;

    Future<double> bandX(double t) async {
      await tester.pumpWidget(
        _wrap(
          Center(
            child: SizedBox(
              width: width,
              child: ShineButton(
                label: 'GET STARTED',
                shine: AlwaysStoppedAnimation(t),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      final finder = find
          .descendant(
            of: find.byType(ShineButton),
            matching: find.byType(Transform),
          )
          .first;
      return tester.widget<Transform>(finder).transform.getTranslation().x;
    }

    expect(await bandX(0.0), -70);
    expect(await bandX(0.6), width + 70);
    // The remaining 40% is a dwell, so the band does not creep back.
    expect(await bandX(1.0), width + 70);
  });
}
