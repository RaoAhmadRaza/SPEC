import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_layout.dart';
import 'package:spec/theme/spec_tokens.dart';

/// Master timeline, matching the loop in the design file. Every interval
/// below is a fraction of this.
const _masterDuration = Duration(milliseconds: 4500);

/// Cross-fade to the next route once the master timeline and warmup are done.
const _exitDuration = Duration(milliseconds: 320);

/// Half of one glow breath; the controller yo-yos, so a full breath is twice
/// this.
const _glowHalfPeriod = Duration(milliseconds: 3250);

/// The glow reads as atmosphere, not as a disc: it is wider than the screen
/// and its falloff runs all the way to the edge of the circle.
const _glowSize = 640.0;
const _glowStops = [0.0, 0.55, 1.0];
const _glowOpacityMin = 0.30;
const _glowOpacityMax = 0.85;
const _glowScaleMin = 0.92;
const _glowScaleMax = 1.16;

/// How much longer than the master timeline a slow cold start may hold the
/// splash. Beyond this the warmup is abandoned and the splash leaves anyway.
const _warmupGrace = Duration(milliseconds: 3000);
final _warmupCap = _masterDuration + _warmupGrace;

const _rise = Cubic(0.16, 1, 0.3, 1);
const _progressCurve = Cubic(0.4, 0, 0.2, 1);

const _letters = ['S', 'P', 'E', 'C'];
const _letterStagger = 0.07;
const _letterSpan = 0.22;
const _letterRise = 26.0;
const _letterScaleFrom = 0.94;

/// Elements that fade up into place share this 8pt travel.
const _fadeRise = 8.0;

/// Phase advance per ghost so the four never pulse together.
/// CSS: `animation-delay: 0s, -0.5s, -1.1s, -1.7s` over a 4.5s cycle.
const _ghostShifts = [0.0, 0.11, 0.24, 0.38];

/// CSS `specGhost`: 0%,15% -> 0; 45% -> 0.5; 75%,100% -> 0.
const _ghostFadeInStart = 0.15;
const _ghostPeak = 0.45;
const _ghostFadeOutEnd = 0.75;
const _ghostPeakOpacity = 0.5;

/// The viewport the screen was drawn on. Every absolute offset below is
/// expressed as a fraction of these, so at 402 x 874 the arithmetic returns
/// the original literal and nothing moves.
const _designWidth = 402.0;
const _designHeight = 874.0;

/// Side air the wordmark keeps inside the centre column before it starts to
/// scale down. Without it the four glyphs touch the edge on a 320pt phone.
const _wordmarkGutter = 24.0;

/// SPEC splash (design file screen 12), rebuilt 1:1 at 402 x 874 pt.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone, this.warmup});

  /// Called once the splash has fully faded out.
  final VoidCallback onDone;

  /// Cold-start work (DB open, first data read). The splash waits for this as
  /// well as the animation, so a slow start extends the splash instead of
  /// flashing an empty Home.
  final Future<void>? warmup;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _master = AnimationController(
    vsync: this,
    duration: _masterDuration,
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: _exitDuration,
  );
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: _glowHalfPeriod,
  )..repeat(reverse: true);

  late final List<Animation<double>> _letterAnims;
  late final Animation<double> _trademarkAnim;
  late final Animation<double> _ruleAnim;
  late final Animation<double> _taglineAnim;
  late final Animation<double> _progressAnim;
  late final Animation<double> _captionAnim;

  Animation<double> _seg(
    double begin,
    double end, {
    Curve curve = Curves.easeInOut,
  }) {
    return CurvedAnimation(
      parent: _master,
      curve: Interval(begin.clamp(0, 1), end.clamp(0, 1), curve: curve),
    );
  }

  @override
  void initState() {
    super.initState();
    _letterAnims = [
      for (var i = 0; i < _letters.length; i++)
        _seg(
          _letterStagger * i,
          _letterStagger * i + _letterSpan,
          curve: _rise,
        ),
    ];
    _trademarkAnim = _seg(0.26, 0.46);
    _ruleAnim = _seg(0.10, 0.40, curve: _rise);
    _taglineAnim = _seg(0.28, 0.48);
    _progressAnim = _seg(0.00, 0.92, curve: _progressCurve);
    _captionAnim = _seg(0.30, 0.50);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _run();
  }

  Future<void> _run() async {
    final warmup = (widget.warmup ?? Future<void>.value())
        .timeout(_warmupCap, onTimeout: () {})
        .catchError((Object error, StackTrace stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'spec splash',
              context: ErrorDescription(
                'warmup failed; continuing to the next route anyway',
              ),
            ),
          );
        });

    await Future.wait([_master.forward(), warmup]);
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    widget.onDone();
  }

  @override
  void dispose() {
    for (final anim in [
      ..._letterAnims,
      _trademarkAnim,
      _ruleAnim,
      _taglineAnim,
      _progressAnim,
      _captionAnim,
    ]) {
      (anim as CurvedAnimation).dispose();
    }
    _master.dispose();
    _exit.dispose();
    _glow.dispose();
    super.dispose();
  }

  double _ghostOpacity(double phase) {
    if (phase < _ghostFadeInStart || phase >= _ghostFadeOutEnd) return 0;
    if (phase < _ghostPeak) {
      final t = (phase - _ghostFadeInStart) / (_ghostPeak - _ghostFadeInStart);
      return Curves.easeInOut.transform(t) * _ghostPeakOpacity;
    }
    final t = (phase - _ghostPeak) / (_ghostFadeOutEnd - _ghostPeak);
    return (1 - Curves.easeInOut.transform(t)) * _ghostPeakOpacity;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final contentWidth = SpecLayout.contentWidth(context);
    final bottomInset = SpecLayout.bottomInset(context, design: 52);
    // The glow has to stay wider than the frame to read as atmosphere. On a
    // phone that is the designed 640; on a tablet it grows by the same ratio
    // it holds against the reference's narrow edge, so a 1280pt iPad gets a
    // wash rather than a disc.
    final glowSize = SpecLayout.isExpanded(context)
        ? size.shortestSide * (_glowSize / _designWidth)
        : _glowSize;
    return AnimatedBuilder(
      animation: Listenable.merge([_master, _glow, _exit]),
      builder: (context, _) {
        final fade = 1 - Curves.easeOut.transform(_exit.value);
        // The rule decays linearly, which is always slower than the eased fade
        // above, so the accent is the last thing to leave the screen.
        final ruleFade = 1 - _exit.value;
        // The splash is its own root: without a text style of its own the
        // strings below inherit the debug fallback (yellow underline).
        return DefaultTextStyle(
          style: const TextStyle(
            fontFamily: SpecFonts.display,
            color: SpecColors.ink,
            decoration: TextDecoration.none,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: SpecColors.bg.withValues(alpha: fade)),
              _buildGlow(fade, glowSize),
              Positioned(
                left: size.width * (34 / _designWidth),
                top: size.height * (214 / _designHeight),
                child: _buildGhost('B22', 0, fade),
              ),
              Positioned(
                right: size.width * (32 / _designWidth),
                top: size.height * (266 / _designHeight),
                child: _buildGhost('205/55 R16', 1, fade),
              ),
              Positioned(
                left: size.width * (52 / _designWidth),
                bottom: size.height * (268 / _designHeight),
                child: _buildGhost('LT1000P', 2, fade),
              ),
              Positioned(
                right: size.width * (44 / _designWidth),
                bottom: size.height * (238 / _designHeight),
                child: _buildGhost('67XL', 3, fade),
              ),
              Center(child: _buildCenterColumn(fade, ruleFade, contentWidth)),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset,
                child: _buildBottomBlock(fade),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlow(double fade, double glowSize) {
    final t = Curves.easeInOut.transform(_glow.value);
    final opacity = _glowOpacityMin + (_glowOpacityMax - _glowOpacityMin) * t;
    final scale = _glowScaleMin + (_glowScaleMax - _glowScaleMin) * t;
    return IgnorePointer(
      child: Align(
        child: Opacity(
          opacity: opacity * fade,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: glowSize,
              height: glowSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    SpecColors.glowInner,
                    SpecColors.glowMid,
                    SpecColors.glowOuter,
                  ],
                  stops: _glowStops,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGhost(String text, int index, double fade) {
    final phase = (_master.value + _ghostShifts[index]) % 1.0;
    return Opacity(
      opacity: _ghostOpacity(phase) * fade,
      child: Text(text, style: SpecText.ghostSpec),
    );
  }

  Widget _buildCenterColumn(double fade, double ruleFade, double maxWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWordmark(fade, maxWidth - _wordmarkGutter * 2),
          const SizedBox(height: 18),
          _buildRule(ruleFade),
          const SizedBox(height: 18),
          _riseIn(
            _taglineAnim,
            fade,
            const Text(
              'REMEMBER THE SPECS\nFORGET THE SEARCH',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SpecText.tagline,
            ),
          ),
        ],
      ),
    );
  }

  /// [BoxFit.scaleDown] only ever shrinks, so the 92pt design size survives
  /// untouched at the reference canvas and a narrow phone or a raised text
  /// scale shrinks the wordmark instead of clipping it.
  Widget _buildWordmark(double fade, double maxWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _letters.length; i++)
              _buildLetter(_letters[i], _letterAnims[i], fade),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _riseIn(
                _trademarkAnim,
                fade,
                const Text('™', style: SpecText.trademark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetter(String char, Animation<double> anim, double fade) {
    final t = anim.value;
    return Opacity(
      opacity: t * fade,
      child: Transform.translate(
        offset: Offset(0, _letterRise * (1 - t)),
        child: Transform.scale(
          scale: _letterScaleFrom + (1 - _letterScaleFrom) * t,
          child: Text(char, style: SpecText.wordmark),
        ),
      ),
    );
  }

  Widget _buildRule(double ruleFade) {
    return Opacity(
      opacity: ruleFade,
      child: Transform(
        alignment: Alignment.centerLeft,
        transform: Matrix4.diagonal3Values(_ruleAnim.value, 1, 1),
        child: Container(
          width: 212,
          height: 2,
          decoration: const BoxDecoration(
            color: SpecColors.accent,
            boxShadow: [
              BoxShadow(color: SpecColors.accentGlow, blurRadius: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBlock(double fade) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: fade,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: 96,
              height: 2,
              child: ColoredBox(
                color: SpecColors.track,
                child: Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.diagonal3Values(_progressAnim.value, 1, 1),
                  child: const ColoredBox(
                    color: SpecColors.accent,
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _riseIn(
          _captionAnim,
          fade,
          const Text('OPENING YOUR LOCAL ARCHIVE', style: SpecText.caption),
        ),
      ],
    );
  }

  /// Shared opacity 0->1 plus an 8pt lift, used by the trademark, tagline and
  /// caption.
  Widget _riseIn(Animation<double> anim, double fade, Widget child) {
    final t = anim.value;
    return Opacity(
      opacity: t * fade,
      child: Transform.translate(
        offset: Offset(0, _fadeRise * (1 - t)),
        child: child,
      ),
    );
  }
}
