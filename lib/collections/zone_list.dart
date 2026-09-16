import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/collections/collections_models.dart';
import 'package:spec/collections/collections_tokens.dart';

const _enterDuration = Duration(milliseconds: 320);

/// A leaving row fades and shrinks for 200ms, then its height collapses for
/// 260ms. One controller runs both, split at [_leaveSplit].
const _leaveDuration = Duration(milliseconds: 460);
const _leaveSplit = 200 / 460;
const _leaveScale = 0.97;

const _liftScale = 1.02;

/// Builds one row. [index] is the row's position among what is on screen,
/// which is also the index a drag listener must be given.
typedef ZoneRowBuilder = Widget Function(
  BuildContext context,
  int index,
  CollectionZone zone,
);

/// The zone rows as a reorderable sliver that animates rows in and out.
///
/// Rows are matched by id across rebuilds: a new id grows in, a vanished id
/// fades and collapses, and a row that survives stays where it is. A list
/// whose ids are all negative is a placeholder (the empty state's default
/// names), and real rows replace it without animating.
class AnimatedZoneList extends StatefulWidget {
  const AnimatedZoneList({
    super.key,
    required this.zones,
    required this.itemBuilder,
    required this.onReorder,
  });

  final List<CollectionZone> zones;
  final ZoneRowBuilder itemBuilder;

  /// The new order of zone ids, top first.
  final ValueChanged<List<int>> onReorder;

  @override
  State<AnimatedZoneList> createState() => _AnimatedZoneListState();
}

class _AnimatedZoneListState extends State<AnimatedZoneList>
    with TickerProviderStateMixin {
  List<_Entry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _entries = [for (final zone in widget.zones) _settled(zone)];
  }

  @override
  void didUpdateWidget(AnimatedZoneList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.zones, widget.zones)) _sync();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  _Entry _settled(CollectionZone zone) => _Entry(
    zone: zone,
    enter: AnimationController(vsync: this, duration: _enterDuration, value: 1),
    leave: AnimationController(vsync: this, duration: _leaveDuration),
  );

  void _sync() {
    final isMotionReduced = MediaQuery.disableAnimationsOf(context);
    final isPlaceholder = _entries.every((e) => e.zone.id < 0);

    if (isPlaceholder) {
      for (final entry in _entries) {
        entry.dispose();
      }
      setState(() {
        _entries = [for (final zone in widget.zones) _settled(zone)];
      });
      return;
    }

    final byId = {for (final entry in _entries) entry.zone.id: entry};
    final incomingIds = {for (final zone in widget.zones) zone.id};
    final next = <_Entry>[];
    var hasEntered = false;

    for (final zone in widget.zones) {
      final existing = byId[zone.id];
      if (existing != null) {
        next.add(existing.withZone(zone));
        continue;
      }
      final entry = _settled(zone);
      if (!isMotionReduced) {
        entry.enter
          ..value = 0
          ..forward();
      }
      hasEntered = true;
      next.add(entry);
    }

    // Leaving rows hold their old position until they have collapsed.
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      if (incomingIds.contains(entry.zone.id)) continue;
      next.insert(i.clamp(0, next.length), entry);
      if (entry.isLeaving) continue;
      entry.isLeaving = true;
      if (isMotionReduced) {
        _drop(entry);
      } else {
        entry.leave.forward().whenComplete(() => _drop(entry));
      }
    }

    if (hasEntered) HapticFeedback.mediumImpact();
    setState(() => _entries = next);
  }

  void _drop(_Entry entry) {
    if (!mounted) return;
    setState(() => _entries = [..._entries]..remove(entry));
    entry.dispose();
  }

  /// [target] is already adjusted for the row lifted out at [oldIndex].
  void _onReorder(int oldIndex, int target) {
    if (target == oldIndex) return;
    final moved = _entries[oldIndex];
    final next = [..._entries]
      ..removeAt(oldIndex)
      ..insert(target, moved);
    setState(() => _entries = next);
    widget.onReorder([
      for (final entry in next)
        if (!entry.isLeaving) entry.zone.id,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SliverReorderableList(
      itemCount: _entries.length,
      onReorderItem: _onReorder,
      onReorderStart: (_) => HapticFeedback.lightImpact(),
      // ponytail: the rows parting around a drag run on the framework's own
      // reorder timing, and there is no per-crossing callback to haptic on;
      // a custom drag layer is the upgrade if either ever matters.
      proxyDecorator: _lift,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return KeyedSubtree(
          key: ValueKey(entry.zone.id),
          child: _Presence(
            entry: entry,
            child: IgnorePointer(
              ignoring: entry.isLeaving,
              child: widget.itemBuilder(context, index, entry.zone),
            ),
          ),
        );
      },
    );
  }

  /// The dragged row rises out of the list: a little larger, with a shadow.
  Widget _lift(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, inner) {
        final t = Curves.easeOutCubic.transform(animation.value);
        // The proxy is drawn in the overlay, outside the screen's text style.
        return DefaultTextStyle(
          style: const TextStyle(decoration: TextDecoration.none),
          child: Transform.scale(
            scale: 1 + (_liftScale - 1) * t,
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: CollectionsColors.liftShadow.withValues(
                      alpha: CollectionsColors.liftShadow.a * t,
                    ),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: inner,
            ),
          ),
        );
      },
    );
  }
}

class _Entry {
  _Entry({required this.zone, required this.enter, required this.leave});

  CollectionZone zone;
  final AnimationController enter;
  final AnimationController leave;
  bool isLeaving = false;

  /// Controllers are identity, so a surviving row keeps them and only its
  /// data is swapped.
  _Entry withZone(CollectionZone next) {
    zone = next;
    return this;
  }

  void dispose() {
    enter.dispose();
    leave.dispose();
  }
}

class _Presence extends StatelessWidget {
  const _Presence({required this.entry, required this.child});

  final _Entry entry;
  final Widget child;

  static const _fadeOut = Interval(0, _leaveSplit, curve: Curves.easeOut);
  static const _collapse = Interval(_leaveSplit, 1, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([entry.enter, entry.leave]),
      child: child,
      builder: (context, inner) {
        final entering = Curves.easeOutCubic.transform(entry.enter.value);
        final fading = _fadeOut.transform(entry.leave.value);
        final collapsing = _collapse.transform(entry.leave.value);
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: entering * (1 - collapsing),
            child: Opacity(
              opacity: entering * (1 - fading),
              child: Transform.scale(
                scale: 1 - (1 - _leaveScale) * fading,
                child: inner,
              ),
            ),
          ),
        );
      },
    );
  }
}
