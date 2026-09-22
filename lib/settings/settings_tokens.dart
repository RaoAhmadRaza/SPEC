import 'package:flutter/widgets.dart';

import 'package:spec/collections/collections_tokens.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// Settings has no design of its own, so every surface here is borrowed from
/// a screen that does: Collections' chips and rules, the object sheet's red.
abstract final class SettingsColors {
  /// `DELETE EVERYTHING`'s outline and wash: the object sheet's destructive
  /// red, the only non-lime accent in the app, at chip strength.
  static const destructiveOutline = Color(0x66FF5A5A);
  static const destructiveFill = Color(0x14FF5A5A);
}

/// Letter spacing is absolute points, so `em` values are pre-multiplied by
/// their font size.
abstract final class SettingsText {
  /// The Collections title, set on one line.
  static const title = CollectionsText.title;

  /// The archive counts under the title, the Collections totals column.
  static const counts = CollectionsText.totals;

  /// `NO ACCOUNT`, `NO CLOUD`: the welcome screen's privacy lines.
  static const privacy = SpecText.privacy;

  static const body = SpecText.bodyCopy;

  static const chip = CollectionsText.chip;
  static final chipAccent = CollectionsText.chip.copyWith(
    color: SpecColors.accent,
  );
  static final chipDestructive = CollectionsText.chip.copyWith(
    color: ObjectColors.destructive,
  );

  /// The result of the last action. Brighter than the privacy lines: it is
  /// the one line on the page that just changed.
  static final status = SpecText.privacy.copyWith(color: SpecColors.ink90);

  /// `SPEC 1.0.1 (2)`.
  static const version = SpecText.caption;
}
