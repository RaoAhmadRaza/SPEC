import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/add/add_kinds.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/reminder_schedule.dart';
import 'package:spec/object/object_action_bar.dart';
import 'package:spec/object/object_hero.dart';
import 'package:spec/object/object_inline_edit.dart';
import 'package:spec/object/object_layout.dart';
import 'package:spec/object/object_models.dart';
import 'package:spec/object/object_notes.dart';
import 'package:spec/object/object_page_route.dart';
import 'package:spec/object/object_parts.dart';
import 'package:spec/object/object_photos.dart';
import 'package:spec/object/object_sheet.dart';
import 'package:spec/object/object_table.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/object/object_viewer.dart';
import 'package:spec/theme/spec_tokens.dart';

const _enterDuration = Duration(milliseconds: 520);
const _reducedEnterDuration = Duration(milliseconds: 200);
const _rulesDuration = Duration(milliseconds: 200);
const _labelsDuration = Duration(milliseconds: 180);
const _pressDuration = Duration(milliseconds: 280);
const _ringDuration = Duration(milliseconds: 420);
const _flashDuration = Duration(milliseconds: 600);
const _dateSwapDuration = Duration(milliseconds: 240);

const _gapChips = 8.0;
const _pillDip = 0.94;
const _hitInset = (ObjectMetrics.minHitBox - ObjectMetrics.circle) / 2;

/// LAST REPLACED, NEXT DUE, PURCHASED, NOTES.
const _metaRowCount = 4;

/// A due date that has arrived takes the accent, the colour that already
/// means "act on this".
final _overdueValue = ObjectText.metaValue.copyWith(color: SpecColors.accent);

/// Room for a sentence without letting a long note push the page around.
const _notesMaxLines = 2;

/// Joins the name and subtitle on the identity line.
const _identitySeparator = ' · ';

/// Screen 03. The spec is the hero: the single largest element, arriving by
/// interpolation from the card that opened it, with nothing on the page
/// allowed to compete.
///
/// Pure presentation driven by callbacks, so its tests build it directly with
/// no database, no photo files and no ProviderScope.
class ObjectScreen extends StatefulWidget {
  const ObjectScreen({
    super.key,
    required this.object,
    required this.sourceSpecStyle,
    required this.sourcePhotoRadius,
    this.source = ObjectSource.homeTile,
    this.onBack,
    this.onShare,
    this.onReplaced,
    this.onSave,
    this.onMenu,
    this.onReplacePhoto,
    this.onRemovePhoto,
  });

  final ObjectView object;

  /// 32pt from a Home tile (27pt when its spec wraps), 26pt from a search row.
  final TextStyle sourceSpecStyle;
  final BorderRadius sourcePhotoRadius;
  final ObjectSource source;

  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final ValueChanged<DateTime>? onReplaced;
  final ValueChanged<ObjectEdits>? onSave;

  /// The ••• circle. The route opens the object actions sheet, which Home's
  /// card ••• shares, so the sheet is not built here.
  final VoidCallback? onMenu;
  final ValueChanged<int>? onReplacePhoto;
  final ValueChanged<int>? onRemovePhoto;

  @override
  State<ObjectScreen> createState() => _ObjectScreenState();
}

class _ObjectScreenState extends State<ObjectScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _enterDuration,
  );
  late final AnimationController _rules = AnimationController(
    vsync: this,
    duration: _rulesDuration,
  );
  late final AnimationController _labels = AnimationController(
    vsync: this,
    duration: _labelsDuration,
  );
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: _pressDuration,
  );
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: _ringDuration,
  );
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: _flashDuration,
  );

  late final _header = _seg(0.00, 0.30);
  late final _subZone = _seg(0.08, 0.40);
  late final _subtitle = _seg(0.15, 0.50);
  late final _tableRules = _seg(0.20, 0.55);
  late final _detailPhoto = _seg(0.38, 0.75);
  late final _bar = _seg(0.55, 1.00);
  final _cells = <int, CurvedAnimation>{};
  late final List<CurvedAnimation> _metaRows = [
    for (var i = 0; i < _metaRowCount; i++)
      _seg(0.45 + i * 0.06, 0.80 + i * 0.06),
  ];

  late final CurvedAnimation _ruleFade = CurvedAnimation(
    parent: _rules,
    curve: Curves.easeOut,
  );
  late final CurvedAnimation _ringOut = CurvedAnimation(
    parent: _ring,
    curve: Curves.easeOut,
  );

  /// 1 → 0.94 over 100ms, then back over 180ms with a little overshoot.
  late final Animation<double> _pillScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: _pillDip,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 100,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: _pillDip,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 180,
    ),
  ]).animate(_press);

  /// ink62 → lime → ink62.
  late final Animation<double> _labelFlash = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _flash, curve: Curves.easeInOut));

  late ObjectView _view = widget.object;
  late final TextEditingController _spec;
  late List<TextEditingController> _fields;
  late final TextEditingController _purchased;
  late final TextEditingController _replaced;
  late final TextEditingController _notes;
  late final FocusNode _specFocus = FocusNode();
  late List<FocusNode> _fieldFocus;
  late final FocusNode _purchasedFocus = FocusNode();
  late final FocusNode _replacedFocus = FocusNode();
  late final FocusNode _notesFocus = FocusNode();

  bool _isEditing = false;
  bool _isMotionReduced = false;

  Animation<double>? _route;

  /// The body's departure is keyed to the route only once it has arrived;
  /// before that, the entrance controller owns it.
  bool _hasArrived = false;

  CurvedAnimation _seg(double begin, double end) => CurvedAnimation(
    parent: _enter,
    curve: Interval(
      begin.clamp(0, 1),
      end.clamp(0, 1),
      curve: Curves.easeOutCubic,
    ),
  );

  CurvedAnimation _cell(int index) => _cells.putIfAbsent(
    index,
    () => _seg(0.28 + index * 0.05, 0.63 + index * 0.05),
  );

  @override
  void initState() {
    super.initState();
    _spec = TextEditingController(text: _view.spec);
    _purchased = TextEditingController();
    _replaced = TextEditingController();
    _notes = NotesController();
    _fields = [];
    _fieldFocus = [];
    _syncControllers();
  }

  @override
  void didUpdateWidget(ObjectScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh read of the row, while the user is not mid-edit, replaces what
    // is on screen. Mid-edit, their typing wins.
    if (widget.object != oldWidget.object && !_isEditing) {
      _view = widget.object;
      _syncControllers();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isMotionReduced = MediaQuery.disableAnimationsOf(context);
    _enter.duration = _isMotionReduced ? _reducedEnterDuration : _enterDuration;

    final route = ModalRoute.of(context)?.animation;
    if (route == _route) return;
    _route?.removeListener(_onRoute);
    _route = route;
    route?.addListener(_onRoute);
    _onRoute();
  }

  /// Starts the body at 45% of the flight, and — once arrived — lets the route
  /// animation carry it back out, so a back swipe clears it under the finger.
  ///
  /// No `setState` here: every entering block listens to the route directly,
  /// so a departure repaints those blocks rather than rebuilding the page on
  /// every frame of it.
  void _onRoute() {
    final route = _route;
    if (route == null || route.isCompleted) {
      _hasArrived = true;
      if (_enter.status.isDismissed) _enter.forward();
      return;
    }
    if (_hasArrived) return;
    final startsAt = _isMotionReduced ? 0.0 : kBodyStartsAt;
    if (route.value >= startsAt && _enter.status.isDismissed) {
      _enter.forward();
    }
  }

  /// 1 while here; falls to 0 over the first 200ms of a 520ms departure.
  double get _leave {
    final route = _route;
    if (!_hasArrived || route == null) return 1;
    return const Interval(1 - kBodyClearsBy, 1).transform(route.value);
  }

  void _syncControllers() {
    _spec.text = _view.spec;
    _purchased.text = _view.purchasedFrom ?? '';
    _replaced.text = _view.lastReplaced == null
        ? ''
        : formatSpecDate(_view.lastReplaced);
    _notes.text = _view.notes ?? '';

    final fields = _view.fields;
    if (_fields.length != fields.length) {
      for (final c in _fields) {
        c.dispose();
      }
      for (final f in _fieldFocus) {
        f.dispose();
      }
      _fields = [for (final f in fields) TextEditingController(text: f.value)];
      _fieldFocus = [for (final _ in fields) FocusNode()];
    } else {
      for (var i = 0; i < fields.length; i++) {
        _fields[i].text = fields[i].value;
      }
    }
  }

  @override
  void dispose() {
    _route?.removeListener(_onRoute);
    for (final animation in [
      _header,
      _subZone,
      _subtitle,
      _tableRules,
      _detailPhoto,
      _bar,
      ..._cells.values,
      ..._metaRows,
      _ruleFade,
      _ringOut,
    ]) {
      animation.dispose();
    }
    for (final controller in [_enter, _rules, _labels, _press, _ring, _flash]) {
      controller.dispose();
    }
    for (final c in [_spec, _purchased, _replaced, _notes, ..._fields]) {
      c.dispose();
    }
    for (final f in [
      _specFocus,
      _purchasedFocus,
      _replacedFocus,
      _notesFocus,
      ..._fieldFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _onBar(BarAction action) {
    switch ((action, _isEditing)) {
      case (BarAction.primary, false):
        _startEditing();
      case (BarAction.primary, true):
        _cancelEditing();
      case (BarAction.secondary, false):
        widget.onShare?.call();
      case (BarAction.secondary, true):
        break;
      case (BarAction.pill, false):
        _markReplaced();
      case (BarAction.pill, true):
        _save();
    }
  }

  /// The one celebratory moment in the app, and the only thing that flashes.
  void _markReplaced() {
    HapticFeedback.mediumImpact();
    final today = DateTime.now();
    _press.forward(from: 0);
    // Reduce Motion keeps the haptic and the date, and drops the ring.
    if (!_isMotionReduced) _ring.forward(from: 0);
    _flash.forward(from: 0);
    setState(() {
      _view = _view.copyWith(lastReplaced: toIsoDate(today));
      _replaced.text = formatSpecDate(_view.lastReplaced);
    });
    widget.onReplaced?.call(today);
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _rules.forward();
    _labels.forward();
    _specFocus.requestFocus();
  }

  void _endEditing() {
    FocusScope.of(context).unfocus();
    _rules.reverse();
    _labels.reverse();
    setState(() => _isEditing = false);
  }

  void _cancelEditing() {
    _syncControllers();
    _endEditing();
  }

  void _save() {
    final spec = _spec.text.trim();
    final purchased = _purchased.text.trim();
    final replacedText = _replaced.text.trim();

    final edits = ObjectEdits(
      // An empty spec would leave the page with no hero; keep the old one.
      spec: spec.isEmpty ? _view.spec : spec,
      fields: [
        for (var i = 0; i < _view.fields.length; i++)
          SpecAttribute(
            label: _view.fields[i].label,
            value: _fields[i].text.trim(),
          ),
      ],
      purchasedFrom: purchased.isEmpty ? null : purchased,
      lastReplaced: replacedText.isEmpty
          ? null
          : parseSpecDate(replacedText) ?? _view.lastReplaced,
      notes: cleanNotes(_notes.text),
    );

    HapticFeedback.mediumImpact();
    setState(() {
      _view = ObjectView(
        id: _view.id,
        name: _view.name,
        zone: _view.zone,
        subZone: _view.subZone,
        spec: edits.spec,
        subtitle: _view.subtitle,
        fields: edits.fields,
        mainPhoto: _view.mainPhoto,
        detailPhoto: _view.detailPhoto,
        lastReplaced: edits.lastReplaced,
        purchasedFrom: edits.purchasedFrom,
        notes: edits.notes,
        remindEveryMonths: _view.remindEveryMonths,
        createdAt: _view.createdAt,
      );
    });
    _syncControllers();
    _endEditing();
    widget.onSave?.call(edits);
  }

  void _onBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    Navigator.maybePop(context);
  }

  void _openPhoto(int slot, Rect origin) {
    final photo = slot == kMainSlot ? _view.mainPhoto : _view.detailPhoto;
    // An empty slot has nothing to expand.
    if (photo == null || origin.isEmpty) return;
    Navigator.of(context).push(
      PhotoViewerRoute(
        photo: photo,
        origin: origin,
        originRadius: slot == kMainSlot
            ? ObjectMetrics.mainPhotoRadius
            : ObjectMetrics.detailPhotoRadius,
        isMotionReduced: _isMotionReduced,
      ),
    );
  }

  void _photoMenu(int slot, Rect _) {
    final photo = slot == kMainSlot ? _view.mainPhoto : _view.detailPhoto;
    // An empty slot has nothing to replace or remove.
    if (photo == null) return;
    HapticFeedback.selectionClick();
    showObjectSheet(
      context,
      items: [
        SheetItem(
          label: 'Replace',
          onTap: () => widget.onReplacePhoto?.call(slot),
        ),
        SheetItem(
          label: 'Remove',
          isDestructive: true,
          needsConfirmation: true,
          onTap: () => widget.onRemovePhoto?.call(slot),
        ),
      ],
    );
  }

  // ─── Motion ───────────────────────────────────────────────────────────────

  /// Fades a block in, and under full motion moves or scales it as it comes.
  /// Once arrived, the route animation fades it back out on departure.
  Widget _in(
    Animation<double> animation,
    Widget child, {
    double dx = 0,
    double dy = 0,
    double scaleFrom = 1,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, ?_route]),
      builder: (context, inner) {
        final t = animation.value;
        final opacity = math.min(t, _leave);
        if (_isMotionReduced) return Opacity(opacity: opacity, child: inner);

        // The departure drops the block as it fades, the way it rose in.
        final settle = math.min(t, 0.5 + _leave / 2);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(dx * (1 - t), dy * (1 - settle)),
            child: Transform.scale(
              scale: scaleFrom + (1 - scaleFrom) * t,
              child: inner,
            ),
          ),
        );
      },
      child: child,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    const page = ObjectMetrics.page;
    final barArea = page.bottom + ObjectMetrics.barHeight;

    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: SpecFonts.display,
        color: SpecColors.ink,
        decoration: TextDecoration.none,
      ),
      child: ColoredBox(
        color: SpecColors.bg,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth - page.horizontal;
            // The bar floats over the column's foot. When the object fits, the
            // spacer parks the metadata right above it; when it does not, the
            // page scrolls under it and the bar stays pinned.
            final minHeight = math.max(
              0.0,
              constraints.maxHeight - page.top - barArea,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                // The viewport ends at the keyboard rather than running under
                // it, so a focused field scrolls up clear of it; the bar's
                // share of the clearance is the fields' own scroll padding.
                Padding(
                  padding: EdgeInsets.only(bottom: keyboard),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      page.left,
                      page.top,
                      page.right,
                      barArea,
                    ),
                    child: BodyWithFoot(
                      minHeight: minHeight,
                      gap: ObjectMetrics.gap,
                      body: _buildBody(contentWidth),
                      foot: _buildFoot(),
                    ),
                  ),
                ),
                // Laid out on 44pt touch targets around 40pt circles, and pulled
                // out by the 2pt difference, so the visuals sit exactly where
                // the design puts them and no target is clipped by the column.
                Positioned(
                  left: page.left - _hitInset,
                  right: page.right - _hitInset,
                  top: page.top - _hitInset,
                  child: _in(
                    _header,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlassCircle.back(onTap: _onBack),
                        GlassCircle.more(onTap: () => widget.onMenu?.call()),
                      ],
                    ),
                    scaleFrom: 0.9,
                  ),
                ),
                Positioned(
                  left: page.left,
                  right: page.right,
                  // Tracks the keyboard with no curve of its own: the keyboard
                  // is already animating, and a second curve would lag it.
                  bottom: page.bottom + keyboard,
                  child: _in(
                    _bar,
                    ObjectActionBar(
                      editing: _labels,
                      pillPress: _pillScale,
                      ring: _ringOut,
                      onAction: _onBar,
                    ),
                    dy: 22,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(double contentWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The circles float above the column (see [build]); this holds their
        // place so the gap below them is the design's 24.
        const SizedBox(height: ObjectMetrics.circle),
        const SizedBox(height: ObjectMetrics.gap),
        _buildIdentity(contentWidth),
        const SizedBox(height: ObjectMetrics.gap),
        SpecTable(
          fields: _view.fields,
          controllers: _fields,
          focusNodes: _fieldFocus,
          isEditing: _isEditing,
          editRule: _ruleFade,
          ruleGrow: _tableRules,
          wrapCell: (index, child) => _in(_cell(index), child, dy: 10),
        ),
        const SizedBox(height: ObjectMetrics.gap),
        PhotoPair(
          id: _view.id,
          mainPhoto: _view.mainPhoto,
          detailPhoto: _view.detailPhoto,
          sourceRadius: widget.sourcePhotoRadius,
          onOpen: _openPhoto,
          onLongPress: _photoMenu,
          wrapDetail: (child) => _in(_detailPhoto, child, scaleFrom: 0.96),
          isMotionReduced: _isMotionReduced,
        ),
      ],
    );
  }

  /// The metadata rows, parked above the bar.
  Widget _buildFoot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _in(_metaRows[0], _buildReplacedRow(), dy: 10),
        _in(_metaRows[1], _buildNextDueRow(), dy: 10),
        _in(
          _metaRows[2],
          MetaRow(
            label: 'PURCHASED',
            value: InlineValue(
              controller: _purchased,
              focusNode: _purchasedFocus,
              style: ObjectText.metaValue,
              isEditing: _isEditing,
              rule: _ruleFade,
              textAlign: TextAlign.right,
              resting: Text(
                _view.purchasedFrom?.toUpperCase() ?? kMissingValue,
                style: ObjectText.metaValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          dy: 10,
        ),
        // Rides PURCHASED's entrance: an optional row, and a fourth slot in
        // the stagger would delay NOTES for every object without one.
        if (_view.remindEveryMonths case final int months)
          _in(
            _metaRows[2],
            MetaRow(
              label: 'REMIND ME',
              value: Text(
                reminderLabel(months),
                style: ObjectText.metaValue,
                maxLines: 1,
              ),
            ),
            dy: 10,
          ),
        _in(_metaRows[3], _buildNotesRow(), dy: 10),
      ],
    );
  }

  /// Last, so it carries the clearance above the bar. Free text keeps the
  /// case it was written in, unlike the vendor above it.
  Widget _buildNotesRow() {
    return MetaRow(
      label: 'NOTES',
      bottomPadding: ObjectMetrics.barClearance,
      value: InlineValue(
        controller: _notes,
        focusNode: _notesFocus,
        style: ObjectText.metaValue,
        isEditing: _isEditing,
        rule: _ruleFade,
        textAlign: TextAlign.right,
        maxLines: _notesMaxLines,
        resting: Text(
          _view.notes ?? kMissingValue,
          style: ObjectText.metaValue,
          textAlign: TextAlign.right,
          maxLines: _notesMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildIdentity(double contentWidth) {
    final subZone = _view.subZone;
    final zoneChip = ZoneChipFrame(
      label: _view.zone,
      origin: ZoneChipOrigin.of(widget.source),
      t: 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Reduce Motion drops the flights: the page cross-fades in with
            // everything already where it rests.
            if (_isMotionReduced)
              zoneChip
            else
              ZoneChipHero(
                id: _view.id,
                label: _view.zone,
                origin: ZoneChipOrigin.of(widget.source),
                child: zoneChip,
              ),
            if (subZone != null) ...[
              const SizedBox(width: _gapChips),
              Flexible(
                child: _in(_subZone, SubZoneChip(label: subZone), dx: -8),
              ),
            ],
          ],
        ),
        const SizedBox(height: ObjectMetrics.identityGap),
        _buildSpec(contentWidth),
        if (_identityLine case final String line) ...[
          const SizedBox(height: ObjectMetrics.identityGap),
          _in(
            _subtitle,
            Text(
              line,
              style: ObjectText.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            dy: 10,
          ),
        ],
      ],
    );
  }

  /// `Bulb`, or `Bulb · 2 fittings`: what the object is called, under the
  /// spec that identifies it.
  String? get _identityLine {
    final parts = [?_view.name, ?_view.subtitle];
    return parts.isEmpty ? null : parts.join(_identitySeparator);
  }

  Widget _buildSpec(double contentWidth) {
    final base = _view.isSpecTall ? ObjectText.specTwoLine : ObjectText.spec;
    final text = _view.specText;
    final style = fitSpecStyle(
      text: text,
      base: base,
      maxWidth: contentWidth,
      textScaler: MediaQuery.textScalerOf(context),
    );
    final maxLines = _view.isSpecTall ? 2 : 1;

    final spec = InlineValue(
      controller: _spec,
      focusNode: _specFocus,
      style: style,
      isEditing: _isEditing,
      rule: _ruleFade,
      maxLines: maxLines,
      resting: Text(
        text,
        style: style,
        maxLines: maxLines,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (_isMotionReduced) return spec;
    return SpecHero(
      id: _view.id,
      text: text,
      sourceStyle: widget.sourceSpecStyle,
      restingStyle: style,
      child: spec,
    );
  }

  Widget _buildReplacedRow() {
    return MetaRow(
      label: 'LAST REPLACED',
      labelFlash: _labelFlash,
      value: InlineValue(
        controller: _replaced,
        focusNode: _replacedFocus,
        style: ObjectText.metaValue,
        isEditing: _isEditing,
        rule: _ruleFade,
        textAlign: TextAlign.right,
        resting: AnimatedSwitcher(
          duration: _isMotionReduced ? Duration.zero : _dateSwapDuration,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerRight,
            children: [...previous, ?current],
          ),
          child: Text(
            formatSpecDate(_view.lastReplaced),
            key: ValueKey(_view.lastReplaced),
            style: ObjectText.metaValue,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  /// Derived from LAST REPLACED, so it is never an editable field.
  Widget _buildNextDueRow() {
    final due = _view.nextDue;
    final isLate = due != null && isOverdue(due, DateTime.now());
    return MetaRow(
      label: 'NEXT DUE',
      value: Text(
        due == null ? kMissingValue : formatSpecDate(toIsoDate(due)),
        style: isLate ? _overdueValue : ObjectText.metaValue,
        maxLines: 1,
      ),
    );
  }
}
