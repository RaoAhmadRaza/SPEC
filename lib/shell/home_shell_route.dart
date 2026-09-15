import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:spec/add/add_entry.dart';
import 'package:spec/collections/collections_route.dart';
import 'package:spec/home/home_route.dart';
import 'package:spec/home/home_tab_bar.dart';
import 'package:spec/shell/tab_shell.dart';

/// Route-level wiring for the two tab roots, Home and Collections, behind the
/// one floating bar and orb.
///
/// Not named `ShellRoute`: go_router already has one, and this is a plain
/// widget built by a plain `GoRoute`.
class HomeShellRoute extends StatelessWidget {
  const HomeShellRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return SpecTabShell(
      // This context sits inside the `/home` page route, which is what the add
      // flow needs to return to.
      onAdd: () => unawaited(openAddEntry(context)),
      builder: (context, tab, isActive) => switch (tab) {
        SpecTab.home => const HomeRoute(),
        SpecTab.collections => CollectionsRoute(isActive: isActive),
      },
    );
  }
}
