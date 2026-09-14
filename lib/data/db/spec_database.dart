import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'spec_database.g.dart';

/// SPEC's local store. There is no server, so this is the whole backend.
@DriftDatabase(include: {'tables.drift', 'queries.drift'})
class SpecDatabase extends _$SpecDatabase {
  SpecDatabase(super.e);

  /// For tests. A real connection to a real sqlite, held in memory.
  SpecDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2: objects gain an optional notes line.
      if (from < 2) await m.addColumn(objects, objects.notes);
    },
    beforeOpen: (details) async {
      // Foreign key enforcement is per-connection and off by default, so
      // without this every cascade in tables.drift is decoration.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Opens the on-disk database in the documents directory.
///
/// Documents, not cache: iOS purges cache under storage pressure and this is
/// not a cache. Deliberately not `drift_flutter`, which still depends on two
/// packages whose own descriptions say they are no longer used.
Future<SpecDatabase> openSpecDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(p.join(directory.path, 'spec.sqlite'));
  return SpecDatabase(NativeDatabase.createInBackground(file));
}
