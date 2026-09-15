import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spec/add/add_draft.dart';
import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_kinds.dart';
import 'package:spec/add/add_sheet_route.dart';
import 'package:spec/add/not_in_library_route.dart';
import 'package:spec/add/not_in_library_screen.dart';
import 'package:spec/library/library_models.dart';
import 'package:spec/library/library_pick_route.dart';
import 'package:spec/providers/database.dart';
import 'package:spec/providers/library.dart';
import 'package:spec/providers/photos.dart';

/// The one way into adding an object, from anywhere: the orb, Home's empty
/// state and add card, and Search's `ADD IT INSTEAD`.
///
/// Opens screen 07. A library pick goes straight to step 05 with its shape
/// chosen; `ADD YOUR OWN` or a miss goes through screen 08 first. SAVE writes
/// the object and closes every step at once, back to where the user started.
///
/// [query] is what the user already typed, carried into the library search.
/// [zone] is the zone the caller was scoped to, pre-selected on the last step.
///
/// [context] must sit inside a page route on the root navigator: the flow
/// returns to that route when it finishes. Providers are read from the
/// enclosing [ProviderScope], so no `WidgetRef` is needed and any widget can
/// call this.
Future<void> openAddEntry(
  BuildContext context, {
  String query = '',
  String? zone,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final origin = ModalRoute.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  // A local read that resolves within a frame, so 07 never waits on it
  // visibly.
  final stored = await container.read(objectRepositoryProvider).zoneNames();
  if (!context.mounted) return;
  final zones = zoneChoices(stored);
  final takePhoto = container.read(photoCaptureProvider).takePhoto;

  // Stops at the first route too, so a lost origin can never empty the stack.
  void returnToOrigin() =>
      navigator.popUntil((route) => route == origin || route.isFirst);

  void save(SpecDraft draft) {
    unawaited(saveDraft(container, draft));
    returnToOrigin();
  }

  // The steps after 07 open from the navigator's own context: the caller's
  // widget may be gone by then, the navigator never is.
  await showLibraryPick(
    context,
    initialQuery: query,
    onPick: (item) {
      final type = addTypeForCategory(item.category);
      unawaited(
        showAddFields(
          navigator.context,
          type: type,
          initialKind: kindForLibraryItem(item, type),
          name: item.name,
          zone: defaultZoneFor(
            scope: zone,
            category: item.category,
            stored: stored,
          ),
          zones: zones,
          pickPhoto: takePhoto,
          onSave: save,
        ),
      );
    },
    onAddOwn: (typed) => unawaited(
      navigator.push<void>(
        notInLibraryPageRoute(
          context: navigator.context,
          builder: (_) => NotInLibraryScreen(
            query: typed,
            pickPhoto: takePhoto,
            // 07 has already loaded the library, so this never reads empty.
            countLibraryMatches: (text) => filterLibrary(
              container.read(libraryItemsProvider).value ?? const [],
              category: kLibraryAll,
              query: text,
            ).length,
            onCancel: returnToOrigin,
            onReturnToLibrary: (_) => navigator.pop(),
            onAdd: (manual) => unawaited(
              showAddFields(
                navigator.context,
                type: AddType.other,
                name: manual.name,
                initialValue: manual.spec,
                photo: manual.photo,
                pickPhoto: takePhoto,
                zone: zone,
                zones: zones,
                onSave: save,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Persists a finished draft. The sheet is already falling by the time this
/// runs; the new object lands on Home through its stream. No toast: the
/// object appearing is the confirmation.
///
/// [libraryTerm] is the synonym the object answers to in search, when the
/// caller knows one.
Future<void> saveDraft(
  ProviderContainer container,
  SpecDraft draft, {
  String? libraryTerm,
}) async {
  try {
    final photoFileNames = <String>[];
    final photo = draft.photo;
    if (photo != null) {
      // The file lands and is flushed before the row that names it exists,
      // so a crash here leaves an invisible orphan rather than a broken tile.
      final store = await container.read(photoStoreProvider.future);
      photoFileNames.add(await store.add(photo));
    }
    await container
        .read(objectRepositoryProvider)
        .create(
          objectDraftFrom(draft).copyWith(libraryTerm: Value(libraryTerm)),
          photoFileNames: photoFileNames,
          zoneName: draft.zone,
        );
  } on Object catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'spec',
        context: ErrorDescription('saving a new object'),
      ),
    );
  }
}
