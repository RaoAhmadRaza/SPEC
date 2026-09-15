import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/add/add_tokens.dart';
import 'package:spec/add/add_value_field.dart';
import 'package:spec/home/home_glass.dart';
import 'package:spec/theme/spec_tokens.dart';

const _rowHeight = 86.0;
const _openHeight = 214.0;
const _gap = 10.0;

/// The two cut corners face each other across the gap.
const _slotRadius = BorderRadius.only(
  topLeft: Radius.circular(18),
  topRight: Radius.circular(18),
  bottomRight: Radius.circular(18),
  bottomLeft: Radius.circular(5),
);
const _cardRadius = BorderRadius.only(
  topLeft: Radius.circular(18),
  topRight: Radius.circular(18),
  bottomLeft: Radius.circular(18),
  bottomRight: Radius.circular(5),
);

/// CSS `blur(20px) saturate(180%)`.
const _cardBlur = 10.0;
const _cardSaturation = 1.8;
const _cardInset = 16.0;

/// Puts `LOCATION` and the zone as a pair in the middle of the closed card.
const _labelTop = 21.0;
const _labelGap = 7.0;

const _openDuration = Duration(milliseconds: 300);
const _closeDuration = Duration(milliseconds: 260);
const _valueSwap = Duration(milliseconds: 160);
const _optionFade = 200;
const _optionStagger = 30.0;
const _optionPadding = 11.0;
const _checkSize = 16.0;

/// Step 05's photo slot beside its location card.
///
/// Tapping the card opens a zone picker in place — no new sheet. The slot
/// holds its 86 and top-aligns while the card grows.
class AddLocationRow extends StatefulWidget {
  const AddLocationRow({
    super.key,
    required this.photo,
    required this.zone,
    required this.zones,
    required this.onZoneChanged,
    this.onPhotoTap,
    this.isMotionReduced = false,
  });

  /// Carried from the step that took it, or taken here. None is a flat tile:
  /// no icon, no label, no dashed border.
  final File? photo;

  /// Takes or replaces the photo. Without it the slot only shows one.
  final VoidCallback? onPhotoTap;
  final String zone;
  final List<String> zones;
  final ValueChanged<String> onZoneChanged;
  final bool isMotionReduced;

  @override
  State<AddLocationRow> createState() => _AddLocationRowState();
}

class _AddLocationRowState extends State<AddLocationRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: _openDuration,
    reverseDuration: _closeDuration,
  );
  late final CurvedAnimation _openCurve = CurvedAnimation(
    parent: _open,
    curve: Curves.easeOutCubic,
  );

  final TextEditingController _newZone = TextEditingController();
  final FocusNode _newZoneFocus = FocusNode();
  bool _isNaming = false;

  bool get _isOpen =>
      _open.status == AnimationStatus.forward ||
      _open.status == AnimationStatus.completed;

  @override
  void dispose() {
    _openCurve.dispose();
    _open.dispose();
    _newZone.dispose();
    _newZoneFocus.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
      return;
    }
    if (widget.isMotionReduced) {
      _open.value = 1;
    } else {
      _open.forward();
    }
    setState(() {});
  }

  void _close() {
    if (widget.isMotionReduced) {
      _open.value = 0;
    } else {
      _open.reverse();
    }
    setState(() => _isNaming = false);
  }

  void _pick(String zone) {
    HapticFeedback.selectionClick();
    widget.onZoneChanged(zone);
    _close();
  }

  void _startNaming() {
    setState(() => _isNaming = true);
    _newZoneFocus.requestFocus();
  }

  void _commitNewZone(String raw) {
    final name = raw.trim();
    _newZone.clear();
    if (name.isEmpty) {
      setState(() => _isNaming = false);
      return;
    }
    _pick(name);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSlot()),
        const SizedBox(width: _gap),
        Expanded(
          child: AnimatedBuilder(
            animation: _openCurve,
            builder: (context, child) => SizedBox(
              height: lerpDouble(_rowHeight, _openHeight, _openCurve.value),
              child: child,
            ),
            child: _buildCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildSlot() {
    final photo = widget.photo;
    final onPhotoTap = widget.onPhotoTap;
    return Semantics(
      button: onPhotoTap != null,
      label: photo == null ? 'Add photo' : 'Retake photo',
      child: GestureDetector(
        key: const ValueKey('add-photo-slot'),
        onTap: onPhotoTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPhotoTap();
              },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: _rowHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: SpecColors.tile,
            borderRadius: _slotRadius,
            border: Border.all(color: AddColors.slotBorder),
          ),
          child: photo == null
              ? null
              : Image.file(
                  photo,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return GlassSurface(
      borderRadius: _cardRadius,
      blur: _cardBlur,
      saturation: _cardSaturation,
      fill: AddColors.locationFill,
      borderColor: AddColors.locationBorder,
      padding: const EdgeInsets.symmetric(horizontal: _cardInset),
      child: GestureDetector(
        onTap: _isNaming ? null : _toggle,
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          button: true,
          label: 'Location, ${widget.zone}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _labelTop),
              const Text('LOCATION', style: AddText.monoLabel),
              const SizedBox(height: _labelGap),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  /// The zone while closed, the picker while open. The zone fades out as the
  /// picker fades in, in the same place.
  Widget _buildBody() {
    return AnimatedBuilder(
      animation: _open,
      builder: (context, _) {
        final t = _open.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (t < 1)
              Opacity(
                opacity: 1 - t,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: AnimatedSwitcher(
                    duration: widget.isMotionReduced
                        ? Duration.zero
                        : _valueSwap,
                    child: Text(
                      widget.zone,
                      key: ValueKey(widget.zone),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AddText.location,
                    ),
                  ),
                ),
              ),
            if (t > 0) _buildPicker(),
          ],
        );
      },
    );
  }

  Widget _buildPicker() {
    final rows = [
      for (final zone in widget.zones) _buildOption(zone),
      _isNaming ? _buildNamingField() : _buildNewZoneRow(),
    ];
    return ClipRect(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++)
              _fadeIn(index: i, count: rows.length, child: rows[i]),
          ],
        ),
      ),
    );
  }

  /// Each row fades in over 200ms, up to 30ms behind the one above it. The
  /// stagger is read off the opening itself, so closing simply fades them all.
  ///
  /// A long list tightens the stagger so the last of [count] rows still lands
  /// by the time the card is open: a fixed 30ms would leave rows past the
  /// fourth part-faded, and `+ NEW ZONE` invisible, for good.
  Widget _fadeIn({
    required int index,
    required int count,
    required Widget child,
  }) {
    if (widget.isMotionReduced) return child;
    final open = _openDuration.inMilliseconds;
    final stagger = count < 2
        ? 0.0
        : math.min(_optionStagger, (open - _optionFade) / (count - 1));
    final elapsed = _open.value * open;
    final t = ((elapsed - index * stagger) / _optionFade).clamp(0.0, 1.0);
    return Opacity(opacity: t, child: child);
  }

  Widget _buildOption(String zone) {
    final isCurrent = zone.toLowerCase() == widget.zone.toLowerCase();
    return GestureDetector(
      onTap: () => _pick(zone),
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: isCurrent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _optionPadding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  zone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AddText.zoneOption,
                ),
              ),
              if (isCurrent) _buildCheck(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheck() {
    return Container(
      width: _checkSize,
      height: _checkSize,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: SpecColors.accent,
        shape: BoxShape.circle,
      ),
      child: const ExcludeSemantics(child: Text('✓', style: AddText.check)),
    );
  }

  Widget _buildNewZoneRow() {
    return GestureDetector(
      onTap: _startNaming,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: _optionPadding),
        child: Text('+ NEW ZONE', style: AddText.monoLabel),
      ),
    );
  }

  Widget _buildNamingField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _optionPadding),
      child: AddMonoInput(
        controller: _newZone,
        focusNode: _newZoneFocus,
        placeholder: 'ZONE NAME',
        textCapitalization: TextCapitalization.words,
        onSubmitted: _commitNewZone,
      ),
    );
  }
}
