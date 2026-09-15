import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/home/home_tab_bar.dart';

const _switchDuration = Duration(milliseconds: 360);
const _reducedSwitchDuration = Duration(milliseconds: 200);

/// Outgoing content leaves toward the side it came from; incoming arrives
/// from the other.
const _switchTravel = 24.0;

const _breathePeriod = Duration(milliseconds: 4200);
const _breatheScale = 1.02;

/// The bar clears over the first 240ms of the 420ms push to Search.
const _pushFadeCurve = Interval(0, 240 / 420, curve: Curves.easeOut);

/// Builds one tab root. [isActive] turns true each time the tab is shown.
typedef TabRootBuilder = Widget Function(
  BuildContext context,
  SpecTab tab,
  bool isActive,
);

/// The two tab roots behind one floating bar and orb.
///
/// The bar, the orb and the orb's breathe live here rather than in either
/// screen, so switching tabs only changes the content behind them: nothing
/// fades, re-enters or restarts its loop.
class SpecTabShell extends StatefulWidget {
  const SpecTabShell({
    super.key,
    required this.builder,
    this.initialTab = SpecTab.home,
    this.onAdd,
  });

  final TabRootBuilder builder;
  final SpecTab initialTab;

  /// The orb. 07 Library pick rises from here.
  final VoidCallback? onAdd;

  /// Brings [tab] forward from anywhere under the shell, the way tapping its
  /// bar item does.
  static void select(BuildContext context, SpecTab tab) =>
      context.findAncestorStateOfType<_SpecTabShellState>()?._select(tab);

  @override
  State<SpecTabShell> createState() => _SpecTabShellState();
}

class _SpecTabShellState extends State<SpecTabShell>
    with TickerProviderStateMixin {
  late SpecTab _tab = widget.initialTab;
  late SpecTab _previous = widget.initialTab;

  late final AnimationController _switch = AnimationController(
    vsync: this,
    duration: _switchDuration,
    value: 1,
  );
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: _breathePeriod,
  );
  late final CurvedAnimation _breatheCurve = CurvedAnimation(
    parent: _breathe,
    curve: Curves.easeInOut,
  );
  late final Animation<double> _orbScale = Tween<double>(
    begin: 1,
    end: _breatheScale,
  ).animate(_breatheCurve);

  bool _isMotionReduced = false;
  bool? _appliedMotionPreference;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isReduced = MediaQuery.disableAnimationsOf(context);
    if (isReduced == _appliedMotionPreference) return;
    _appliedMotionPreference = isReduced;
    _isMotionReduced = isReduced;
    _switch.duration = isReduced ? _reducedSwitchDuration : _switchDuration;
    if (isReduced) {
      // The orb holds at rest rather than breathing.
      _breathe
        ..stop()
        ..value = 0;
    } else {
      _breathe.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breatheCurve.dispose();
    _switch.dispose();
    _breathe.dispose();
    super.dispose();
  }

  void _select(SpecTab tab) {
    if (tab == _tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _previous = _tab;
      _tab = tab;
    });
    _switch.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final tab in SpecTab.values) _buildRoot(context, tab),
        Positioned(
          left: kTabBarInset,
          right: kTabBarInset,
          bottom: kTabBarBottom,
          child: _pushFade(
            HomeTabBar(
              active: _tab,
              onHome: () => _select(SpecTab.home),
              onCollections: () => _select(SpecTab.collections),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: kOrbBottom,
          child: _pushFade(
            Center(
              child: HomeOrb(breathe: _orbScale, onTap: widget.onAdd ?? () {}),
            ),
          ),
        ),
      ],
    );
  }

  /// Both roots stay built so each keeps its scroll position; only the
  /// current one, and the one leaving during a switch, are on stage.
  Widget _buildRoot(BuildContext context, SpecTab tab) {
    final isCurrent = tab == _tab;
    final isLeaving = tab == _previous && !isCurrent;

    return AnimatedBuilder(
      animation: _switch,
      child: widget.builder(context, tab, isCurrent),
      builder: (context, child) {
        final isSwitching = _switch.isAnimating;
        final isOnStage = isCurrent || (isLeaving && isSwitching);
        final t = Curves.easeOutCubic.transform(_switch.value);
        final direction = _tab.index > _previous.index ? 1.0 : -1.0;

        final opacity = isCurrent ? t : 1 - t;
        final dx = _isMotionReduced
            ? 0.0
            : isCurrent
            ? _switchTravel * direction * (1 - t)
            : -_switchTravel * direction * t;

        // Flutter collects Heroes even inside an Offstage, so a hidden root's
        // would fly on a push, or collide with the visible root's same tag.
        return HeroMode(
          enabled: isCurrent,
          child: Offstage(
            offstage: !isOnStage,
            child: TickerMode(
              enabled: isOnStage,
              child: IgnorePointer(
                ignoring: !isCurrent,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Fades the bar and orb out as a route is pushed over the shell — Search
  /// has no tab bar.
  Widget _pushFade(Widget child) {
    final secondary = ModalRoute.of(context)?.secondaryAnimation;
    if (secondary == null) return child;
    return AnimatedBuilder(
      animation: secondary,
      child: child,
      builder: (context, inner) => Opacity(
        opacity: 1 - _pushFadeCurve.transform(secondary.value.clamp(0, 1)),
        child: inner,
      ),
    );
  }
}
