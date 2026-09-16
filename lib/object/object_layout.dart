import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A body and a foot: the foot sits at the bottom of [minHeight] when both fit,
/// and simply follows the body, [gap] below it, when they do not.
///
/// This is CSS's `margin-top: auto` inside a scroll view. The usual Flutter
/// recipe — `IntrinsicHeight` around a `Column` with a `Spacer` — asks every
/// descendant for its intrinsic and baseline sizes, which glass, editable
/// text and baseline-aligned rows cannot all answer. This lays each part out
/// once at its natural height and places the foot.
class BodyWithFoot extends MultiChildRenderObjectWidget {
  BodyWithFoot({
    super.key,
    required this.minHeight,
    required this.gap,
    required Widget body,
    required Widget foot,
  }) : super(children: [body, foot]);

  final double minHeight;
  final double gap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderBodyWithFoot(minHeight, gap);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBodyWithFoot renderObject,
  ) {
    renderObject
      ..minHeight = minHeight
      ..gap = gap;
  }
}

class _Slot extends ContainerBoxParentData<RenderBox> {}

/// The render object behind [BodyWithFoot].
class RenderBodyWithFoot extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _Slot>,
        RenderBoxContainerDefaultsMixin<RenderBox, _Slot> {
  RenderBodyWithFoot(this._minHeight, this._gap);

  double _minHeight;
  set minHeight(double value) {
    if (value == _minHeight) return;
    _minHeight = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _Slot) child.parentData = _Slot();
  }

  @override
  void performLayout() {
    final body = firstChild;
    final foot = body == null ? null : childAfter(body);
    if (body == null || foot == null) {
      size = constraints.smallest;
      return;
    }

    final width = constraints.maxWidth;
    final part = BoxConstraints.tightFor(width: width);
    body.layout(part, parentUsesSize: true);
    foot.layout(part, parentUsesSize: true);

    final natural = body.size.height + _gap + foot.size.height;
    size = constraints.constrain(Size(width, math.max(_minHeight, natural)));

    (body.parentData! as _Slot).offset = Offset.zero;
    (foot.parentData! as _Slot).offset = Offset(
      0,
      size.height - foot.size.height,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
