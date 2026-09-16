import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:spec/add/add_kinds.dart';
import 'package:spec/data/models/spec_models.dart';
import 'package:spec/data/object_repository.dart';
import 'package:spec/data/photo_store.dart';
import 'package:spec/object/object_sheet.dart';
import 'package:spec/providers/collections.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/photos.dart';

/// The ••• sheet for one object: Move to zone, Duplicate, Set reminder and a
/// two-tap Delete. Screen 03 and Home's card ••• open the same one.
///
/// [onDeleting] runs before the row goes, so screen 03 can leave first and
/// depart the way it arrived. [onDuplicated] gets the copy's id.
Future<void> showObjectActions(
  BuildContext context,
  WidgetRef ref,
  int id, {
  VoidCallback? onDeleting,
  ValueChanged<int>? onDuplicated,
}) {
  // Read up front: by the time a choice is made, the page that owns this ref
  // may be gone.
  final repository = ref.read(objectRepositoryProvider);
  final zones = ref.read(zoneRepositoryProvider);
  final photos = ref.read(photoStoreProvider.future);

  return showObjectSheet(
    context,
    items: [
      SheetItem(
        label: 'Move to zone',
        onTap: () => reportObjectWrite(id, () async {
          // Zones are seeded the first time Collections opens; a user who
          // has not been there yet still gets a list to pick from.
          await zones.ensureDefaults();
          final names = await repository.zoneNames();
          final current = (await repository.detail(id))?.summary.zoneName;
          if (!context.mounted) return;
          await showObjectSheet(
            context,
            items: [
              for (final name in names)
                SheetItem(
                  label: name,
                  isSelected: name.toLowerCase() == current?.toLowerCase(),
                  onTap: () =>
                      reportObjectWrite(id, repository.moveToZone(id, name)),
                ),
            ],
          );
        }()),
      ),
      SheetItem(
        label: 'Duplicate',
        onTap: () => reportObjectWrite(id, () async {
          final copy = await repository.duplicate(id, await photos);
          onDuplicated?.call(copy);
        }()),
      ),
      SheetItem(
        label: 'Set reminder',
        onTap: () => reportObjectWrite(id, () async {
          final current = (await repository.detail(id))?.remindEveryMonths;
          if (!context.mounted) return;
          await showObjectSheet(
            context,
            items: [
              for (final months in reminderCycle)
                SheetItem(
                  label: reminderLabel(months),
                  isSelected: months == current,
                  onTap: () =>
                      reportObjectWrite(id, repository.setReminder(id, months)),
                ),
            ],
          );
        }()),
      ),
      SheetItem(
        label: 'Delete',
        isDestructive: true,
        needsConfirmation: true,
        onTap: () {
          onDeleting?.call();
          // Files go after the row, so a failure between the two leaves an
          // orphan for the startup sweep rather than a row pointing at
          // nothing.
          reportObjectWrite(id, () async {
            final names = await repository.delete(id);
            await (await photos).remove(names);
          }());
        },
      ),
    ],
  );
}

/// Share on screen 03: the system sheet with a plain-text summary and the
/// object's photo files. Nothing leaves the device unless the user sends it.
Future<void> shareObject(
  ObjectRepository repository,
  Future<PhotoStore> photos,
  int id, {
  Rect? origin,
}) async {
  final detail = await repository.detail(id);
  if (detail == null) return;
  await SharePlus.instance.share(
    objectShareParams(detail, await photos, origin: origin),
  );
}

/// What Share hands the system sheet. [origin] anchors it on iPad.
ShareParams objectShareParams(
  ObjectDetail detail,
  PhotoStore photos, {
  Rect? origin,
}) {
  final summary = detail.summary;
  final files = [
    for (final name in detail.photoFileNames) XFile(photos.resolve(name).path),
  ];
  return ShareParams(
    subject: summary.name,
    text: [
      summary.name,
      '${kindLabel(summary.specKind)}: ${summary.specValue}',
      if (summary.zoneName case final String zone) 'Zone: $zone',
      if (detail.notes case final String notes) 'Notes: $notes',
    ].join('\n'),
    files: files.isEmpty ? null : files,
    sharePositionOrigin: origin,
  );
}

/// The screen has already shown the change, so a failed write is reported
/// rather than awaited — never dropped.
void reportObjectWrite(int id, Future<void> write) {
  unawaited(
    write.catchError((Object error, StackTrace stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'object',
          context: ErrorDescription('while saving object $id'),
        ),
      );
    }),
  );
}
