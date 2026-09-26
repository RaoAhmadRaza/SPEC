import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/object/object_parts.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/settings/settings_parts.dart';
import 'package:spec/settings/settings_screen.dart';
import 'package:spec/theme/spec_layout.dart';

import '../support/fonts.dart';
import '../support/responsive.dart';

const _canvas = Size(402, 874);
const _counts = ArchiveCounts(objects: 41, photos: 96);

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
          counts: _counts,
          storage: '2.1 MB',
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

const _longStatus =
    'This backup is from a newer version of SPEC. Update SPEC and try again.';

Future<void> _pumpResponsiveSettings(
  WidgetTester tester, {
  required Size canvas,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1.0,
  String? status,
}) async {
  await pumpResponsive(
    tester,
    SettingsScreen(
      version: 'SPEC 1.0.0 (1)',
      counts: _counts,
      storage: '2.1 MB',
      status: status,
      isBusy: false,
      onBack: () {},
      onExport: () {},
      onRestore: () {},
      onDeleteEverything: () {},
    ),
    canvas: canvas,
    padding: padding,
    textScale: textScale,
  );
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

ScrollPosition _pageScroll(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

const _pillLabels = [
  'EXPORT BACKUP',
  'RESTORE FROM BACKUP',
  'DELETE EVERYTHING',
];

void main() {
  setUpAll(loadSpecFonts);

  group('responsive', () {
    testWidgets('does not throw at text scale 1.5 on a tiny screen', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveSettings(
        tester,
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
        status: _longStatus,
      );

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('matches the design at the reference canvas', (tester) async {
      // Arrange / Act
      await _pumpResponsiveSettings(tester, canvas: specReferenceCanvas);

      // Assert: cards and pills share the 22pt margin and fill the column,
      // and the page fits without scrolling.
      const width = 402.0 - 22 * 2;
      for (final card in tester.widgetList(find.byType(SettingsCard))) {
        final rect = tester.getRect(find.byWidget(card));
        expect(rect.left, 22.0);
        expect(rect.width, width);
      }
      expect(_pageScroll(tester).maxScrollExtent, 0.0);
      expect(
        tester.getRect(find.widgetWithText(SettingsCard, 'BACKUP')).height,
        closeTo(74.0, 1.5),
      );
      expect(
        tester.getRect(find.widgetWithText(SettingsCard, 'ABOUT')).height,
        closeTo(57.0, 1.5),
      );
    });

    testWidgets('content scrolls when it does not fit', (tester) async {
      // Arrange / Act
      await _pumpResponsiveSettings(
        tester,
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
        status: _longStatus,
      );

      // Assert
      expect(_pageScroll(tester).maxScrollExtent, greaterThan(0.0));
    });

    testWidgets('cards carry no chevron and centre their reading', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveSettings(tester, canvas: specReferenceCanvas);

      // Assert: back is the only circle, and chevrons belong to the three
      // pills only.
      expect(find.byType(GlassCircle), findsOneWidget);
      expect(find.byType(SettingsChevron), findsNWidgets(3));
      for (final (label, value) in [
        ('BACKUP', 'OFF'),
        ('ON THIS PHONE', '41'),
        ('PHOTOS', '96'),
        ('STORAGE', '2.1 MB'),
      ]) {
        final card = tester.getRect(find.widgetWithText(SettingsCard, label));
        final reading = tester.getRect(find.text(value));
        expect(reading.center.dy, closeTo(card.center.dy, 0.5), reason: label);
        expect(card.right - reading.right, 17.0, reason: label);
      }
    });

    testWidgets('title shrinks rather than clips on a tiny screen at 1.5', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveSettings(
        tester,
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Assert
      final title = tester.getRect(find.byType(FittedBox).first);
      expect(title.right, lessThanOrEqualTo(320.0 - 22));
      expectNoOverflow(tester);
    });

    testWidgets('action pills span the content column', (tester) async {
      // Arrange / Act
      await _pumpResponsiveSettings(tester, canvas: specReferenceCanvas);

      // Assert: 38pt drawn, 44pt of touch target.
      for (final label in _pillLabels) {
        final pill = tester.getRect(find.widgetWithText(SettingsPill, label));
        expect(pill.left, 22.0, reason: label);
        expect(pill.width, 402.0 - 22 * 2, reason: label);
        expect(pill.height, 44.0, reason: label);
      }
    });

    testWidgets('RESTORE FROM BACKUP does not clip at text scale 1.5', (
      tester,
    ) async {
      // Arrange / Act
      await _pumpResponsiveSettings(
        tester,
        canvas: specCanvases['tiny']!,
        textScale: 1.5,
      );

      // Assert
      expect(find.text('RESTORE FROM BACKUP'), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('content is capped and centred on a landscape tablet', (
      tester,
    ) async {
      // Arrange
      final canvas = specCanvases['tabletLandscape']!;

      // Act
      await _pumpResponsiveSettings(tester, canvas: canvas);

      // Assert
      final title = tester.getRect(find.text('SETTINGS'));
      expect(title.left, greaterThan(18.0));
      final rule = tester.getRect(find.byType(SettingsRule).first);
      expect(rule.width, lessThanOrEqualTo(SpecLayout.maxContentWidth));
      expect(rule.center.dx, closeTo(canvas.width / 2, 0.5));
    });

    testWidgets('content clears a 34pt home indicator and a 59pt Dynamic '
        'Island', (tester) async {
      // Arrange / Act
      await _pumpResponsiveSettings(
        tester,
        canvas: specReferenceCanvas,
        padding: const EdgeInsets.only(top: 59, bottom: 34),
      );

      // Assert
      expect(
        tester.getRect(find.byType(GlassCircle).first).top,
        greaterThanOrEqualTo(59.0),
      );
      expect(
        specReferenceCanvas.height -
            tester.getRect(find.text('SPEC 1.0.0 (1)')).bottom,
        greaterThanOrEqualTo(34.0),
      );
    });
  });

  testWidgets('shows title, counts, cards, actions and version', (
    tester,
  ) async {
    // Arrange / Act
    await _pump(tester);
    await tester.pumpAndSettle();

    // Assert
    for (final text in [
      'SETTINGS',
      '41 OBJECTS · 96 PHOTOS',
      'BACKUP',
      'OFF',
      'ON THIS PHONE',
      '41',
      'PHOTOS',
      '96',
      'STORAGE',
      '2.1 MB',
      'ABOUT',
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
    await tester.tap(find.text('BACKUP'));

    // Assert: the Backup card exports too.
    expect([taps.export, taps.restore, taps.delete, taps.back], [2, 1, 1, 1]);
  });

  testWidgets('actions ignore taps while busy', (tester) async {
    // Arrange
    final taps = await _pump(tester, isBusy: true);
    await tester.pumpAndSettle();

    // Act
    for (final label in [..._pillLabels, 'BACKUP']) {
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
