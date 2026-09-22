import 'package:flutter/widgets.dart';

import 'package:spec/home/home_glass.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

const _barBlur = 15.0;
const _barSaturation = 2.0;
const _barPadding = EdgeInsets.only(left: 24, right: 8);
const _pillPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
const _ringStroke = 1.5;
const _ringGrowth = 0.6;
const _ringOpacity = 0.5;

/// Which action a tap in the bar landed on.
enum BarAction { primary, secondary, pill }

/// The floating glass bar: `Edit · Share · REPLACED`, or while editing,
/// `Cancel · · · SAVE`.
///
/// The labels are laid out at their visual sizes, exactly as the design draws
/// them, and one detector over the whole bar hands each tap to the nearest
/// label. That is how every target clears 44pt without a single point of the
/// layout moving to make room for it.
class ObjectActionBar extends StatefulWidget {
  const ObjectActionBar({
    super.key,
    required this.editing,
    required this.pillPress,
    required this.ring,
    required this.onAction,
  });

  /// 0 shows `Edit / Share / REPLACED`, 1 shows `Cancel / · / SAVE`.
  final Animation<double> editing;

  /// The pill's 0.94 dip and settle.
  final Animation<double> pillPress;

  /// 0 → 1 as the lime ring expands out of the pill.
  final Animation<double> ring;

  final ValueChanged<BarAction> onAction;

  @override
  State<ObjectActionBar> createState() => _ObjectActionBarState();
}

class _ObjectActionBarState extends State<ObjectActionBar> {
  final _keys = {for (final action in BarAction.values) action: GlobalKey()};

  void _onTapUp(TapUpDetails details) {
    BarAction? nearest;
    var nearestDistance = double.infinity;
    for (final MapEntry(key: action, value: key) in _keys.entries) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final centre = box.localToGlobal(box.size.center(Offset.zero)).dx;
      final distance = (centre - details.globalPosition.dx).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = action;
      }
    }
    if (nearest != null) widget.onAction(nearest);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: objectBarHeight(context),
      child: Stack(
        // The ring expands past the bar's edge; the glass clips, the row must
        // not.
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GlassSurface(
              borderRadius: BorderRadius.circular(999),
              blur: _barBlur,
              saturation: _barSaturation,
              fill: ObjectColors.barFill,
              borderColor: ObjectColors.barBorder,
              topHighlight: ObjectColors.barHighlight,
              shadows: const [
                BoxShadow(
                  color: ObjectColors.barShadow,
                  offset: Offset(0, 16),
                  blurRadius: 40,
                ),
              ],
            ),
          ),
          Padding(
            padding: _barPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Every label yields. None was flexible before, so at 320pt
                // the three of them overflowed the row outright.
                Flexible(
                  child: _Labelled(
                    editing: widget.editing,
                    labels: const ('Edit', 'Cancel'),
                    onTap: () => widget.onAction(BarAction.primary),
                    child: _CrossFade(
                      key: _keys[BarAction.primary],
                      t: widget.editing,
                      from: const Text(
                        'Edit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ObjectText.action,
                      ),
                      to: const Text(
                        'Cancel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ObjectText.action,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: _Labelled(
                    editing: widget.editing,
                    labels: const ('Share', null),
                    onTap: () => widget.onAction(BarAction.secondary),
                    child: _CrossFade(
                      key: _keys[BarAction.secondary],
                      t: widget.editing,
                      from: const Text(
                        'Share',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ObjectText.actionQuiet,
                      ),
                      to: const Text(
                        '·',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ObjectText.actionQuiet,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: _Labelled(
                    editing: widget.editing,
                    labels: const ('Mark replaced today', 'Save'),
                    onTap: () => widget.onAction(BarAction.pill),
                    child: _Pill(
                      key: _keys[BarAction.pill],
                      editing: widget.editing,
                      press: widget.pillPress,
                      ring: widget.ring,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: _onTapUp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A screen-reader node for one action. Taps are routed by distance for
/// touch; this gives assistive tech a distinct, named button for each label.
/// A null label (the `·` while editing) is not a button.
class _Labelled extends StatelessWidget {
  const _Labelled({
    required this.editing,
    required this.labels,
    required this.onTap,
    required this.child,
  });

  final Animation<double> editing;
  final (String, String?) labels;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: editing,
      builder: (context, inner) {
        final label = editing.value < 0.5 ? labels.$1 : labels.$2;
        return Semantics(
          button: label != null,
          label: label,
          excludeSemantics: true,
          onTap: label == null ? null : onTap,
          child: inner,
        );
      },
      child: child,
    );
  }
}

/// Two labels in one slot. The slot is sized by the wider of the two, so the
/// row never reflows as they swap.
class _CrossFade extends StatelessWidget {
  const _CrossFade({
    super.key,
    required this.t,
    required this.from,
    required this.to,
  });

  final Animation<double> t;
  final Widget from;
  final Widget to;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, _) => Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 1 - t.value, child: from),
          Opacity(opacity: t.value, child: to),
        ],
      ),
    );
  }
}

/// The lime pill. Its text changes in edit mode; its geometry never does.
class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.editing,
    required this.press,
    required this.ring,
  });

  final Animation<double> editing;
  final Animation<double> press;
  final Animation<double> ring;

  @override
  Widget build(BuildContext context) {
    final pill = DecoratedBox(
      decoration: const BoxDecoration(
        color: SpecColors.accent,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: _pillPadding,
        child: _CrossFade(
          t: editing,
          from: const Text('REPLACED', style: ObjectText.replaced),
          to: const Text('SAVE', style: ObjectText.replaced),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: _Ring(ring)),
        ScaleTransition(scale: press, child: pill),
      ],
    );
  }
}

/// A 1.5pt lime outline that grows out of the pill and fades as it goes.
class _Ring extends StatelessWidget {
  const _Ring(this.t);

  final Animation<double> t;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: t,
        builder: (context, _) {
          // Resting and finished both draw nothing, so the ring never lingers.
          if (t.value == 0 || t.isCompleted) return const SizedBox.shrink();
          return Opacity(
            opacity: _ringOpacity * (1 - t.value),
            child: Transform.scale(
              scale: 1 + _ringGrowth * t.value,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                  border: Border.fromBorderSide(
                    BorderSide(color: SpecColors.accent, width: _ringStroke),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
