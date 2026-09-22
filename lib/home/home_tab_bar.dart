import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/home/home_glass.dart';
import 'package:spec/home/home_icons.dart';
import 'package:spec/home/home_tokens.dart';
import 'package:spec/theme/spec_layout.dart';
import 'package:spec/theme/spec_tokens.dart';

const double kTabBarHeight = 64;
const double kTabBarInset = 16;
const double kTabBarBottom = 24;
const double kOrbSize = 66;
const double kOrbBottom = 32;

/// Air between a scrolling tab's last item and the top of the floating bar.
const double kShellChromeGap = 24;

/// What a scrolling tab must pad at the bottom so its last item clears the
/// floating bar and orb. Home and Collections both read this; changing the
/// bar's size must not require editing two other files.
///
/// At zero padding this is 24 + 64 + 24 = 112, the number both screens used
/// to carry as a literal. The orb's own top sits at 32 + 66 = 98, so the bar
/// is what sets the total.
double specShellChromeHeight(BuildContext context) =>
    SpecLayout.bottomInset(context, design: kTabBarBottom) +
    kTabBarHeight +
    kShellChromeGap;

const _barBlur = 30.0;
const _orbBlur = 24.0;
const _glassSaturation = 2.0;

const _pressDuration = Duration(milliseconds: 120);
const _pressedScale = 0.94;

/// Icon fill and label weight cross-fade when the active tab changes.
const _activeFade = Duration(milliseconds: 200);

/// The two tab roots.
enum SpecTab { home, collections }

/// The floating bar. It sits outside the scroll view and never moves.
class HomeTabBar extends StatelessWidget {
  const HomeTabBar({
    super.key,
    required this.onHome,
    required this.onCollections,
    this.active = SpecTab.home,
  });

  final VoidCallback onHome;
  final VoidCallback onCollections;
  final SpecTab active;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // A floor, not a fixed height: at a raised text scale the labels need
      // more room, and the glass pill's own ClipRRect would cut them off
      // without reporting an overflow.
      constraints: const BoxConstraints(minHeight: kTabBarHeight),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(999),
        blur: _barBlur,
        saturation: _glassSaturation,
        fill: HomeColors.barFill,
        borderColor: HomeColors.barBorder,
        topHighlight: HomeColors.barHighlight,
        shadows: const [
          BoxShadow(
            color: HomeColors.barShadow,
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _Tab(
                label: 'Home',
                isActive: active == SpecTab.home,
                idleIcon: const HomeIcon.house(
                  size: 19,
                  color: SpecColors.ink72,
                ),
                activeIcon: const HomeIcon.house(
                  size: 19,
                  color: SpecColors.ink,
                  isFilled: true,
                ),
                onTap: onHome,
              ),
            ),
            Flexible(
              child: _Tab(
                label: 'Collections',
                isActive: active == SpecTab.collections,
                idleIcon: const HomeIcon.folder(
                  size: 19,
                  color: SpecColors.ink72,
                ),
                activeIcon: const HomeIcon.folder(
                  size: 19,
                  color: SpecColors.ink,
                  isFilled: true,
                ),
                onTap: onCollections,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isActive,
    required this.idleIcon,
    required this.activeIcon,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Widget idleIcon;
  final Widget activeIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kTabBarHeight),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: isActive ? 1 : 0),
          duration: _activeFade,
          builder: (context, t, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Opacity(opacity: 1 - t, child: idleIcon),
                  Opacity(opacity: t, child: activeIcon),
                ],
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle.lerp(
                    HomeText.tabIdle,
                    HomeText.tabActive,
                    t,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised `+`. The primary action on this screen, and the only one in the
/// empty state.
class HomeOrb extends StatefulWidget {
  const HomeOrb({super.key, required this.breathe, required this.onTap});

  /// A slow scale loop owned by the screen, so reduced motion can park it.
  final Animation<double> breathe;
  final VoidCallback onTap;

  @override
  State<HomeOrb> createState() => _HomeOrbState();
}

class _HomeOrbState extends State<HomeOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: _pressDuration,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _press.forward();

  void _onTapCancel() => _press.reverse();

  void _onTap() {
    HapticFeedback.mediumImpact();
    _press.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.breathe, _press]),
        builder: (context, child) {
          final pressed = Curves.easeOut.transform(_press.value);
          final scale =
              widget.breathe.value * (1 - (1 - _pressedScale) * pressed);
          return Transform.scale(scale: scale, child: child);
        },
        child: GlassSurface(
          borderRadius: BorderRadius.circular(999),
          blur: _orbBlur,
          saturation: _glassSaturation,
          borderColor: HomeColors.orbBorder,
          topHighlight: HomeColors.orbHighlight,
          topHighlightHeight: 2,
          gradient: const RadialGradient(
            center: Alignment(-0.36, -0.56),
            radius: 0.6,
            colors: [
              HomeColors.orbInner,
              HomeColors.orbMid,
              HomeColors.orbOuter,
            ],
            stops: [0, 0.55, 1],
          ),
          shadows: const [
            BoxShadow(
              color: HomeColors.orbShadow,
              blurRadius: 40,
              offset: Offset(0, 18),
            ),
          ],
          child: const SizedBox.square(
            dimension: kOrbSize,
            child: Center(child: Text('+', style: HomeText.plusOrb)),
          ),
        ),
      ),
    );
  }
}
