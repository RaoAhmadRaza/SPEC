import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spec/collections/collections_models.dart';
import 'package:spec/data/photo_thumbnail.dart';
import 'package:spec/data/zone_repository.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/photos.dart';

part 'collections.g.dart';

@Riverpod(keepAlive: true)
ZoneRepository zoneRepository(Ref ref) =>
    ZoneRepository(ref.watch(specDatabaseProvider).requireValue);

/// Counts requests to start a new zone from outside screen 06 — Home's rail
/// `+`. A count rather than a flag, so every tap is a change to hear.
@Riverpod(keepAlive: true)
class NewZoneRequests extends _$NewZoneRequests {
  @override
  int build() => 0;

  void request() => state++;
}

/// Screen 06's rows in list order, with thumbs resolved into image
/// providers. Seeds the default zones and files unfiled objects first.
@riverpod
Stream<List<CollectionZone>> collectionZones(Ref ref) async* {
  final store = await ref.watch(photoStoreProvider.future);
  final zones = ref.watch(zoneRepositoryProvider);
  await zones.ensureDefaults();

  yield* zones.watchAll().map(
    (rows) => [
      for (final row in rows)
        CollectionZone(
          id: row.id,
          name: row.name,
          count: row.count,
          specs: row.specValues,
          photo: switch (row.photoFileName) {
            final String fileName => photoThumbnail(
              store.resolve(fileName),
              edge: kPhotoEdgeSmall,
            ),
            null => null,
          },
        ),
    ],
  );
}
