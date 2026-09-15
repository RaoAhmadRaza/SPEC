import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spec/library/library_models.dart';
import 'package:spec/library/library_pick_screen.dart';
import 'package:spec/providers/library.dart';

const _riseDuration = Duration(milliseconds: 420);
const _dropDuration = Duration(milliseconds: 360);
const _reducedDuration = Duration(milliseconds: 200);

/// The screen arrives as a full screen, not a sheet: its top corners round
/// only while it is still travelling.
const _flightRadius = 30.0;

/// The iOS card-stack recession of whatever is behind.
const _callerScale = 0.96;
const _callerOpacity = 0.6;

/// The strip along the top edge that a downward drag starts from. Above the
/// header, so it never competes with `CANCEL` or with the grid's scroll.
const _dragEdge = 44.0;

/// Past this much of the height, or this fast, a release dismisses.
const _dismissFraction = 0.30;
const _dismissVelocity = 700.0;
const _settleDuration = Duration(milliseconds: 260);

/// Presents screen 07 over the current screen.
///
/// The library is read before the route is pushed, so the screen never has a
/// loading state: it is bundled, and after the first open it is in memory.
Future<void> showLibraryPick(
  BuildContext context, {
  required ValueChanged<LibraryItem> onPick,
  ValueChanged<String>? onAddOwn,
  String stepLabel = 'STEP 1 / 3',
  String initialQuery = '',
}) async {
  final items = await ProviderScope.containerOf(
    context,
    listen: false,
  ).read(libraryItemsProvider.future);
  if (!context.mounted) return;

  final navigator = Navigator.of(context, rootNavigator: true);
  await navigator.push<void>(
    LibraryPickPageRoute(
      isMotionReduced: MediaQuery.disableAnimationsOf(context),
      builder: (context) => LibraryPickScreen(
        items: items,
        stepLabel: stepLabel,
        initialQuery: initialQuery,
        onPick: onPick,
        onAddOwn: onAddOwn,
        // Nothing was committed, so there is nothing to confirm.
        onCancel: () {
          unawaited(HapticFeedback.lightImpact());
          if (navigator.canPop()) navigator.pop();
        },
      ),
    ),
  );
}

/// A full-screen modal route: it rises from the bottom, and the screen behind
/// recedes to 0.96 while it does.
class LibraryPickPageRoute extends PageRoute<void> {
  LibraryPickPageRoute({required this.builder, this.isMotionReduced = false});

  final WidgetBuilder builder;
  final bool isMotionReduced;

  /// Exposed to the scaffold so a drag can move the route by hand.
  AnimationController get flight => controller!;

  @override
  Duration get transitionDuration =>
      isMotionReduced ? _reducedDuration : _riseDuration;

  @override
  Duration get reverseTransitionDuration =>
      isMotionReduced ? _reducedDuration : _dropDuration;

  /// Opaque once it has arrived. While it travels, or while a finger holds
  /// it, the framework keeps painting the screen behind.
  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  /// The caller scales and dims itself off this route's own animation, so a
  /// drag that moves this route moves the recession with it.
  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      isMotionReduced ? _dimBehind : _recedeBehind;

  static Widget? _recedeBehind(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => AnimatedBuilder(
    animation: secondaryAnimation,
    child: child,
    builder: (context, inner) {
      final t = Curves.easeOut.transform(secondaryAnimation.value.clamp(0, 1));
      return Opacity(
        opacity: 1 - (1 - _callerOpacity) * t,
        child: Transform.scale(scale: 1 - (1 - _callerScale) * t, child: inner),
      );
    },
  );

  /// Reduce Motion keeps the dim and drops the scale.
  static Widget? _dimBehind(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => AnimatedBuilder(
    animation: secondaryAnimation,
    child: child,
    builder: (context, inner) => Opacity(
      opacity: 1 - (1 - _callerOpacity) * secondaryAnimation.value,
      child: inner,
    ),
  );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _ModalScaffold(route: this, child: builder(context));

  /// The scaffold drives the transition itself, because a drag has to move
  /// the screen without a curve getting in the way of the finger.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class _ModalScaffold extends StatefulWidget {
  const _ModalScaffold({required this.route, required this.child});

  final LibraryPickPageRoute route;
  final Widget child;

  @override
  State<_ModalScaffold> createState() => _ModalScaffoldState();
}

class _ModalScaffoldState extends State<_ModalScaffold> {
  /// While a finger owns the screen, position follows the finger rather than
  /// a curve, or the screen would lag behind the touch.
  bool _isDragDriven = false;

  AnimationController get _flight => widget.route.flight;

  double get _rise {
    final value = _flight.value.clamp(0.0, 1.0);
    if (_isDragDriven) return value;
    return _flight.status == AnimationStatus.reverse
        ? Curves.easeInCubic.flipped.transform(value)
        : Curves.easeOutCubic.transform(value);
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.route.isCurrent) return;
    setState(() => _isDragDriven = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragDriven || !widget.route.isCurrent) return;
    final height = context.size?.height ?? 0;
    if (height <= 0) return;
    _flight.value = (_flight.value - details.primaryDelta! / height).clamp(
      0.0,
      1.0,
    );
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragDriven || !widget.route.isCurrent) return;
    final velocity = details.primaryVelocity ?? 0;
    final isDismissed =
        _flight.value < 1 - _dismissFraction || velocity > _dismissVelocity;

    if (isDismissed) {
      // Finish the throw over what is left of the distance rather than
      // replaying a full-length drop from wherever the finger let go.
      _flight.reverseDuration = Duration(
        microseconds:
            (widget.route.reverseTransitionDuration.inMicroseconds *
                    _flight.value)
                .round(),
      );
      Navigator.of(context).pop();
      return;
    }

    unawaited(
      _flight
          .animateTo(1, duration: _settleDuration, curve: Curves.easeOutBack)
          .whenComplete(() {
            if (mounted) setState(() => _isDragDriven = false);
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _dragEdge,
          child: GestureDetector(
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            behavior: HitTestBehavior.opaque,
          ),
        ),
      ],
    );

    if (widget.route.isMotionReduced) {
      return FadeTransition(opacity: _flight, child: page);
    }

    return AnimatedBuilder(
      animation: _flight,
      child: page,
      builder: (context, child) {
        final rise = _rise;
        return FractionalTranslation(
          translation: Offset(0, 1 - rise),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(_flightRadius * (1 - rise)),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
