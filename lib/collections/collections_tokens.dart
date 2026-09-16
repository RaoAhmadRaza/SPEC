import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// Screen 06's own surfaces, lifted from `SPEC Screens.dc.html`.
abstract final class CollectionsColors {
  /// The `SPEC` pill, a shade brighter than the `EDIT` pill beside it.
  static const specPillFill = Color(0x12FFFFFF);
  static const specPillBorder = Color(0x29FFFFFF);
  static const editPillFill = Color(0x0FFFFFFF);
  static const editPillBorder = Color(0x24FFFFFF);

  /// `DONE`'s border, the same lime outline `EXPORT` wears.
  static const limeOutline = Color(0x66D7FF3E);
  static const limeFill = Color(0x14D7FF3E);

  /// `EXPORT`'s fill at the peak of its tap flash.
  static const limeFlash = Color(0x33D7FF3E);

  /// Above the first zone row, and between the rows.
  static const ruleStrong = Color(0x29FFFFFF);
  static const hairline = Color(0x14FFFFFF);

  static const thumbBorder = Color(0x24FFFFFF);

  /// `+ NEW ZONE`.
  static const chipFill = Color(0x0DFFFFFF);
  static const chipBorder = Color(0x24FFFFFF);

  /// A zone row's background while pressed.
  static const rowPress = Color(0x0AFFFFFF);

  /// The ghost rows of the empty state.
  static const ghostName = Color(0x47F5F6F7);
  static const ghostCount = Color(0x33F5F6F7);

  /// The rename and new-zone fields' underline.
  static const fieldUnderline = Color(0x4DFFFFFF);

  /// The `×` circle beside each row in edit mode.
  static const removeBorder = Color(0x33FFFFFF);

  /// The lifted row's shadow while it is dragged.
  static const liftShadow = Color(0x8C000000);
}

/// Letter spacing is absolute points, so the design's `em` values are
/// pre-multiplied by their font size.
abstract final class CollectionsText {
  /// 10.5pt / 0.24em.
  static const editPill = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10.5,
    letterSpacing: 2.52,
    color: SpecColors.ink70,
  );

  /// 54pt / 700 / -0.05em.
  static const title = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 54,
    height: 0.9,
    letterSpacing: -2.70,
    color: SpecColors.ink,
  );

  /// 10pt / 0.22em, the totals column.
  static const totals = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    height: 1.9,
    letterSpacing: 2.20,
    color: SpecColors.ink62,
  );

  /// 26pt / 500 / -0.035em.
  static const zoneName = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: 26,
    height: 1,
    letterSpacing: -0.91,
    color: SpecColors.ink,
  );

  /// 9.5pt / 0.16em.
  static const zoneSpecs = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 1.52,
    color: SpecColors.ink62,
  );

  /// 15pt mono.
  static const zoneCount = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 15,
    color: SpecColors.ink60,
  );

  /// 10pt / 0.20em.
  static const chip = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2.00,
    color: SpecColors.ink62,
  );

  /// 42pt / 600 / -0.05em.
  static const emptyTitle = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 42,
    height: 0.92,
    letterSpacing: -2.10,
    color: SpecColors.ink,
  );

  static const emptyBody = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 15,
    height: 1.5,
    color: SpecColors.ink70,
  );

  /// The inline delete confirmation, the size of the chips.
  static const confirm = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2.00,
    color: SpecColors.accent,
  );

  static const remove = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 14,
    height: 1,
    color: SpecColors.ink70,
  );
}
