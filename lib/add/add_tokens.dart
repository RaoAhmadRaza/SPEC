import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// Tokens for screen 04, the add flow's "what" step, lifted 1:1 from
/// `SPEC Screens.dc.html`.
///
/// The sheet is the only surface in the app with live content behind it, so
/// its glass is heavier than anything in [SpecColors] and earns its own file.
abstract final class AddColors {
  /// `rgba(28,30,32,0.72)`.
  static const sheetFill = Color(0xB81C1E20);

  /// The lit top edge, `rgba(255,255,255,0.16)`.
  static const sheetBorder = Color(0x29FFFFFF);

  /// `0 -30px 60px rgba(0,0,0,0.5)`, cast upward.
  static const sheetShadow = Color(0x80000000);

  /// `rgba(255,255,255,0.25)`.
  static const handle = Color(0x40FFFFFF);

  /// The photo card's edge, `rgba(255,255,255,0.16)`.
  static const cardBorder = Color(0x29FFFFFF);

  /// The `+ PHOTO` chip and the clear disc share one glass recipe.
  static const chipFill = Color(0x1FFFFFFF);
  static const chipBorder = Color(0x33FFFFFF);

  /// Unselected type tiles: `rgba(255,255,255,0.05)` on `rgba(…,0.14)`.
  static const tileFill = Color(0x0DFFFFFF);
  static const tileBorder = Color(0x24FFFFFF);

  /// The selected tile is a lime *outline*, so its fill stays a tint.
  static const selectedTileFill = Color(0x1AD7FF3E);
  static const selectedTileShadow = Color(0x1FD7FF3E);

  /// A shadow that lerps to [selectedTileShadow] without the box resizing.
  static const tileShadowIdle = Color(0x00D7FF3E);

  /// `0 14px 34px rgba(215,255,62,0.2)` under CONTINUE.
  static const continueShadow = Color(0x33D7FF3E);

  /// Sits over the blurred Home to stand in for its `opacity: 0.3`: dropping
  /// the layer to 30% over `bg` is the same as painting `bg` at 70% on top.
  static const backdropDim = Color(0xB30A0B0C);

  /// `rgba(0,0,0,0.35)`, the scrim that rides in with the sheet.
  static const scrim = Color(0x59000000);

  // Step 05, the fields.

  /// `rgba(28,30,32,0.74)`: a touch heavier, because the sheet covers more.
  static const fieldsSheetFill = Color(0xBD1C1E20);

  /// Home at 22% rather than 30%, as `bg` at 78% over it.
  static const fieldsBackdropDim = Color(0xC70A0B0C);

  /// The 1.5pt rule under the value.
  static const fieldRule = Color(0x4DFFFFFF);

  /// Above the field block.
  static const sectionRule = Color(0x24FFFFFF);

  /// Above the reminder row.
  static const hairline = Color(0x14FFFFFF);

  static const kindChipBorder = Color(0x24FFFFFF);

  static const slotBorder = Color(0x29FFFFFF);
  static const locationFill = Color(0x0FFFFFFF);
  static const locationBorder = Color(0x24FFFFFF);

  static const saveDisabled = Color(0x1AFFFFFF);
}

abstract final class AddText {
  /// 30pt / 600 / -0.035em.
  static const question = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 30,
    height: 1.05,
    letterSpacing: -1.05,
    color: SpecColors.ink,
  );

  /// 9.5pt / 0.22em. Brighter than [SpecText.kicker] because it sits on glass
  /// over a photograph rather than on the page.
  static const photoChip = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 2.09,
    color: SpecColors.ink,
  );

  static const tileLabel = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: SpecColors.ink80,
  );

  /// Full white w600 — the lime lives in the container, never the label.
  static const tileLabelSelected = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: SpecColors.ink,
  );

  static const check = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 11,
    height: 1,
    color: SpecColors.onAccent,
  );

  // Step 05, the fields.

  /// `DEVICE · KITCHEN`, the field label and `LOCATION`: mono 10pt / 0.22em.
  static const monoLabel = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2.2,
    color: SpecColors.ink62,
  );

  /// The only lime text on the screen. 11pt / 0.28em.
  static const prompt = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 11,
    letterSpacing: 3.08,
    color: SpecColors.accent,
  );

  /// 11pt / 0.16em. Selected swaps colour and weight only, never geometry.
  static const kindChip = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 11,
    letterSpacing: 1.76,
    color: SpecColors.ink55,
  );

  static const kindChipSelected = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 11,
    letterSpacing: 1.76,
    fontWeight: FontWeight.w500,
    color: SpecColors.onAccent,
  );

  /// 42pt / 600 / -0.045em, the largest thing on the sheet by far.
  static const value = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 42,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.89,
    height: 1,
    color: SpecColors.ink,
  );

  /// The OTHER kind's own name for its field.
  static const fieldName = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2.2,
    color: SpecColors.ink,
  );

  /// `Kitchen`, 18pt / 500 / -0.02em.
  static const location = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.36,
    color: SpecColors.ink,
  );

  /// A zone in the expanded picker, 17pt / 500.
  static const zoneOption = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: SpecColors.ink,
  );

  /// `REMIND ME`, 10pt / 0.20em.
  static const reminderLabel = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2,
    color: SpecColors.ink62,
  );

  /// `EVERY 6 MONTHS`, 12pt / 0.06em.
  static const reminderValue = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 12,
    letterSpacing: 0.72,
    color: SpecColors.ink,
  );

  /// 16pt / 600 / 0.06em.
  static const save = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.96,
    color: SpecColors.onAccent,
  );

  static const saveDisabled = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.96,
    color: SpecColors.ink55,
  );
}
