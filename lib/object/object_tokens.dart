import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_layout.dart';
import 'package:spec/theme/spec_tokens.dart';

/// Screen 03's own surfaces, lifted from `SPEC Screens.dc.html`.
///
/// The glass recipes differ from Home's by blur radius and fill, and the three
/// rule weights exist nowhere else, so they live here rather than being forced
/// into the shared tokens. Alpha channels are the CSS `rgba()` fractions
/// rounded to the nearest byte.
abstract final class ObjectColors {
  /// The back and ••• circles: `rgba(255,255,255,0.07)` on a `0.14` border.
  static const circleFill = Color(0x12FFFFFF);
  static const circleBorder = Color(0x24FFFFFF);

  /// The glass sub-zone chip. Brighter border than the circles.
  static const chipFill = Color(0x12FFFFFF);
  static const chipBorder = Color(0x2EFFFFFF);

  /// The spec table's outer rules, and the hairlines between its columns.
  static const ruleStrong = Color(0x29FFFFFF);
  static const ruleInner = Color(0x1AFFFFFF);

  /// The rule above each metadata row, a shade fainter again.
  static const hairline = Color(0x14FFFFFF);

  static const photoBorder = Color(0x1FFFFFFF);

  /// The floating action bar.
  static const barFill = Color(0x14FFFFFF);
  static const barBorder = Color(0x29FFFFFF);
  static const barHighlight = Color(0x38FFFFFF);
  static const barShadow = Color(0x8C000000);

  /// The rule under a field while `Edit` is open.
  static const editRule = Color(0x4DFFFFFF);

  /// The full-screen photo viewer's ground, a shade under the page.
  static const viewerGround = Color(0xFF060708);

  /// The ••• sheet's scrim over the page behind it.
  static const sheetScrim = Color(0x4D000000);

  /// `Delete` — the only non-lime accent in the app, used nowhere else.
  static const destructive = Color(0xF2FF5A5A);
}

/// Text styles unique to screen 03. Letter spacing is absolute points, so the
/// design's `em` values are pre-multiplied by their font size.
abstract final class ObjectText {
  /// 108pt / 600 / -0.06em. The largest type anywhere in the app.
  static const spec = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 108,
    height: 0.82,
    letterSpacing: -6.48,
    color: SpecColors.ink,
    decoration: TextDecoration.none,
  );

  /// A spec that needs two lines sets smaller and opens its leading.
  static const specTwoLine = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w600,
    fontSize: 72,
    height: 0.88,
    letterSpacing: -4.32,
    color: SpecColors.ink,
    decoration: TextDecoration.none,
  );

  /// 17pt / -0.01em.
  static const subtitle = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 17,
    letterSpacing: -0.17,
    color: SpecColors.ink62,
  );

  /// 9.5pt / 0.24em, on lime.
  static const zoneChip = TextStyle(
    fontFamily: SpecFonts.mono,
    fontWeight: FontWeight.w500,
    fontSize: 9.5,
    letterSpacing: 2.28,
    color: SpecColors.onAccent,
    decoration: TextDecoration.none,
  );

  /// The same chip on glass.
  static const subZoneChip = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 2.28,
    color: SpecColors.ink80,
    decoration: TextDecoration.none,
  );

  /// 9.5pt / 0.20em.
  static const tableLabel = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 9.5,
    letterSpacing: 1.90,
    color: SpecColors.ink62,
  );

  /// 19pt / 500 / -0.02em.
  static const tableValue = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: 19,
    letterSpacing: -0.38,
    color: SpecColors.ink,
  );

  /// 10pt / 0.20em.
  static const metaLabel = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2.00,
    color: SpecColors.ink62,
  );

  /// 12pt / 0.06em.
  static const metaValue = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 12,
    letterSpacing: 0.72,
    color: SpecColors.ink,
  );

  /// The label that flashes lime when a replacement is stamped.
  static const metaLabelAccent = TextStyle(
    fontFamily: SpecFonts.mono,
    fontSize: 10,
    letterSpacing: 2.00,
    color: SpecColors.accent,
  );

  /// 15pt / 500, the action bar's leading label.
  static const action = TextStyle(
    fontFamily: SpecFonts.display,
    fontWeight: FontWeight.w500,
    fontSize: 15,
    color: SpecColors.ink,
  );

  /// 15pt, a shade behind it.
  static const actionQuiet = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 15,
    color: SpecColors.ink72,
  );

  /// 11pt / 0.16em, inside the lime pill.
  static const replaced = TextStyle(
    fontFamily: SpecFonts.mono,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    letterSpacing: 1.76,
    color: SpecColors.onAccent,
  );

  /// 15pt, one row of the ••• sheet.
  static const menuItem = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 15,
    color: SpecColors.ink85,
  );

  static const menuItemDestructive = TextStyle(
    fontFamily: SpecFonts.display,
    fontSize: 15,
    color: ObjectColors.destructive,
  );
}

/// Screen 03's geometry. Every number is a logical point on a 402 × 874 canvas.
abstract final class ObjectMetrics {
  /// Note the 22 either side: Home uses 18.
  static const page = EdgeInsets.fromLTRB(22, 62, 22, 44);

  /// The design's outer column gap. The chips, spec and subtitle sit in a
  /// nested group that overrides it.
  static const gap = 24.0;
  static const identityGap = 12.0;

  static const circle = 40.0;
  static const minHitBox = 44.0;

  static const chipPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);

  static const photoRowHeight = 158.0;
  static const photoGap = 9.0;

  /// The photo pair's shape rather than its height: 358pt across and 158pt
  /// tall at the reference canvas, so this reproduces 158 exactly there and
  /// stops the main photo becoming a letterbox on a tablet.
  static const photoPairRatio = 358 / photoRowHeight;

  /// Past this the 108pt spec, the table and the bar all stretch the full
  /// width of an iPad. The body is capped here and centred instead.
  static const maxContentWidth = SpecLayout.maxContentWidth;

  /// Three corners at 20 and one cut to 6. The two cuts face each other
  /// across the gap.
  static const mainPhotoRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomRight: Radius.circular(6),
    bottomLeft: Radius.circular(20),
  );
  static const detailPhotoRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(6),
    bottomRight: Radius.circular(20),
    bottomLeft: Radius.circular(20),
  );

  /// The bar's designed height. [objectBarHeight] is what anything laying
  /// out against it should read.
  static const barHeight = 62.0;

  /// The gap metadata row two opens under itself to clear the bar.
  static const barClearance = 16.0;

  /// A spec shrinks to fit rather than wrapping, but never below this.
  static const specFloor = 56.0;
}

/// The action bar's height at the current text scale.
///
/// The bar itself and the screen's reserved [ObjectMetrics.barHeight] band
/// both read this one function, so a bar that grows can never end up sitting
/// over content the screen thought it had cleared. At scale 1.0 it is exactly
/// the 62pt design value.
double objectBarHeight(BuildContext context) => MediaQuery.textScalerOf(context)
    .scale(ObjectMetrics.barHeight)
    .clamp(
      ObjectMetrics.barHeight,
      ObjectMetrics.barHeight * SpecLayout.maxTextScale,
    );
