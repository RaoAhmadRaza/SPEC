import 'package:flutter/widgets.dart';

/// The Hero flight's durations.
const _push = Duration(milliseconds: 420);
const _pop = Duration(milliseconds: 380);
const _reduced = Duration(milliseconds: 200);

/// A scoped search also flies the zone's name into the chip, which needs a
/// little longer than a plain dissolve to read under Reduce Motion.
const _reducedScoped = Duration(milliseconds: 240);

/// The screen underneath clears over the first 200ms of the 420ms push.
const _behindFade = Interval(0, 0.48, curve: Curves.easeOut);

/// Screen 02's page.
///
/// Only the page's background cross-dissolves. The pill flies in the overlay
/// above it, and the screen fades its own content in over the back of the
/// flight.
class SearchPage extends Page<void> {
  const SearchPage({
    super.key,
    super.name,
    required this.child,
    this.isScoped = false,
  });

  final Widget child;

  /// Pushed from a Collections zone row rather than Home's pill.
  final bool isScoped;

  @override
  Route<void> createRoute(BuildContext context) => _SearchPageRoute(
    page: this,
    isMotionReduced: MediaQuery.disableAnimationsOf(context),
    reducedDuration: isScoped ? _reducedScoped : _reduced,
  );
}

class _SearchPageRoute extends PageRoute<void> {
  _SearchPageRoute({
    required SearchPage page,
    required this.isMotionReduced,
    required this.reducedDuration,
  }) : super(settings: page);

  final bool isMotionReduced;
  final Duration reducedDuration;

  @override
  Duration get transitionDuration => isMotionReduced ? reducedDuration : _push;

  @override
  Duration get reverseTransitionDuration =>
      isMotionReduced ? reducedDuration : _pop;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  /// The screen beneath fades out as Search arrives.
  ///
  /// Declared here rather than inside that screen, so it runs only under
  /// Search: a sheet or a modal pushed over the same screen asks for its own
  /// treatment of what is behind it.
  @override
  DelegatedTransitionBuilder? get delegatedTransition => _fadeBehind;

  static Widget? _fadeBehind(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => AnimatedBuilder(
    animation: secondaryAnimation,
    child: child,
    builder: (context, inner) => Opacity(
      opacity: 1 - _behindFade.transform(secondaryAnimation.value.clamp(0, 1)),
      child: inner,
    ),
  );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => (settings as SearchPage).child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}
