import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:spec/add/manual_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// The 210pt card flies into step 05's photo slot.
const kManualPhotoTag = 'manual-photo';

/// The typed name flies into step 05's context row.
const kManualNameTag = 'manual-name';

const manualPhotoRadius = BorderRadius.only(
  topLeft: Radius.circular(22),
  topRight: Radius.circular(22),
  bottomRight: Radius.circular(22),
  bottomLeft: Radius.circular(6),
);

/// Step 05's slot keeps the same cut, a size down.
const _slotRadius = BorderRadius.only(
  topLeft: Radius.circular(18),
  topRight: Radius.circular(18),
  bottomRight: Radius.circular(18),
  bottomLeft: Radius.circular(5),
);

/// What the name becomes in step 05's context row: mono 10pt ink62.
const _contextStyle = TextStyle(
  fontFamily: SpecFonts.mono,
  fontSize: 10,
  letterSpacing: 2.20,
  color: SpecColors.ink62,
);

/// The photo in flight: `BoxFit.cover` the whole way, the radius lerping from
/// the card's to the slot's. No chip and no ×; those belong to the card.
HeroFlightShuttleBuilder manualPhotoShuttle(File? photo) =>
    (flightContext, animation, direction, fromHeroContext, toHeroContext) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) => ClipRRect(
          borderRadius: BorderRadius.lerp(
            manualPhotoRadius,
            _slotRadius,
            animation.value,
          )!,
          child: child,
        ),
        child: ColoredBox(
          color: SpecColors.tile,
          child: photo == null
              ? const SizedBox.expand()
              : Image.file(
                  photo,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  excludeFromSemantics: true,
                ),
        ),
      );
    };

/// The name in flight. The string is uppercased before take-off, so no glyph
/// swaps case mid-air; only size, weight and ink travel.
HeroFlightShuttleBuilder manualNameShuttle(String name) {
  final label = name.trim().toUpperCase();
  return (flightContext, animation, direction, fromHeroContext, toHeroContext) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.clip,
          softWrap: false,
          style: TextStyle.lerp(
            ManualText.fieldValue,
            _contextStyle,
            animation.value,
          ),
        ),
      ),
    );
  };
}
