import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spec/app/router.dart';
import 'package:spec/home/home_card.dart';
import 'package:spec/home/home_models.dart';
import 'package:spec/home/home_tokens.dart';
import 'package:spec/object/object_actions.dart';
import 'package:spec/object/object_models.dart';
import 'package:spec/object/object_page_route.dart';
import 'package:spec/object/object_screen.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/object.dart';
import 'package:spec/providers/photos.dart';

// Home's card ••• opens the same sheet, and Home already reaches screen 03's
// wiring through this file.
export 'package:spec/object/object_actions.dart' show showObjectActions;

/// What the caller already knows when it opens screen 03.
///
/// The seed matters more than it looks: Hero destinations are collected on
/// the first frame of the push, and a database stream does not reliably emit
/// inside that frame. Without the card's own spec, zone and photo on screen
/// from frame one, there is nothing to fly to.
@immutable
class ObjectRouteArgs {
  const ObjectRouteArgs({
    required this.seed,
    required this.sourceSpecStyle,
    required this.sourcePhotoRadius,
    this.source = ObjectSource.homeTile,
  });

  final ObjectView seed;
  final TextStyle sourceSpecStyle;
  final BorderRadius sourcePhotoRadius;
  final ObjectSource source;
}

/// Seeds screen 03 from the Home tile that was tapped: its spec style, its
/// cut corner (which rotates with the grid position), zone and photo.
ObjectRouteArgs objectRouteArgsFor(HomeObject object, List<HomeObject> shown) {
  final index = shown.indexWhere((o) => o.id == object.id);
  return ObjectRouteArgs(
    seed: ObjectView(
      id: object.id,
      name: object.name,
      zone: object.zone,
      spec: object.spec,
      mainPhoto: object.photo,
    ),
    sourceSpecStyle: object.isSpecTall
        ? HomeText.cardSpecTall
        : HomeText.cardSpec,
    sourcePhotoRadius: kCardRadii[index.clamp(0, kCardRadii.length - 1)],
  );
}

/// A [Page] that opens with [ObjectPageRoute], so go_router gets the
/// shared-element push and the interactive back swipe.
class ObjectPage<T> extends Page<T> {
  const ObjectPage({required this.child, super.key, super.name});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    late final ObjectPageRoute<T> route;
    route = ObjectPageRoute<T>(
      settings: this,
      isMotionReduced: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
      // Reads the page the route currently holds, so an updated page is not
      // answered with the child it was first built with.
      builder: (_) => (route.settings as ObjectPage<T>).child,
    );
    return route;
  }
}

/// Route-level wiring for screen 03.
///
/// The screen stays pure presentation driven by callbacks, so its tests build
/// it directly with no ProviderScope. This wrapper adds no render object.
class ObjectRoute extends ConsumerWidget {
  const ObjectRoute({super.key, required this.id, this.args});

  final int id;

  /// Null when the route was reached without a card to fly from — a deep
  /// link, or a restored stack.
  final ObjectRouteArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = this.args;
    final view =
        ref.watch(objectViewProvider(id)).value ??
        args?.seed ??
        ObjectView(id: id, zone: '', spec: '');
    final repository = ref.read(objectRepositoryProvider);

    return ObjectScreen(
      object: view,
      source: args?.source ?? ObjectSource.homeTile,
      sourceSpecStyle: args?.sourceSpecStyle ?? ObjectText.spec,
      sourcePhotoRadius:
          args?.sourcePhotoRadius ?? ObjectMetrics.mainPhotoRadius,
      onBack: () => context.pop(),
      onShare: () => reportObjectWrite(
        id,
        shareObject(
          repository,
          ref.read(photoStoreProvider.future),
          id,
          origin: _originOf(context),
        ),
      ),
      onReplaced: (day) =>
          reportObjectWrite(id, repository.markReplaced(id, on: day)),
      onSave: (edits) => reportObjectWrite(
        id,
        repository.updateDetail(
          id,
          specValue: edits.spec,
          attributes: edits.fields,
          purchasedFrom: edits.purchasedFrom,
          replacedOn: edits.lastReplaced,
          notes: edits.notes,
        ),
      ),
      onMenu: () => unawaited(
        showObjectActions(
          context,
          ref,
          id,
          // Leave first, so the page departs the way it arrived; the row goes
          // once nothing is drawing it.
          onDeleting: () => context.pop(),
          onDuplicated: (copy) {
            if (!context.mounted) return;
            // Replaces this page, so back returns where the original was
            // opened from rather than to the original.
            context.pushReplacementNamed(
              RouteNames.object,
              pathParameters: {'id': '$copy'},
              extra: ObjectRouteArgs(
                seed: ObjectView(
                  id: copy,
                  name: view.name,
                  zone: view.zone,
                  subZone: view.subZone,
                  spec: view.spec,
                ),
                sourceSpecStyle: ObjectText.spec,
                sourcePhotoRadius: ObjectMetrics.mainPhotoRadius,
              ),
            );
          },
        ),
      ),
      onReplacePhoto: (slot) {
        // Read before the camera opens: the page can be gone when it closes.
        final capture = ref.read(photoCaptureProvider);
        final photos = ref.read(photoStoreProvider.future);
        reportObjectWrite(id, () async {
          final file = await capture.takePhoto();
          if (file == null) return;
          final store = await photos;
          final fileName = await store.add(file);
          final String old;
          try {
            old = await repository.replacePhoto(id, slot, fileName);
          } on Object {
            await store.remove([fileName]);
            rethrow;
          }
          // After the commit, so a failed swap never costs the old photo.
          await store.remove([old]);
        }());
      },
      onRemovePhoto: (slot) {
        final photos = ref.read(photoStoreProvider.future);
        reportObjectWrite(id, () async {
          final old = await repository.removePhoto(id, slot);
          await (await photos).remove([old]);
        }());
      },
    );
  }

  /// iPad anchors the share sheet here; iPhone ignores it.
  Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
