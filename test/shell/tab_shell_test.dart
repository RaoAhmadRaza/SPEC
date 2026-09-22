import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/home/home_tab_bar.dart';
import 'package:spec/home/home_tokens.dart';
import 'package:spec/shell/tab_shell.dart';
import 'package:spec/theme/spec_layout.dart';

import '../support/fonts.dart';
import '../support/responsive.dart';

const _canvas = Size(402, 874);

Future<void> _pumpFrames(WidgetTester tester, int count) async {
  // The orb breathes forever, so pumpAndSettle would never return.
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<List<(SpecTab, bool)>> _pump(
  WidgetTester tester, {
  VoidCallback? onAdd,
}) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final builds = <(SpecTab, bool)>[];
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: _canvas),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SpecTabShell(
          onAdd: onAdd,
          builder: (context, tab, isActive) {
            builds.add((tab, isActive));
            return Center(child: Text('root:${tab.name}'));
          },
        ),
      ),
    ),
  );
  await _pumpFrames(tester, 5);
  return builds;
}

Text _label(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label));

Future<void> _pumpResponsiveShell(
  WidgetTester tester, {
  required Size canvas,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1.0,
}) async {
  await pumpResponsive(
    tester,
    SpecTabShell(
      builder: (context, tab, isActive) =>
          Center(child: Text('root:${tab.name}')),
    ),
    canvas: canvas,
    padding: padding,
    textScale: textScale,
  );
  await _pumpFrames(tester, 5);
}

Rect _barRect(WidgetTester tester) => tester.getRect(find.byType(HomeTabBar));

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('chrome height is 112 at zero padding', (tester) async {
    // Arrange / Act
    await _pumpResponsiveShell(tester, canvas: specReferenceCanvas);

    // Assert: the literal Home and Collections used to carry.
    expect(
      specShellChromeHeight(tester.element(find.byType(HomeTabBar))),
      112.0,
    );
  });

  testWidgets('tab bar clears a 34pt home indicator', (tester) async {
    // Arrange / Act
    await _pumpResponsiveShell(
      tester,
      canvas: specReferenceCanvas,
      padding: const EdgeInsets.only(bottom: 34),
    );

    // Assert
    expect(
      specReferenceCanvas.height - _barRect(tester).bottom,
      greaterThanOrEqualTo(34.0),
    );
  });

  testWidgets('orb clears a 34pt home indicator', (tester) async {
    // Arrange / Act
    await _pumpResponsiveShell(
      tester,
      canvas: specReferenceCanvas,
      padding: const EdgeInsets.only(bottom: 34),
    );

    // Assert
    expect(
      specReferenceCanvas.height - tester.getRect(find.byType(HomeOrb)).bottom,
      greaterThanOrEqualTo(34.0),
    );
  });

  testWidgets('tab bar spans the full inset width on a phone', (tester) async {
    // Arrange / Act
    await _pumpResponsiveShell(tester, canvas: specReferenceCanvas);

    // Assert: the cap is a no-op below the expanded breakpoint.
    expect(
      _barRect(tester).width,
      specReferenceCanvas.width - 2 * kTabBarInset,
    );
  });

  testWidgets('tab bar is capped and centred on a landscape tablet', (
    tester,
  ) async {
    // Arrange
    final canvas = specCanvases['tabletLandscape']!;

    // Act
    await _pumpResponsiveShell(tester, canvas: canvas);

    // Assert
    final bar = _barRect(tester);
    expect(bar.width, lessThanOrEqualTo(SpecLayout.maxContentWidth));
    expect(bar.center.dx, closeTo(canvas.width / 2, 0.5));
  });

  testWidgets('tab labels do not clip at text scale 1.5', (tester) async {
    // Arrange / Act
    await _pumpResponsiveShell(
      tester,
      canvas: specCanvases['tiny']!,
      textScale: 1.5,
    );

    // Assert
    final bar = _barRect(tester);
    for (final label in ['Home', 'Collections']) {
      final rect = tester.getRect(find.text(label));
      expect(bar.contains(rect.topLeft), isTrue, reason: label);
      expect(bar.contains(rect.bottomRight), isTrue, reason: label);
    }
    expectNoOverflow(tester);
  });

  testWidgets('switching tabs keeps one bar and one orb with the same state', (
    tester,
  ) async {
    // Arrange
    await _pump(tester);
    final orbState = tester.state(find.byType(HomeOrb));

    // Act
    await tester.tap(find.text('Collections'));
    await _pumpFrames(tester, 30);

    // Assert
    expect(find.byType(HomeTabBar), findsOneWidget);
    expect(find.byType(HomeOrb), findsOneWidget);
    expect(tester.state(find.byType(HomeOrb)), same(orbState));
  });

  testWidgets('the active tab label cross-fades to the tapped tab', (
    tester,
  ) async {
    // Arrange
    await _pump(tester);

    // Act
    await tester.tap(find.text('Collections'));
    await _pumpFrames(tester, 20);

    // Assert
    expect(
      _label(tester, 'Collections').style!.fontWeight,
      HomeText.tabActive.fontWeight,
    );
    expect(_label(tester, 'Home').style!.color, HomeText.tabIdle.color);
  });

  testWidgets('only the current root is on stage once the switch ends', (
    tester,
  ) async {
    // Arrange
    final builds = await _pump(tester);

    // Act
    await tester.tap(find.text('Collections'));
    await _pumpFrames(tester, 30);

    // Assert
    expect(find.text('root:collections'), findsOneWidget);
    expect(find.text('root:home'), findsNothing, reason: 'offstage');
    expect(builds.last, (SpecTab.collections, true));
  });

  testWidgets('select brings a tab forward from inside a root', (tester) async {
    // Arrange
    tester.view
      ..physicalSize = _canvas * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: SpecTabShell(
          builder: (context, tab, isActive) => Center(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () => SpecTabShell.select(context, SpecTab.collections),
                child: Text('root:${tab.name}'),
              ),
            ),
          ),
        ),
      ),
    );
    await _pumpFrames(tester, 5);

    // Act
    await tester.tap(find.text('root:home'));
    await _pumpFrames(tester, 30);

    // Assert
    expect(find.text('root:collections'), findsOneWidget);
    expect(find.text('root:home'), findsNothing, reason: 'offstage');
  });

  testWidgets('tapping the orb asks to add exactly once', (tester) async {
    // Arrange
    var adds = 0;
    await _pump(tester, onAdd: () => adds++);

    // Act
    await tester.tap(find.byType(HomeOrb));
    await _pumpFrames(tester, 2);

    // Assert
    expect(adds, 1);
  });

  testWidgets("a hidden root's Heroes stay out of a push", (tester) async {
    // Arrange: both roots carry the same tag as the page pushed over them.
    tester.view
      ..physicalSize = _canvas * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: SpecTabShell(
          builder: (context, tab, isActive) =>
              const Hero(tag: 'dup', child: SizedBox(width: 40, height: 40)),
        ),
      ),
    );
    await _pumpFrames(tester, 5);

    // Act
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(
            MaterialPageRoute<void>(
              builder: (_) => const Hero(
                tag: 'dup',
                child: SizedBox(width: 80, height: 80),
              ),
            ),
          ),
    );
    await _pumpFrames(tester, 40);

    // Assert
    expect(tester.takeException(), isNull);
  });
}
