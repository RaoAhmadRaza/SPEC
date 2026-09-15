import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spec/add/add_entry.dart';
import 'package:spec/app/router.dart';
import 'package:spec/object/search_route_args.dart';
import 'package:spec/providers/search.dart';
import 'package:spec/search/search_models.dart';
import 'package:spec/search/search_screen.dart';

/// Route-level wiring for screen 02.
///
/// The screen stays pure presentation driven by callbacks, so its tests build
/// it directly with no ProviderScope.
class SearchRoute extends ConsumerWidget {
  const SearchRoute({
    super.key,
    this.scope,
    this.isListingAll = false,
    this.initialQuery = '',
  });

  final String? scope;
  final bool isListingAll;
  final String initialQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runner = ref
        .watch(
          searchQueryRunnerProvider(scope: scope, isListingAll: isListingAll),
        )
        .value;

    return SearchScreen(
      // A top-level function rather than a closure: the screen re-runs its
      // query when the runner changes identity, and a fresh closure per build
      // would make that every build.
      runSearch: runner == null ? nothingFound : runner.run,
      scope: scope,
      isListingAll: isListingAll,
      initialQuery: initialQuery,
      recents: ref.watch(recentQueriesProvider),
      zones: ref.watch(searchZonesProvider).value ?? const [],
      counts: ref.watch(archiveCountsProvider).value ?? ArchiveCounts.empty,
      onCancel: context.pop,
      onQueryRun: ref.read(recentQueriesProvider.notifier).remember,
      onOpen: (result) => context.pushNamed(
        RouteNames.object,
        pathParameters: {'id': '${result.id}'},
        extra: objectRouteArgsForSearch(result),
      ),
      // Nothing matched, so the add flow opens on the library already
      // searching for it, filed under the zone the search was scoped to.
      onAdd: (query) =>
          unawaited(openAddEntry(context, query: query, zone: scope)),
      onZone: (zone) => context.pushNamed(
        RouteNames.search,
        queryParameters: {'scope': zone.name},
      ),
      onClearScope: () => context.pushReplacementNamed(RouteNames.search),
    );
  }
}

/// The runner before the photo store has opened. Never reached in practice —
/// the splash awaits the store — but a screen must not be built without one.
Future<SearchResults> nothingFound(String query) async => SearchResults.none;
