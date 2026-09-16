import 'dart:io';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:spec/data/backup_service.dart';
import 'package:spec/providers/collections.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/onboarding.dart';
import 'package:spec/providers/photos.dart';
import 'package:spec/providers/search.dart';

part 'backup.g.dart';

/// Zip only. iOS's document picker throws without a uniform type identifier,
/// so the UTI is not optional there.
const _backupTypes = XTypeGroup(
  label: 'SPEC backup',
  extensions: ['zip'],
  uniformTypeIdentifiers: ['public.zip-archive'],
);

@Riverpod(keepAlive: true)
Future<BackupService> backupService(Ref ref) async => BackupService(
  await ref.watch(specDatabaseProvider.future),
  await ref.watch(photoStoreProvider.future),
);

/// The data-control actions a screen can trigger: export, restore, wipe.
///
/// A notifier rather than bare functions so each action can also reset the
/// app state that depends on the data — recent searches, the zone list, the
/// onboarding flag — in the right order.
@Riverpod(keepAlive: true)
class BackupActions extends _$BackupActions {
  @override
  void build() {}

  /// Writes a backup zip and opens the share sheet on it. [origin] anchors
  /// the sheet on iPad. Throws; the caller reports.
  ///
  /// False only when the sheet was dismissed without sharing. A platform
  /// that cannot say what happened reports `unavailable`, which counts as
  /// shared: the zip was written and the sheet was shown.
  Future<bool> exportAndShare({Rect? origin}) async {
    final service = await ref.read(backupServiceProvider.future);
    final temp = await getTemporaryDirectory();
    final folder = Directory(p.join(temp.path, 'spec-backup'));
    // A previous backup must not be the file that gets shared.
    if (folder.existsSync()) await folder.delete(recursive: true);
    await folder.create(recursive: true);

    final zip = await service.writeZip(into: folder);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zip.path)],
        subject: 'SPEC backup',
        sharePositionOrigin: origin,
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }

  /// Lets the user pick a backup file. Null means they cancelled.
  Future<File?> pickBackup() async {
    final picked = await openFile(acceptedTypeGroups: const [_backupTypes]);
    return picked == null ? null : File(picked.path);
  }

  /// Validates [zip] without touching data. See [BackupService.inspect].
  Future<BackupSummary> inspect(File zip) async =>
      (await ref.read(backupServiceProvider.future)).inspect(zip);

  /// Replaces all data with [zip]. See [BackupService.restore].
  Future<BackupSummary> restore(File zip) async {
    final service = await ref.read(backupServiceProvider.future);
    final summary = await service.restore(zip);
    // The zone stream seeds defaults once on build; rebuild it so it runs
    // against the restored rows.
    ref.invalidate(collectionZonesProvider);
    return summary;
  }

  /// Deletes all data and photo files, clears recent searches, and resets
  /// onboarding last so the welcome screens show again.
  Future<void> deleteEverything() async {
    final service = await ref.read(backupServiceProvider.future);
    await service.deleteEverything();
    ref.invalidate(recentQueriesProvider);
    // Last: flipping the flag navigates away from whoever called this.
    await ref.read(onboardingCompletedProvider.notifier).reset();
  }
}
