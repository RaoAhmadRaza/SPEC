import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/collections/collections_models.dart';
import 'package:spec/collections/collections_tokens.dart';
import 'package:spec/collections/square_caret_field.dart';
import 'package:spec/collections/zone_hero.dart';
import 'package:spec/data/zone_repository.dart';
import 'package:spec/theme/spec_tokens.dart';

const _rowPadding = 13.0;
const _thumbSize = 58.0;
const _thumbGap = 14.0;
const _nameToSpecs = 6.0;
const _countGap = 12.0;

/// Edit mode's affordances: a 20pt handle on the left, a 22pt `×` on the
/// right, each with the row's gap beside it.
const _handleWidth = 20.0;
const _handleBar = 2.0;
const _handleBarGap = 4.0;
const _removeSize = 22.0;

const _ghostThumbOpacity = 0.5;

const _pressDuration = Duration(milliseconds: 110);
const _editDuration = Duration(milliseconds: 260);
const _ghostDuration = Duration(milliseconds: 300);
const _limeDuration = Duration(milliseconds: 200);
const _countFade = Duration(milliseconds: 160);
const _specsFade = Duration(milliseconds: 180);
const _photoFade = Duration(milliseconds: 300);

/// One zone: cut-corner thumb, name over a mono spec sample, count on the
/// right.
///
/// Everything that changes in place — ghost to real, lime moving, edit mode,
/// rename, the delete confirmation — animates inside the row. Entering and
/// leaving the list is the list's job.
class ZoneRow extends StatefulWidget {
  const ZoneRow({
    super.key,
    required this.index,
    required this.zone,
    this.isLime = false,
    this.isGhost = false,
    this.isEditing = false,
    this.isRenaming = false,
    this.isConfirming = false,
    this.onOpen,
    this.onStartRename,
    this.onRename,
    this.onRemove,
    this.onConfirmRemove,
    this.onCancelConfirm,
    this.wrapHandle,
  });

  /// Position in the list, which picks the thumb's cut corner.
  final int index;
  final CollectionZone zone;
  final bool isLime;
  final bool isGhost;
  final bool isEditing;
  final bool isRenaming;
  final bool isConfirming;

  final VoidCallback? onOpen;
  final VoidCallback? onStartRename;

  /// Resolves false when the name was refused, which keeps the field open
  /// with the reason under it.
  final Future<bool> Function(String name)? onRename;
  final VoidCallback? onRemove;
  final VoidCallback? onConfirmRemove;
  final VoidCallback? onCancelConfirm;

  /// Lets the list turn the handle into a drag start without this row
  /// knowing how reordering works.
  final Widget Function(Widget handle)? wrapHandle;

  @override
  State<ZoneRow> createState() => _ZoneRowState();
}

class _ZoneRowState extends State<ZoneRow> {
  bool _isPressed = false;
  TextEditingController? _renameText;
  FocusNode? _renameFocus;
  bool _isCommitting = false;

  /// The name last refused. Its reason replaces the spec line until the text
  /// changes.
  String? _refusedName;

  bool get _isMotionReduced => MediaQuery.disableAnimationsOf(context);

  Duration _motion(Duration duration) =>
      _isMotionReduced ? Duration.zero : duration;

  @override
  void initState() {
    super.initState();
    if (widget.isRenaming) _beginRename();
  }

  @override
  void didUpdateWidget(ZoneRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRenaming && !oldWidget.isRenaming) _beginRename();
    if (!widget.isRenaming && oldWidget.isRenaming) _endRename();
  }

  @override
  void dispose() {
    _endRename();
    super.dispose();
  }

  void _beginRename() {
    _renameText = TextEditingController(text: widget.zone.name)
      ..selection = TextSelection.collapsed(offset: widget.zone.name.length);
    _renameFocus = FocusNode()..addListener(_onRenameFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _renameFocus?.requestFocus();
    });
  }

  void _endRename() {
    _renameFocus
      ?..removeListener(_onRenameFocus)
      ..dispose();
    _renameText?.dispose();
    _renameFocus = null;
    _renameText = null;
    _refusedName = null;
  }

  /// Tapping away commits, the same as pressing done.
  void _onRenameFocus() {
    final focus = _renameFocus;
    if (focus == null || focus.hasFocus) return;
    unawaited(
      _commitRename(_renameText?.text ?? widget.zone.name, isSubmitted: false),
    );
  }

  /// A refusal on done keeps the keyboard up to fix the name; one on blur
  /// lets focus go where the tap sent it rather than snapping it back.
  Future<void> _commitRename(String value, {required bool isSubmitted}) async {
    final onRename = widget.onRename;
    if (onRename == null || _isCommitting) return;
    _isCommitting = true;
    final isRenamed = await onRename(value);
    _isCommitting = false;
    if (!mounted || isRenamed || !widget.isRenaming) return;
    setState(() => _refusedName = value);
    if (isSubmitted) _renameFocus?.requestFocus();
  }

  void _setPressed(bool isPressed) {
    if (_isPressed != isPressed) setState(() => _isPressed = isPressed);
  }

  void _onTap() {
    if (widget.isConfirming) {
      widget.onCancelConfirm?.call();
      return;
    }
    if (widget.isEditing || widget.isGhost) return;
    HapticFeedback.selectionClick();
    widget.onOpen?.call();
  }

  @override
  Widget build(BuildContext context) {
    final canPress = !widget.isGhost && !widget.isEditing;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: canPress ? (_) => _setPressed(true) : null,
      onTapUp: canPress ? (_) => _setPressed(false) : null,
      onTapCancel: canPress ? () => _setPressed(false) : null,
      onTap: widget.isGhost ? null : _onTap,
      child: AnimatedContainer(
        duration: _pressDuration,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: _rowPadding),
        decoration: BoxDecoration(
          color: _isPressed
              ? CollectionsColors.rowPress
              : CollectionsColors.rowPress.withValues(alpha: 0),
          border: const Border(
            bottom: BorderSide(color: CollectionsColors.hairline),
          ),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.isGhost ? 0 : 1),
          duration: _motion(_ghostDuration),
          builder: (context, realness, _) => TweenAnimationBuilder<double>(
            tween: Tween(end: widget.isEditing ? 1 : 0),
            duration: _motion(_editDuration),
            curve: Curves.easeOutCubic,
            builder: (context, edit, _) => _buildRow(realness, edit),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(double realness, double edit) {
    return Row(
      children: [
        _slot(
          width: (_handleWidth + _thumbGap) * edit,
          opacity: edit,
          alignment: Alignment.centerLeft,
          child:
              widget.wrapHandle?.call(const _DragHandle()) ??
              const _DragHandle(),
        ),
        Opacity(
          opacity: _ghostThumbOpacity + (1 - _ghostThumbOpacity) * realness,
          child: _Thumb(
            radius: zoneThumbRadius(widget.index),
            photo: widget.isGhost ? null : widget.zone.photo,
            fade: _motion(_photoFade),
          ),
        ),
        const SizedBox(width: _thumbGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [_buildName(realness), _buildSpecs(realness)],
          ),
        ),
        const SizedBox(width: _countGap),
        AnimatedSwitcher(
          duration: _motion(_countFade),
          child: widget.isConfirming
              ? _ConfirmChip(
                  key: const ValueKey('confirm'),
                  onTap: widget.onConfirmRemove,
                )
              : _buildCount(realness),
        ),
        _slot(
          width:
              (_countGap + _removeSize) * edit * (widget.isConfirming ? 0 : 1),
          opacity: edit,
          alignment: Alignment.centerRight,
          child: _RemoveButton(onTap: widget.onRemove),
        ),
      ],
    );
  }

  /// A zero-to-full width slot whose child keeps its own size, so the
  /// affordance slides in rather than squashing.
  Widget _slot({
    required double width,
    required double opacity,
    required Alignment alignment,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      height: _thumbSize,
      child: ClipRect(
        child: OverflowBox(
          alignment: alignment,
          maxWidth: double.infinity,
          child: IgnorePointer(
            ignoring: opacity < 1,
            child: Opacity(opacity: opacity, child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildName(double realness) {
    if (widget.isRenaming && _renameText != null && _renameFocus != null) {
      return SquareCaretField(
        controller: _renameText!,
        focusNode: _renameFocus!,
        style: CollectionsText.zoneName,
        maxLength: kZoneNameMaxLength,
        underlineColor: CollectionsColors.fieldUnderline,
        onSubmitted: (value) =>
            unawaited(_commitRename(value, isSubmitted: true)),
      );
    }

    final isHeroReady = realness == 1 && !widget.isGhost && !widget.isEditing;
    final Widget name = isHeroReady
        ? zoneNameHero(ZoneHeroLabel(name: widget.zone.name))
        : Text(
            widget.zone.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CollectionsText.zoneName.copyWith(
              color: Color.lerp(
                CollectionsColors.ghostName,
                SpecColors.ink,
                realness,
              ),
            ),
          );

    if (!widget.isEditing) return name;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onStartRename,
      child: name,
    );
  }

  /// The mono line grows in with the row becoming real, rather than the name
  /// jumping up the moment it appears.
  Widget _buildSpecs(double realness) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topLeft,
        heightFactor: realness,
        child: Opacity(
          opacity: realness,
          child: Padding(
            padding: const EdgeInsets.only(top: _nameToSpecs),
            child: ListenableBuilder(
              listenable: Listenable.merge([_renameText]),
              builder: (context, _) {
                final isRefused =
                    _refusedName != null && _renameText?.text == _refusedName;
                final line = isRefused
                    ? kZoneNameTaken
                    : widget.zone.specSample;
                return AnimatedSwitcher(
                  duration: _motion(_specsFade),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    line,
                    key: ValueKey(line),
                    style: CollectionsText.zoneSpecs,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCount(double realness) {
    final base = widget.isLime && !widget.isEditing
        ? SpecColors.accent
        : SpecColors.ink60;
    return TweenAnimationBuilder<Color?>(
      key: const ValueKey('count'),
      tween: ColorTween(end: base),
      duration: _motion(_limeDuration),
      builder: (context, color, _) => AnimatedSwitcher(
        duration: _motion(_countFade),
        child: Text(
          formatZoneCount(widget.isGhost ? 0 : widget.zone.count),
          key: ValueKey(widget.isGhost ? 0 : widget.zone.count),
          style: CollectionsText.zoneCount.copyWith(
            color: Color.lerp(CollectionsColors.ghostCount, color, realness),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.radius, required this.photo, required this.fade});

  final BorderRadius radius;
  final ImageProvider? photo;
  final Duration fade;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: _thumbSize,
        height: _thumbSize,
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: CollectionsColors.thumbBorder),
        ),
        decoration: BoxDecoration(color: SpecColors.tile, borderRadius: radius),
        child: switch (photo) {
          final ImageProvider image => Image(
            image: image,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            frameBuilder: (context, child, frame, isSynchronous) {
              if (isSynchronous) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: fade,
                child: child,
              );
            },
            // A missing file is a flat tile, the same as no photo at all.
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
          null => null,
        },
      ),
    );
  }
}

/// Three 2pt bars, 4pt apart.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _handleWidth,
      height: _thumbSize,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: _handleBarGap),
            const SizedBox(
              width: _handleWidth,
              height: _handleBar,
              child: ColoredBox(color: SpecColors.ink62),
            ),
          ],
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _countGap + _removeSize,
        height: _thumbSize,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: _removeSize,
            height: _removeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CollectionsColors.removeBorder),
            ),
            alignment: Alignment.center,
            child: const Text('×', style: CollectionsText.remove),
          ),
        ),
      ),
    );
  }
}

/// The inline confirmation for a zone that still holds objects. Its objects
/// move to their type's default zone rather than being deleted, so nothing is
/// lost by confirming.
class _ConfirmChip extends StatelessWidget {
  const _ConfirmChip({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: CollectionsColors.limeFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CollectionsColors.limeOutline),
        ),
        child: const Text('DELETE?', style: CollectionsText.confirm),
      ),
    );
  }
}
