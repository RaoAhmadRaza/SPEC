import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Layout facts the screens share: device class, reading width, safe-area
/// insets, grid columns, and the text-scale ceiling.
///
/// Colour and type live in `spec_tokens.dart`. This file holds only what
/// depends on the window, so nothing here is a constant a screen could have
/// written itself.
abstract final class SpecLayout {
  /// Below this, a screen is a phone. Without it every tablet gets a phone
  /// layout stretched across 1280pt.
  static const double expandedBreakpoint = 600.0;

  /// True on tablets in either orientation.
  ///
  /// Measured on `shortestSide`, so rotating an iPad does not demote it to a
  /// phone halfway through a gesture.
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= expandedBreakpoint;

  /// The widest a column of SPEC's display type stays readable. Without the
  /// cap, a 54–108pt headline runs the full 1280pt of a landscape iPad and
  /// the eye loses the line.
  static const double maxContentWidth = 560.0;

  /// The window's width, capped at [maxContentWidth].
  static double contentWidth(BuildContext context) =>
      math.min(MediaQuery.sizeOf(context).width, maxContentWidth);

  /// Breathing room between the status bar and the first glyph. Without it a
  /// headline sits flush against the notch on a device whose inset exceeds
  /// the design constant.
  static const double minTopGap = 12.0;

  /// The same, above the home indicator, which is a touch target the system
  /// owns.
  static const double minBottomGap = 12.0;

  /// The screen's own top padding, raised only where the real inset needs it.
  ///
  /// `max(design, real + gap)` rather than `design + real`: at the 402x874
  /// test canvas `MediaQuery` padding is zero, so this returns [design]
  /// unchanged and no existing layout moves.
  static double topInset(BuildContext context, {required double design}) =>
      math.max(design, MediaQuery.paddingOf(context).top + minTopGap);

  /// The bottom half of [topInset]'s bargain.
  static double bottomInset(BuildContext context, {required double design}) =>
      math.max(design, MediaQuery.paddingOf(context).bottom + minBottomGap);

  /// How many cells of roughly [idealCell] fit across [available].
  ///
  /// Gaps are deliberately not subtracted: the count is a coarse choice
  /// between two and six columns, and the cell width the caller derives
  /// afterwards is what absorbs the gaps.
  static int columnsFor(
    double available, {
    required double idealCell,
    required int min,
    required int max,
  }) => (available / idealCell).floor().clamp(min, max);

  /// The ceiling `main.dart` clamps the system text scale to. Named here so a
  /// screen can say what worst case it has to survive.
  static const double maxTextScale = 1.5;
}
