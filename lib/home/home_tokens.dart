import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// Home's own surfaces, lifted from screen 01 of `SPEC Screens.dc.html`.
///
/// The glass recipes differ from onboarding's by more than a shade — blur
/// radius, gradient and inner highlight all change — so they live here rather
/// than being forced into the shared tokens.
abstract final class HomeColors {
  /// The `SPEC` pill and the ••• circle.
  static const pillFill = Color(0x12FFFFFF);
  static const pillBorder = Color(0x29FFFFFF);
  static const dotsFill = Color(0x14FFFFFF);
  static const dotsBorder = Color(0x24FFFFFF);

  /// The search pill: a vertical gradient rather than a flat fill.
  static const searchBorder = Color(0x33FFFFFF);
  static const searchTop = Color(0x29FFFFFF);
  static const searchBottom = Color(0x12FFFFFF);
  static const searchHighlight = Color(0x4DFFFFFF);
  static const searchUnderline = Color(0x1AFFFFFF);
  static const searchShadow = Color(0x73000000);

  /// Category chips and the `+` circle beside them.
  static const chipFill = Color(0x0FFFFFFF);
  static const chipBorder = Color(0x24FFFFFF);

  /// The mono rule under the side column.
  static const sideRule = Color(0x47FFFFFF);

  /// Object tiles.
  static const cardBorder = Color(0x1AFFFFFF);
  static const zoneChipFill = Color(0x1AFFFFFF);
  static const zoneChipBorder = Color(0x33FFFFFF);
  static const cardDotsFill = Color(0x1FFFFFFF);
  static const arrowBorder = Color(0x47FFFFFF);

  /// The add card's lime `+` disc.
  static const addDiscFill = Color(0x1AFFFFFF);
  static const addDiscBorder = Color(0x33FFFFFF);

  /// Diagonal scrim over a card's photo, dark corner first.
  static const scrimNear = Color(0xF208090A);
  static const scrimNearSoft = Color(0xF008090A);
  static const scrimMid = Color(0x9908090A);
  static const scrimMidSoft = Color(0x8C08090A);
  static const scrimFar = Color(0x1A08090A);
  static const scrimFarSoft = Color(0x3308090A);

  /// The floating tab bar and the orb raised out of it.
  static const barFill = Color(0x14FFFFFF);
  static const barBorder = Color(0x29FFFFFF);
  static const barHighlight = Color(0x38FFFFFF);
  static const barShadow = Color(0x8C000000);
  static const orbBorder = Color(0x47FFFFFF);
  static const orbInner = Color(0x6BFFFFFF);
  static const orbMid = Color(0x24FFFFFF);
  static const orbOuter = Color(0x14FFFFFF);
  static const orbHighlight = Color(0x73FFFFFF);
  static const orbShadow = Color(0x99000000);

  /// The hairline that fades in once the content has scrolled.
  static const scrollHairline = Color(0x1AFFFFFF);

  /// Rules under the two mono side notes, and beside the numbered steps.
  static const noteRule = Color(0x33FFFFFF);

  /// The outlined lime call to action.
  static const firstItemGlow = Color(0x24D7FF3E);
  static const firstItemFill = Color(0x05D7FF3E);
}

/// Text styles unique to screen 01. Letter spacing is absolute points, so the
/// design's `em` values are pre-multiplied by their font size.
abstract final class HomeText {
  /// 72pt / 700 / -0.045em.
  static const wordmark = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 72,
    height: 0.86,
    letterSpacing: -3.24,
    color: SpecColors.ink,
  );

  static const trademark = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 11,
    color: SpecColors.ink75,
  );

  /// 11.5pt / 0.24em.
  static const tagline = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 11.5,
    height: 1.85,
    letterSpacing: 2.76,
    color: SpecColors.ink72,
  );

  /// 9.5pt / 0.24em, the LOCAL · PRIVATE · YOURS column.
  static const sideColumn = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 2.28,
    color: SpecColors.ink62,
  );

  static const sideColumnAccent = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 2.28,
    color: SpecColors.accent,
  );

  /// 17pt, the search placeholder.
  static const searchHint = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 17,
    color: SpecColors.ink60,
  );

  /// 13pt / 500, a category chip's name.
  static const categoryName = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.15,
    color: SpecColors.ink,
  );

  /// 9pt mono, a category chip's count.
  static const categoryCount = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9,
    height: 1.15,
    color: SpecColors.ink62,
  );

  /// 10.5pt / 0.24em.
  static const sectionRule = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10.5,
    letterSpacing: 2.52,
    color: SpecColors.ink70,
  );

  /// 10.5pt / 0.18em.
  static const seeAll = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10.5,
    letterSpacing: 1.89,
    color: SpecColors.ink60,
  );

  /// 9.5pt / 0.22em, a card's zone chip.
  static const zoneChip = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 2.09,
    color: SpecColors.ink,
  );

  /// 32pt / 600 / -0.04em, the hero spec.
  static const cardSpec = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 32,
    height: 0.9,
    letterSpacing: -1.28,
    color: SpecColors.ink,
  );

  /// 27pt when the spec needs two lines.
  static const cardSpecTall = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 27,
    height: 0.95,
    letterSpacing: -1.08,
    color: SpecColors.ink,
  );

  /// 9.5pt / 0.20em, the attribute lines under the spec.
  static const cardSub = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    height: 1.6,
    letterSpacing: 1.90,
    color: SpecColors.ink78,
  );

  /// 12pt, the object's name.
  static const cardName = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 12,
    color: SpecColors.ink85,
  );

  /// 19pt / 600 / -0.03em.
  static const addTitle = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 19,
    letterSpacing: -0.57,
    color: SpecColors.ink,
  );

  static const addBody = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 12.5,
    height: 1.5,
    color: SpecColors.ink68,
  );

  /// 15pt / 500, the active tab.
  static const tabActive = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    color: SpecColors.ink,
  );

  static const tabIdle = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 15,
    color: SpecColors.ink72,
  );

  /// The `+` glyphs, which are text rather than icons in the design.
  static const plusSmall = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 20,
    color: SpecColors.ink80,
  );

  static const plusAccent = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 24,
    color: SpecColors.accent,
  );

  static const plusOrb = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 30,
    color: SpecColors.ink,
  );

  /// 9pt / 0.20em, the mono notes flanking the collage.
  static const note = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9,
    height: 1.9,
    letterSpacing: 1.80,
    color: SpecColors.ink62,
  );

  /// 24pt / 600 / -0.02em, the empty state's headline.
  static const emptyTitle = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    letterSpacing: -0.48,
    color: SpecColors.ink,
  );

  static const emptyBody = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 13,
    height: 1.5,
    color: SpecColors.ink68,
  );

  /// 11pt / 0.20em, the label inside the lime pill.
  static const firstItem = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10.5,
    letterSpacing: 2.00,
    color: SpecColors.ink,
  );

  /// The step numbers, a shade behind their labels.
  static const stepNumber = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    height: 2.0,
    letterSpacing: 1.71,
    color: SpecColors.ink45,
  );

  static const stepLabel = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    height: 2.0,
    letterSpacing: 1.71,
    color: SpecColors.ink70,
  );

  /// 10.5pt / 0.18em, NO ZONES YET.
  static const hint = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10.5,
    height: 2.0,
    letterSpacing: 1.89,
    color: SpecColors.ink62,
  );
}
