import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/collections/collections_chips.dart';
import 'package:spec/collections/collections_header.dart';
import 'package:spec/collections/collections_models.dart';
import 'package:spec/collections/collections_tokens.dart';
import 'package:spec/collections/zone_list.dart';
import 'package:spec/collections/zone_row.dart';
import 'package:spec/data/zone_repository.dart';
import 'package:spec/theme/spec_tokens.dart';

/// 56 for the status bar, 18 either side, and 112 at the bottom so the last
/// row scrolls clear of the floating tab bar.
///
/// The list's viewport starts at [_top] rather than the content inside it,
/// so scrolled rows are clipped there and never pass under the status bar.
const _side = 18.0;
const _top = 56.0;
const _bottom = 112.0;
const _blockGap = 20.0;

const _enterDuration = Duration(milliseconds: 680);
const _reducedEnterDuration = Duration(milliseconds: 200);

/// Rows past this share the last stagger slot rather than arriving late.
const _maxStaggeredRows = 8;

const _hairlineOffset = 8.0;
const _hairlineDuration = Duration(milliseconds: 160);
const _hairlineColor = Color(0x1AFFFFFF);

const _emptyDuration = Duration(milliseconds: 300);

/// Content clears over the first 200ms of the 420ms push to Search.
const _pushFadeCurve = Interval(0, 0.48, curve: Curves.easeOut);

/// Screen 06, the second tab root. Zero [objects] drives the empty state,
/// which keeps the populated layout and ghosts its rows.
///
/// The tab bar and orb are not here: they belong to the shell both roots
/// share, so they never re-enter on a tab switch.
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({
    super.key,
    required this.zones,
    required this.objects,
    required this.photos,
    this.isActive = true,
    this.onOpenZone,
    this.onCreateZone,
    this.onRenameZone,
    this.onReorderZones,
    this.onDeleteZone,
    this.onExport,
    this.newZoneRequest = 0,
  });

  final List<CollectionZone> zones;
  final int objects;
  final int photos;

  /// Flipping to true replays the entrance, which runs each time the tab is
  /// shown.
  final bool isActive;

  final ValueChanged<CollectionZone>? onOpenZone;

  /// Both resolve false when the name was refused.
  final Future<bool> Function(String name)? onCreateZone;
  final Future<bool> Function(int id, String name)? onRenameZone;

  final ValueChanged<List<int>>? onReorderZones;
  final ValueChanged<int>? onDeleteZone;

  /// Resolves false when the share sheet was dismissed without sharing.
  final Future<bool> Function()? onExport;

  /// Each change opens the `+ NEW ZONE` name field, focused.
  final int newZoneRequest;

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _enterDuration,
  );
  final ScrollController _scroll = ScrollController();

  bool _isMotionReduced = false;
  bool _isScrolled = false;
  bool _isEditing = false;
  int? _renamingId;
  int? _confirmingId;

  bool get _isEmpty => widget.objects == 0;

  /// The empty state teaches the populated one: before any zone exists, the
  /// defaults stand in as ghosts, with negative ids so the list knows they
  /// are placeholders.
  ///
  /// Only an empty archive gets them. Objects left with every zone deleted
  /// show no rows, never interactive rows with no zone behind them.
  List<CollectionZone> get _rows => widget.zones.isNotEmpty || !_isEmpty
      ? widget.zones
      : [
          for (var i = 0; i < kDefaultZoneNames.length; i++)
            CollectionZone(id: -1 - i, name: kDefaultZoneNames[i], count: 0),
        ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isReduced = MediaQuery.disableAnimationsOf(context);
    final isFirst = _enter.status == AnimationStatus.dismissed;
    _isMotionReduced = isReduced;
    _enter.duration = isReduced ? _reducedEnterDuration : _enterDuration;
    if (isFirst && widget.isActive) _enter.forward();
  }

  @override
  void didUpdateWidget(CollectionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _enter.forward(from: 0);
    if (_isEmpty && _isEditing) _stopEditing();
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _enter.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isScrolled = _scroll.offset > _hairlineOffset;
    if (isScrolled != _isScrolled) setState(() => _isScrolled = isScrolled);
  }

  void _toggleEditing() {
    if (_isEditing) {
      HapticFeedback.mediumImpact();
      _stopEditing();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _isEditing = true);
  }

  void _stopEditing() {
    // Unfocusing commits a rename in progress before its field goes away. The
    // focus change lands in a microtask, and its commit must still find the row
    // renaming, so the edit state clears in a microtask queued after it.
    FocusManager.instance.primaryFocus?.unfocus();
    scheduleMicrotask(() {
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _renamingId = null;
        _confirmingId = null;
      });
    });
  }

  void _remove(CollectionZone zone) {
    // An empty zone goes at once; one holding objects asks, in the row.
    if (zone.count == 0) {
      widget.onDeleteZone?.call(zone.id);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _confirmingId = zone.id);
  }

  void _confirmRemove(CollectionZone zone) {
    HapticFeedback.mediumImpact();
    setState(() => _confirmingId = null);
    widget.onDeleteZone?.call(zone.id);
  }

  /// Resolves false when the name was refused; the field then stays open
  /// for the row to say why.
  Future<bool> _rename(CollectionZone zone, String name) async {
    if (_renamingId != zone.id) return true;
    if (name.trim() != zone.name) {
      final isRenamed = await widget.onRenameZone?.call(zone.id, name) ?? false;
      if (!mounted) return isRenamed;
      if (!isRenamed) {
        unawaited(HapticFeedback.lightImpact());
        return false;
      }
    }
    if (_renamingId == zone.id) setState(() => _renamingId = null);
    return true;
  }

  /// Fades a block in over its slice of the entrance, lifting it by [dy].
  Widget _rise(double begin, double end, Widget child, {double dy = 0}) {
    final curve = Interval(
      begin.clamp(0, 1),
      end.clamp(0, 1),
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: _enter,
      child: child,
      builder: (context, inner) {
        final t = curve.transform(_enter.value);
        return Opacity(
          opacity: t,
          child: _isMotionReduced || dy == 0
              ? inner
              : Transform.translate(
                  offset: Offset(0, dy * (1 - t)),
                  child: inner,
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: SpecFonts.display,
        color: SpecColors.ink,
        decoration: TextDecoration.none,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: SpecColors.bg),
          Positioned(
            top: _top,
            left: 0,
            right: 0,
            // The keyboard's top edge, so a focused field scrolls clear of
            // it rather than being typed into underneath.
            bottom: MediaQuery.viewInsetsOf(context).bottom,
            child: _pushFade(
              CustomScrollView(
                controller: _scroll,
                slivers: [
                  _box(_buildTop()),
                  _box(_buildRule()),
                  _box(_buildEmptyBlock()),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: _side),
                    sliver: AnimatedZoneList(
                      zones: _rows,
                      itemBuilder: _buildRow,
                      onReorder: (ids) => widget.onReorderZones?.call(ids),
                    ),
                  ),
                  _box(
                    _rise(
                      0.58,
                      0.92,
                      CollectionsChips(
                        onCreateZone: widget.onCreateZone ?? (_) async => false,
                        // Present whenever there is something to export, even
                        // before a share target is wired.
                        onExport: _isEmpty
                            ? null
                            : (widget.onExport ?? () async => false),
                        openRequest: widget.newZoneRequest,
                      ),
                      dy: 12,
                    ),
                    top: _blockGap,
                    bottom: _bottom,
                  ),
                ],
              ),
            ),
          ),
          // The only thing the scroll position changes.
          Positioned(
            top: _top,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _isScrolled ? 1 : 0,
              duration: _hairlineDuration,
              child: const SizedBox(
                height: 1,
                child: ColoredBox(color: _hairlineColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(Widget child, {double top = 0, double bottom = 0}) =>
      SliverPadding(
        padding: EdgeInsets.fromLTRB(_side, top, _side, bottom),
        sliver: SliverToBoxAdapter(child: child),
      );

  Widget _buildTop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rise(
          0,
          0.26,
          CollectionsHeaderRow(
            isEditing: _isEditing,
            onEdit: _isEmpty ? null : _toggleEditing,
          ),
        ),
        const SizedBox(height: _blockGap),
        CollectionsTitle(
          objects: widget.objects,
          photos: widget.photos,
          wrapTitle: (child) => _rise(0.06, 0.50, child, dy: 20),
          wrapTotal: (i, child) =>
              _rise(0.14 + i * 0.05, 0.42 + i * 0.05, child),
        ),
        const SizedBox(height: _blockGap),
      ],
    );
  }

  /// The strong rule above the rows, drawn outward from the left.
  Widget _buildRule() {
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final t = const Interval(
          0.20,
          0.52,
          curve: Curves.easeOutCubic,
        ).transform(_enter.value);
        return Transform.scale(
          scaleX: _isMotionReduced ? 1 : t,
          alignment: Alignment.centerLeft,
          child: Opacity(opacity: _isMotionReduced ? t : 1, child: child),
        );
      },
      child: const SizedBox(
        height: 1,
        child: ColoredBox(color: CollectionsColors.ruleStrong),
      ),
    );
  }

  Widget _buildEmptyBlock() {
    return AnimatedSize(
      duration: _isMotionReduced ? Duration.zero : _emptyDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _isEmpty
          ? _rise(
              0.26,
              0.60,
              const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CollectionsEmptyBlock(),
                  SizedBox(height: _blockGap),
                ],
              ),
              dy: 18,
            )
          : const SizedBox(width: double.infinity),
    );
  }

  Widget _buildRow(BuildContext context, int index, CollectionZone zone) {
    final zones = _rows;
    final lime = _isEmpty ? null : largestZoneIndex(zones);
    final slot = index.clamp(0, _maxStaggeredRows - 1);
    // Ghosts sit under the empty block, so they start after it.
    final start = (_isEmpty ? 0.34 : 0.26) + slot * 0.05;

    return _rise(
      start,
      start + 0.34,
      ZoneRow(
        index: index,
        zone: zone,
        isLime: zones.indexWhere((z) => z.id == zone.id) == lime,
        isGhost: _isEmpty,
        isEditing: _isEditing,
        isRenaming: _renamingId == zone.id,
        isConfirming: _confirmingId == zone.id,
        onOpen: () => widget.onOpenZone?.call(zone),
        onStartRename: () => setState(() {
          _confirmingId = null;
          _renamingId = zone.id;
        }),
        onRename: (name) => _rename(zone, name),
        onRemove: () => _remove(zone),
        onConfirmRemove: () => _confirmRemove(zone),
        onCancelConfirm: () => setState(() => _confirmingId = null),
        wrapHandle: (handle) => _isEditing
            ? ReorderableDragStartListener(index: index, child: handle)
            : handle,
      ),
      dy: 18,
    );
  }

  /// Fades the content out as a route is pushed over the shell.
  ///
  /// Driven by the outgoing route animation, so the content clears at exactly
  /// the rate the pushed screen arrives.
  Widget _pushFade(Widget child) {
    final secondary = ModalRoute.of(context)?.secondaryAnimation;
    if (secondary == null) return child;
    return AnimatedBuilder(
      animation: secondary,
      child: child,
      builder: (context, inner) => Opacity(
        opacity: 1 - _pushFadeCurve.transform(secondary.value.clamp(0, 1)),
        child: inner,
      ),
    );
  }
}
