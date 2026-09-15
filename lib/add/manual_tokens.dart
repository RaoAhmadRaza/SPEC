import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// Screen 08, the add flow's "not in library" fallback, lifted 1:1 from
/// `SPEC Screens.dc.html`. The glass recipes here are the add flow's shared
/// chrome. The header, the search pill and the return bar's glass are
/// Search's and 07's, and are reused from there rather than restated.
abstract final class ManualColors {
  /// `rgba(255,255,255,0.16)`, heavier than a list divider.
  static const ruleStrong = Color(0x29FFFFFF);

  /// Field rows, at rest and focused. Only colour moves; geometry never does.
  static const fieldFill = Color(0x0FFFFFFF);
  static const fieldBorder = Color(0x24FFFFFF);
  static const fieldFillFocused = Color(0x17FFFFFF);
  static const fieldBorderFocused = Color(0x47FFFFFF);

  static const buttonDisabledFill = Color(0x1AFFFFFF);
}

abstract final class ManualText {
  /// 10pt / 0.22em.
  static const matches = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2.20,
    color: SpecColors.ink70,
  );

  /// 42pt / 700 / -0.05em.
  static const verdict = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 42,
    height: 0.92,
    letterSpacing: -2.10,
    color: SpecColors.ink,
  );

  static const body = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.5,
    color: SpecColors.ink68,
  );

  /// 10pt / 0.22em, fixed to a 56pt column by the row.
  static const fieldLabel = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2.20,
    color: SpecColors.ink62,
  );

  static const fieldValue = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: 17,
    color: SpecColors.ink,
  );

  static const fieldHint = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w400,
    fontSize: 17,
    color: SpecColors.ink60,
  );

  static const buttonDisabled = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    letterSpacing: 0.90,
    color: SpecColors.ink60,
  );

  /// 9.5pt / 0.18em. Advisory, one step dimmer than the privacy caption.
  static const noPhotoHint = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 1.71,
    color: SpecColors.ink60,
  );

  static const barLabel = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w400,
    fontSize: 14.5,
    color: SpecColors.ink80,
  );

  /// 11pt / 0.16em / 500 on lime.
  static const barPill = TextStyle(
    fontFamily: SpecFonts.mono,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    letterSpacing: 1.76,
    color: SpecColors.onAccent,
  );
}
