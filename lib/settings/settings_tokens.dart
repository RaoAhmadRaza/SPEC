import 'package:flutter/widgets.dart';

import 'package:spec/collections/collections_tokens.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// Measured off the Settings design at its 402 × 874 canvas.
abstract final class SettingsColors {
  static const cardFill = Color(0x08FFFFFF);
  static const cardBorder = SpecColors.glassFaintBorder;

  static const discFill = SpecColors.leadingFill;
  static const discBorder = SpecColors.leadingBorder;

  /// `EXPORT BACKUP`: the one thing to do.
  static const accentOutline = SpecColors.limeCardBorder;
  static const accentFill = Color(0x0AD7FF3E);

  /// `RESTORE FROM BACKUP`: brighter than a card's edge, still quiet.
  static const plainOutline = Color(0x40FFFFFF);
  static const plainFill = Color(0x08FFFFFF);

  /// `DELETE EVERYTHING`: the object sheet's destructive red, the only
  /// non-lime accent in the app, at outline strength.
  static const destructiveOutline = Color(0xCCFF5A5A);
  static const destructiveFill = Color(0x0AFF5A5A);
  static const destructive = ObjectColors.destructive;
}

/// Letter spacing is absolute points, so `em` values are pre-multiplied by
/// their font size.
abstract final class SettingsText {
  /// The Collections title, set on one line.
  static const title = CollectionsText.title;

  /// The archive counts under the title: the Collections totals column, on
  /// a line box tight enough to tuck under the title.
  static final counts = CollectionsText.totals.copyWith(height: 1.2);

  /// `BACKUP`, `PHOTOS`: 10pt / 0.20em.
  static const rowLabel = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    height: 1.25,
    letterSpacing: 2.00,
    color: SpecColors.ink85,
  );

  /// `Keep your specs safe.` 11pt on a 14.6pt line, so two lines keep a card
  /// at the design's 74pt.
  static const rowDetail = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 11,
    height: 1.33,
    color: SpecColors.ink62,
  );

  /// `SPEC 1.0.3 (4)` under `ABOUT`.
  static const rowVersion = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    height: 1.25,
    letterSpacing: 0.5,
    color: SpecColors.ink62,
  );

  /// `12`, `2.1 MB`: a reading, so it is the brightest thing on the row.
  static const rowValue = TextStyle(
    fontFamily: SpecFonts.mono,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    height: 1.25,
    letterSpacing: 1.3,
    color: SpecColors.ink,
  );

  /// `OFF`: a state, not a reading, so it stays dim.
  static const rowState = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    height: 1.25,
    letterSpacing: 2.00,
    color: SpecColors.ink50,
  );

  /// `EXPORT BACKUP`: 10pt / 0.20em.
  static const pill = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2.00,
    color: SpecColors.ink70,
  );

  /// The result of the last action. Brighter than the counts: it is the one
  /// line on the page that just changed.
  static final status = SpecText.privacy.copyWith(color: SpecColors.ink90);
}
