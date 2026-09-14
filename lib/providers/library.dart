import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spec/library/library_models.dart';

part 'library.g.dart';

const _libraryAsset = 'assets/library.json';

/// The bundled library, read once and held for the life of the app.
///
/// It ships inside the binary, which is what makes screen 07 work in
/// airplane mode and what `OFFLINE` on that screen is a statement of.
@Riverpod(keepAlive: true)
Future<List<LibraryItem>> libraryItems(Ref ref) async =>
    parseLibrary(await rootBundle.loadString(_libraryAsset));
