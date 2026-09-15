import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/add/add_draft.dart';
import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_kinds.dart';
import 'package:spec/add/add_location_row.dart';
import 'package:spec/add/add_tokens.dart';
import 'package:spec/add/add_value_field.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/theme/spec_tokens.dart';

/// No grab handle: this step continues a sheet, it is not a new one.
const _padding = EdgeInsets.fromLTRB(22, 14, 22, 0);
const _bottomInset = 46.0;

/// With the keyboard up, SAVE rides this far above it.
const _keyboardClearance = 12.0;
const _blockGap = 22.0;
const _chipGap = 8.0;

const _enterDuration = Duration(milliseconds: 480);
const _reducedDuration = Duration(milliseconds: 200);
const _focusDelay = Duration(milliseconds: 320);

const _riseShort = 12.0;
const _riseChip = 10.0;
const _rise = 14.0;
const _rowEnterScale = 0.98;
const _chipStart = 0.14;
const _chipStagger = 0.035;
const _chipSpan = 0.30;

/// Chip switch: the old value leaves over 140ms, the new one arrives over the
/// next 140ms.
const _wipeDuration = Duration(milliseconds: 280);
const _wipeTravel = 10.0;
const _chipTreatment = Duration(milliseconds: 200);
const _labelSwap = Duration(milliseconds: 240);

/// The label's cross-fade starts 60ms in: 60 / 240.
const _labelDelay = 0.25;

const _otherDuration = Duration(milliseconds: 240);
const _fieldNameHeight = 22.0;
const _fieldNameGap = 10.0;

const _reminderSwap = Duration(milliseconds: 160);
const _reminderTravel = 6.0;
const _reminderPadding = 12.0;
const _notesGap = 16.0;

const _saveHeight = 58.0;
const _savePressedScale = 0.96;
const _savePressIn = Duration(milliseconds: 100);
const _savePressOut = Duration(milliseconds: 140);

/// Screen 05, the add flow's last step: one value, then leave.
///
/// Content only. The glass, its geometry and the step transition belong to
/// the flow, so this builds directly in a test with no route.
class AddFieldsSheet extends StatefulWidget {
  const AddFieldsSheet({
    super.key,
    required this.type,
    required this.zone,
    required this.zones,
    required this.stepLabel,
    required this.onSave,
    this.initialKind,
    this.photo,
    this.pickPhoto,
    this.name,
    this.initialValue = '',
  });

  final AddType type;
  final String zone;

  /// What the location picker offers.
  final List<String> zones;

  /// `STEP 2 / 2`, derived from the flow's depth by the caller: `STEP 2 / 3`
  /// when step 07 or 08 came first.
  final String stepLabel;
  final ValueChanged<SpecDraft> onSave;

  /// Null means the type's most-used kind.
  final SpecKind? initialKind;
  final File? photo;

  /// Takes a photo from the slot beside LOCATION, replacing [photo]. Null
  /// leaves the slot display-only.
  final Future<File?> Function()? pickPhoto;

  /// The object's name when an earlier step already knows it — a library
  /// pick's `Tyre`. Shown in the context row in place of the type, and saved.
  final String? name;

  /// What the value field opens with: the spec typed on screen 08.
  final String initialValue;

  @override
  State<AddFieldsSheet> createState() => _AddFieldsSheetState();
}

class _AddFieldsSheetState extends State<AddFieldsSheet>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _enterDuration,
  );
  late final AnimationController _wipe = AnimationController(
    vsync: this,
    duration: _wipeDuration,
    value: 1,
  )..addListener(_onWipeTick);
  late final AnimationController _other = AnimationController(
    vsync: this,
    duration: _otherDuration,
    value: _kind == SpecKind.other ? 1 : 0,
  );
  late final CurvedAnimation _otherCurve = CurvedAnimation(
    parent: _other,
    curve: Curves.easeOutCubic,
  );

  late final List<SpecKind> _kinds = kindsFor(widget.type);
  late final List<CurvedAnimation> _segments = [];

  late final Animation<double> _context = _seg(0.00, 0.26);
  late final Animation<double> _prompt = _seg(0.06, 0.42);
  late final List<Animation<double>> _chips = [
    for (var i = 0; i < _kinds.length; i++)
      _seg(
        _chipStart + i * _chipStagger,
        _chipStart + i * _chipStagger + _chipSpan,
      ),
  ];
  late final Animation<double> _rule = _seg(0.22, 0.52);
  late final Animation<double> _label = _seg(0.28, 0.52);
  late final Animation<double> _value = _seg(0.32, 0.70);
  late final Animation<double> _row = _seg(0.42, 0.78);
  late final Animation<double> _reminderIn = _seg(0.52, 0.82);
  late final Animation<double> _notesIn = _seg(0.56, 0.86);
  late final Animation<double> _save = _seg(0.60, 1.00);

  late final TextEditingController _field = TextEditingController(
    text: widget.initialValue,
  );
  final TextEditingController _fieldName = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final FocusNode _focus = FocusNode();
  final FocusNode _fieldNameFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();
  Timer? _focusTimer;

  late SpecKind _kind;

  /// The kind whose value the field is showing. It trails [_kind] until the
  /// wipe reaches its midpoint.
  late SpecKind _fieldKind;
  final Map<SpecKind, String> _valuesByKind = {};
  bool _isRestoring = false;

  late String _zone = widget.zone;
  late File? _photo = widget.photo;
  late int? _reminder;
  bool _hasChosenReminder = false;
  bool _isSavePressed = false;

  bool _isMotionReduced = false;
  bool? _appliedMotionPreference;

  @override
  void initState() {
    super.initState();
    // Eager, not `late` initialisers: [_fieldKind] must capture the kind at
    // mount, not whatever [_kind] is on its first read mid-wipe.
    _kind = widget.initialKind ?? defaultKindFor(widget.type);
    _fieldKind = _kind;
    _reminder = defaultReminderFor(_kind);
  }

  Animation<double> _seg(double begin, double end) {
    final segment = CurvedAnimation(
      parent: _enter,
      curve: Interval(
        begin.clamp(0, 1),
        end.clamp(0, 1),
        curve: Curves.easeOutCubic,
      ),
    );
    _segments.add(segment);
    return segment;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isReduced = MediaQuery.disableAnimationsOf(context);
    if (isReduced == _appliedMotionPreference) return;
    final isFirst = _appliedMotionPreference == null;
    _appliedMotionPreference = isReduced;
    _isMotionReduced = isReduced;
    _enter
      ..duration = isReduced ? _reducedDuration : _enterDuration
      ..forward();
    if (!isFirst) return;
    // The keyboard rises at the end of the step transition, on its own curve.
    _focusTimer = Timer(isReduced ? _reducedDuration : _focusDelay, () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    for (final segment in _segments) {
      segment.dispose();
    }
    _otherCurve.dispose();
    _enter.dispose();
    _wipe.dispose();
    _other.dispose();
    _field.dispose();
    _fieldName.dispose();
    _notes.dispose();
    _focus.dispose();
    _fieldNameFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  // Kind switching.

  void _selectKind(SpecKind kind) {
    if (kind == _kind) return;
    HapticFeedback.selectionClick();
    setState(() {
      _kind = kind;
      if (!_hasChosenReminder) _reminder = defaultReminderFor(kind);
    });
    _syncOther();

    if (_isMotionReduced) {
      _swapValue();
      return;
    }
    // Already past the swap: send the restored value back out first.
    if (!_wipe.isAnimating || _wipe.value >= 0.5) _wipe.value = 0;
    unawaited(_wipe.forward());
  }

  void _syncOther() {
    final isOther = _kind == SpecKind.other;
    if (_isMotionReduced) {
      _other.value = isOther ? 1 : 0;
    } else if (isOther) {
      unawaited(_other.forward());
    } else {
      unawaited(_other.reverse());
    }
  }

  void _onWipeTick() {
    if (_wipe.value >= 0.5 && _fieldKind != _kind) _swapValue();
    setState(() {});
  }

  /// Values persist per kind: switching away and back restores what was
  /// typed.
  void _swapValue() {
    _valuesByKind[_fieldKind] = _field.text;
    final restored = _valuesByKind[_kind] ?? '';
    _fieldKind = _kind;
    _isRestoring = restored.isNotEmpty;
    _field.text = restored;
  }

  double get _wipeOpacity {
    final t = _wipe.value;
    if (t < 0.5) return 1 - Curves.easeIn.transform(t * 2);
    return Curves.easeOut.transform((t - 0.5) * 2);
  }

  double get _wipeShift {
    final t = _wipe.value;
    if (t < 0.5) return -_wipeTravel * Curves.easeIn.transform(t * 2);
    if (!_isRestoring) return 0;
    return -_wipeTravel * (1 - Curves.easeOut.transform((t - 0.5) * 2));
  }

  // Other controls.

  void _setZone(String zone) => setState(() => _zone = zone);

  /// A cancelled or refused pick keeps whatever photo was already there.
  Future<void> _pickPhoto() async {
    final photo = await widget.pickPhoto?.call();
    if (photo == null || !mounted) return;
    setState(() => _photo = photo);
  }

  void _cycleReminder() {
    HapticFeedback.selectionClick();
    setState(() {
      _hasChosenReminder = true;
      _reminder = nextReminder(_reminder);
    });
  }

  void _onSave() {
    if (_fieldKind != _kind) _swapValue();
    // A tap mid-wipe can land while the old kind's text still shows; the kind
    // being saved may have nothing typed under it.
    if (_field.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    _focus.unfocus();
    _notesFocus.unfocus();
    widget.onSave(
      SpecDraft(
        type: widget.type,
        kind: _kind,
        value: _field.text,
        fieldName: _kind == SpecKind.other ? _fieldName.text : null,
        zone: _zone,
        photo: _photo,
        remindEveryMonths: _reminder,
        name: widget.name,
        notes: _notes.text,
      ),
    );
  }

  // Entrance.

  double _opacityOf(Animation<double> segment) =>
      _isMotionReduced ? _enter.value : segment.value;

  double _travelOf(Animation<double> segment, double distance) =>
      _isMotionReduced ? 0 : distance * (1 - segment.value);

  Widget _enterIn(
    Animation<double> segment,
    Widget child, {
    double rise = 0,
    double scaleFrom = 1,
  }) {
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) => Opacity(
        opacity: _opacityOf(segment),
        child: Transform.translate(
          offset: Offset(0, _travelOf(segment, rise)),
          child: Transform.scale(
            scale: _isMotionReduced
                ? 1
                : scaleFrom + (1 - scaleFrom) * segment.value,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }

  // Layout.

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bottom = keyboard > 0 ? keyboard + _keyboardClearance : _bottomInset;
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: SpecFonts.display,
        color: SpecColors.ink,
        decoration: TextDecoration.none,
      ),
      child: Padding(
        padding: _padding.copyWith(bottom: bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stands in for the design's Spacer: the blocks sit at the top
            // and SAVE at the bottom, and when the keyboard takes the room
            // the blocks scroll instead of overflowing.
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _enterIn(_context, _buildContextRow()),
                    const SizedBox(height: _blockGap),
                    _buildPromptAndChips(),
                    const SizedBox(height: _blockGap),
                    _buildFieldBlock(),
                    const SizedBox(height: _blockGap),
                    _enterIn(
                      _row,
                      AddLocationRow(
                        photo: _photo,
                        onPhotoTap: widget.pickPhoto == null
                            ? null
                            : () => unawaited(_pickPhoto()),
                        zone: _zone,
                        zones: widget.zones,
                        onZoneChanged: _setZone,
                        isMotionReduced: _isMotionReduced,
                      ),
                      rise: _rise,
                      scaleFrom: _rowEnterScale,
                    ),
                    const SizedBox(height: _blockGap),
                    _enterIn(_reminderIn, _buildReminderRow()),
                    _enterIn(_notesIn, _buildNotesRow()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: _blockGap),
            _enterIn(_save, _buildSave(), rise: _rise),
          ],
        ),
      ),
    );
  }

  Widget _buildContextRow() {
    final name = widget.name?.trim() ?? '';
    final subject = name.isEmpty ? addTypeLabels[widget.type]! : name;
    final context = '$subject · $_zone'.toUpperCase();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: AnimatedSwitcher(
            duration: _isMotionReduced ? Duration.zero : _reminderSwap,
            layoutBuilder: _leftAligned,
            child: Text(
              context,
              key: ValueKey(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AddText.monoLabel,
            ),
          ),
        ),
        Text(widget.stepLabel, style: AddText.monoLabel),
      ],
    );
  }

  Widget _buildPromptAndChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _enterIn(
          _prompt,
          const Text('WHAT DO YOU NEED TO REMEMBER?', style: AddText.prompt),
          rise: _riseShort,
        ),
        // `gap: 6` plus the chips' own `margin-top: 10`.
        const SizedBox(height: 16),
        Wrap(
          spacing: _chipGap,
          runSpacing: _chipGap,
          children: [
            for (var i = 0; i < _kinds.length; i++)
              _enterIn(
                _chips[i],
                _KindChip(
                  label: kindLabel(_kinds[i]),
                  isSelected: _kinds[i] == _kind,
                  isMotionReduced: _isMotionReduced,
                  onTap: () => _selectKind(_kinds[i]),
                ),
                rise: _riseChip,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The block's top border, drawn separately so it can sweep in.
        AnimatedBuilder(
          animation: _enter,
          builder: (context, child) => Transform.scale(
            scaleX: _isMotionReduced ? 1 : _rule.value,
            alignment: Alignment.centerLeft,
            child: Opacity(
              opacity: _isMotionReduced ? _enter.value : 1,
              child: child,
            ),
          ),
          child: const SizedBox(
            height: 1,
            child: ColoredBox(color: AddColors.sectionRule),
          ),
        ),
        // `padding-top: 6` on the block, then 10 on the label.
        const SizedBox(height: 16),
        _enterIn(
          _label,
          AnimatedSwitcher(
            duration: _isMotionReduced ? Duration.zero : _labelSwap,
            switchInCurve: const Interval(
              _labelDelay,
              1,
              curve: Curves.easeOut,
            ),
            switchOutCurve: const Interval(
              _labelDelay,
              1,
              curve: Curves.easeOut,
            ),
            layoutBuilder: _leftAligned,
            child: Text(
              kindLabel(_kind),
              key: ValueKey(_kind),
              style: AddText.monoLabel,
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _otherCurve,
          alignment: Alignment.topCenter,
          child: FadeTransition(opacity: _otherCurve, child: _buildFieldName()),
        ),
        const SizedBox(height: 10),
        _enterIn(
          _value,
          AddValueField(
            controller: _field,
            focusNode: _focus,
            kind: _kind,
            isMotionReduced: _isMotionReduced,
            textOpacity: _wipeOpacity,
            textShift: _wipeShift,
          ),
          rise: _rise,
        ),
      ],
    );
  }

  /// OTHER's own name for its field, above the value, on a 1px rule.
  Widget _buildFieldName() {
    return Padding(
      padding: const EdgeInsets.only(top: _fieldNameGap),
      child: Container(
        height: _fieldNameHeight,
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AddColors.fieldRule)),
        ),
        child: AddMonoInput(
          controller: _fieldName,
          focusNode: _fieldNameFocus,
          placeholder: 'FIELD NAME',
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _focus.requestFocus(),
        ),
      ),
    );
  }

  Widget _buildReminderRow() {
    return GestureDetector(
      onTap: _cycleReminder,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: _reminderPadding),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AddColors.hairline)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('REMIND ME', style: AddText.reminderLabel),
              AnimatedSwitcher(
                duration: _isMotionReduced ? Duration.zero : _reminderSwap,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: _advance,
                child: Text(
                  reminderLabel(_reminder),
                  key: ValueKey(_reminder),
                  style: AddText.reminderValue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A line of free text, in REMIND ME's row style so it reads as one more
  /// optional setting rather than a form field. Capped where storage caps it.
  Widget _buildNotesRow() {
    return GestureDetector(
      // The empty field is only as wide as its placeholder; the row focuses.
      onTap: _notesFocus.requestFocus,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: _reminderPadding),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AddColors.hairline)),
        ),
        child: Row(
          children: [
            const Text('NOTES', style: AddText.reminderLabel),
            const SizedBox(width: _notesGap),
            Expanded(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  ListenableBuilder(
                    listenable: _notes,
                    builder: (context, _) => _notes.text.isEmpty
                        ? const Text('OPTIONAL', style: AddText.monoLabel)
                        : const SizedBox.shrink(),
                  ),
                  EditableText(
                    controller: _notes,
                    focusNode: _notesFocus,
                    style: AddText.reminderValue,
                    textAlign: TextAlign.right,
                    cursorColor: SpecColors.accent,
                    backgroundCursorColor: SpecColors.ink45,
                    cursorWidth: 2,
                    keyboardAppearance: Brightness.dark,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(kNotesMaxLength),
                    ],
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Outgoing drifts up, incoming rises from below: the list advances.
  Widget _advance(Widget child, Animation<double> animation) {
    final isIncoming = child.key == ValueKey(_reminder);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(
            0,
            (isIncoming ? _reminderTravel : -_reminderTravel) *
                (1 - animation.value),
          ),
          child: child,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSave() {
    return ListenableBuilder(
      listenable: _field,
      builder: (context, _) {
        final isEnabled = _field.text.trim().isNotEmpty;
        return Semantics(
          button: true,
          enabled: isEnabled,
          child: GestureDetector(
            onTapDown: isEnabled
                ? (_) => setState(() => _isSavePressed = true)
                : null,
            onTapCancel: () => setState(() => _isSavePressed = false),
            onTap: isEnabled
                ? () {
                    setState(() => _isSavePressed = false);
                    _onSave();
                  }
                : null,
            behavior: HitTestBehavior.opaque,
            child: AnimatedScale(
              scale: _isSavePressed ? _savePressedScale : 1,
              duration: _isSavePressed ? _savePressIn : _savePressOut,
              curve: _isSavePressed ? Curves.easeOut : Curves.easeOutBack,
              child: Container(
                height: _saveHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isEnabled ? SpecColors.accent : AddColors.saveDisabled,
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                  boxShadow: isEnabled
                      ? const [
                          BoxShadow(
                            color: AddColors.continueShadow,
                            blurRadius: 34,
                            offset: Offset(0, 14),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'SAVE',
                  style: isEnabled ? AddText.save : AddText.saveDisabled,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _leftAligned(Widget? current, List<Widget> previous) =>
      Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]);
}

/// Chip geometry is identical in both states — same padding, same 1px border
/// — so selecting one never reflows the row.
class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.isSelected,
    required this.isMotionReduced,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isMotionReduced;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = isMotionReduced ? Duration.zero : _chipTreatment;
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? SpecColors.accent
                : SpecColors.accent.withValues(alpha: 0),
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            border: Border.all(
              color: isSelected ? SpecColors.accent : AddColors.kindChipBorder,
            ),
          ),
          // Weight snaps at the midpoint of the lerp; colour cross-fades.
          child: AnimatedDefaultTextStyle(
            duration: duration,
            curve: Curves.easeOut,
            style: isSelected ? AddText.kindChipSelected : AddText.kindChip,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
