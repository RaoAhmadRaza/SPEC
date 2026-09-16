import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spec/app/router.dart';
import 'package:spec/collections/collections_models.dart';
import 'package:spec/collections/collections_screen.dart';
import 'package:spec/data/zone_repository.dart';
import 'package:spec/home/home_tab_bar.dart';
import 'package:spec/providers/backup.dart';
import 'package:spec/providers/collections.dart';
import 'package:spec/providers/search.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/shell/tab_shell.dart';

/// Route-level wiring for screen 06.
///
/// The screen stays pure presentation driven by callbacks, so its tests build
/// it directly with no ProviderScope.
class CollectionsRoute extends ConsumerWidget {
  const CollectionsRoute({super.key, this.isActive = true});

  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No spinner: a local stream resolves within a frame. An unresolved read
    // renders the empty state, the same as Home.
    final zones =
        ref.watch(collectionZonesProvider).value ?? const <CollectionZone>[];
    final counts =
        ref.watch(archiveCountsProvider).value ?? ArchiveCounts.empty;
    // Read when a callback runs, never while building. The tab shell builds
    // this screen at launch, underneath the splash, before the database has
    // opened — and the repository needs an open database.
    ZoneRepository repository() => ref.read(zoneRepositoryProvider);
    // A new zone asked for elsewhere, Home's rail `+`, brings this tab forward
    // and opens the name field.
    ref.listen(
      newZoneRequestsProvider,
      (_, _) => SpecTabShell.select(context, SpecTab.collections),
    );

    return CollectionsScreen(
      zones: zones,
      objects: counts.objects,
      photos: counts.photos,
      isActive: isActive,
      onOpenZone: (zone) => context.pushNamed(
        RouteNames.search,
        queryParameters: {'scope': zone.name},
      ),
      onCreateZone: (name) async => await repository().create(name) != null,
      onRenameZone: (id, name) => repository().rename(id, name),
      onReorderZones: (ids) => unawaited(repository().reorder(ids)),
      onDeleteZone: (id) => unawaited(repository().delete(id)),
      onExport: () => _export(context, ref),
      newZoneRequest: ref.watch(newZoneRequestsProvider),
    );
  }

  /// Writes a backup zip and hands it to the system share sheet. False when
  /// the sheet was dismissed or the export failed.
  Future<bool> _export(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      return await ref
          .read(backupActionsProvider.notifier)
          .exportAndShare(
            // iPad anchors the sheet here; iPhone ignores it.
            origin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          );
    } on Exception catch (error, stack) {
      // Disk, database or platform channel. No error surface exists in the
      // design; the share sheet simply does not appear, and the cause is
      // reported rather than swallowed.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'collections',
          context: ErrorDescription('while writing the export archive'),
        ),
      );
      return false;
    }
  }
}
