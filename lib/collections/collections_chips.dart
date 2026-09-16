import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/collections/collections_models.dart';
import 'package:spec/collections/collections_tokens.dart';
import 'package:spec/collections/square_caret_field.dart';
import 'package:spec/data/zone_repository.dart';
import 'package:spec/theme/spec_tokens.dart';

const _chipPadding = EdgeInsets.symmetric(horizontal: 13, vertical: 8);
const _chipGap = 8.0;

/// Between the chips, or the name field, and the mono line beneath them.
const _hintGap = 8.0;

const _expandDuration = Duration(milliseconds: 280);
const _collapseDuration = Duration(milliseconds: 240);
const _flashDuration = Duration(milliseconds: 160);

/// `+ NEW ZONE` and `EXPORT`. The new-zone chip opens in place into a
/// full-width name field; [onExport] null removes `EXPORT`.
class CollectionsChips extends StatefulWidget {
  const CollectionsChips({
    super.key,
    required this.onCreateZone,
    this.onExport,
    this.openRequest = 0,
  });

  /// Resolves false when the name was refused, which keeps the field open.
  final Future<bool> Function(String name) onCreateZone;

  /// Resolves false when the share sheet was dismissed without sharing.
  final Future<bool> Function()? onExport;

  /// Each change opens the name field, focused: a new zone asked for from
  /// outside this screen.
  final int openRequest;

  @override
  State<CollectionsChips> createState() => _CollectionsChipsState();
}

class _CollectionsChipsState extends State<CollectionsChips> {
  final _name = TextEditingController();
  final _focus = FocusNode();
  Timer? _flash;
  bool _isAdding = false;
  bool _isFlashing = false;
  bool _isCommitting = false;

  /// The name last refused. Its reason shows until the text changes.
  String? _refusedName;

  /// `BACKUP READY` after a shared export, until the next tap here.
  String? _exportStatus;

  bool get _isMotionReduced => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(CollectionsChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openRequest != oldWidget.openRequest) _open();
  }

  @override
  void dispose() {
    _flash?.cancel();
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();
    _name.dispose();
    super.dispose();
  }

  void _open() {
    HapticFeedback.selectionClick();
    setState(() {
      _isAdding = true;
      _exportStatus = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  /// Tapping away commits a typed name and collapses an empty one.
  void _onFocusChange() {
    if (_focus.hasFocus || !_isAdding) return;
    unawaited(_commit(_name.text, isSubmitted: false));
  }

  /// A refused name stays in the open field with its reason beneath. Done
  /// keeps the keyboard up to fix it; a blur lets focus go where the tap
  /// sent it, or every tap elsewhere would be refused and snap focus back.
  Future<void> _commit(String value, {required bool isSubmitted}) async {
    if (_isCommitting) return;
    if (value.trim().isEmpty) {
      _close();
      return;
    }
    _isCommitting = true;
    final isCreated = await widget.onCreateZone(value);
    _isCommitting = false;
    if (!mounted) return;
    if (isCreated) {
      _close();
      return;
    }
    unawaited(HapticFeedback.lightImpact());
    setState(() => _refusedName = value);
    if (isSubmitted) _focus.requestFocus();
  }

  void _close() {
    _name.clear();
    _focus.unfocus();
    setState(() {
      _isAdding = false;
      _refusedName = null;
    });
  }

  void _export() {
    final onExport = widget.onExport;
    if (onExport == null || _isFlashing) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isFlashing = true;
      _exportStatus = null;
    });
    // Leaving the screen mid-flash cancels the export with it: there is no
    // screen left to anchor a share sheet to.
    _flash = Timer(_isMotionReduced ? Duration.zero : _flashDuration, () {
      if (!mounted) return;
      setState(() => _isFlashing = false);
      unawaited(_share(onExport));
    });
  }

  Future<void> _share(Future<bool> Function() onExport) async {
    final isShared = await onExport();
    if (mounted && isShared) setState(() => _exportStatus = kBackupReady);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChips(),
        ListenableBuilder(
          listenable: _name,
          builder: (context, _) {
            final hint = _isAdding
                ? (_name.text == _refusedName ? kZoneNameTaken : null)
                : _exportStatus;
            if (hint == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: _hintGap),
              child: Text(hint, style: CollectionsText.zoneSpecs),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChips() {
    final sizeDuration = _isMotionReduced
        ? Duration.zero
        : (_isAdding ? _expandDuration : _collapseDuration);

    return AnimatedSize(
      duration: sizeDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: _isAdding
          ? SquareCaretField(
              controller: _name,
              focusNode: _focus,
              style: CollectionsText.zoneName,
              placeholder: 'ZONE NAME',
              placeholderStyle: CollectionsText.chip,
              maxLength: kZoneNameMaxLength,
              underlineColor: CollectionsColors.fieldUnderline,
              onSubmitted: (value) =>
                  unawaited(_commit(value, isSubmitted: true)),
            )
          : Row(
              children: [
                _Chip(
                  label: '+ NEW ZONE',
                  style: CollectionsText.chip,
                  fill: CollectionsColors.chipFill,
                  border: CollectionsColors.chipBorder,
                  onTap: _open,
                ),
                if (widget.onExport != null) ...[
                  const SizedBox(width: _chipGap),
                  _Chip(
                    label: 'EXPORT',
                    style: CollectionsText.chip.copyWith(
                      color: SpecColors.accent,
                    ),
                    fill: _isFlashing
                        ? CollectionsColors.limeFlash
                        : CollectionsColors.limeFill,
                    border: CollectionsColors.limeOutline,
                    flash: _isMotionReduced ? Duration.zero : _flashDuration,
                    onTap: _export,
                  ),
                ],
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.style,
    required this.fill,
    required this.border,
    required this.onTap,
    this.flash = Duration.zero,
  });

  final String label;
  final TextStyle style;
  final Color fill;
  final Color border;
  final VoidCallback onTap;
  final Duration flash;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: flash,
        curve: Curves.easeOut,
        padding: _chipPadding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(label, style: style),
      ),
    );
  }
}
