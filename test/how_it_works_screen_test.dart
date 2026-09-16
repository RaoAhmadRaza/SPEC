import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/onboarding/how_it_works_screen.dart';
import 'package:spec/onboarding/step_card.dart';

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

void main() {
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
