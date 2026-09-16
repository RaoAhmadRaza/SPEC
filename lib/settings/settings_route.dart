import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spec/collections/collections_models.dart';
import 'package:spec/data/backup_service.dart';
import 'package:spec/object/object_sheet.dart';
import 'package:spec/providers/app_info.dart';
import 'package:spec/providers/backup.dart';
import 'package:spec/providers/search.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/settings/settings_screen.dart';

const _exportFailed = 'COULD NOT MAKE A BACKUP. TRY AGAIN.';
const _restoreFailed = 'COULD NOT RESTORE THAT BACKUP. NOTHING CHANGED.';
const _deleteFailed = 'COULD NOT DELETE EVERYTHING. TRY AGAIN.';

/// Route-level wiring for the Settings screen: privacy, backup, restore,
/// Delete Everything, app info.
///
/// Stateful because every action is a chain of awaits whose result lands in a
/// status line, and Delete Everything ends with the router taking this page
/// away mid-chain — so every await is followed by a `mounted` check.
class SettingsRoute extends ConsumerStatefulWidget {
  const SettingsRoute({super.key});

  @override
  ConsumerState<SettingsRoute> createState() => _SettingsRouteState();
}

class _SettingsRouteState extends ConsumerState<SettingsRoute> {
  String? _status;
  bool _isBusy = false;

  BackupActions get _actions => ref.read(backupActionsProvider.notifier);

  @override
  Widget build(BuildContext context) {
    // No spinner: both resolve within a frame, and a blank line is honest
    // for the instant before they do.
    final version = ref.watch(appVersionProvider).value ?? '';
    final counts =
        ref.watch(archiveCountsProvider).value ?? ArchiveCounts.empty;

    return SettingsScreen(
      version: version,
      counts: counts.label,
      status: _status,
      isBusy: _isBusy,
      onBack: () => unawaited(Navigator.of(context).maybePop()),
      onExport: () => unawaited(_run(_export, failure: _exportFailed)),
      onRestore: () => unawaited(_run(_restore, failure: _restoreFailed)),
      onDeleteEverything: () =>
          unawaited(_run(_deleteEverything, failure: _deleteFailed)),
    );
  }

  /// Runs one action with the others locked out, then shows what it
  /// returned. A null result leaves the status line empty.
  ///
  /// A [BackupFormatException] is the user's to read, so its reason is shown
  /// as written. Anything else gets [failure] on screen and the real cause
  /// reported, never swallowed.
  Future<void> _run(
    Future<String?> Function() action, {
    required String failure,
  }) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _status = null;
    });

    String? status;
    try {
      status = await action();
    } on BackupFormatException catch (error) {
      status = error.reason;
    } on Exception catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'settings',
          context: ErrorDescription('while running a backup action'),
        ),
      );
      status = failure;
    } finally {
      // Delete Everything's redirect disposes this page before it returns.
      if (mounted) {
        setState(() {
          _isBusy = false;
          _status = status;
        });
      }
    }
  }

  Future<String?> _export() async {
    // iPad anchors the share sheet here; iPhone ignores it.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final isShared = await _actions.exportAndShare(origin: origin);
    return isShared ? kBackupReady : null;
  }

  /// Pick, count, ask, replace — in that order, so nothing is replaced until
  /// the user has seen how much the backup holds and said yes twice.
  Future<String?> _restore() async {
    final actions = _actions;
    final file = await actions.pickBackup();
    if (file == null || !mounted) return null;

    final summary = await actions.inspect(file);
    if (!mounted) return null;

    final isConfirmed = await _confirm(
      'Replace with ${countLabel(summary.objects, 'OBJECT').toLowerCase()}',
    );
    if (!isConfirmed || !mounted) return null;

    final restored = await actions.restore(file);
    return 'RESTORED ${countLabel(restored.objects, 'OBJECT')}';
  }

  Future<String?> _deleteEverything() async {
    final isConfirmed = await _confirm('Delete everything');
    if (!isConfirmed || !mounted) return null;
    await _actions.deleteEverything();
    // Normally unseen: the router has already left for the welcome screen.
    return 'EVERYTHING DELETED';
  }

  /// Asks inside the object sheet: the first tap relabels the row to
  /// `Yes, …`, the second confirms. Dismissing the sheet answers no.
  Future<bool> _confirm(String label) async {
    var isConfirmed = false;
    await showObjectSheet(
      context,
      items: [
        SheetItem(
          label: label,
          onTap: () => isConfirmed = true,
          isDestructive: true,
          needsConfirmation: true,
        ),
      ],
    );
    return isConfirmed;
  }
}
