import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spec/data/db/spec_database.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/providers/search.dart';
import 'package:spec/settings/storage_size.dart';

part 'storage.g.dart';

/// Bytes SPEC keeps on this device: the database file and every photo.
///
/// Watches the archive counts so it weighs again whenever an object or a
/// photo comes or goes, instead of showing the size the page opened with.
@riverpod
Future<int> storageBytes(Ref ref) async {
  ref.watch(archiveCountsProvider);
  final store = await ref.watch(photoStoreProvider.future);
  final sizes = await Future.wait([
    bytesOf(await specDatabaseFile()),
    bytesOf(store.directory),
  ]);
  return sizes[0] + sizes[1];
}
