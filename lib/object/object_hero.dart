import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:spec/object/object_models.dart';
import 'package:spec/object/object_page_route.dart';
import 'package:spec/object/object_tags.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// The three elements that interpolate between the card that opened this
/// screen and the screen itself. Everything else fades.
///
/// The flight is one easeOutCubic, applied by [Hero.curve] so the rect and the
/// shuttle's own interpolation never disagree.
///
/// A shuttle's `animation` reads 0 at the card and 1 at this screen in both
/// directions — on a pop it simply runs backwards — so every tween below is
/// fixed source → screen and never consults [HeroFlightDirection].
const kFlightCurve = Curves.easeOutCubic;

/// On the way out the heroes hold still while the body clears, then fly: the
/// reverse of an arrival where they fly first and the body follows.
const kDepartureCurve = Interval(
  0,
  1 - kBodyClearsBy,
  curve: FlippedCurve(Curves.easeOutCubic),
);

/// The overlay a shuttle draws into sits outside the screen's own
/// `DefaultTextStyle`, so text in flight needs one of its own.
Widget _inFlight(Widget child) => DefaultTextStyle(
  style: const TextStyle(
    fontFamily: SpecFonts.display,
    color: SpecColors.ink,
    decoration: TextDecoration.none,
  ),
  child: child,
);

/// The spec, interpolated from the source card's size to 108pt.
///
/// One text widget whose `TextStyle` is lerped — never two cross-fading at
/// different sizes, which is the most common way to get this screen wrong.
class SpecHero extends StatelessWidget {
  const SpecHero({
    super.key,
    required this.id,
    required this.text,
    required this.sourceStyle,
    required this.restingStyle,
    required this.child,
  });

  final int id;
  final String text;
  final TextStyle sourceStyle;

  /// The style the spec actually settles at, which is [ObjectText.spec] scaled
  /// down when a long spec had to shrink to fit.
  final TextStyle restingStyle;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: objectSpecTag(id),
      curve: kFlightCurve,
      reverseCurve: kDepartureCurve,
      flightShuttleBuilder: (_, animation, _, _, _) => AnimatedBuilder(
        animation: animation,
        builder: (_, _) => _inFlight(
          Text(
            text,
            style: TextStyle.lerp(sourceStyle, restingStyle, animation.value),
          ),
        ),
      ),
      child: child,
    );
  }
}

/// The photo, held at `BoxFit.cover` for the whole flight so it never
/// letterboxes mid-air, with its cut corner rotating as it flies.
class PhotoHero extends StatelessWidget {
  const PhotoHero({
    super.key,
    required this.tag,
    required this.photo,
    required this.sourceRadius,
    required this.restingRadius,
    required this.child,
  });

  final String tag;
  final ImageProvider photo;
  final BorderRadius sourceRadius;
  final BorderRadius restingRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      curve: kFlightCurve,
      reverseCurve: kDepartureCurve,
      flightShuttleBuilder: (_, animation, _, _, _) => AnimatedBuilder(
        animation: animation,
        builder: (_, _) => ClipRRect(
          borderRadius: BorderRadius.lerp(
            sourceRadius,
            restingRadius,
            animation.value,
          )!,
          child: Image(image: photo, fit: BoxFit.cover, gaplessPlayback: true),
        ),
      ),
      child: child,
    );
  }
}

/// Where a zone chip flies in from, and how it gets here.
///
/// Two origins, because there are two ways into this screen. Home's glass chip
/// becomes lime; Search's plain mono line grows a lime fill behind it.
@immutable
class ZoneChipOrigin {
  const ZoneChipOrigin({
    required this.style,
    required this.fill,
    required this.border,
    required this.padding,
    required this.blur,
    required this.fillFadeStart,
  });

  /// Home's card chip: glass already, so only its colour has to change.
  static const homeTile = ZoneChipOrigin(
    style: TextStyle(
      fontFamily: SpecFonts.mono,
      fontSize: 9.5,
      letterSpacing: 2.09,
      color: SpecColors.ink,
      decoration: TextDecoration.none,
    ),
    fill: Color(0x1AFFFFFF),
    border: Color(0x33FFFFFF),
    padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    blur: 14,
    fillFadeStart: 0.60,
  );

  /// Search's zone line: no chip at all until the fill arrives behind it.
  static const searchRow = ZoneChipOrigin(
    style: TextStyle(
      fontFamily: SpecFonts.mono,
      fontSize: 10,
      letterSpacing: 1.80,
      color: SpecColors.ink62,
      decoration: TextDecoration.none,
    ),
    fill: Color(0x00FFFFFF),
    border: Color(0x00FFFFFF),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    blur: 0,
    fillFadeStart: 0.50,
  );

  final TextStyle style;
  final Color fill;
  final Color border;
  final EdgeInsets padding;
  final double blur;

  /// The point in the flight where the lime fill starts to arrive. Before it,
  /// the chip still reads as it did on the card it left.
  final double fillFadeStart;

  static ZoneChipOrigin of(ObjectSource source) => switch (source) {
    ObjectSource.homeTile => homeTile,
    ObjectSource.searchRow => searchRow,
  };
}

/// The zone chip, lerped from its origin to this screen's lime pill.
class ZoneChipHero extends StatelessWidget {
  const ZoneChipHero({
    super.key,
    required this.id,
    required this.label,
    required this.origin,
    required this.child,
  });

  final int id;
  final String label;
  final ZoneChipOrigin origin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: objectZoneTag(id),
      curve: kFlightCurve,
      reverseCurve: kDepartureCurve,
      flightShuttleBuilder: (_, animation, _, _, _) => AnimatedBuilder(
        animation: animation,
        builder: (_, _) => _inFlight(
          ZoneChipFrame(label: label, origin: origin, t: animation.value),
        ),
      ),
      child: child,
    );
  }
}

/// One chip drawn anywhere between its origin and its lime resting state.
///
/// The screen renders it at `t: 1`; the flight walks it there.
class ZoneChipFrame extends StatelessWidget {
  const ZoneChipFrame({
    super.key,
    required this.label,
    required this.origin,
    required this.t,
  });

  final String label;
  final ZoneChipOrigin origin;
  final double t;

  /// How far through the fill fade we are, 0 before it starts.
  double get _fill =>
      ((t - origin.fillFadeStart) / (1 - origin.fillFadeStart)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    final sigma = origin.blur * (1 - _fill);

    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(origin.fill, SpecColors.accent, _fill),
        borderRadius: radius,
        border: Border.all(
          color: Color.lerp(origin.border, const Color(0x00FFFFFF), _fill)!,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.lerp(origin.padding, ObjectMetrics.chipPadding, t)!,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle.lerp(origin.style, ObjectText.zoneChip, t),
        ),
      ),
    );

    // Once the lime has arrived there is nothing left to see through, so the
    // blur is dropped rather than paid for.
    if (sigma <= 0) return ClipRRect(borderRadius: radius, child: chip);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: chip,
      ),
    );
  }
}
