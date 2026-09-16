import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/object/object_viewer.dart';

/// A 1 × 1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]);

void main() {
  testWidgets('shows the whole photo rather than cropping it to fill', (
    tester,
  ) async {
    late NavigatorState navigator;
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, _) => Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (context, _, _) {
              navigator = Navigator.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    unawaited(
      navigator.push(
        PhotoViewerRoute(
          photo: MemoryImage(_png),
          origin: const Rect.fromLTWH(20, 300, 200, 158),
          originRadius: ObjectMetrics.mainPhotoRadius,
          isMotionReduced: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final images = tester.widgetList<Image>(
      find.descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(Image),
      ),
    );
    expect(images, isNotEmpty);
    for (final image in images) {
      expect(image.fit, BoxFit.contain);
    }
  });
}
