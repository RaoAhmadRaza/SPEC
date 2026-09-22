import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'package:spec/add/add_draft.dart';
import 'package:spec/add/add_fields_sheet.dart';
import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_sheet_shell.dart';
import 'package:spec/add/add_tokens.dart';
import 'package:spec/add/add_what_sheet.dart';

/// Where step 05's sheet anchors its top edge.
const kFieldsSheetTop = 96.0;

/// The most of a viewport the sheet may ever take.
const _maxSheetFraction = 0.92;

/// Step 05's sheet height: leave a 96pt peek of Home at the top, but never
/// give away more than 8% of a short viewport to that peek.
///
/// At 874 the peek wins (778 < 804), so the reference rendering is unchanged.
/// The fraction only binds above roughly 1200pt of height; below that the
/// subtraction is already the smaller of the two. Clamped at zero so a
/// viewport shorter than the peek cannot ask for a negative height.
double addFieldsSheetHeight(BuildContext context) {
  final height = MediaQuery.sizeOf(context).height;
  return math.max(
    0.0,
    math.min(height - kFieldsSheetTop, height * _maxSheetFraction),
  );
}

/// The manual branch: 04 then 05.
const _manualSteps = 2;

/// 380ms for the geometry and the outgoing step, the incoming step 60ms
/// behind on the same curve.
const _stepMs = 380;
const _incomingDelayMs = 60;
const _stepDuration = Duration(milliseconds: _stepMs + _incomingDelayMs);
const _reducedStepDuration = Duration(milliseconds: 200);
const _stepTravel = 28.0;

/// The add flow's single sheet.
///
/// Steps swap inside it and its top edge animates between them; it never
/// drops and re-rises. The route owns the rise, the drag and the backdrop;
/// this owns which step is showing and the sheet's rect.
class AddFlowSheet extends StatefulWidget {
  const AddFlowSheet({
    super.key,
    required this.zones,
    required this.onSave,
    this.initialType = defaultAddType,
    this.pickPhoto,
    this.depth,
  });

  /// What step 05's location picker offers. The first is the default.
  final List<String> zones;
  final ValueChanged<SpecDraft> onSave;
  final AddType initialType;
  final Future<File?> Function()? pickPhoto;

  /// Reports how far into step 05 the sheet is, 0 → 1, so the route can deepen
  /// the backdrop's dim on the same clock.
  final ValueNotifier<double>? depth;

  @override
  State<AddFlowSheet> createState() => _AddFlowSheetState();
}

class _AddFlowSheetState extends State<AddFlowSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _step = AnimationController(
    vsync: this,
    duration: _stepDuration,
  )..addListener(_reportDepth);

  final GlobalKey _sheetKey = GlobalKey();

  bool _isMotionReduced = false;
  bool _hasFields = false;
  double _fromHeight = 0;
  AddType _type = defaultAddType;
  File? _photo;

  /// A fresh step 05 each time the user continues, so the entrance replays.
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isMotionReduced = MediaQuery.disableAnimationsOf(context);
    _step.duration = _isMotionReduced ? _reducedStepDuration : _stepDuration;
  }

  @override
  void dispose() {
    _step.dispose();
    super.dispose();
  }

  void _reportDepth() => widget.depth?.value = _geometry;

  void _continue(AddType type, File? photo) {
    if (_hasFields) return;
    setState(() {
      _fromHeight = _sheetKey.currentContext?.size?.height ?? 0;
      _type = type;
      _photo = photo;
      _hasFields = true;
      _generation++;
    });
    unawaited(_step.forward(from: 0));
  }

  /// Back from 05 reverses the transition exactly.
  void _back() {
    if (!_hasFields || _step.status == AnimationStatus.reverse) return;
    FocusScope.of(context).unfocus();
    unawaited(
      _step.reverse().whenComplete(() {
        if (mounted) setState(() => _hasFields = false);
      }),
    );
  }

  /// The sheet's rect. Under reduced motion it snaps and only content fades.
  double get _geometry {
    if (_isMotionReduced) return _step.value > 0 ? 1 : 0;
    return Curves.easeOutCubic.transform(
      (_step.value * _stepDuration.inMilliseconds / _stepMs).clamp(0.0, 1.0),
    );
  }

  double get _outgoing => _isMotionReduced ? _step.value : _geometry;

  double get _incoming {
    if (_isMotionReduced) return _step.value;
    final elapsed = _step.value * _stepDuration.inMilliseconds;
    return Curves.easeOutCubic.transform(
      ((elapsed - _incomingDelayMs) / _stepMs).clamp(0.0, 1.0),
    );
  }

  double get _travel => _isMotionReduced ? 0 : _stepTravel;

  @override
  Widget build(BuildContext context) {
    final fullHeight = addFieldsSheetHeight(context);
    return PopScope(
      canPop: !_hasFields,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnimatedBuilder(
        animation: _step,
        builder: (context, _) => AddSheetShell(
          key: _sheetKey,
          fill: Color.lerp(
            AddColors.sheetFill,
            AddColors.fieldsSheetFill,
            _geometry,
          )!,
          child: SizedBox(
            height: _hasFields
                ? lerpDouble(_fromHeight, fullHeight, _geometry)
                : null,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                _buildWhat(),
                if (_hasFields) _buildFields(fullHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhat() {
    final t = _hasFields ? _outgoing : 0.0;
    return IgnorePointer(
      ignoring: _hasFields,
      child: ExcludeFocus(
        excluding: _hasFields,
        child: Opacity(
          opacity: 1 - t,
          child: Transform.translate(
            offset: Offset(-_travel * t, 0),
            // Kept mounted under step 05, so going back finds the tile and
            // photo exactly as they were left.
            child: TickerMode(
              enabled: !_hasFields || _step.isAnimating,
              child: AddWhatSheet(
                initialType: widget.initialType,
                pickPhoto: widget.pickPhoto,
                onContinue: _continue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Laid out at its final height from the first frame and pinned to the
  /// sheet's top edge; the sheet's clip reveals the rest as the edge rises.
  Widget _buildFields(double fullHeight) {
    final t = _incoming;
    return OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: fullHeight,
      maxHeight: fullHeight,
      // Not tappable while it is still fading in or out.
      child: IgnorePointer(
        ignoring: _step.isAnimating,
        child: Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(_travel * (1 - t), 0),
            child: AddFieldsSheet(
              key: ValueKey(_generation),
              type: _type,
              photo: _photo,
              pickPhoto: widget.pickPhoto,
              zone: widget.zones.first,
              zones: widget.zones,
              stepLabel: 'STEP $_manualSteps / $_manualSteps',
              onSave: widget.onSave,
            ),
          ),
        ),
      ),
    );
  }
}
