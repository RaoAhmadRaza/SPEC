import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The canvases a responsive test sweeps.
///
/// `ref` is the 402x874 canvas every existing test already pins, so a sweep
/// that includes it re-runs the layout the screens were drawn against.
const specCanvases = <String, Size>{
  'tiny': Size(320, 568),
  'small': Size(375, 667),
  'ref': Size(402, 874),
  'large': Size(430, 932),
  'tabletPortrait': Size(810, 1080),
  'tabletLandscape': Size(1280, 800),
};

/// The canvas the design was authored on.
const specReferenceCanvas = Size(402, 874);

/// Pumps [child] on [canvas] with the device conditions a screen has to
/// survive: a real safe-area [padding], a system [textScale], and motion
/// either on or off.
///
/// Mirrors what each screen's own `_pump` helper already does, so a
/// responsive test and an existing test see the same widget tree.
Future<void> pumpResponsive(
  WidgetTester tester,
  Widget child, {
  Size canvas = specReferenceCanvas,
  EdgeInsets padding = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
  double textScale = 1.0,
  bool disableAnimations = true,
}) async {
  tester.view
    ..physicalSize = canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: canvas,
        padding: padding,
        viewPadding: padding,
        viewInsets: viewInsets,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    ),
  );
}

/// Fails if the pump recorded a layout overflow.
///
/// A caveat worth knowing before trusting this alone: a `RenderFlex` overflow
/// is reported at paint time through `FlutterError`, and the test binding
/// keeps only the first such exception. So this catches *that* there was an
/// overflow, not how many. It also cannot see a layout that stays inside its
/// own box while running off the canvas — for that, measure the subject
/// against the canvas the way `test/settings/settings_screen_test.dart` does
/// ("a long status fits the canvas without overflow").
void expectNoOverflow(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception == null) return;
  final text = exception.toString();
  fail(
    text.contains('overflowed by')
        ? 'Layout overflowed: $text'
        : 'Unexpected exception during pump: $text',
  );
}
