import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/object/object_action_bar.dart';

import '../support/fonts.dart';

/// The bar at the width the object screen gives it: the canvas less 18pt
/// either side.
Future<void> _pumpBar(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: width - 36,
            child: ObjectActionBar(
              editing: const AlwaysStoppedAnimation(0),
              pillPress: const AlwaysStoppedAnimation(1),
              ring: const AlwaysStoppedAnimation(0),
              onAction: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadSpecFonts);

  for (final (width, scale) in [(402.0, 1.0), (320.0, 1.0), (320.0, 1.5)]) {
    testWidgets('labels and pill sit on the bar centre line, REPLACED on one '
        'line, at ${width}pt × $scale', (tester) async {
      // Arrange / Act
      await _pumpBar(tester, width: width, textScale: scale);

      // Assert
      final bar = tester.getRect(find.byType(ObjectActionBar));
      for (final label in ['Edit', 'Share', 'REPLACED']) {
        expect(
          tester.getRect(find.text(label)).center.dy,
          closeTo(bar.center.dy, 0.5),
          reason: label,
        );
      }
      // SAVE is one short word and never wraps, so a REPLACED any taller has
      // broken onto a second line.
      expect(
        tester.getSize(find.text('REPLACED')).height,
        tester.getSize(find.text('SAVE')).height,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
