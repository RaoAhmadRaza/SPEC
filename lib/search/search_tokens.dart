import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// Screen 02's own surfaces, lifted from `SPEC Screens.dc.html`.
///
/// The ink levels live in [SpecColors] with every other one; what is here is
/// the handful of fills, borders and rules that only Search draws.
abstract final class SearchColors {
  /// The `SPEC` pill: `rgba(255,255,255,0.07)` on `rgba(255,255,255,0.16)`.
  static const specPillFill = Color(0x12FFFFFF);
  static const specPillBorder = Color(0x29FFFFFF);

  /// `CANCEL` sits a shade behind it.
  static const cancelFill = Color(0x0FFFFFFF);
  static const cancelBorder = Color(0x24FFFFFF);

  /// The search pill's two border states. The Hero flight lerps between them,
  /// which is how focus reads as the lime arriving.
  static const pillBorderFocused = Color(0x80D7FF3E);
  static const pillBorderBlurred = Color(0x33FFFFFF);

  static const pillTop = Color(0x29FFFFFF);
  static const pillBottom = Color(0x12FFFFFF);
  static const pillHighlight = Color(0x4DFFFFFF);
  static const pillShadow = Color(0x73000000);

  /// The count row's bottom border, heavier than the list's dividers.
  static const rule = Color(0x1AFFFFFF);

  /// Between results, and under each zone row.
  static const hairline = Color(0x12FFFFFF);

  /// Result thumbs: a flat tile, never an icon or a label.
  static const thumbBorder = Color(0x24FFFFFF);

  /// Recent query chips carry a border and no fill.
  static const chipBorder = Color(0x1FFFFFFF);

  /// `0 14 34 rgba(215,255,62,0.20)` under the lime call to action.
  static const buttonShadow = Color(0x33D7FF3E);

  /// The flash a row shows while it is held, before it opens.
  static const rowPress = Color(0x0AFFFFFF);
}

/// Text styles unique to screen 02.
///
/// Letter spacing is absolute points in Flutter, so the design's `em` values
/// are pre-multiplied by their font size.
abstract final class SearchText {
  /// `SPEC` and `CANCEL` are metrically identical to two onboarding styles,
  /// so they are the same constants rather than copies that could drift.
  static const specPill = SpecText.pill;
  static const cancelPill = SpecText.skip;

  /// 10pt / 0.22em. Also the `RECENT` and `BROWSE BY ZONE` section labels.
  static const count = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2.20,
    color: SpecColors.ink62,
  );

  /// 10pt / 0.14em. A measurement, so it is dimmer than the count beside it.
  static const timing = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 1.40,
    color: SpecColors.ink55,
  );

  /// 17pt / 500, the query the user typed.
  static const query = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: 17,
    color: SpecColors.ink,
  );

  /// The placeholder sits one step behind the query.
  static const hint = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: 17,
    color: SpecColors.ink50,
  );

  /// 17pt / 500, a result's name and a zone row's name.
  static const name = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: 17,
    color: SpecColors.ink,
  );

  /// 10pt / 0.18em, `HOME · CEILING`.
  static const zone = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 1.80,
    color: SpecColors.ink62,
  );

  /// 26pt / 600 / -0.04em. The best match's copy of this is lime.
  static const spec = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 26,
    letterSpacing: -1.04,
    color: SpecColors.ink,
  );

  static const specBest = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 26,
    letterSpacing: -1.04,
    color: SpecColors.accent,
  );

  /// 10pt / 0.16em, a recent query.
  static const chip = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 1.60,
    color: SpecColors.ink60,
  );

  /// 42pt / 600 / -0.05em, the two-word empty headline.
  static const emptyTitle = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 42,
    height: 0.92,
    letterSpacing: -2.10,
    color: SpecColors.ink,
  );

  /// The body under it is the shared 15pt copy style.
  static const emptyBody = SpecText.bodyCopy;

  /// The lime button's label is metrically the onboarding one.
  static const button = SpecText.nextButton;

  /// 15pt mono, a zone's count on the browse list.
  static const zoneCount = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 15,
    color: SpecColors.ink60,
  );

  /// 9.5pt mono on lime, the scope chip inside the pill.
  static const scopeChip = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    color: SpecColors.onAccent,
  );

  /// The `×` that clears the scope.
  static const scopeClear = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 14,
    color: SpecColors.onAccent,
  );
}
