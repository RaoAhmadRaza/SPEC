import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:spec/home/home_glass.dart';
import 'package:spec/home/home_icons.dart';
import 'package:spec/home/home_models.dart';
import 'package:spec/home/home_tokens.dart';
import 'package:spec/object/object_tags.dart';
import 'package:spec/theme/spec_tokens.dart';

/// The designed tile height, now a floor rather than a fixed size: at a
/// raised text scale the content column needs more room, and a rigid box
/// would clip it. The grid rows are `IntrinsicHeight` so both tiles in a row
/// still share whichever height the taller one needs.
const double kCardHeight = 170;

/// Three corners at 20 and one cut to 6. The cut rotates in reading order,
/// so the four tiles never read as a plain grid.
const kCardRadii = <BorderRadius>[
  BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomRight: Radius.circular(20),
    bottomLeft: Radius.circular(6),
  ),
  BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomRight: Radius.circular(6),
    bottomLeft: Radius.circular(20),
  ),
  BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(6),
    bottomRight: Radius.circular(20),
    bottomLeft: Radius.circular(20),
  ),
  BorderRadius.only(
    topLeft: Radius.circular(6),
    topRight: Radius.circular(20),
    bottomRight: Radius.circular(20),
    bottomLeft: Radius.circular(20),
  ),
];

/// The scrim is what makes a white spec readable over any photograph, so it
/// runs corner to corner rather than top to bottom.
const _scrimAngle = 105.0;
const _addScrimAngle = 115.0;

/// The first tile's scrim is a shade denser than the rest.
const _leadScrimStops = [0.20, 0.62, 1.0];
const _scrimStops = [0.18, 0.65, 1.0];
const _addScrimStops = [0.25, 0.70, 1.0];

const _cardBlur = 14.0;

/// The DUE chip is the zone chip in lime: the accent already means "act on
/// this" everywhere else in the app, so it needs no colour of its own.
const _chipGap = 6.0;
final _dueChipText = HomeText.zoneChip.copyWith(color: SpecColors.accent);

/// One object tile: photo, diagonal scrim, and the spec as the hero.
class ObjectCard extends StatelessWidget {
  const ObjectCard({
    super.key,
    required this.object,
    required this.radius,
    required this.onTap,
    required this.onMenu,
    this.isLead = false,
  });

  final HomeObject object;
  final BorderRadius radius;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  /// The first tile in the grid, which carries the denser scrim.
  final bool isLead;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      radius: radius,
      photo: object.photo,
      // The photo, the spec and the zone chip are the three things that fly
      // into screen 03. Everything else on the card stays and fades with Home.
      photoHeroTag: objectPhotoTag(object.id),
      scrim: _scrimGradient(
        angle: _scrimAngle,
        stops: isLead ? _leadScrimStops : _scrimStops,
        colors: isLead
            ? const [
                HomeColors.scrimNear,
                HomeColors.scrimMid,
                HomeColors.scrimFar,
              ]
            : const [
                HomeColors.scrimNearSoft,
                HomeColors.scrimMidSoft,
                HomeColors.scrimFar,
              ],
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Hero(
                          tag: objectZoneTag(object.id),
                          child: _ZoneChip(object.zone),
                        ),
                      ),
                      if (object.isDue) ...[
                        const SizedBox(width: _chipGap),
                        _ZoneChip('DUE', style: _dueChipText),
                      ],
                    ],
                  ),
                ),
                _DotsButton(onTap: onMenu),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: objectSpecTag(object.id),
                  // Two lines, because a tall spec is already two by design
                  // ('205/55\nR16'). Truncating to one would change what this
                  // Hero's flight into the Object screen interpolates.
                  child: Text(
                    object.specText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: object.isSpecTall
                        ? HomeText.cardSpecTall
                        : HomeText.cardSpec,
                  ),
                ),
                const SizedBox(height: 7),
                Text(object.subLines.join('\n'), style: HomeText.cardSub),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        object.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeText.cardName,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _ArrowCircle(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The Add Something tile, the fourth slot in the grid.
class AddCard extends StatelessWidget {
  const AddCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const disc = _AddDisc();
    const copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Add Something', style: HomeText.addTitle),
        SizedBox(height: 6),
        Text('Save the details\nfor future you.', style: HomeText.addBody),
      ],
    );

    return _CardShell(
      radius: kCardRadii[3],
      photo: null,
      scrim: _scrimGradient(
        angle: _addScrimAngle,
        stops: _addScrimStops,
        colors: const [
          HomeColors.scrimNearSoft,
          HomeColors.scrimMid,
          HomeColors.scrimFarSoft,
        ],
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [disc, SizedBox(height: 14), copy],
        ),
      ),
    );
  }
}

/// Everything the two card kinds share: the clip, the border, the flat tile
/// behind a missing photo, and the scrim between photo and content.
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.radius,
    required this.photo,
    required this.scrim,
    required this.onTap,
    required this.child,
    this.photoHeroTag,
  });

  final BorderRadius radius;
  final ImageProvider? photo;

  /// Set on object cards, whose photo flies into screen 03.
  final String? photoHeroTag;
  final Gradient scrim;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kCardHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // A missing photo is a flat tile: no icon, no label.
            color: SpecColors.tile,
            borderRadius: radius,
            border: Border.all(color: HomeColors.cardBorder),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo case final ImageProvider image)
                  _maybeHero(
                    photoHeroTag,
                    Image(
                      image: image,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: scrim),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _maybeHero(String? tag, Widget child) =>
    tag == null ? child : Hero(tag: tag, child: child);

/// Converts a CSS gradient angle into the begin and end alignments Flutter
/// wants. 0deg points up, and the angle turns clockwise.
LinearGradient _scrimGradient({
  required double angle,
  required List<double> stops,
  required List<Color> colors,
}) {
  final radians = angle * math.pi / 180;
  final direction = Alignment(math.sin(radians), -math.cos(radians));
  return LinearGradient(
    begin: -direction,
    end: direction,
    colors: colors,
    stops: stops,
  );
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip(this.label, {this.style = HomeText.zoneChip});

  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(999),
      blur: _cardBlur,
      fill: HomeColors.zoneChipFill,
      borderColor: HomeColors.zoneChipBorder,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

class _DotsButton extends StatelessWidget {
  const _DotsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(999),
        blur: _cardBlur,
        fill: HomeColors.cardDotsFill,
        child: const SizedBox.square(
          dimension: 26,
          child: Center(
            child: HomeDots(dotSize: 2.5, gap: 2.5, color: SpecColors.ink85),
          ),
        ),
      ),
    );
  }
}

/// The three dots that stand in for an overflow menu, at two sizes.
class HomeDots extends StatelessWidget {
  const HomeDots({
    super.key,
    required this.dotSize,
    required this.gap,
    required this.color,
  });

  final double dotSize;
  final double gap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dot = DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: SizedBox.square(dimension: dotSize),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        SizedBox(width: gap),
        dot,
        SizedBox(width: gap),
        dot,
      ],
    );
  }
}

class _ArrowCircle extends StatelessWidget {
  const _ArrowCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: HomeColors.arrowBorder),
      ),
      child: const Center(
        child: HomeIcon.arrow(size: 11, color: SpecColors.ink90),
      ),
    );
  }
}

class _AddDisc extends StatelessWidget {
  const _AddDisc();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(999),
      blur: _cardBlur,
      fill: HomeColors.addDiscFill,
      borderColor: HomeColors.addDiscBorder,
      child: const SizedBox.square(
        dimension: 44,
        child: Center(child: Text('+', style: HomeText.plusAccent)),
      ),
    );
  }
}
