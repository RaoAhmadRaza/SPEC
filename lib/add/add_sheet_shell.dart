import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'package:spec/add/add_tokens.dart';

const _sheetRadius = BorderRadius.vertical(top: Radius.circular(30));

/// CSS `blur(40px) saturate(180%)`.
const _sheetBlur = 20.0;
const _sheetSaturation = 1.8;

/// The one glass sheet every add step lives in.
///
/// The heaviest glass in the app, because it is the only surface with live
/// content behind it. It carries no padding: each step lays out its own.
class AddSheetShell extends StatelessWidget {
  const AddSheetShell({super.key, required this.fill, required this.child});

  /// Lerps between steps: step 05's sheet is a touch denser than step 04's.
  final Color fill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The shadow is drawn outside the clip, or it would be clipped away, and
    // it is cast upward.
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: _sheetRadius,
        boxShadow: [
          BoxShadow(
            color: AddColors.sheetShadow,
            blurRadius: 60,
            offset: Offset(0, -30),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _sheetRadius,
        child: BackdropFilter(
          filter: _sheetFilter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: _sheetRadius,
              border: const Border(
                top: BorderSide(color: AddColors.sheetBorder),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Blur plus `saturate(180%)`, built once: above 1 it lifts the colour of
/// whatever shows through, which is what stops the glass reading as flat grey
/// over the Home behind it.
final _sheetFilter = ImageFilter.compose(
  outer: ColorFilter.matrix(_saturationMatrix(_sheetSaturation)),
  inner: ImageFilter.blur(sigmaX: _sheetBlur, sigmaY: _sheetBlur),
);

/// The standard luminance-preserving saturation matrix, so `saturate()` means
/// the same thing here as it does in the design file's CSS.
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
