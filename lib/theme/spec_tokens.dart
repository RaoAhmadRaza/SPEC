import 'package:flutter/widgets.dart';

/// Design tokens for SPEC, lifted 1:1 from `SPEC Screens.dc.html`.
///
/// Alpha channels are the CSS `rgba()` fractions rounded to the nearest byte,
/// e.g. `0.72 * 255 = 184 = 0xB8`.
abstract final class SpecColors {
  static const bg = Color(0xFF0A0B0C);
  static const ink = Color(0xFFF5F6F7);
  static const ink90 = Color(0xE6F5F6F7);
  static const ink85 = Color(0xD9F5F6F7);
  static const ink75 = Color(0xBFF5F6F7);
  static const ink72 = Color(0xB8F5F6F7);
  static const ink80 = Color(0xCCF5F6F7);
  static const ink78 = Color(0xC7F5F6F7);
  static const ink70 = Color(0xB3F5F6F7);
  static const ink68 = Color(0xADF5F6F7);
  static const ink62 = Color(0x9EF5F6F7);
  static const ink60 = Color(0x99F5F6F7);
  static const ink55 = Color(0x8CF5F6F7);
  static const ink50 = Color(0x80F5F6F7);
  static const ink45 = Color(0x73F5F6F7);

  /// Base tint of the ghost specs. The pulse animation multiplies this.
  static const ghost = Color(0x8CF5F6F7);

  static const accent = Color(0xFFD7FF3E);

  /// Text and icons drawn on top of [accent].
  static const onAccent = Color(0xFF08090A);

  /// `box-shadow: 0 0 18px rgba(215,255,62,0.5)` on the lime rule.
  static const accentGlow = Color(0x80D7FF3E);

  /// Stops of the radial glow behind the wordmark. The mid stop sits above a
  /// straight linear falloff, which keeps the spread soft rather than ringed.
  static const glowInner = Color(0x2ED7FF3E);
  static const glowMid = Color(0x17D7FF3E);
  static const glowOuter = Color(0x00D7FF3E);

  /// Unfilled part of the progress hairline.
  static const track = Color(0x24FFFFFF);

  /// Inner stop of the welcome screen's glow, which is denser and smaller than
  /// the splash's.
  static const welcomeGlowInner = Color(0x29D7FF3E);

  /// Frosted surfaces: the header pill and the floating spec chips.
  static const pillFill = Color(0x12FFFFFF);
  static const pillBorder = Color(0x29FFFFFF);
  static const glassFill = Color(0x14FFFFFF);
  static const glassBorder = Color(0x2EFFFFFF);
  static const glassFaintFill = Color(0x0DFFFFFF);
  static const glassFaintBorder = Color(0x24FFFFFF);

  static const chipShadow = Color(0x80000000);
  static const limeChipShadow = Color(0x47D7FF3E);
  static const buttonShadow = Color(0x3DD7FF3E);

  /// Band that sweeps across the primary button.
  static const shinePeak = Color(0x8CFFFFFF);
  static const shinePeakSoft = Color(0x80FFFFFF);
  static const shineEdge = Color(0x00FFFFFF);

  /// Step cards. The lime one is a tinted variant of the same shell.
  static const cardFill = Color(0x0FFFFFFF);
  static const cardBorder = Color(0x24FFFFFF);
  static const cardShadow = Color(0x80000000);
  static const limeCardFill = Color(0x17D7FF3E);
  static const limeCardBorder = Color(0x8CD7FF3E);
  static const limeCardShadow = Color(0x29D7FF3E);

  /// The 64pt square that leads each step card.
  static const leadingFill = Color(0x0FFFFFFF);
  static const leadingBorder = Color(0x29FFFFFF);
  static const limeLeadingFill = Color(0x24D7FF3E);
  static const limeLeadingBorder = Color(0x66D7FF3E);

  /// The capture frame: a flat tile with lime brackets and pulsing rings.
  static const tile = Color(0xFF121416);
  static const frameBorder = Color(0x29FFFFFF);
  static const bracket = Color(0xE6D7FF3E);
  static const ring = Color(0xB3D7FF3E);

  /// Unselected suggestion chips.
  static const suggestionFill = Color(0x0FFFFFFF);
  static const suggestionBorder = Color(0x29FFFFFF);

  /// Page dots that are not the current page.
  static const dotIdle = Color(0x47FFFFFF);

  static const nextButtonShadow = Color(0x38D7FF3E);
}

abstract final class SpecFonts {
  static const display = 'GeneralSans';
  static const mono = 'GeistMono';
}

/// Letter spacing is absolute points in Flutter, so the CSS `em` values are
/// pre-multiplied by their font size here.
abstract final class SpecText {
  /// 92pt / 700 / -0.05em.
  static const wordmark = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 92,
    height: 0.9,
    letterSpacing: -4.6,
    color: SpecColors.ink,
  );

  static const trademark = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 12,
    color: SpecColors.ink72,
  );

  /// 11pt / 0.28em.
  static const tagline = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 11,
    height: 1.9,
    letterSpacing: 3.08,
    color: SpecColors.ink72,
  );

  /// 9.5pt / 0.24em.
  static const caption = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 2.28,
    color: SpecColors.ink62,
  );

  /// 86pt / 700 / -0.05em, the welcome screen's wordmark.
  static const welcomeWordmark = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 86,
    height: 0.84,
    letterSpacing: -4.3,
    color: SpecColors.ink,
  );

  static const welcomeTrademark = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 13,
    color: SpecColors.ink75,
  );

  /// 26pt / 500 / -0.03em.
  static const headline = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: 26,
    height: 1.2,
    letterSpacing: -0.78,
    color: SpecColors.ink,
  );

  /// 11pt / 0.24em.
  static const privacy = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 11,
    height: 1.9,
    letterSpacing: 2.64,
    color: SpecColors.ink70,
  );

  /// 13pt / 0.14em.
  static const chip = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 13,
    letterSpacing: 1.82,
    color: SpecColors.ink90,
  );

  /// 12pt / 0.14em.
  static const chipFaint = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 12,
    letterSpacing: 1.68,
    color: SpecColors.ink75,
  );

  static const chipLime = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 13,
    letterSpacing: 1.82,
    color: SpecColors.onAccent,
  );

  /// 11pt / 0.30em.
  static const pill = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 11,
    letterSpacing: 3.30,
    color: SpecColors.ink85,
  );

  /// 40pt / 700 / -0.05em, the how-it-works headline.
  static const howHeadline = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 40,
    height: 0.92,
    letterSpacing: -2.00,
    color: SpecColors.ink,
  );

  /// 46pt / 700 / -0.05em, the first-object headline.
  static const firstObjectHeadline = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 46,
    height: 0.92,
    letterSpacing: -2.30,
    color: SpecColors.ink,
  );

  static const bodyCopy = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.5,
    color: SpecColors.ink70,
  );

  /// 10.5pt / 0.18em.
  static const suggestion = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10.5,
    letterSpacing: 1.89,
    color: SpecColors.ink75,
  );

  static const suggestionSelected = TextStyle(
    fontFamily: SpecFonts.mono,
    fontWeight: FontWeight.w500,
    fontSize: 10.5,
    letterSpacing: 1.89,
    color: SpecColors.onAccent,
  );

  /// 9.5pt / 0.18em.
  static const frameCaption = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 1.71,
    color: SpecColors.ink62,
  );

  /// 9.5pt / 0.22em. Scaled with the headline so the pairing holds.
  static const kicker = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 2.09,
    color: SpecColors.ink70,
  );

  /// 9.5pt / 0.24em.
  static const stepLabel = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 2.28,
    color: SpecColors.accent,
  );

  /// 19pt / 600 / -0.02em.
  static const cardTitle = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 19,
    letterSpacing: -0.38,
    color: SpecColors.ink,
  );

  static const cardBody = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    color: SpecColors.ink70,
  );

  /// The lime card's body sits a touch brighter than the glass cards'.
  static const cardBodyBright = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    color: SpecColors.ink72,
  );

  /// 17pt / 700 / -0.02em, the `B22` standing in for an icon.
  static const limeLeading = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 17,
    letterSpacing: -0.34,
    color: SpecColors.accent,
  );

  /// 15pt / 600 / 0.06em.
  static const nextButton = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    letterSpacing: 0.90,
    color: SpecColors.onAccent,
  );

  /// 10.5pt / 0.24em.
  static const skip = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10.5,
    letterSpacing: 2.52,
    color: SpecColors.ink70,
  );

  /// 16pt / 600 / 0.06em.
  static const button = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 0.96,
    color: SpecColors.onAccent,
  );

  /// 11pt / 0.18em.
  static const ghostSpec = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 11,
    letterSpacing: 1.98,
    color: SpecColors.ghost,
  );
}
