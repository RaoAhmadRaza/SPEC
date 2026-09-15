import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spec/data/photo_thumbnail.dart';
import 'package:spec/home/home_models.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/providers/reminders.dart';
import 'package:spec/providers/search.dart';
import 'package:spec/search/search_models.dart';

part 'home.g.dart';

/// Zone names the design gives an icon to. Anything else gets the neutral one.
const _zoneIcons = <String, HomeCategoryIcon>{
  'home': HomeCategoryIcon.house,
  'car': HomeCategoryIcon.car,
  'devices': HomeCategoryIcon.monitor,
  'device': HomeCategoryIcon.monitor,
};

/// Everything Home renders, newest first, with photo file names already
/// resolved into image providers.
@riverpod
Stream<List<HomeObject>> homeObjects(Ref ref) async* {
  final store = await ref.watch(photoStoreProvider.future);
  final repository = ref.watch(objectRepositoryProvider);
  final database = ref.watch(specDatabaseProvider).requireValue;

  yield* repository.watchAll().asyncMap((rows) async {
    // Read alongside, since summaries do not carry the reminder columns.
    // ponytail: "due" is judged at emission, so a card turns DUE at midnight
    // only on the next change or launch.
    final dueIds = await dueObjectIds(database, DateTime.now());
    return [
      for (final row in rows)
        HomeObject(
          id: row.id,
          zone: (row.zoneName ?? row.type.name).toUpperCase(),
          spec: row.specValue,
          name: row.name,
          // The design shows the attribute values, not their labels, and
          // never more than two lines.
          subLines: [
            for (final attribute in row.attributes.take(2))
              attribute.value.toUpperCase(),
          ],
          photo: switch (row.photoFileName) {
            final String fileName => photoThumbnail(
              store.resolve(fileName),
              edge: kPhotoEdgeLarge,
            ),
            null => null,
          },
          isDue: dueIds.contains(row.id),
        ),
    ];
  });
}

/// The zone rail: the same zones, counts and names as Search's
/// `BROWSE BY ZONE`, so the two can never disagree.
@riverpod
List<HomeCategory> homeCategories(Ref ref) => [
  for (final zone
      in ref.watch(searchZonesProvider).value ?? const <SearchZone>[])
    HomeCategory(
      label: zone.name,
      count: zone.count,
      icon: _zoneIcons[zone.name.toLowerCase()] ?? HomeCategoryIcon.monitor,
    ),
];
