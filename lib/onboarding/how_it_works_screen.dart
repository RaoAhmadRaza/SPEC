import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';
import 'package:spec/widgets/tap_target.dart';

import 'spec_icons.dart';
import 'step_card.dart';

/// One full undulation of the card stack.
const _risePeriod = Duration(milliseconds: 6000);
const _enterDuration = Duration(milliseconds: 780);

/// Reduced motion replaces the staged entrance with a single plain fade.
const _reducedEnterDuration = Duration(milliseconds: 200);
const _pressDuration = Duration(milliseconds: 120);

const _riseDistance = 9.0;
const _cardCount = 3;

/// Air between the cards. Card heights are intrinsic, so the group is measured
/// rather than positioned, which lets it centre on any screen height.
const _cardGap = 26.0;

/// Exactly one cut corner per card, rotating bottom-right, bottom-left, then
/// top-left down the stack.
const _cutRadiusCornerBottomRight = BorderRadius.only(
  topLeft: Radius.circular(22),
  topRight: Radius.circular(22),
  bottomRight: Radius.circular(6),
  bottomLeft: Radius.circular(22),
);
const _cutRadiusCornerBottomLeft = BorderRadius.only(
  topLeft: Radius.circular(22),
  topRight: Radius.circular(22),
  bottomRight: Radius.circular(22),
  bottomLeft: Radius.circular(6),
);
const _cutRadiusCornerTopLeft = BorderRadius.only(
  topLeft: Radius.circular(6),
  topRight: Radius.circular(22),
  bottomRight: Radius.circular(22),
  bottomLeft: Radius.circular(22),
);

/// Scrim over the background photograph. The image is already near-black
/// below the bulb, so this mostly protects the headline without dulling it.
const _scrimStops = [0.0, 0.45, 1.0];
const _scrimAlphas = [0.22, 0.34, 0.55];

const _contentPadding = EdgeInsets.fromLTRB(18, 56, 18, 0);
const _sectionGap = 20.0;
const _headlineOffset = 4.0;

/// The kicker is pulled toward the headline rather than pushed away from it.
const _kickerPull = -8.0;
const _stackOffset = 6.0;

const _enterRiseHeadline = 22.0;
const _enterRiseSmall = 12.0;
const _enterRiseCard = 30.0;
const _pressScale = 0.985;

const _bottomBarInset = 24.0;

const _dotSize = 7.0;
const _dotGap = 6.0;
const _activeDotWidth = 22.0;
const _activePage = 1;
const _buttonHeight = 58.0;
const _bottomBarGap = 12.0;

final _scrim = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    for (final alpha in _scrimAlphas) SpecColors.bg.withValues(alpha: alpha),
  ],
  stops: _scrimStops,
);

/// Onboarding 02, the how-it-works screen.
class HowItWorksScreen extends StatefulWidget {
  const HowItWorksScreen({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  /// NEXT, which continues to onboarding 03.
  final VoidCallback onNext;

  /// SKIP, which goes straight to Home.
  final VoidCallback onSkip;

  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: _risePeriod,
  );
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _enterDuration,
  );
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: _pressDuration,
  );

  late final Animation<double> _header = _seg(0.00, 0.28);
  late final Animation<double> _headline = _seg(0.08, 0.55);
  late final Animation<double> _kicker = _seg(0.22, 0.62);
  late final Animation<double> _bottomBar = _seg(0.60, 1.00);
  late final List<Animation<double>> _cardEntries = [
    for (var i = 0; i < _cardCount; i++) _seg(0.30 + i * 0.10, 0.75 + i * 0.10),
  ];

  bool _isMotionReduced = false;
  bool? _appliedMotionPreference;
  int? _pressedCard;

  Animation<double> _seg(double begin, double end) => CurvedAnimation(
    parent: _enter,
    curve: Interval(
      begin.clamp(0, 1),
      end.clamp(0, 1),
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotionPreference(MediaQuery.disableAnimationsOf(context));
  }

  void _syncMotionPreference(bool isReduced) {
    if (isReduced == _appliedMotionPreference) return;
    _appliedMotionPreference = isReduced;
    _isMotionReduced = isReduced;

    if (isReduced) {
      _rise
        ..stop()
        ..value = 0;
      _enter
        ..duration = _reducedEnterDuration
        ..forward();
      return;
    }

    _enter
      ..duration = _enterDuration
      ..forward();
    _rise.repeat();
  }

  @override
  void dispose() {
    for (final anim in [
      _header,
      _headline,
      _kicker,
      _bottomBar,
      ..._cardEntries,
    ]) {
      (anim as CurvedAnimation).dispose();
    }
    _rise.dispose();
    _enter.dispose();
    _press.dispose();
    super.dispose();
  }

  /// How far card [index] currently sits above its resting position. One
  /// controller drives all three, read a third of a cycle apart.
  double _riseFor(int index) {
    if (_isMotionReduced) return 0;
    final phase = (_rise.value + index / _cardCount) % 1.0;
    final triangle = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return -_riseDistance * Curves.easeInOut.transform(triangle);
  }

  /// Under reduced motion every element shares one plain fade.
  double _opacityOf(Animation<double> segment) =>
      _isMotionReduced ? _enter.value : segment.value;

  /// Under reduced motion nothing travels; only the fade remains.
  double _travelOf(Animation<double> segment, double distance) =>
      _isMotionReduced ? 0 : distance * (1 - segment.value);

  Future<void> _onCardTap(int index) async {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _pressedCard = index);
    await _press.forward();
    await _press.reverse();
    if (!mounted) return;
    setState(() => _pressedCard = null);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: SpecFonts.display,
        color: SpecColors.ink,
        decoration: TextDecoration.none,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: SpecColors.bg),
          Image.asset(
            'assets/images/how_it_works_bg.png',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          DecoratedBox(
            decoration: BoxDecoration(gradient: _scrim),
            child: const SizedBox.expand(),
          ),
          Padding(
            padding: _contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: _sectionGap + _headlineOffset),
                _buildHeadline(),
                const SizedBox(height: _sectionGap + _kickerPull),
                _buildKicker(),
                const SizedBox(height: _sectionGap + _stackOffset),
                Expanded(
                  child: Padding(
                    // Reserve the bottom bar's band so the cards centre in the
                    // space they actually have, not underneath the button.
                    padding: const EdgeInsets.only(
                      bottom: _bottomBarInset + _buttonHeight,
                    ),
                    child: Center(child: _buildCardStack()),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: _bottomBarInset,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return _enterIn(
      _header,
      0,
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: SpecColors.pillFill,
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                  border: Border.all(color: SpecColors.pillBorder),
                ),
                child: const Text('02 / 03', style: SpecText.pill),
              ),
            ),
          ),
          TapTarget(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onSkip();
            },
            child: const Text('SKIP', style: SpecText.skip),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return _enterIn(
      _headline,
      _enterRiseHeadline,
      const Text('THREE\nSECONDS.', style: SpecText.howHeadline),
    );
  }

  Widget _buildKicker() {
    return _enterIn(
      _kicker,
      _enterRiseSmall,
      const Text('THAT IS THE WHOLE PRODUCT', style: SpecText.kicker),
    );
  }

  Widget _buildCardStack() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCard(
          0,
          const StepCard(
            radius: _cutRadiusCornerBottomRight,
            leading: SpecIcon.camera(),
            label: '01 — SNAP',
            title: 'Photograph the thing',
            body: 'Bulb, tyre, filter, label.',
          ),
        ),
        const SizedBox(height: _cardGap),
        _buildCard(
          1,
          const StepCard(
            radius: _cutRadiusCornerBottomLeft,
            leading: Text('B22', style: SpecText.limeLeading),
            label: '02 — SPEC',
            title: 'Keep only what matters',
            body: 'One number. Not a form.',
            isLime: true,
          ),
        ),
        const SizedBox(height: _cardGap),
        _buildCard(
          2,
          const StepCard(
            radius: _cutRadiusCornerTopLeft,
            leading: SpecIcon.search(),
            label: '03 — RECALL',
            title: 'Find it in the aisle',
            body: 'Search works offline.',
          ),
        ),
      ],
    );
  }

  Widget _buildCard(int index, Widget card) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rise, _enter, _press]),
      builder: (context, child) {
        final entry = _cardEntries[index];
        final press = _pressedCard == index ? _press.value : 0.0;
        return Opacity(
          opacity: _opacityOf(entry),
          child: Transform.translate(
            offset: Offset(
              0,
              _riseFor(index) + _travelOf(entry, _enterRiseCard),
            ),
            child: Transform.scale(
              scale: 1 - (1 - _pressScale) * press,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _onCardTap(index),
        behavior: HitTestBehavior.opaque,
        child: card,
      ),
    );
  }

  Widget _buildBottomBar() {
    return _enterIn(
      _bottomBar,
      _enterRiseSmall,
      Row(
        children: [
          const _PageDots(),
          const SizedBox(width: _bottomBarGap),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onNext();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: _buttonHeight,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: SpecColors.accent,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                  boxShadow: [
                    BoxShadow(
                      color: SpecColors.nextButtonShadow,
                      blurRadius: 40,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: const Text('NEXT', style: SpecText.nextButton),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _enterIn(Animation<double> segment, double rise, Widget child) {
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) => Opacity(
        opacity: _opacityOf(segment),
        child: Transform.translate(
          offset: Offset(0, _travelOf(segment, rise)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var page = 0; page < _cardCount; page++) ...[
          if (page > 0) const SizedBox(width: _dotGap),
          Container(
            width: page == _activePage ? _activeDotWidth : _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              color: page == _activePage
                  ? SpecColors.accent
                  : SpecColors.dotIdle,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ],
    );
  }
}
