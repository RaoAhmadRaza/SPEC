import 'package:flutter/widgets.dart';

import 'package:spec/collections/zone_hero.dart';
import 'package:spec/home/home_glass.dart';
import 'package:spec/home/home_icons.dart';
import 'package:spec/search/search_tokens.dart';
import 'package:spec/search/search_waveform.dart';
import 'package:spec/theme/spec_tokens.dart';

/// Home's pill and Search's pill are the same element, so they share a tag.
const kSearchPillTag = 'search-pill';

/// Both ends of the flight cross-fade their contents over its last 40%.
const _contentFadeStart = 0.6;

const _pillPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 17);
const _glyphSize = 19.0;
const _contentGap = 12.0;
const _scopeClearGap = 6.0;

/// The glass shell of the search pill.
///
/// Both ends of the Hero are one of these, which is what lets the flight read
/// each end's border colour and interpolate a single pill rather than
/// cross-fading two of them.
class SearchPillShell extends StatelessWidget {
  const SearchPillShell({
    super.key,
    required this.borderColor,
    required this.blur,
    required this.child,
    this.bottomHighlight,
    this.flightChild,
    this.padding = _pillPadding,
  });

  final Color borderColor;

  /// CSS `blur(30px)` is a 15pt sigma. Home was authored against the raw CSS
  /// number and is left on it, so the two ends differ and the flight lerps
  /// between them rather than popping at either end.
  final double blur;

  /// `box-shadow: inset 0 -1px 0 …`. Home draws one; Search does not.
  final Color? bottomHighlight;

  final Widget child;

  /// What the flight draws in place of [child].
  ///
  /// Search's pill holds a focused text field, and a second one in the flight
  /// overlay would fight the first for its focus node — so the flight gets a
  /// plain twin. Null means [child] is already inert.
  final Widget? flightChild;

  /// The library pill (07) sits one point shorter than Search's.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(999),
      blur: blur,
      saturation: 2,
      borderColor: borderColor,
      topHighlight: SearchColors.pillHighlight,
      bottomHighlight: bottomHighlight,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [SearchColors.pillTop, SearchColors.pillBottom],
      ),
      shadows: const [
        BoxShadow(
          color: SearchColors.pillShadow,
          blurRadius: 30,
          offset: Offset(0, 12),
        ),
      ],
      padding: padding,
      child: child,
    );
  }
}

/// Wraps [shell] as the shared element between Home and Search.
Widget searchPillHero({required SearchPillShell shell}) =>
    Hero(tag: kSearchPillTag, flightShuttleBuilder: _shuttle, child: shell);

SearchPillShell _shellOf(BuildContext context) =>
    (context.widget as Hero).child as SearchPillShell;

Widget _shuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final from = _shellOf(fromHeroContext);
  final to = _shellOf(toHeroContext);
  final fromChild = from.flightChild ?? from.child;
  final toChild = to.flightChild ?? to.child;

  // Reading both ends off the heroes rather than off [direction] keeps the
  // flight correct in both directions without depending on which way the
  // framework drives the animation on a pop.
  if (MediaQuery.disableAnimationsOf(flightContext)) {
    return _CrossFade(animation: animation, from: fromChild, to: toChild);
  }

  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) => SearchPillShell(
      borderColor: Color.lerp(
        from.borderColor,
        to.borderColor,
        animation.value,
      )!,
      blur: from.blur + (to.blur - from.blur) * animation.value,
      bottomHighlight: Color.lerp(
        from.bottomHighlight ?? const Color(0x00FFFFFF),
        to.bottomHighlight ?? const Color(0x00FFFFFF),
        animation.value,
      ),
      child: _CrossFade(
        animation: animation,
        from: fromChild,
        to: toChild,
        begin: _contentFadeStart,
      ),
    ),
  );
}

/// Holds both children so the pill's height never jumps mid-flight.
class _CrossFade extends StatelessWidget {
  const _CrossFade({
    required this.animation,
    required this.from,
    required this.to,
    this.begin = 0,
  });

  final Animation<double> animation;
  final Widget from;
  final Widget to;
  final double begin;

  @override
  Widget build(BuildContext context) {
    // Transformed by hand rather than through a CurvedAnimation: the shuttle
    // rebuilds on every frame of the flight, and a controller allocated there
    // would never be disposed.
    final curve = Interval(begin, 1, curve: Curves.easeOut);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = curve.transform(animation.value.clamp(0, 1));
        return Stack(
          children: [
            Opacity(opacity: 1 - t, child: from),
            Positioned.fill(
              child: Opacity(opacity: t, child: to),
            ),
          ],
        );
      },
    );
  }
}

/// The row inside the pill: glyph, optional scope chip, query, waveform.
class SearchPillContent extends StatelessWidget {
  const SearchPillContent({
    super.key,
    required this.field,
    required this.waveform,
    this.scope,
    this.onClearScope,
    this.glyphColor = SpecColors.ink85,
  });

  /// The live [EditableText], or a plain [Text] standing in for it.
  final Widget field;
  final Widget waveform;

  /// Non-null narrows the search to one zone (§4.3).
  final String? scope;
  final VoidCallback? onClearScope;

  /// Home sets its glyph a step behind Search's.
  final Color glyphColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HomeIcon.search(size: _glyphSize, color: glyphColor),
        const SizedBox(width: _contentGap),
        if (scope case final String zone) ...[
          // The chip yields before the pill overflows: a long zone name used
          // to push the field off the end.
          Flexible(
            child: _ScopeChip(zone: zone, onClear: onClearScope),
          ),
          const SizedBox(width: _contentGap),
        ],
        Expanded(child: field),
        const SizedBox(width: _contentGap),
        waveform,
      ],
    );
  }
}

/// The zone Search is narrowed to, and the `×` that widens it again.
///
/// The name is the far end of the Collections row's Hero, so the label paints
/// its own lime fill and padding: a fill drawn here would sit still while the
/// name flies into it. The `×` stays outside the Hero, since it has no twin
/// on the row to fly from, and so sits on the glass beside the chip, in ink.
class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.zone, this.onClear});

  final String zone;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: zoneNameHero(ZoneHeroLabel(name: zone, isChip: true))),
        const SizedBox(width: _scopeClearGap),
        GestureDetector(
          onTap: onClear,
          behavior: HitTestBehavior.opaque,
          child: Text(
            '×',
            style: SearchText.scopeClear.copyWith(color: SpecColors.ink85),
          ),
        ),
      ],
    );
  }
}

/// The waveform the flight draws — inert, so it cannot tick on its own.
const kFlightWaveform = StaticWaveform();
