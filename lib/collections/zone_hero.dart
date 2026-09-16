import 'package:flutter/widgets.dart';

import 'package:spec/collections/collections_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// Zone names are unique regardless of case, so the lowercased name is the
/// zone's identity across both screens. Search only ever knows its scope by
/// name, which is why the tag is not the row id.
String zoneHeroTag(String name) => 'zone-${name.toLowerCase()}';

/// The lime fill fades in over the back half of the flight.
const _fillFadeStart = 0.5;

const _chipPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 5);

/// The scope chip's label: 9.5pt mono on lime, as Search draws it.
const _chipText = TextStyle(
  fontFamily: SpecFonts.mono,
  fontSize: 9.5,
  height: 1,
  color: SpecColors.onAccent,
);

/// A zone's name as either end of the Collections → Search flight draws it:
/// the 26pt row name, or Search's lime scope chip.
class ZoneHeroLabel extends StatelessWidget {
  const ZoneHeroLabel({super.key, required this.name, this.isChip = false});

  final String name;
  final bool isChip;

  @override
  Widget build(BuildContext context) => _paint(name, isChip ? 1 : 0);
}

/// Wraps [label] as the shared element between a zone row and Search's scope
/// chip.
Widget zoneNameHero(ZoneHeroLabel label) => Hero(
  tag: zoneHeroTag(label.name),
  // Hero defaults to fastOutSlowIn; the flight is authored on easeOutCubic.
  curve: Curves.easeOutCubic,
  flightShuttleBuilder: _shuttle,
  child: label,
);

Widget _shuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final from = (fromHeroContext.widget as Hero).child as ZoneHeroLabel;
  final to = (toHeroContext.widget as Hero).child as ZoneHeroLabel;
  final fromChip = from.isChip ? 1.0 : 0.0;
  final toChip = to.isChip ? 1.0 : 0.0;

  // Reduced motion: no text lerp, just the two ends dissolving.
  if (MediaQuery.disableAnimationsOf(flightContext)) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Stack(
        children: [
          Opacity(opacity: 1 - animation.value, child: from),
          Positioned.fill(
            child: Opacity(opacity: animation.value, child: to),
          ),
        ],
      ),
    );
  }

  // Read off both heroes rather than [direction], so a pop flies the chip
  // home without any special case.
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) =>
        _paint(from.name, fromChip + (toChip - fromChip) * animation.value),
  );
}

/// [chipness] 0 is the row name, 1 the scope chip.
Widget _paint(String name, double chipness) {
  final style = TextStyle.lerp(
    CollectionsText.zoneName,
    _chipText,
    chipness,
  )!.copyWith(decoration: TextDecoration.none);
  final fill = const Interval(
    _fillFadeStart,
    1,
  ).transform(chipness.clamp(0, 1));

  return Container(
    padding: EdgeInsets.lerp(EdgeInsets.zero, _chipPadding, chipness),
    decoration: BoxDecoration(
      color: SpecColors.accent.withValues(alpha: fill),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      chipness < 0.5 ? name : name.toUpperCase(),
      style: style,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
    ),
  );
}
