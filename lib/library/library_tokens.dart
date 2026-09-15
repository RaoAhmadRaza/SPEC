import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// Screen 07's own surfaces, lifted from `SPEC Screens.dc.html`.
///
/// The step pill, `CANCEL`, the search pill's shell and the lime button are
/// Search's, and are reused from there rather than restated.
abstract final class LibraryColors {
  /// Unselected filter chips: `rgba(255,255,255,0.05)` on `0.14`.
  static const chipFill = Color(0x0DFFFFFF);
  static const chipBorder = Color(0x24FFFFFF);

  /// The selected chip keeps a border the colour of its fill, so the two
  /// states have identical geometry and the row never reflows.
  static const chipBorderSelected = Color(0x00D7FF3E);

  /// The rule above the grid, heavier than Search's.
  static const ruleStrong = Color(0x24FFFFFF);

  /// Library thumbs.
  static const thumbBorder = Color(0x1FFFFFFF);

  /// The floating `ADD YOUR OWN` bar.
  static const barFill = Color(0x14FFFFFF);
  static const barBorder = Color(0x29FFFFFF);
  static const barHighlight = Color(0x38FFFFFF);
  static const barShadow = Color(0x8C000000);

  /// `SHOW ALL`, a lime outline rather than a lime fill.
  static const showAllFill = Color(0x14D7FF3E);
  static const showAllBorder = Color(0x66D7FF3E);
}

/// Letter spacing is absolute points, so the design's `em` values are
/// pre-multiplied by their font size.
abstract final class LibraryText {
  /// 52pt / 700 / -0.05em.
  static const headline = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 52,
    height: 0.9,
    letterSpacing: -2.60,
    color: SpecColors.ink,
  );

  /// 16pt, the placeholder.
  static const hint = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 16,
    color: SpecColors.ink60,
  );

  /// 16pt / 500, the query.
  static const query = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: SpecColors.ink,
  );

  /// 10pt / 0.18em.
  static const chip = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 1.80,
    color: SpecColors.ink70,
  );

  static const chipSelected = TextStyle(
    fontFamily: SpecFonts.mono,
    fontWeight: FontWeight.w500,
    fontSize: 10,
    letterSpacing: 1.80,
    color: SpecColors.onAccent,
  );

  /// 10pt / 0.22em, `LIBRARY · 100 OBJECTS`.
  static const ruleCount = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2.20,
    color: SpecColors.ink70,
  );

  /// 10pt / 0.18em, `OFFLINE`.
  static const offline = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 1.80,
    color: SpecColors.ink62,
  );

  /// 13pt / -0.01em.
  static const itemName = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 13,
    letterSpacing: -0.13,
    color: SpecColors.ink,
  );

  /// 9pt / 0.14em.
  static const itemSpec = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9,
    letterSpacing: 1.26,
    color: SpecColors.ink62,
  );

  /// 14.5pt.
  static const barPrompt = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 14.5,
    color: SpecColors.ink78,
  );

  /// 11pt / 500 / 0.16em.
  static const addOwn = TextStyle(
    fontFamily: SpecFonts.mono,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    letterSpacing: 1.76,
    color: SpecColors.onAccent,
  );

  /// 42pt / 700 / -0.05em.
  static const emptyTitle = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 42,
    height: 0.92,
    letterSpacing: -2.10,
    color: SpecColors.ink,
  );

  /// 10pt / 0.18em in lime.
  static const showAll = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 1.80,
    color: SpecColors.accent,
  );
}
