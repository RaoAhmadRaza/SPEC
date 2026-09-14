import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spec/data/photo_store.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/services/photo_capture.dart';

part 'photos.g.dart';

/// Opens the store and deletes files no row refers to — the orphans a crash
/// between writing a photo and inserting its row, or a restore, leaves behind.
///
/// A failed sweep costs disk space, not photos, so it is reported and the
/// store is still returned: every photo writer awaits this provider first.
@Riverpod(keepAlive: true)
Future<PhotoStore> photoStore(Ref ref) async {
  final store = await PhotoStore.open();
  try {
    await ref.read(specDatabaseProvider.future);
    await store.sweep(
      await ref.read(objectRepositoryProvider).photoFileNames(),
    );
  } on Object catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'photos',
        context: ErrorDescription('while sweeping orphan photo files'),
      ),
    );
  }
  return store;
}

@Riverpod(keepAlive: true)
PhotoCapture photoCapture(Ref ref) => PhotoCapture();
