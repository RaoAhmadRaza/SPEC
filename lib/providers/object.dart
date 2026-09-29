import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/data/photo_thumbnail.dart';
import 'package:spec/library/library_models.dart';
import 'package:spec/object/object_models.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/library.dart';
import 'package:spec/providers/photos.dart';

part 'object.g.dart';

/// Everything screen 03 renders for one object, live: stamping REPLACED or
/// saving an edit rewrites the row, and the screen follows it with no manual
/// invalidation. Null once the object has been deleted.
@riverpod
Stream<ObjectView?> objectView(Ref ref, int id) async* {
  final store = await ref.watch(photoStoreProvider.future);
  // Not awaited: the bundled pictures are decoration, so nothing waits on
  // the library. This rebuilds with them once it has loaded.
  final library =
      ref.watch(libraryItemsProvider).value ?? const <LibraryItem>[];
  final repository = ref.watch(objectRepositoryProvider);

  yield* repository
      .watchDetail(id)
      .map(
        (detail) => detail == null
            ? null
            : toObjectView(detail, store, library: library),
      );
}

/// The database row as the screen draws it.
///
/// An object picked from the library with no photo of its own shows the
/// library's bundled picture in the main slot.
ObjectView toObjectView(
  ObjectDetail detail,
  PhotoStore store, {
  List<LibraryItem> library = const [],
}) {
  final summary = detail.summary;
  final photos = detail.photoFileNames;
  ImageProvider? photoAt(int index) => index < photos.length
      ? photoThumbnail(store.resolve(photos[index]), edge: kPhotoEdgeLarge)
      : null;
  final bundled = photos.isEmpty
      ? libraryAssetFor(summary.name, library)
      : null;

  return ObjectView(
    id: summary.id,
    // The same fallback Home uses, so the chip reads the same on both ends of
    // the flight.
    zone: (summary.zoneName ?? summary.type.name).toUpperCase(),
    subZone: summary.subLocation?.toUpperCase(),
    spec: summary.specValue,
    name: summary.name,
    subtitle: detail.subtitle,
    fields: summary.attributes,
    mainPhoto: switch (bundled) {
      final String asset => assetThumbnail(asset, edge: kPhotoEdgeLarge),
      null => photoAt(0),
    },
    isMainPhotoBundled: bundled != null,
    detailPhoto: photoAt(1),
    lastReplaced: detail.replacedOn,
    purchasedFrom: detail.purchasedFrom,
    notes: detail.notes,
    remindEveryMonths: detail.remindEveryMonths,
    createdAt: detail.createdAt,
  );
}
