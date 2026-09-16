import 'package:flutter/widgets.dart';

/// 600ms in, 520ms out.
const kArrivalDuration = Duration(milliseconds: 600);
const kDepartureDuration = Duration(milliseconds: 520);

/// Reduce Motion: a plain cross-fade, the spec already at size.
const kReducedRouteDuration = Duration(milliseconds: 240);

/// The body entrance starts once the flight is 45% of the way here.
const kBodyStartsAt = 0.45;

/// Of the 520ms departure, the body clears over the first 200 before the
/// heroes leave.
const kBodyClearsBy = 200 / 520;

/// The strip along the leading edge that starts a back swipe.
const _edgeWidth = 20.0;
const _flingVelocity = 1.0;
const _commitFraction = 0.5;

/// The route that opens screen 03.
///
/// A shared-element expansion over a fade, not a page sliding in: everything
/// that is not one of the three Heroes fades. `CupertinoPageRoute` owns the
/// interactive back swipe this screen needs, but its gesture detector is
/// private and welded to its slide, so the swipe is rebuilt here on the same
/// public hooks it uses — [NavigatorState.didStartUserGesture] and the route's
/// own controller. That is what lets a Hero track the finger instead of
/// playing out a fire-and-forget animation.
class ObjectPageRoute<T> extends PageRoute<T> {
  ObjectPageRoute({
    required this.builder,
    required this.isMotionReduced,
    super.settings,
  });

  final WidgetBuilder builder;
  final bool isMotionReduced;

  @override
  Duration get transitionDuration =>
      isMotionReduced ? kReducedRouteDuration : kArrivalDuration;

  @override
  Duration get reverseTransitionDuration =>
      isMotionReduced ? kReducedRouteDuration : kDepartureDuration;

  @override
  bool get opaque => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: _EdgeSwipe(route: this, child: child),
    );
  }

  bool get _canSwipe =>
      !isFirst && !willHandlePopInternally && !popGestureInProgress;

  void _startSwipe() => navigator?.didStartUserGesture();

  void _updateSwipe(double fractionDelta) {
    final flight = controller;
    if (flight == null) return;
    flight.value = (flight.value - fractionDelta).clamp(0.0, 1.0);
  }

  void _endSwipe(double velocity) {
    final flight = controller;
    final nav = navigator;
    if (flight == null || nav == null) return;

    final isCommitted = velocity.abs() >= _flingVelocity
        ? velocity > 0
        : flight.value < _commitFraction;

    if (isCommitted) {
      nav.pop();
    } else {
      flight.forward();
    }

    // Hand control back to the navigator once the settle has finished, or a
    // pop would land while it still thinks a finger is down.
    if (flight.isAnimating) {
      late final AnimationStatusListener onDone;
      onDone = (status) {
        if (status.isAnimating) return;
        nav.didStopUserGesture();
        flight.removeStatusListener(onDone);
      };
      flight.addStatusListener(onDone);
    } else {
      nav.didStopUserGesture();
    }
  }
}

class _EdgeSwipe extends StatefulWidget {
  const _EdgeSwipe({required this.route, required this.child});

  final ObjectPageRoute<dynamic> route;
  final Widget child;

  @override
  State<_EdgeSwipe> createState() => _EdgeSwipeState();
}

class _EdgeSwipeState extends State<_EdgeSwipe> {
  bool _isDragging = false;

  void _onStart(DragStartDetails details) {
    if (!widget.route._canSwipe) return;
    _isDragging = true;
    widget.route._startSwipe();
  }

  void _onUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final width = context.size?.width ?? 0;
    if (width <= 0) return;
    widget.route._updateSwipe((details.primaryDelta ?? 0) / width);
  }

  void _onEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    final width = context.size?.width ?? 1;
    widget.route._endSwipe(details.velocity.pixelsPerSecond.dx / width);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).left;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _edgeWidth + inset,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _onStart,
            onHorizontalDragUpdate: _onUpdate,
            onHorizontalDragEnd: _onEnd,
            onHorizontalDragCancel: () => _onEnd(DragEndDetails()),
          ),
        ),
      ],
    );
  }
}
