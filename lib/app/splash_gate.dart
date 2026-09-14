import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spec/providers/startup.dart';
import 'package:spec/splash/splash_screen.dart';

/// Holds the splash above the app until both its timeline and the cold-start
/// work have finished.
///
/// The splash stays an overlay rather than becoming a route, so it keeps
/// cross-fading over the first route the way it was built to.
class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate> {
  bool _isSplashDone = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isSplashDone)
          SplashScreen(
            warmup: ref.read(appStartupProvider.future),
            onDone: () => setState(() => _isSplashDone = true),
          ),
      ],
    );
  }
}
