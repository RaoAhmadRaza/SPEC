import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/zone_naming.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/search/search_query.dart';

part 'search.g.dart';

/// The design shows three; six is where the wrap stops being scannable.
const _recentLimit = 6;

/// The queries the user ran, newest first.
///
/// Deliberately not persisted: a search history that outlives the session is
/// a record of what someone was looking for, and SPEC keeps none.
@Riverpod(keepAlive: true)
class RecentQueries extends _$RecentQueries {
  @override
  List<String> build() => const [];

  void remember(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final lower = trimmed.toLowerCase();
    state = [
      trimmed,
      for (final existing in state)
        if (existing.toLowerCase() != lower) existing,
    ].take(_recentLimit).toList();
  }
}

/// `41 OBJECTS · 96 PHOTOS`.
@riverpod
Stream<ArchiveCounts> archiveCounts(Ref ref) async* {
  final database = await ref.watch(specDatabaseProvider.future);
  yield* database.archiveCounts().watchSingle().map(
    (row) => ArchiveCounts(objects: row.objectCount, photos: row.photoCount),
  );
}

/// `BROWSE BY ZONE`. Derived from the objects themselves rather than from the
/// zones table, because nothing creates zones yet.
@riverpod
Stream<List<SearchZone>> searchZones(Ref ref) async* {
  // The repository needs an open database; waiting here means a watcher that
  // builds early gets a loading state rather than a thrown `requireValue`.
  await ref.watch(specDatabaseProvider.future);
  yield* ref.watch(objectRepositoryProvider).watchAll().map((rows) {
    // Grouped by the uppercased key, so `Home` and `HOME` stay one zone, but
    // named the way it was stored.
    final zones = <String, SearchZone>{};
    for (final row in rows) {
      zones.update(
        zoneOf(row),
        (zone) => SearchZone(name: zone.name, count: zone.count + 1),
        ifAbsent: () => SearchZone(name: zoneNameOf(row), count: 1),
      );
    }
    return zones.values.toList();
  });
}

/// Fires whenever an object is added, edited or deleted.
///
/// The runner rebuilds on it, and screen 02 re-runs its query when the runner
/// changes, so results never outlive the rows they were read from.
@riverpod
Stream<List<ObjectSummary>> searchArchive(Ref ref) async* {
  await ref.watch(specDatabaseProvider.future);
  yield* ref.watch(objectRepositoryProvider).watchAll();
}

/// The runner screen 02 hands each keystroke to.
///
/// [isListingAll] is SEE ALL on Home: a blank query lists the whole archive.
@riverpod
Future<SearchQueryRunner> searchQueryRunner(
  Ref ref, {
  String? scope,
  bool isListingAll = false,
}) async {
  ref.watch(searchArchiveProvider);
  final photos = await ref.watch(photoStoreProvider.future);
  return SearchQueryRunner(
    ref.watch(searchServiceProvider),
    ref.watch(objectRepositoryProvider),
    photos,
    scope: scope,
    isListingAll: isListingAll,
  );
}
