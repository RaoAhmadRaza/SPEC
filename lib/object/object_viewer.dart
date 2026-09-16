import 'package:flutter/widgets.dart';

import 'package:spec/data/photo_thumbnail.dart';
import 'package:spec/object/object_icons.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

const _openDuration = Duration(milliseconds: 380);
const _reducedDuration = Duration(milliseconds: 200);

/// How far down the finger has to travel to dismiss outright.
const _dismissFraction = 0.30;
const _dismissVelocity = 700.0;

const _maxZoom = 4.0;

/// The full-screen photo, expanded out of the slot that was tapped.
///
/// Deliberately not a `Hero`: the slot's own Hero tag already belongs to the
/// flight in from the card that opened this screen, and a widget cannot be two
/// heroes at once. Animating the slot's rect directly costs less than the
/// contortions of sharing one tag between two different flights — and it is
/// what lets a drag drive the reverse interactively.
class PhotoViewerRoute extends PageRoute<void> {
  PhotoViewerRoute({
    required this.photo,
    required this.origin,
    required this.originRadius,
    required this.isMotionReduced,
  });

  final ImageProvider photo;

  /// The slot's rect in global coordinates, measured at the moment of the tap.
  final Rect origin;
  final BorderRadius originRadius;
  final bool isMotionReduced;

  @override
  Duration get transitionDuration =>
      isMotionReduced ? _reducedDuration : _openDuration;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get barrierDismissible => false;

  @override
  bool get maintainState => true;

  /// The drag needs to drive the flight, which means driving this directly.
  AnimationController? get flight => controller;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> a,
    Animation<double> b,
  ) {
    return _PhotoViewer(route: this);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.route});

  final PhotoViewerRoute route;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  final TransformationController _zoom = TransformationController();
  late final CurvedAnimation _t = CurvedAnimation(
    parent: widget.route.animation!,
    curve: Curves.easeOutCubic,
  );

  double _dragStart = 0;

  /// Panning a zoomed photo must not also dismiss it.
  bool get _isZoomed => _zoom.value.getMaxScaleOnAxis() > 1.01;

  @override
  void dispose() {
    _t.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _dragStart = details.globalPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails details, double height) {
    final flight = widget.route.flight;
    if (flight == null || height <= 0) return;
    final travelled = (details.globalPosition.dy - _dragStart) / height;
    flight.value = (1 - travelled).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    final flight = widget.route.flight;
    if (flight == null) return;
    final isDismissed =
        flight.value < 1 - _dismissFraction ||
        details.velocity.pixelsPerSecond.dy > _dismissVelocity;
    if (isDismissed) {
      Navigator.of(context).pop();
      return;
    }
    flight.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final full = Offset.zero & size;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      onVerticalDragStart: _isZoomed ? null : _onDragStart,
      onVerticalDragUpdate: _isZoomed
          ? null
          : (details) => _onDragUpdate(details, size.height),
      onVerticalDragEnd: _isZoomed ? null : _onDragEnd,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final t = _t.value;
          final rect = Rect.lerp(widget.route.origin, full, t)!;
          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: ObjectColors.viewerGround.withValues(alpha: t),
                ),
              ),
              Positioned.fromRect(
                rect: rect,
                child: ClipRRect(
                  borderRadius: BorderRadius.lerp(
                    widget.route.originRadius,
                    BorderRadius.zero,
                    t,
                  )!,
                  child: InteractiveViewer(
                    transformationController: _zoom,
                    maxScale: _maxZoom,
                    // Zooming needs every pixel, so the viewer decodes the
                    // original. The thumbnail it grew from holds the frame
                    // until that decode lands, so it never opens blank.
                    //
                    // Contained, not covered: the tile crops to fill, and the
                    // viewer is where a label cut off at its edge is read.
                    child: Image(
                      image: fullResolution(widget.route.photo),
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      frameBuilder: (context, child, frame, isSync) =>
                          frame == null && !isSync
                          ? Image(
                              image: widget.route.photo,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                            )
                          : child,
                    ),
                  ),
                ),
              ),
              // The chrome is the last thing in and the first thing out.
              Positioned(
                left: ObjectMetrics.page.left,
                top: ObjectMetrics.page.top,
                child: Opacity(
                  opacity: t,
                  child: _CloseButton(onTap: () => Navigator.of(context).pop()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const SizedBox.square(
        dimension: ObjectMetrics.minHitBox,
        child: Center(child: BackChevron(color: SpecColors.ink75)),
      ),
    );
  }
}
