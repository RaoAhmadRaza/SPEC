import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/splash/splash_screen.dart';

const _master = Duration(milliseconds: 4500);
const _exit = Duration(milliseconds: 320);
const _warmupGrace = Duration(milliseconds: 3000);
final _warmupCap = _master + _warmupGrace;
const _frame = Duration(milliseconds: 16);

/// Handoffs land on frame boundaries, so allow a few frames of slack.
const _slack = Duration(milliseconds: 100);

/// Opacity applied to the nearest [Opacity] ancestor of a piece of text.
double _opacityOf(WidgetTester tester, String text) {
  final finder = find
      .ancestor(of: find.text(text), matching: find.byType(Opacity))
      .first;
  return tester.widget<Opacity>(finder).opacity;
}

Future<void> _pumpSplash(
  WidgetTester tester, {
  required VoidCallback onDone,
  Future<void>? warmup,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: SplashScreen(onDone: onDone, warmup: warmup),
    ),
  );
}

/// Pumps one frame at a time until [isDone], and reports how long that took.
/// Never use `pumpAndSettle`: the glow repeats forever.
Future<Duration?> _pumpUntilDone(
  WidgetTester tester,
  bool Function() isDone, {
  Duration budget = const Duration(seconds: 6),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < budget) {
    if (isDone()) return elapsed;
    await tester.pump(_frame);
    elapsed += _frame;
  }
  return null;
}

void main() {
  testWidgets('letters arrive left to right, not together', (tester) async {
    await _pumpSplash(tester, onDone: () {});

    // 0.286 of the master timeline: S (0.00-0.22) has landed, C (0.21-0.43)
    // is still on its way in.
    await tester.pump(_master * 0.286);

    expect(_opacityOf(tester, 'S'), 1.0);
    expect(_opacityOf(tester, 'C'), lessThan(1.0));
    expect(_opacityOf(tester, 'C'), greaterThan(0.0));
  });

  testWidgets('the four ghost specs never pulse in sync', (tester) async {
    await _pumpSplash(tester, onDone: () {});
    await tester.pump(_master * 0.5);

    final opacities = [
      _opacityOf(tester, 'B22'),
      _opacityOf(tester, '205/55 R16'),
      _opacityOf(tester, 'LT1000P'),
      _opacityOf(tester, '67XL'),
    ];

    expect(opacities.toSet(), hasLength(opacities.length));
    for (final opacity in opacities) {
      // Base ghost tint is 0.55, so the on-screen peak stays near 0.28.
      expect(opacity, lessThanOrEqualTo(0.5));
    }
  });

  testWidgets('a warm start still shows the full splash', (tester) async {
    var isDone = false;
    await _pumpSplash(tester, onDone: () => isDone = true);

    final elapsed = await _pumpUntilDone(tester, () => isDone);

    expect(elapsed, isNotNull);
    expect(elapsed, greaterThanOrEqualTo(_master + _exit));
    expect(elapsed, lessThan(_master + _exit + _slack));
  });

  testWidgets('a slow warmup extends the splash', (tester) async {
    final warmup = Completer<void>();
    var isDone = false;
    await _pumpSplash(
      tester,
      onDone: () => isDone = true,
      warmup: warmup.future,
    );

    await _pumpUntilDone(
      tester,
      () => isDone,
      budget: _master + _exit + _slack,
    );
    expect(isDone, isFalse);

    warmup.complete();
    final remaining = await _pumpUntilDone(tester, () => isDone);

    expect(remaining, isNotNull);
    expect(remaining, lessThan(_exit + _slack));
  });

  testWidgets('a warmup that never finishes cannot strand the splash', (
    tester,
  ) async {
    var isDone = false;
    await _pumpSplash(
      tester,
      onDone: () => isDone = true,
      warmup: Completer<void>().future,
    );

    final elapsed = await _pumpUntilDone(
      tester,
      () => isDone,
      budget: _warmupCap + _exit + _slack,
    );

    // The warmup is abandoned after _warmupCap, so the splash leaves anyway.
    expect(elapsed, isNotNull);
    expect(elapsed, greaterThanOrEqualTo(_warmupCap));
    expect(elapsed, lessThan(_warmupCap + _exit + _slack));
  });
}
