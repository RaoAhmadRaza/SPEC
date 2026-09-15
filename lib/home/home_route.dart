import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spec/add/add_entry.dart';
import 'package:spec/app/router.dart';
import 'package:spec/home/home_models.dart';
import 'package:spec/home/home_screen.dart';
import 'package:spec/object/object_route.dart';
import 'package:spec/providers/collections.dart';
import 'package:spec/providers/home.dart';

/// Route-level wiring for screen 01.
///
/// The screen stays pure presentation driven by callbacks, so its tests build
/// it directly with no ProviderScope. This wrapper adds no render object.
class HomeRoute extends ConsumerWidget {
  const HomeRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No spinner: a local stream resolves within a frame, so a spinner would
    // flash and look broken. An unresolved read renders the empty state.
    final objects =
        ref.watch(homeObjectsProvider).value ?? const <HomeObject>[];

    return HomeScreen(
      objects: objects,
      categories: ref.watch(homeCategoriesProvider),
      // Pushed, not a tab root: the pill flies up and CANCEL brings it back.
      onSearch: () => context.pushNamed(RouteNames.search),
      // The same scoped search a Collections zone row opens.
      onCategory: (category) => context.pushNamed(
        RouteNames.search,
        queryParameters: {'scope': category.label},
      ),
      onSeeAll: () =>
          context.pushNamed(RouteNames.search, queryParameters: {'all': '1'}),
      onObject: (object) => context.pushNamed(
        RouteNames.object,
        pathParameters: {'id': '${object.id}'},
        extra: objectRouteArgsFor(object, objects),
      ),
      onObjectMenu: (object) =>
          unawaited(showObjectActions(context, ref, object.id)),
      onAdd: () => unawaited(openAddEntry(context)),
      onMenu: () => context.pushNamed(RouteNames.settings),
      onNewZone: () => ref.read(newZoneRequestsProvider.notifier).request(),
    );
  }
}
