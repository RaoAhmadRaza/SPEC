import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/settings/settings_screen.dart';

import '../support/fonts.dart';

const _canvas = Size(402, 874);

/// Counts each callback so a test can say which ran, and how often.
class _Taps {
  int back = 0;
  int export = 0;
  int restore = 0;
  int delete = 0;
}

Future<_Taps> _pump(
  WidgetTester tester, {
  String? status,
  bool isBusy = false,
  bool isMotionReduced = false,
}) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final taps = _Taps();
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: _canvas, disableAnimations: isMotionReduced),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SettingsScreen(
          version: 'SPEC 1.0.0 (1)',
          counts: '41 OBJECTS · 96 PHOTOS',
          status: status,
          isBusy: isBusy,
          onBack: () => taps.back++,
          onExport: () => taps.export++,
          onRestore: () => taps.restore++,
          onDeleteEverything: () => taps.delete++,
        ),
      ),
    ),
  );
  return taps;
}

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('shows title, counts, privacy, actions and version', (
    tester,
  ) async {
    // Arrange / Act
    await _pump(tester);
    await tester.pumpAndSettle();

    // Assert
    for (final text in [
      'SETTINGS',
      '41 OBJECTS · 96 PHOTOS',
      'NO ACCOUNT',
      'NO CLOUD',
      'STAYS ON THIS PHONE',
      'NO TRACKING',
      'EXPORT BACKUP',
      'RESTORE FROM BACKUP',
      'DELETE EVERYTHING',
      'SPEC 1.0.0 (1)',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long status fits the canvas without overflow', (tester) async {
    // Arrange / Act
    await _pump(
      tester,
      status:
          'This backup is from a newer version of SPEC. Update SPEC and '
          'try again.',
    );
    await tester.pumpAndSettle();

    // Assert
    expect(tester.takeException(), isNull);
    final version = tester.getRect(find.text('SPEC 1.0.0 (1)'));
    expect(version.bottom, lessThanOrEqualTo(_canvas.height));
  });

  testWidgets('each action calls its own callback', (tester) async {
    // Arrange
    final taps = await _pump(tester);
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('EXPORT BACKUP'));
    await tester.tap(find.text('RESTORE FROM BACKUP'));
    await tester.tap(find.text('DELETE EVERYTHING'));
    await tester.tap(find.bySemanticsLabel('Back'));

    // Assert
    expect([taps.export, taps.restore, taps.delete, taps.back], [1, 1, 1, 1]);
  });

  testWidgets('actions ignore taps while busy', (tester) async {
    // Arrange
    final taps = await _pump(tester, isBusy: true);
    await tester.pumpAndSettle();

    // Act
    for (final label in [
      'EXPORT BACKUP',
      'RESTORE FROM BACKUP',
      'DELETE EVERYTHING',
    ]) {
      await tester.tap(find.text(label), warnIfMissed: false);
    }

    // Assert
    expect([taps.export, taps.restore, taps.delete], [0, 0, 0]);
  });

  testWidgets('reduced motion renders the finished page on the first frame', (
    tester,
  ) async {
    // Arrange / Act
    await _pump(tester, isMotionReduced: true);

    // Assert: no frames pumped, yet nothing is still fading in.
    final opacities = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .map((o) => o.opacity);
    expect(opacities, everyElement(1.0));
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
