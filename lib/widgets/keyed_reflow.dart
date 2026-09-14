import 'package:flutter/widgets.dart';

/// How cells arrive, leave and travel when the list under a [KeyedReflow]
/// changes.
@immutable
class ReflowMotion {
  const ReflowMotion({
    required this.move,
    required this.enter,
    required this.exit,
    required this.stagger,
    required this.enterOffset,
    required this.exitScale,
  });

  /// A cell that survives a change travels to its new slot over this long.
  final Duration move;

  final Duration enter;
  final Duration exit;

  /// Entering cells come in one after another, in reading order.
  final Duration stagger;

  /// An entering cell rises this far as it fades in.
  final double enterOffset;

  /// A leaving cell shrinks to this as it fades out.
  final double exitScale;
}

/// Builds one cell. [isLeaving] is true while the cell fades out, so a cell
/// can drop any emphasis it should not keep on its way out.
typedef ReflowCellBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
  bool isLeaving,
);

/// A grid of fixed-height cells positioned rather than laid out.
///
/// A `Column` or `GridView` rebuilt from a new list cuts every cell to its new
/// place. SPEC's lists do the opposite: a cell that survives a re-query or a
/// filter visibly travels, which needs each cell to hold a position it can
/// animate. One column is a list.
class KeyedReflow<T> extends StatefulWidget {
  const KeyedReflow({
    super.key,
    required this.items,
    required this.keyOf,
    required this.cellHeight,
    required this.motion,
    required this.itemBuilder,
    this.columns = 1,
    this.crossGap = 0,
    this.mainGap = 0,
  });

  final List<T> items;
  final Object Function(T item) keyOf;
  final double cellHeight;
  final ReflowMotion motion;
  final ReflowCellBuilder<T> itemBuilder;
  final int columns;
  final double crossGap;
  final double mainGap;

  @override
  State<KeyedReflow<T>> createState() => _KeyedReflowState<T>();
}

class _KeyedReflowState<T> extends State<KeyedReflow<T>>
    with TickerProviderStateMixin {
  final List<_Slot<T>> _slots = [];

  bool get _isMotionReduced => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_slots.isEmpty) _sync(isFirstBuild: true);
  }

  @override
  void didUpdateWidget(KeyedReflow<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) _sync();
  }

  /// Diffs the incoming items against what is on screen, by key.
  void _sync({bool isFirstBuild = false}) {
    final incoming = widget.items;
    final keys = {for (final item in incoming) widget.keyOf(item)};
    final motion = widget.motion;
    var entering = 0;

    for (final slot in _slots) {
      if (keys.contains(slot.key) || slot.isLeaving) continue;
      slot.isLeaving = true;
      if (_isMotionReduced) {
        slot.controller.value = 0;
        _scheduleRemoval(slot);
      } else {
        slot.controller.reverse();
      }
    }

    for (var index = 0; index < incoming.length; index++) {
      final item = incoming[index];
      final key = widget.keyOf(item);
      final existing = _slots.where((slot) => slot.key == key).firstOrNull;

      if (existing != null) {
        // A cell that comes back while still fading out is revived in place
        // rather than doubled: two slots under one key would collide.
        if (existing.isLeaving) {
          existing.isLeaving = false;
          if (_isMotionReduced) {
            existing.controller.value = 1;
          } else {
            existing.controller.forward();
          }
        }
        existing
          ..item = item
          ..index = index;
        continue;
      }

      // The first paint is not an entrance: the screen's own entrance owns
      // that, and a stagger underneath it would read as a stutter.
      final delay = isFirstBuild ? Duration.zero : motion.stagger * entering;
      entering++;
      final slot = _Slot<T>(
        key: key,
        item: item,
        index: index,
        stagger: delay,
        controller: AnimationController(
          vsync: this,
          duration: motion.enter + delay,
          reverseDuration: motion.exit,
        ),
      );
      slot.controller.addStatusListener((status) {
        if (status == AnimationStatus.dismissed && slot.isLeaving) {
          _scheduleRemoval(slot);
        }
      });
      _slots.add(slot);
      if (_isMotionReduced || isFirstBuild) {
        slot.controller.value = 1;
      } else {
        slot.controller.forward();
      }
    }

    if (!isFirstBuild) setState(() {});
  }

  /// Deferred: the controller may be mid-notification, and disposing it from
  /// inside its own listener trips an assertion.
  void _scheduleRemoval(_Slot<T> slot) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !slot.isLeaving || !_slots.contains(slot)) return;
      slot.controller.dispose();
      setState(() => _slots.remove(slot));
    });
  }

  @override
  void dispose() {
    for (final slot in _slots) {
      slot.controller.dispose();
    }
    super.dispose();
  }

  double _heightFor(int count) {
    if (count == 0) return 0;
    final rows = (count / widget.columns).ceil();
    return rows * widget.cellHeight + (rows - 1) * widget.mainGap;
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = _isMotionReduced;
    final move = isReduced ? Duration.zero : widget.motion.move;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = widget.columns;
        final cellWidth =
            (constraints.maxWidth - (columns - 1) * widget.crossGap) / columns;

        return AnimatedContainer(
          duration: move,
          curve: Curves.easeOutCubic,
          height: _heightFor(widget.items.length),
          child: Stack(
            // Cells on their way out can sit below the new height.
            clipBehavior: Clip.none,
            children: [
              for (final slot in _slots)
                AnimatedPositioned(
                  key: ValueKey(slot.key),
                  duration: move,
                  curve: Curves.easeOutCubic,
                  left: (slot.index % columns) * (cellWidth + widget.crossGap),
                  top:
                      (slot.index ~/ columns) *
                      (widget.cellHeight + widget.mainGap),
                  width: cellWidth,
                  height: widget.cellHeight,
                  child: _SlotBody<T>(
                    slot: slot,
                    motion: widget.motion,
                    child: widget.itemBuilder(
                      context,
                      slot.item,
                      slot.index,
                      slot.isLeaving,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Slot<T> {
  _Slot({
    required this.key,
    required this.item,
    required this.index,
    required this.stagger,
    required this.controller,
  });

  final Object key;
  T item;
  int index;
  bool isLeaving = false;
  final Duration stagger;
  final AnimationController controller;

  /// Where this cell's entrance begins inside its own controller.
  double get staggerFraction {
    final total = controller.duration?.inMicroseconds ?? 0;
    return total == 0 ? 0 : stagger.inMicroseconds / total;
  }
}

/// Fades a cell in as it lifts, or out as it shrinks.
class _SlotBody<T> extends StatelessWidget {
  const _SlotBody({
    required this.slot,
    required this.motion,
    required this.child,
  });

  final _Slot<T> slot;
  final ReflowMotion motion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: slot.controller,
      child: child,
      builder: (context, child) {
        final raw = slot.controller.value.clamp(0.0, 1.0);
        if (slot.isLeaving) {
          final t = Curves.easeOut.transform(raw);
          return Opacity(
            opacity: t,
            child: Transform.scale(
              scale: motion.exitScale + (1 - motion.exitScale) * t,
              child: child,
            ),
          );
        }
        final t = Interval(
          slot.staggerFraction,
          1,
          curve: Curves.easeOutCubic,
        ).transform(raw);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, motion.enterOffset * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
