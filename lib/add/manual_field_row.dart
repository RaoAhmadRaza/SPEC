import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/add/manual_tokens.dart';
import 'package:spec/add/plain_field_theme.dart';
import 'package:spec/widgets/square_caret_field.dart';

/// Both values start on the same x because both labels hold this width.
const _labelWidth = 56.0;
const _gap = 12.0;

/// CSS draws the 1pt border inside the box and pads inside that; a
/// [DecoratedBox] does not inset for its border, so the border is added here.
const _borderWidth = 1.0;
const _rowPadding = EdgeInsets.symmetric(
  horizontal: 16 + _borderWidth,
  vertical: 14 + _borderWidth,
);

/// CSS `blur(20px) saturate(180%)`.
const _rowBlur = 10.0;
const _rowSaturation = 1.8;

const _focusDuration = Duration(milliseconds: 200);
const _instant = Duration.zero;

/// `NAME` cuts bottom-left and `SPEC` bottom-right, so the pair mirrors.
const manualNameRadius = BorderRadius.only(
  topLeft: Radius.circular(18),
  topRight: Radius.circular(18),
  bottomRight: Radius.circular(18),
  bottomLeft: Radius.circular(5),
);
const manualSpecRadius = BorderRadius.only(
  topLeft: Radius.circular(18),
  topRight: Radius.circular(18),
  bottomRight: Radius.circular(5),
  bottomLeft: Radius.circular(18),
);

/// A labelled glass row holding a real text field.
///
/// Focus only moves colour: the border and fill lerp, and nothing about the
/// row's geometry changes, so the column under it cannot reflow. The caret is
/// [SquareCaretField]'s, which draws only while its field is focused — so the
/// screen never shows two.
class ManualFieldRow extends StatelessWidget {
  const ManualFieldRow({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.focusNode,
    required this.borderRadius,
    this.capitalization = TextCapitalization.sentences,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.isMotionReduced = false,
    this.valueWrapper,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final FocusNode focusNode;
  final BorderRadius borderRadius;
  final TextCapitalization capitalization;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isMotionReduced;

  /// Lets the screen put the value inside a Hero or a fade without the row
  /// knowing why.
  final Widget Function(Widget value)? valueWrapper;

  @override
  Widget build(BuildContext context) {
    final field = PlainFieldTheme(
      child: SquareCaretField(
        controller: controller,
        focusNode: focusNode,
        style: ManualText.fieldValue,
        hint: placeholder,
        hintStyle: ManualText.fieldHint,
        textCapitalization: capitalization,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );

    return GestureDetector(
      onTap: focusNode.requestFocus,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: _rowFilter,
          child: ListenableBuilder(
            listenable: focusNode,
            builder: (context, child) => TweenAnimationBuilder<double>(
              tween: Tween<double>(end: focusNode.hasFocus ? 1 : 0),
              duration: isMotionReduced ? _instant : _focusDuration,
              curve: Curves.easeOut,
              builder: (context, t, child) => DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.lerp(
                    ManualColors.fieldFill,
                    ManualColors.fieldFillFocused,
                    t,
                  ),
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: Color.lerp(
                      ManualColors.fieldBorder,
                      ManualColors.fieldBorderFocused,
                      t,
                    )!,
                  ),
                ),
                child: child,
              ),
              child: child,
            ),
            child: Padding(
              padding: _rowPadding,
              child: Row(
                children: [
                  SizedBox(
                    width: _labelWidth,
                    child: Text(label, style: ManualText.fieldLabel),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(child: valueWrapper?.call(field) ?? field),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final _rowFilter = ImageFilter.compose(
  outer: ColorFilter.matrix(_saturationMatrix(_rowSaturation)),
  inner: ImageFilter.blur(sigmaX: _rowBlur, sigmaY: _rowBlur),
);

/// The standard luminance-preserving saturation matrix, so `saturate(180%)`
/// means here what it means in the design file's CSS.
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
