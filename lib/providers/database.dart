import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spec/data/db/spec_database.dart';
import 'package:spec/data/object_repository.dart';
import 'package:spec/data/search_service.dart';

part 'database.g.dart';

/// The open database. Awaited by `appStartup`, so it is resolved before any
/// screen builds — which is what lets the repositories below read it
/// synchronously.
@Riverpod(keepAlive: true)
Future<SpecDatabase> specDatabase(Ref ref) async {
  final database = await openSpecDatabase();
  ref.onDispose(database.close);
  // drift connects lazily, so without a first statement the migration and the
  // foreign-key pragma would run under whichever screen reads first rather
  // than under the splash that exists to wait for them.
  await database.customSelect('SELECT 1').getSingle();
  return database;
}

@Riverpod(keepAlive: true)
ObjectRepository objectRepository(Ref ref) =>
    ObjectRepository(ref.watch(specDatabaseProvider).requireValue);

@Riverpod(keepAlive: true)
SearchService searchService(Ref ref) =>
    SearchService(ref.watch(objectRepositoryProvider));
