import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';
import 'package:spec/widgets/tap_target.dart';

import 'shine_button.dart';
import 'spec_chip.dart';

/// One entrance pass, then the loops below take over.
const _enterDuration = Duration(milliseconds: 700);
const _glowPeriod = Duration(milliseconds: 3500);
const _shinePeriod = Duration(milliseconds: 3400);

/// Half of each chip's float period, since the controllers yo-yo.
const _floatHalfPeriodsMs = [3250, 4000, 3700, 4500, 5000, 4300];

/// Fixed, unrelated starting phases so no two chips crest together.
const _floatPhases = [0.00, 0.31, 0.62, 0.18, 0.47, 0.83];

/// Where each chip drifts to, and how it tilts along the way.
const _floatDrifts = [
  Offset(6, -16),
  Offset(-8, -13),
  Offset(-5, -20),
  Offset(9, -11),
  Offset(-8, -13),
  Offset(6, -16),
];
const _floatRotationsFrom = [-4.0, 5.0, -2.0, 7.0, 5.0, -4.0];
const _floatRotationsTo = [-1.0, 2.0, 3.0, 3.0, 2.0, -1.0];

const _glowOpacityMin = 0.35;
const _glowOpacityMax = 0.75;
const _glowScaleMax = 1.06;

/// Where the glow rests when the viewer has asked for reduced motion.
const _glowRestValue = 0.5;

/// Scrim over the background photograph. It stays light across the top so the
/// objects read, then ramps to the app background behind the message block.
const _scrimStops = [0.0, 0.35, 0.62, 1.0];
const _scrimAlphas = [0.35, 0.45, 0.90, 0.99];

const _contentPadding = EdgeInsets.fromLTRB(18, 56, 18, 0);
const _messagePadding = EdgeInsets.only(bottom: 34);
const _messageGap = 18.0;

/// Extra breathing room above the button, on top of [_messageGap].
const _buttonGap = 6.0;
const _headlineMaxWidth = 320.0;

const _enterRise = 20.0;
const _enterRiseMid = 14.0;
const _enterRiseLate = 12.0;
const _chipEnterScaleFrom = 0.9;
const _chipEnterStagger = 0.06;
const _chipEnterSpan = 0.35;

final _scrim = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    for (final alpha in _scrimAlphas) SpecColors.bg.withValues(alpha: alpha),
  ],
  stops: _scrimStops,
);

/// Onboarding 09, the welcome screen.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onStart, required this.onSkip});

  /// GET STARTED, which continues to onboarding 02.
  final VoidCallback onStart;

  /// SKIP, which goes straight to Home.
  final VoidCallback onSkip;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _enterDuration,
  );
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: _glowPeriod,
  );
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: _shinePeriod,
  );
  late final List<AnimationController> _floats = [
    for (final ms in _floatHalfPeriodsMs)
      AnimationController(
        vsync: this,
        duration: Duration(milliseconds: ms),
      ),
  ];

  late final Animation<double> _header = _seg(0.00, 0.30);
  late final Animation<double> _wordmark = _seg(0.20, 0.65);
  late final Animation<double> _copy = _seg(0.35, 0.80);
  late final Animation<double> _actions = _seg(0.50, 1.00);
  late final List<Animation<double>> _chipEntries = [
    for (var i = 0; i < _floatHalfPeriodsMs.length; i++)
      _seg(
        0.05 + i * _chipEnterStagger,
        0.05 + i * _chipEnterStagger + _chipEnterSpan,
      ),
  ];

  bool? _isMotionReduced;

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

  /// Reduced motion parks every loop at a resting frame rather than changing
  /// the layout, so the screen looks the same but holds still.
  void _syncMotionPreference(bool isReduced) {
    if (isReduced == _isMotionReduced) return;
    _isMotionReduced = isReduced;

    if (isReduced) {
      _enter.value = 1;
      _glow
        ..stop()
        ..value = _glowRestValue;
      _shine
        ..stop()
        ..value = 0;
      for (final controller in _floats) {
        controller
          ..stop()
          ..value = 0;
      }
      return;
    }

    _enter.forward();
    _glow.repeat(reverse: true);
    _shine.repeat();
    for (var i = 0; i < _floats.length; i++) {
      _floats[i]
        ..value = _floatPhases[i]
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final anim in [_header, _wordmark, _copy, _actions, ..._chipEntries]) {
      (anim as CurvedAnimation).dispose();
    }
    for (final controller in [..._floats, _enter, _glow, _shine]) {
      controller.dispose();
    }
    super.dispose();
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
            'assets/images/welcome_bg.png',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          DecoratedBox(
            decoration: BoxDecoration(gradient: _scrim),
            child: const SizedBox.expand(),
          ),
          _buildGlow(),
          ..._buildChips(),
          Padding(
            padding: _contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildHeader(), const Spacer(), _buildMessageBlock()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow() {
    return Positioned(
      left: -60,
      top: 180,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_glow.value);
            return Opacity(
              opacity:
                  _glowOpacityMin + (_glowOpacityMax - _glowOpacityMin) * t,
              child: Transform.scale(
                scale: 1 + (_glowScaleMax - 1) * t,
                child: child,
              ),
            );
          },
          child: Container(
            width: 320,
            height: 320,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [SpecColors.welcomeGlowInner, SpecColors.glowOuter],
                stops: [0.0, 0.7],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChips() {
    return [
      Positioned(
        left: 26,
        top: 132,
        child: _float(0, const SpecChip.glass('B22', cut: ChipCut.bottomLeft)),
      ),
      Positioned(
        right: 22,
        top: 196,
        child: _float(
          1,
          const SpecChip.glass('205/55 R16', cut: ChipCut.bottomRight),
        ),
      ),
      Positioned(
        left: 38,
        top: 296,
        child: _float(2, const SpecChip.lime('67XL', cut: ChipCut.topRight)),
      ),
      Positioned(
        right: 44,
        top: 322,
        child: _float(3, const SpecChip.glass('LT1000P', cut: ChipCut.topLeft)),
      ),
      Positioned(
        left: 120,
        top: 236,
        child: _float(4, const SpecChip.faint('M10 × 1.5')),
      ),
      Positioned(
        left: 96,
        top: 386,
        child: _float(5, const SpecChip.faint('32GB')),
      ),
    ];
  }

  /// Wraps a chip in its own drift loop plus its slot in the entrance stagger.
  Widget _float(int index, Widget chip) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floats[index], _chipEntries[index]]),
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_floats[index].value);
        final degrees =
            _floatRotationsFrom[index] +
            (_floatRotationsTo[index] - _floatRotationsFrom[index]) * t;
        final entry = _chipEntries[index].value;
        return Opacity(
          opacity: entry,
          child: Transform.scale(
            scale: _chipEnterScaleFrom + (1 - _chipEnterScaleFrom) * entry,
            child: Transform.rotate(
              angle: degrees * math.pi / 180,
              child: Transform.translate(
                offset: _floatDrifts[index] * t,
                child: child,
              ),
            ),
          ),
        );
      },
      child: chip,
    );
  }

  Widget _buildHeader() {
    return _fadeIn(
      _header,
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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

  Widget _buildMessageBlock() {
    return Padding(
      padding: _messagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _riseIn(_wordmark, _enterRise, _buildWordmark()),
          const SizedBox(height: _messageGap),
          _riseIn(
            _copy,
            _enterRiseMid,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _headlineMaxWidth),
              child: const Text(
                'Your physical world, remembered.',
                style: SpecText.headline,
              ),
            ),
          ),
          const SizedBox(height: _messageGap),
          _riseIn(
            _copy,
            _enterRiseMid,
            const Text(
              'NO ACCOUNT · NO CLOUD\nNOTHING LEAVES THIS PHONE',
              style: SpecText.privacy,
            ),
          ),
          const SizedBox(height: _messageGap + _buttonGap),
          _riseIn(
            _actions,
            _enterRiseLate,
            ShineButton(
              label: 'GET STARTED',
              shine: _shine,
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onStart();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The trademark hangs from the cap top rather than sitting on the baseline.
  Widget _buildWordmark() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SPEC', style: SpecText.welcomeWordmark),
        Text('™', style: SpecText.welcomeTrademark),
      ],
    );
  }

  Widget _fadeIn(Animation<double> anim, Widget child) => AnimatedBuilder(
    animation: anim,
    builder: (context, child) => Opacity(opacity: anim.value, child: child),
    child: child,
  );

  Widget _riseIn(Animation<double> anim, double rise, Widget child) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, rise * (1 - anim.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
