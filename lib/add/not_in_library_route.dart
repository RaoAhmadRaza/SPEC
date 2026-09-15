import 'package:flutter/widgets.dart';

const _pushDuration = Duration(milliseconds: 380);

/// The return path to 07 is the push reversed, a touch quicker.
const _popDuration = Duration(milliseconds: 360);
const _reducedDuration = Duration(milliseconds: 200);

/// 08 enters from +40; 07 leaves to −40 through its own secondary animation.
const _travel = 40.0;

/// How long the push from 07 takes, and the pop back to it.
({Duration push, Duration pop}) notInLibraryDurations({
  required bool isMotionReduced,
}) => isMotionReduced
    ? (push: _reducedDuration, pop: _reducedDuration)
    : (push: _pushDuration, pop: _popDuration);

/// The push from 07: this page slides in from +40 and fades up.
///
/// The header and the search pill are not part of it. Both are heroes that
/// fly onto themselves, so they sit in the overlay above this transition and
/// hold perfectly still — which is what makes the push read as the page under
/// them changing rather than a new screen arriving.
Widget notInLibraryTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final isReduced = MediaQuery.disableAnimationsOf(context);
  final curve = isReduced ? Curves.easeOut : Curves.easeOutCubic;
  // Transformed by hand: a CurvedAnimation allocated here would be rebuilt
  // with the route and never disposed.
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final t = curve.transform(animation.value.clamp(0, 1));
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(isReduced ? 0 : _travel * (1 - t), 0),
          child: child,
        ),
      );
    },
    child: child,
  );
}

/// A plain route for the push, for callers on the imperative navigator. A
/// go_router page passes [notInLibraryTransition] to its own page instead.
PageRoute<void> notInLibraryPageRoute({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final durations = notInLibraryDurations(
    isMotionReduced: MediaQuery.disableAnimationsOf(context),
  );
  return PageRouteBuilder<void>(
    transitionDuration: durations.push,
    reverseTransitionDuration: durations.pop,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: notInLibraryTransition,
  );
}
