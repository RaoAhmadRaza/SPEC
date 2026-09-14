import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spec/object/object_route.dart';
import 'package:spec/onboarding/onboarding_routes.dart';
import 'package:spec/providers/onboarding.dart';
import 'package:spec/search/search_page_route.dart';
import 'package:spec/search/search_route.dart';
import 'package:spec/settings/settings_route.dart';
import 'package:spec/shell/home_shell_route.dart';

part 'router.g.dart';

/// Route names, so call sites never repeat a path string.
abstract final class RouteNames {
  static const welcome = 'onboardingWelcome';
  static const howItWorks = 'onboardingHowItWorks';
  static const firstObject = 'onboardingFirstObject';
  static const home = 'home';
  static const search = 'search';
  static const object = 'object';
  static const settings = 'settings';
}

abstract final class RoutePaths {
  static const welcome = '/onboarding/welcome';
  static const howItWorks = '/onboarding/how-it-works';
  static const firstObject = '/onboarding/first-object';
  static const home = '/home';
  static const search = '/search';
  static const object = '/object/:id';
  static const settings = '/settings';
}

const _onboardingPrefix = '/onboarding';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Never watch changing state here: rebuilding the GoRouter would destroy the
  // navigation stack. The onboarding flag is pushed in through a listenable
  // instead, which is what refreshListenable exists for.
  // Until the flag has been read from disk, treat the user as new. That first
  // frame happens underneath an opaque splash, so no redirect is ever seen.
  final isOnboarded = ValueNotifier<bool>(
    ref.read(onboardingCompletedProvider).value ?? false,
  );
  ref.listen<AsyncValue<bool>>(
    onboardingCompletedProvider,
    (_, next) => isOnboarded.value = next.value ?? false,
  );
  ref.onDispose(isOnboarded.dispose);

  return GoRouter(
    initialLocation: RoutePaths.home,
    refreshListenable: isOnboarded,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final isInOnboarding = state.matchedLocation.startsWith(
        _onboardingPrefix,
      );
      if (!isOnboarded.value && !isInOnboarding) return RoutePaths.welcome;
      if (isOnboarded.value && isInOnboarding) return RoutePaths.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.welcome,
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeRoute(),
      ),
      GoRoute(
        path: RoutePaths.howItWorks,
        name: RouteNames.howItWorks,
        builder: (context, state) => const HowItWorksRoute(),
      ),
      GoRoute(
        path: RoutePaths.firstObject,
        name: RouteNames.firstObject,
        builder: (context, state) => const FirstObjectRoute(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeShellRoute(),
      ),
      GoRoute(
        path: RoutePaths.search,
        name: RouteNames.search,
        pageBuilder: (context, state) {
          final scope = state.uri.queryParameters['scope'];
          return SearchPage(
            key: state.pageKey,
            name: state.name,
            isScoped: scope != null,
            child: SearchRoute(
              scope: scope,
              isListingAll: state.uri.queryParameters['all'] == '1',
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.object,
        name: RouteNames.object,
        // Screen 03 is always pushed from a card or a result row, and flies in
        // from it. A malformed id has no object to show, so it goes home.
        redirect: (context, state) =>
            int.tryParse(state.pathParameters['id'] ?? '') == null
            ? RoutePaths.home
            : null,
        pageBuilder: (context, state) => ObjectPage<void>(
          key: state.pageKey,
          name: state.name,
          child: ObjectRoute(
            id: int.parse(state.pathParameters['id']!),
            args: switch (state.extra) {
              final ObjectRouteArgs args => args,
              _ => null,
            },
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsRoute(),
      ),
    ],
  );
}
