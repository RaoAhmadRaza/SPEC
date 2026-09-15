import 'dart:ui';

import 'package:flutter/widgets.dart';

/// A frosted surface: blur, saturate, fill, border and inner highlights.
///
/// Screen 01 has seven of these and no two share a recipe, so the recipe is
/// the parameter list rather than a set of named variants.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.borderRadius,
    required this.blur,
    this.saturation = 1,
    this.fill,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1,
    this.topHighlight,
    this.topHighlightHeight = 1.5,
    this.bottomHighlight,
    this.shadows = const [],
    this.padding = EdgeInsets.zero,
    this.child,
  });

  final BorderRadius borderRadius;
  final double blur;

  /// CSS `saturate()`. Above 1 it lifts the colour of whatever shows through,
  /// which is what stops the glass reading as flat grey over a photo.
  final double saturation;

  final Color? fill;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;

  /// `box-shadow: inset 0 1.5px 0 …`, the lit top edge.
  final Color? topHighlight;
  final double topHighlightHeight;

  /// `box-shadow: inset 0 -1px 0 …`.
  final Color? bottomHighlight;

  final List<BoxShadow> shadows;
  final EdgeInsets padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // The shadow is drawn outside the clip, or it would be clipped away.
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: _filter,
          child: Container(
            decoration: BoxDecoration(
              color: gradient == null ? fill : null,
              gradient: gradient,
              borderRadius: borderRadius,
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor!, width: borderWidth),
            ),
            child: Stack(
              children: [
                if (topHighlight != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topHighlightHeight,
                    child: ColoredBox(color: topHighlight!),
                  ),
                if (bottomHighlight != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 1,
                    child: ColoredBox(color: bottomHighlight!),
                  ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ImageFilter get _filter {
    final blurFilter = ImageFilter.blur(sigmaX: blur, sigmaY: blur);
    if (saturation == 1) return blurFilter;
    return ImageFilter.compose(
      outer: ColorFilter.matrix(_saturationMatrix(saturation)),
      inner: blurFilter,
    );
  }
}

/// The standard luminance-preserving saturation matrix, so `saturate(200%)`
/// means the same thing here as it does in the design file's CSS.
List<double> _saturationMatrix(double amount) {
  const r = 0.213;
  const g = 0.715;
  const b = 0.072;
  final inverse = 1 - amount;
  final ir = inverse * r;
  final ig = inverse * g;
  final ib = inverse * b;
  return [
    ir + amount, ig, ib, 0, 0, //
    ir, ig + amount, ib, 0, 0, //
    ir, ig, ib + amount, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}
