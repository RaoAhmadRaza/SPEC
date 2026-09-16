import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spec/data/backup_service.dart';
import 'package:spec/providers/app_info.dart';
import 'package:spec/providers/backup.dart';
import 'package:spec/providers/search.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/settings/settings_route.dart';

import '../support/fonts.dart';

const _canvas = Size(402, 874);

/// Records every call in order, and answers from what a test configured.
class FakeBackupActions extends BackupActions {
  FakeBackupActions({
    this.picked,
    this.summary = const BackupSummary(zones: 5, objects: 41, photos: 96),
    this.inspectError,
    this.exportError,
    this.isShared = true,
  });

  final File? picked;
  final BackupSummary summary;
  final Exception? inspectError;
  final Exception? exportError;
  final bool isShared;

  final calls = <String>[];

  @override
  Future<bool> exportAndShare({Rect? origin}) async {
    calls.add('export');
    if (exportError case final error?) throw error;
    return isShared;
  }

  @override
  Future<File?> pickBackup() async {
    calls.add('pick');
    return picked;
  }

  @override
  Future<BackupSummary> inspect(File zip) async {
    calls.add('inspect');
    if (inspectError case final error?) throw error;
    return summary;
  }

  @override
  Future<BackupSummary> restore(File zip) async {
    calls.add('restore');
    return summary;
  }

  @override
  Future<void> deleteEverything() async => calls.add('delete');
}

Future<void> _pump(WidgetTester tester, FakeBackupActions fake) async {
  tester.view
    ..physicalSize = _canvas * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backupActionsProvider.overrideWith(() => fake),
        appVersionProvider.overrideWith((ref) async => 'SPEC 1.0.0 (1)'),
        archiveCountsProvider.overrideWith(
          (ref) => Stream.value(const ArchiveCounts(objects: 41, photos: 96)),
        ),
      ],
      child: const MaterialApp(home: SettingsRoute()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSpecFonts);

  testWidgets('shows the archive counts and version from providers', (
    tester,
  ) async {
    // Arrange / Act
    await _pump(tester, FakeBackupActions());

    // Assert
    expect(find.text('41 OBJECTS · 96 PHOTOS'), findsOneWidget);
    expect(find.text('SPEC 1.0.0 (1)'), findsOneWidget);
  });

  testWidgets('restore picks, inspects, asks twice, then restores', (
    tester,
  ) async {
    // Arrange
    final fake = FakeBackupActions(picked: File('spec-backup.zip'));
    await _pump(tester, fake);

    // Act
    await tester.tap(find.text('RESTORE FROM BACKUP'));
    await tester.pumpAndSettle();
    expect(fake.calls, ['pick', 'inspect']);

    await tester.tap(find.text('Replace with 41 objects'));
    await tester.pumpAndSettle();
    expect(fake.calls, ['pick', 'inspect']);

    await tester.tap(find.text('Yes, replace with 41 objects'));
    await tester.pumpAndSettle();

    // Assert
    expect(fake.calls, ['pick', 'inspect', 'restore']);
    expect(find.text('RESTORED 41 OBJECTS'), findsOneWidget);
  });

  testWidgets('delete runs only on the confirmed tap, exactly once', (
    tester,
  ) async {
    // Arrange
    final fake = FakeBackupActions();
    await _pump(tester, fake);
    await tester.tap(find.text('DELETE EVERYTHING'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('Delete everything'));
    await tester.pumpAndSettle();
    final callsAfterFirstTap = [...fake.calls];
    await tester.tap(find.text('Yes, delete everything'));
    await tester.pumpAndSettle();

    // Assert
    expect(callsAfterFirstTap, isEmpty);
    expect(fake.calls, ['delete']);
  });

  testWidgets('a backup SPEC cannot read shows its reason', (tester) async {
    // Arrange
    const reason = 'This backup is from a newer version of SPEC.';
    final fake = FakeBackupActions(
      picked: File('spec-backup.zip'),
      inspectError: const BackupFormatException(reason),
    );
    await _pump(tester, fake);

    // Act
    await tester.tap(find.text('RESTORE FROM BACKUP'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text(reason), findsOneWidget);
    expect(fake.calls, ['pick', 'inspect']);
  });

  testWidgets('a cancelled pick calls nothing else', (tester) async {
    // Arrange
    final fake = FakeBackupActions();
    await _pump(tester, fake);

    // Act
    await tester.tap(find.text('RESTORE FROM BACKUP'));
    await tester.pumpAndSettle();

    // Assert
    expect(fake.calls, ['pick']);
    expect(find.text('Replace with 41 objects'), findsNothing);
  });

  testWidgets('export shows BACKUP READY', (tester) async {
    // Arrange
    final fake = FakeBackupActions();
    await _pump(tester, fake);

    // Act
    await tester.tap(find.text('EXPORT BACKUP'));
    await tester.pumpAndSettle();

    // Assert
    expect(fake.calls, ['export']);
    expect(find.text('BACKUP READY'), findsOneWidget);
  });

  testWidgets('a dismissed share sheet leaves the status blank', (
    tester,
  ) async {
    // Arrange
    final fake = FakeBackupActions(isShared: false);
    await _pump(tester, fake);

    // Act
    await tester.tap(find.text('EXPORT BACKUP'));
    await tester.pumpAndSettle();

    // Assert
    expect(fake.calls, ['export']);
    expect(find.text('BACKUP READY'), findsNothing);
  });

  testWidgets('a failed export shows a friendly line and reports the cause', (
    tester,
  ) async {
    // Arrange
    final fake = FakeBackupActions(exportError: Exception('disk full'));
    await _pump(tester, fake);

    // Act
    await tester.tap(find.text('EXPORT BACKUP'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('COULD NOT MAKE A BACKUP. TRY AGAIN.'), findsOneWidget);
    expect(tester.takeException(), isException);
  });
}
