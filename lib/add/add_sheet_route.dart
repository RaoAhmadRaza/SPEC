import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'package:spec/add/add_draft.dart';
import 'package:spec/add/add_fields_sheet.dart';
import 'package:spec/add/add_flow_sheet.dart';
import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_kinds.dart';
import 'package:spec/add/add_sheet_shell.dart';
import 'package:spec/add/add_tokens.dart';
import 'package:spec/add/add_what_sheet.dart';
import 'package:spec/data/models/spec_models.dart';

const _riseDuration = Duration(milliseconds: 420);
const _tapDismissDuration = Duration(milliseconds: 320);
const _reducedDuration = Duration(milliseconds: 200);

/// SAVE lets the sheet fall a little slower than a dismissal, so the object
/// underneath reads as revealed rather than jumped to.
const _saveDropDuration = Duration(milliseconds: 420);

/// Furniture, not a toy: a damped settle, never a bouncy spring.
const _riseCurve = Cubic(0.16, 1, 0.3, 1);

/// CSS `blur(4px)` maps to sigma 2.
const _backdropBlur = 2.0;

/// Past this much of the sheet's height, releasing dismisses.
const _dismissFraction = 0.35;
const _dismissVelocity = 700.0;

/// A release that does not dismiss springs back.
const _settleDuration = Duration(milliseconds: 260);

/// Opens the manual add flow, 04 then 05, over the live Home.
///
/// Nothing is committed until SAVE, so every other dismissal — drag, backdrop
/// tap — returns to Home with no data saved and no confirmation prompt. SAVE
/// drops the sheet and hands [onSave] the draft; writing it is the caller's.
Future<void> showAddFlow(
  BuildContext context, {
  required ValueChanged<SpecDraft> onSave,
  List<String> zones = starterZones,
  AddType initialType = defaultAddType,
  Future<File?> Function()? pickPhoto,
}) {
  late final AddSheetRoute route;
  route = AddSheetRoute(
    isMotionReduced: MediaQuery.disableAnimationsOf(context),
    builder: (context) => AddFlowSheet(
      zones: zones,
      initialType: initialType,
      pickPhoto: pickPhoto,
      depth: route.stepDepth,
      onSave: (draft) {
        route.dropAway();
        onSave(draft);
      },
    ),
  );
  return Navigator.of(context, rootNavigator: true).push<void>(route);
}

/// Opens step 05 on its own, for a flow whose earlier steps were screens
/// rather than sheets: a library pick on 07, or a name typed on 08.
///
/// The sheet rises straight to its step 05 height and fill, over whatever is
/// underneath. As with [showAddFlow], only SAVE commits: it drops the sheet
/// and hands [onSave] the draft. [zone] pre-selects the matching entry of
/// [zones], ignoring case, or the first when nothing matches.
Future<void> showAddFields(
  BuildContext context, {
  required AddType type,
  required List<String> zones,
  required ValueChanged<SpecDraft> onSave,
  String? zone,
  SpecKind? initialKind,
  String? name,
  String initialValue = '',
  File? photo,
  Future<File?> Function()? pickPhoto,
  String stepLabel = 'STEP 2 / 3',
}) {
  final wanted = zone?.toLowerCase();
  late final AddSheetRoute route;
  route = AddSheetRoute(
    isMotionReduced: MediaQuery.disableAnimationsOf(context),
    builder: (context) => AddSheetShell(
      fill: AddColors.fieldsSheetFill,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height - kFieldsSheetTop,
        child: AddFieldsSheet(
          type: type,
          zone: zones.firstWhere(
            (z) => z.toLowerCase() == wanted,
            orElse: () => zones.first,
          ),
          zones: zones,
          stepLabel: stepLabel,
          initialKind: initialKind,
          name: name,
          initialValue: initialValue,
          photo: photo,
          pickPhoto: pickPhoto,
          onSave: (draft) {
            route.dropAway();
            onSave(draft);
          },
        ),
      ),
    ),
  );
  // Step 05's deeper dim from the start: there is no shorter sheet to grow
  // out of.
  route.stepDepth.value = 1;
  return Navigator.of(context, rootNavigator: true).push<void>(route);
}

/// A transparent route so the Home underneath keeps rendering and animating.
///
/// The backdrop is that live widget blurred, never a screenshot: the blur has
/// to ramp in with the sheet and unwind under a drag, and a bitmap cannot do
/// either.
class AddSheetRoute extends PageRoute<void> {
  AddSheetRoute({required this.builder, this.isMotionReduced = false});

  final WidgetBuilder builder;
  final bool isMotionReduced;

  /// The controller that drives the rise, exposed to the scaffold so a drag
  /// can move it by hand.
  AnimationController get sheetController => controller!;

  /// How far the sheet has grown into step 05, 0 → 1. The backdrop dims
  /// deeper as it does, because the taller sheet covers more.
  final ValueNotifier<double> stepDepth = ValueNotifier(0);

  /// SAVE: the sheet falls away over 420ms rather than a dismissal's 320.
  void dropAway() {
    final navigator = this.navigator;
    if (!isCurrent || navigator == null) return;
    controller?.reverseDuration = isMotionReduced
        ? _reducedDuration
        : _saveDropDuration;
    navigator.pop();
  }

  @override
  void dispose() {
    stepDepth.dispose();
    super.dispose();
  }

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  /// The backdrop is painted inside the route, so the framework's plain
  /// colour barrier stays out of it.
  @override
  Color? get barrierColor => null;

  /// Dismissal is handled by the backdrop's own detector, which can also drag.
  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration =>
      isMotionReduced ? _reducedDuration : _riseDuration;

  @override
  Duration get reverseTransitionDuration =>
      isMotionReduced ? _reducedDuration : _tapDismissDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _AddSheetScaffold(
      route: this,
      isMotionReduced: isMotionReduced,
      child: builder(context),
    );
  }

  /// No [buildTransitions]: the scaffold drives every part of the transition
  /// off [animation] itself, because a drag has to move the sheet and unwind
  /// the backdrop together.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class _AddSheetScaffold extends StatefulWidget {
  const _AddSheetScaffold({
    required this.route,
    required this.isMotionReduced,
    required this.child,
  });

  final AddSheetRoute route;
  final bool isMotionReduced;
  final Widget child;

  @override
  State<_AddSheetScaffold> createState() => _AddSheetScaffoldState();
}

class _AddSheetScaffoldState extends State<_AddSheetScaffold> {
  final GlobalKey _sheetKey = GlobalKey();

  /// While a finger owns the sheet, position follows the finger rather than a
  /// curve, or the sheet would lag behind the touch.
  bool _isDragDriven = false;

  AnimationController get _controller => widget.route.sheetController;

  double get _riseValue {
    if (_isDragDriven) return _controller.value;
    return _curved(
      widget.isMotionReduced ? Curves.easeOut : _riseCurve,
      Curves.easeInCubic.flipped,
    );
  }

  double get _backdropValue {
    if (_isDragDriven) return _controller.value;
    return _curved(Curves.easeOut, Curves.easeOut.flipped);
  }

  double _curved(Curve forward, Curve reverse) {
    final curve = _controller.status == AnimationStatus.reverse
        ? reverse
        : forward;
    return curve.transform(_controller.value.clamp(0, 1));
  }

  double get _sheetHeight =>
      _sheetKey.currentContext?.size?.height ?? double.infinity;

  /// Once the route is on its way out, nothing may pop it again: a second pop
  /// would take Home with it.
  void _dismiss() {
    if (!widget.route.isCurrent) return;
    Navigator.of(context).pop();
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.route.isCurrent) return;
    setState(() => _isDragDriven = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragDriven || !widget.route.isCurrent) return;
    final height = _sheetHeight;
    if (!height.isFinite || height <= 0) return;
    _controller.value = (_controller.value - details.primaryDelta! / height)
        .clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragDriven || !widget.route.isCurrent) return;
    final velocity = details.primaryVelocity ?? 0;
    final isDismissed =
        _controller.value < 1 - _dismissFraction || velocity > _dismissVelocity;

    if (isDismissed) {
      // Finish the throw over what is left of the distance rather than
      // restarting a full-length exit from wherever the finger let go.
      _controller.reverseDuration = _scaled(_controller.value);
      _dismiss();
      return;
    }

    _controller
        .animateTo(1, duration: _settleDuration, curve: Curves.easeOutBack)
        .whenComplete(() {
          if (mounted) setState(() => _isDragDriven = false);
        });
  }

  Duration _scaled(double fraction) => Duration(
    microseconds:
        (widget.route.reverseTransitionDuration.inMicroseconds * fraction)
            .round(),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, widget.route.stepDepth]),
      builder: (context, child) {
        final backdrop = _backdropValue;
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildBackdrop(backdrop),
            Align(
              alignment: Alignment.bottomCenter,
              // The sheet's own height drives the offset, so nothing has to
              // measure it to put it off-screen.
              child: FractionalTranslation(
                translation: Offset(0, 1 - _riseValue),
                child: child,
              ),
            ),
          ],
        );
      },
      child: GestureDetector(
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        behavior: HitTestBehavior.opaque,
        child: KeyedSubtree(key: _sheetKey, child: widget.child),
      ),
    );
  }

  /// The live Home behind, blurred and dimmed. Dropping that layer to 30%
  /// over `bg` is the same as painting `bg` at 70% on top of it, which is what
  /// [AddColors.backdropDim] is. Step 05 deepens it to 22%.
  Widget _buildBackdrop(double t) {
    final dim = Color.lerp(
      AddColors.backdropDim,
      AddColors.fieldsBackdropDim,
      widget.route.stepDepth.value,
    )!;
    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _backdropBlur * t,
          sigmaY: _backdropBlur * t,
        ),
        child: ColoredBox(
          color: dim.withValues(alpha: dim.a * t),
          child: ColoredBox(
            color: AddColors.scrim.withValues(alpha: AddColors.scrim.a * t),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
