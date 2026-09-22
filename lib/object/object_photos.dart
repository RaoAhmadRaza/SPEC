import 'package:flutter/widgets.dart';

import 'package:spec/object/object_hero.dart';
import 'package:spec/object/object_tags.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// The two slots, in the order the design lays them out.
const kMainSlot = 0;
const kDetailSlot = 1;

/// A slot was tapped or long-pressed. [origin] is its rect on screen, which the
/// viewer expands out of.
typedef PhotoSlotCallback = void Function(int slot, Rect origin);

/// A photo slot: clipped, bordered, and flat `#121416` when empty.
///
/// A missing photo is the tile and nothing else — no icon, no label, no dashed
/// border. The absence is the information.
class PhotoSlot extends StatelessWidget {
  const PhotoSlot({super.key, required this.photo, required this.radius});

  final ImageProvider? photo;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SpecColors.tile,
        borderRadius: radius,
        border: Border.all(color: ObjectColors.photoBorder),
      ),
      child: switch (photo) {
        final ImageProvider image => Image(
          image: image,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        ),
        null => null,
      },
    );
  }
}

/// The pair: 2 : 1, 158 tall, with opposite cut corners facing each other
/// across the 9pt gap.
class PhotoPair extends StatelessWidget {
  const PhotoPair({
    super.key,
    required this.id,
    required this.mainPhoto,
    required this.detailPhoto,
    required this.sourceRadius,
    required this.onOpen,
    required this.onLongPress,
    required this.wrapDetail,
    this.isMotionReduced = false,
  });

  final int id;
  final ImageProvider? mainPhoto;
  final ImageProvider? detailPhoto;

  /// The radius the main photo flew in from, so its cut corner rotates rather
  /// than snapping when the flight lands.
  final BorderRadius sourceRadius;

  final PhotoSlotCallback onOpen;
  final PhotoSlotCallback onLongPress;

  /// The detail photo enters with the body; the main one is already here.
  final Widget Function(Widget child) wrapDetail;

  /// Reduce Motion drops the flight: the tile is simply here.
  final bool isMotionReduced;

  @override
  Widget build(BuildContext context) {
    final main = PhotoSlot(
      photo: mainPhoto,
      radius: ObjectMetrics.mainPhotoRadius,
    );

    return AspectRatio(
      aspectRatio: ObjectMetrics.photoPairRatio,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: _Gestures(
              slot: kMainSlot,
              onOpen: onOpen,
              onLongPress: onLongPress,
              child: switch (mainPhoto) {
                final ImageProvider photo when !isMotionReduced => PhotoHero(
                  tag: objectPhotoTag(id),
                  photo: photo,
                  sourceRadius: sourceRadius,
                  restingRadius: ObjectMetrics.mainPhotoRadius,
                  child: main,
                ),
                // No photo to fly, or no flights at all: the tile is here.
                _ => main,
              },
            ),
          ),
          const SizedBox(width: ObjectMetrics.photoGap),
          Expanded(
            child: wrapDetail(
              _Gestures(
                slot: kDetailSlot,
                onOpen: onOpen,
                onLongPress: onLongPress,
                child: PhotoSlot(
                  photo: detailPhoto,
                  radius: ObjectMetrics.detailPhotoRadius,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Measures the slot at the moment of the gesture, so the viewer expands out
/// of wherever the slot actually is — mid-scroll included.
class _Gestures extends StatelessWidget {
  const _Gestures({
    required this.slot,
    required this.onOpen,
    required this.onLongPress,
    required this.child,
  });

  final int slot;
  final PhotoSlotCallback onOpen;
  final PhotoSlotCallback onLongPress;
  final Widget child;

  Rect _rectOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return Rect.zero;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onOpen(slot, _rectOf(context)),
      onLongPress: () => onLongPress(slot, _rectOf(context)),
      child: child,
    );
  }
}
