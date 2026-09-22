import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/main.dart';
import 'package:spec/onboarding/welcome_screen.dart';
import 'package:spec/theme/spec_layout.dart';

import '../support/database.dart';
import '../support/fonts.dart';
import '../support/prefs.dart';
import '../support/responsive.dart';

/// The Library grid's own numbers: an 18pt side margin on the 402pt reference
/// canvas, three columns of roughly 116pt.
const _libraryAvailable = 402.0 - 18 * 2;
const _libraryCell = 116.0;
const _libraryColumns = 3;

/// Pumps a probe on [canvas] and hands its [BuildContext] to [read].
Future<T> _read<T>(
  WidgetTester tester,
  T Function(BuildContext context) read, {
  Size canvas = specReferenceCanvas,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  late T value;
  await pumpResponsive(
    tester,
    Builder(
      builder: (context) {
        value = read(context);
        return const SizedBox.shrink();
      },
    ),
    canvas: canvas,
    padding: padding,
  );
  return value;
}

void main() {
  setUpAll(loadSpecFonts);
  setUp(useInMemoryPrefs);

  testWidgets('topInset returns the design constant when padding is zero', (
    tester,
  ) async {
    // Arrange / Act
    final inset = await _read(
      tester,
      (context) => SpecLayout.topInset(context, design: 56),
    );

    // Assert
    expect(inset, 56);
  });

  testWidgets('topInset returns padding plus the gap when it exceeds the '
      'design constant', (tester) async {
    // Arrange / Act
    final inset = await _read(
      tester,
      (context) => SpecLayout.topInset(context, design: 56),
      padding: const EdgeInsets.only(top: 59),
    );

    // Assert
    expect(inset, 59 + SpecLayout.minTopGap);
  });

  testWidgets('bottomInset returns padding plus the gap when it exceeds the '
      'design constant', (tester) async {
    // Arrange / Act
    final inset = await _read(
      tester,
      (context) => SpecLayout.bottomInset(context, design: 44),
      padding: const EdgeInsets.only(bottom: 34),
    );

    // Assert
    expect(inset, 34 + SpecLayout.minBottomGap);
  });

  testWidgets('isExpanded is false on a phone and true on a tablet in either '
      'orientation', (tester) async {
    // Arrange / Act
    final phone = await _read(
      tester,
      SpecLayout.isExpanded,
      canvas: specCanvases['large']!,
    );
    final portrait = await _read(
      tester,
      SpecLayout.isExpanded,
      canvas: specCanvases['tabletPortrait']!,
    );
    final landscape = await _read(
      tester,
      SpecLayout.isExpanded,
      canvas: specCanvases['tabletLandscape']!,
    );

    // Assert
    expect(phone, isFalse);
    expect(portrait, isTrue);
    expect(landscape, isTrue);
  });

  test('columnsFor returns the design column count at the reference width', () {
    // Arrange / Act
    final columns = SpecLayout.columnsFor(
      _libraryAvailable,
      idealCell: _libraryCell,
      min: 2,
      max: 6,
    );

    // Assert
    expect(columns, _libraryColumns);
  });

  test('columnsFor clamps to max on a very wide canvas', () {
    // Arrange / Act
    final columns = SpecLayout.columnsFor(
      2000,
      idealCell: _libraryCell,
      min: 2,
      max: 6,
    );

    // Assert
    expect(columns, 6);
  });

  testWidgets('contentWidth caps at maxContentWidth on a landscape tablet', (
    tester,
  ) async {
    // Arrange / Act
    final wide = await _read(
      tester,
      SpecLayout.contentWidth,
      canvas: specCanvases['tabletLandscape']!,
    );
    final phone = await _read(tester, SpecLayout.contentWidth);

    // Assert
    expect(wide, SpecLayout.maxContentWidth);
    expect(phone, specReferenceCanvas.width);
  });

  testWidgets('the app clamps a system text scale of 3.0 to maxTextScale', (
    tester,
  ) async {
    // Arrange
    tester.view
      ..physicalSize = specReferenceCanvas * 3
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // Act
    await tester.pumpWidget(withInMemoryDatabase(const SpecApp()));
    final scaler = MediaQuery.textScalerOf(
      tester.element(find.byType(WelcomeScreen)),
    );

    // Assert
    expect(scaler.scale(100), 100 * SpecLayout.maxTextScale);

    // Reminder sync holds a live query from launch; unmounting closes its
    // timer before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
