import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/onboarding/how_it_works_screen.dart';
import 'package:spec/onboarding/step_card.dart';

import 'support/fonts.dart';
import 'support/responsive.dart';

const _enter = Duration(milliseconds: 780);

/// The canvas every number in the design brief is measured against.
const _canvas = Size(402, 874);
const _cardCount = 3;
const _cutRadius = Radius.circular(6);

Future<void> _pumpScreen(
  WidgetTester tester, {
  VoidCallback? onNext,
  VoidCallback? onSkip,
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
        child: HowItWorksScreen(
          onNext: onNext ?? () {},
          onSkip: onSkip ?? () {},
        ),
      ),
    ),
  );
}

/// How far card [index] is currently lifted. The outer of the two [Transform]s
/// around a card is its translation; the inner one is the tap scale.
double _liftOf(WidgetTester tester, int index) {
  final finder = find
      .ancestor(
        of: find.byType(StepCard).at(index),
        matching: find.byType(Transform),
      )
      .last;
  return tester.widget<Transform>(finder).transform.getTranslation().y;
}

double _opacityOf(WidgetTester tester, Finder of) {
  final finder = find.ancestor(of: of, matching: find.byType(Opacity)).first;
  return tester.widget<Opacity>(finder).opacity;
}

ScrollPosition _cardScroll(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

/// The NEXT button's box, which is what the card region must never reach.
Rect _nextButton(WidgetTester tester) => tester.getRect(
  find
      .ancestor(of: find.text('NEXT'), matching: find.byType(GestureDetector))
      .first,
);

Future<void> _pumpResponsiveScreen(
  WidgetTester tester, {
  required Size canvas,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1.0,
}) async {
  await pumpResponsive(
    tester,
    HowItWorksScreen(onNext: () {}, onSkip: () {}),
    canvas: canvas,
    padding: padding,
    textScale: textScale,
  );
  await tester.pump(_enter);
}

/// Brings every card into view in turn and checks it lands whole inside the
/// canvas. Without the scroll view the tall cases silently overhang and clip,
/// which no overflow banner reports.
Future<void> _expectEveryCardReachable(
  WidgetTester tester,
  Size canvas,
  String reason,
) async {
  for (var i = 0; i < _cardCount; i++) {
    await tester.ensureVisible(find.byType(StepCard).at(i));
    await tester.pump();
    final card = tester.getRect(find.byType(StepCard).at(i));
    expect(card.top, greaterThanOrEqualTo(0.0), reason: '$reason card $i');
    expect(card.left, greaterThanOrEqualTo(0.0), reason: '$reason card $i');
    expect(
      card.right,
      lessThanOrEqualTo(canvas.width),
      reason: '$reason card $i',
    );
    expect(
      card.bottom,
      lessThanOrEqualTo(canvas.height),
      reason: '$reason card $i',
    );
  }
}

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('every card is reachable and fully visible at every canvas', (
    tester,
  ) async {
    for (final MapEntry(key: name, value: canvas) in specCanvases.entries) {
      // Arrange / Act
      await _pumpResponsiveScreen(tester, canvas: canvas);

      // Assert
      await _expectEveryCardReachable(tester, canvas, name);
      expectNoOverflow(tester);
    }
  });

  testWidgets('card region scrolls rather than clipping at text scale 1.5 on '
      'a tiny screen', (tester) async {
    // Arrange
    final canvas = specCanvases['tiny']!;

    // Act
    await _pumpResponsiveScreen(tester, canvas: canvas, textScale: 1.5);

    // Assert
    expect(_cardScroll(tester).maxScrollExtent, greaterThan(0.0));
    await _expectEveryCardReachable(tester, canvas, 'tiny at 1.5');
    expectNoOverflow(tester);
  });

  testWidgets('card region does not scroll at the reference canvas', (
    tester,
  ) async {
    // Arrange / Act
    await _pumpResponsiveScreen(tester, canvas: specReferenceCanvas);

    // Assert
    expect(_cardScroll(tester).maxScrollExtent, 0.0);
    expectNoOverflow(tester);
  });

  testWidgets('NEXT button never overlaps the card region', (tester) async {
    for (final MapEntry(key: name, value: canvas) in specCanvases.entries) {
      // Arrange / Act
      await _pumpResponsiveScreen(tester, canvas: canvas);

      // Assert: the reserve and the bar read one inset, so the scrollable
      // region always stops above the button.
      final region = tester.getRect(find.byType(Scrollable).first);
      expect(
        region.bottom,
        lessThanOrEqualTo(_nextButton(tester).top),
        reason: name,
      );
    }
  });

  testWidgets('bottom bar clears a 34pt home indicator', (tester) async {
    // Arrange / Act
    await _pumpResponsiveScreen(
      tester,
      canvas: specReferenceCanvas,
      padding: const EdgeInsets.only(bottom: 34),
    );

    // Assert
    expect(
      specReferenceCanvas.height - _nextButton(tester).bottom,
      greaterThanOrEqualTo(34.0),
    );
  });

  testWidgets('the three cards undulate rather than pump together', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 1500));

    final lifts = [for (var i = 0; i < _cardCount; i++) _liftOf(tester, i)];

    expect(lifts.toSet(), hasLength(_cardCount));
    for (final lift in lifts) {
      expect(lift, inInclusiveRange(-9.0, 0.0));
    }
  });

  testWidgets('each card cuts exactly one corner, rotating down the stack', (
    tester,
  ) async {
    await _pumpScreen(tester);

    final radii = [
      for (var i = 0; i < _cardCount; i++)
        tester.widget<StepCard>(find.byType(StepCard).at(i)).radius,
    ];

    expect(radii[0].bottomRight, _cutRadius);
    expect(radii[1].bottomLeft, _cutRadius);
    expect(radii[2].topLeft, _cutRadius);

    for (final radius in radii) {
      final corners = [
        radius.topLeft,
        radius.topRight,
        radius.bottomRight,
        radius.bottomLeft,
      ];
      expect(corners.where((c) => c == _cutRadius), hasLength(1));
    }
  });

  testWidgets('the entrance settles every element at full opacity', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(_opacityOf(tester, find.text('SKIP')), lessThan(1.0));

    await tester.pump(_enter);

    for (final finder in [
      find.text('SKIP'),
      find.text('THREE\nSECONDS.'),
      find.text('THAT IS THE WHOLE PRODUCT'),
      find.text('NEXT'),
      find.byType(StepCard).at(2),
    ]) {
      expect(_opacityOf(tester, finder), 1.0);
    }
  });

  testWidgets('reduced motion holds the cards flat and fades everything once', (
    tester,
  ) async {
    await _pumpScreen(tester, disableAnimations: true);
    await tester.pump(const Duration(milliseconds: 200));

    for (var i = 0; i < _cardCount; i++) {
      expect(_liftOf(tester, i), 0.0, reason: 'card $i');
      expect(_opacityOf(tester, find.byType(StepCard).at(i)), 1.0);
    }

    // Still flat once the rise loop would otherwise have moved them.
    await tester.pump(const Duration(seconds: 2));
    expect(_liftOf(tester, 0), 0.0);
  });

  testWidgets('the two exits report separately', (tester) async {
    var next = 0;
    var skipped = 0;
    await _pumpScreen(tester, onNext: () => next++, onSkip: () => skipped++);
    await tester.pump(_enter);

    await tester.tap(find.text('NEXT'));
    await tester.tap(find.text('SKIP'));

    expect([next, skipped], [1, 1]);
  });

  testWidgets('tapping a card is feedback, not navigation', (tester) async {
    var next = 0;
    var skipped = 0;
    await _pumpScreen(tester, onNext: () => next++, onSkip: () => skipped++);
    await tester.pump(_enter);

    await tester.tap(find.byType(StepCard).first);
    await tester.pump(const Duration(milliseconds: 60));

    expect([next, skipped], [0, 0]);

    // Let the press settle so no timers outlive the test.
    await tester.pump(const Duration(milliseconds: 300));
  });
}
