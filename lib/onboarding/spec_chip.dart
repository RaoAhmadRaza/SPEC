import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// Corner radius used by every chip except the cut one.
const _chipRadius = 14.0;

/// The single tightened corner that gives a chip its cut silhouette.
const _chipCut = 4.0;

/// Faint chips are rounded evenly instead of cut.
const _faintRadius = 12.0;

/// Which corner of a glass chip is tightened. Faint chips use [none].
enum ChipCut {
  bottomLeft,
  bottomRight,
  topLeft,
  topRight,
  none;

  BorderRadius get radius => switch (this) {
    ChipCut.none => BorderRadius.circular(_faintRadius),
    ChipCut.bottomLeft => const BorderRadius.only(
      topLeft: Radius.circular(_chipRadius),
      topRight: Radius.circular(_chipRadius),
      bottomRight: Radius.circular(_chipRadius),
      bottomLeft: Radius.circular(_chipCut),
    ),
    ChipCut.bottomRight => const BorderRadius.only(
      topLeft: Radius.circular(_chipRadius),
      topRight: Radius.circular(_chipRadius),
      bottomRight: Radius.circular(_chipCut),
      bottomLeft: Radius.circular(_chipRadius),
    ),
    ChipCut.topLeft => const BorderRadius.only(
      topLeft: Radius.circular(_chipCut),
      topRight: Radius.circular(_chipRadius),
      bottomRight: Radius.circular(_chipRadius),
      bottomLeft: Radius.circular(_chipRadius),
    ),
    ChipCut.topRight => const BorderRadius.only(
      topLeft: Radius.circular(_chipRadius),
      topRight: Radius.circular(_chipCut),
      bottomRight: Radius.circular(_chipRadius),
      bottomLeft: Radius.circular(_chipRadius),
    ),
  };
}

/// One of the spec chips drifting over the welcome screen.
///
/// Three looks share this widget: frosted glass, a fainter and smaller glass,
/// and a solid lime fill that carries no blur or border.
class SpecChip extends StatelessWidget {
  const SpecChip.glass(this.text, {super.key, required this.cut})
    : _variant = _ChipVariant.glass;

  const SpecChip.faint(this.text, {super.key})
    : cut = ChipCut.none,
      _variant = _ChipVariant.faint;

  const SpecChip.lime(this.text, {super.key, required this.cut})
    : _variant = _ChipVariant.lime;

  final String text;
  final ChipCut cut;
  final _ChipVariant _variant;

  @override
  Widget build(BuildContext context) {
    final radius = cut.radius;
    final content = Container(
      padding: _variant.padding,
      decoration: BoxDecoration(
        color: _variant.fill,
        borderRadius: radius,
        border: _variant.border,
        boxShadow: _variant.shadow,
      ),
      child: Text(text, style: _variant.textStyle),
    );

    if (_variant.blurSigma == null) return content;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _variant.blurSigma!,
          sigmaY: _variant.blurSigma!,
        ),
        child: content,
      ),
    );
  }
}

enum _ChipVariant {
  glass,
  faint,
  lime;

  EdgeInsets get padding => switch (this) {
    _ChipVariant.faint => const EdgeInsets.symmetric(
      horizontal: 13,
      vertical: 9,
    ),
    _ => const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
  };

  Color get fill => switch (this) {
    _ChipVariant.glass => SpecColors.glassFill,
    _ChipVariant.faint => SpecColors.glassFaintFill,
    _ChipVariant.lime => SpecColors.accent,
  };

  /// The lime chip is solid, so it neither blurs nor frosts.
  double? get blurSigma => switch (this) {
    _ChipVariant.glass => 9,
    _ChipVariant.faint => 7,
    _ChipVariant.lime => null,
  };

  Border? get border => switch (this) {
    _ChipVariant.glass => Border.all(color: SpecColors.glassBorder),
    _ChipVariant.faint => Border.all(color: SpecColors.glassFaintBorder),
    _ChipVariant.lime => null,
  };

  List<BoxShadow>? get shadow => switch (this) {
    _ChipVariant.glass => const [
      BoxShadow(
        color: SpecColors.chipShadow,
        blurRadius: 34,
        offset: Offset(0, 16),
      ),
    ],
    _ChipVariant.faint => null,
    _ChipVariant.lime => const [
      BoxShadow(
        color: SpecColors.limeChipShadow,
        blurRadius: 40,
        offset: Offset(0, 18),
      ),
    ],
  };

  TextStyle get textStyle => switch (this) {
    _ChipVariant.glass => SpecText.chip,
    _ChipVariant.faint => SpecText.chipFaint,
    _ChipVariant.lime => SpecText.chipLime,
  };
}
