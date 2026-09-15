import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// Five bars, bottom-aligned, at the design's heights.
const _barHeights = [7.0, 14.0, 18.0, 11.0, 6.0];

/// Per-bar offsets into the cycle, so the row ripples rather than pumping.
const _barPhases = [0.0, 0.20, 0.45, 0.65, 0.85];

const _barWidth = 2.0;
const _barGap = 2.5;
const _boxHeight = 18.0;

/// A querying bar shrinks to this fraction of its resting height.
const _duck = 0.45;

const _cycle = Duration(milliseconds: 900);
const _settleDuration = Duration(milliseconds: 260);

const _restingOpacity = 0.45;
const _activeOpacity = 0.75;

/// What the waveform is reporting.
enum WaveformState {
  /// No query yet. The bars hold their static heights.
  resting,

  /// A keystroke has landed and the query is in flight.
  querying,

  /// Results are on screen. The bars ease back to their static heights.
  settled,
}

/// A live indicator of query state, not decoration.
///
/// Heights animate from the bottom — the bars are bottom-aligned, so only
/// their top edge moves.
class SearchWaveform extends StatefulWidget {
  const SearchWaveform({super.key, required this.state});

  final WaveformState state;

  @override
  State<SearchWaveform> createState() => _SearchWaveformState();
}

class _SearchWaveformState extends State<SearchWaveform>
    with TickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: _cycle,
  );

  /// How much of the ripple to apply. Settling eases this to zero, which is
  /// what returns the bars to their static heights without a second curve.
  late final AnimationController _amplitude = AnimationController(
    vsync: this,
    duration: _settleDuration,
  );

  bool _isMotionReduced = false;
  bool? _appliedMotionPreference;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isReduced = MediaQuery.disableAnimationsOf(context);
    if (isReduced != _appliedMotionPreference) {
      _appliedMotionPreference = isReduced;
      _isMotionReduced = isReduced;
      _syncMotion();
    }
    _syncState();
  }

  @override
  void didUpdateWidget(SearchWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncState();
  }

  void _syncMotion() {
    if (_isMotionReduced) {
      _wave
        ..stop()
        ..value = 0;
      _amplitude.value = 0;
      return;
    }
    if (!_wave.isAnimating) _wave.repeat(reverse: true);
  }

  void _syncState() {
    if (_isMotionReduced) return;
    switch (widget.state) {
      // The ripple starts at full depth: a keystroke is not a fade-in.
      case WaveformState.querying:
        _amplitude.value = 1;
      case WaveformState.settled:
        _amplitude.animateBack(0, curve: Curves.easeOut);
      case WaveformState.resting:
        _amplitude.value = 0;
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    _amplitude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.state == WaveformState.resting
        ? _restingOpacity
        : _activeOpacity;

    return SizedBox(
      height: _boxHeight,
      child: AnimatedBuilder(
        animation: Listenable.merge([_wave, _amplitude]),
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _barHeights.length; i++) ...[
              if (i > 0) const SizedBox(width: _barGap),
              _bar(_heightOf(i), opacity),
            ],
          ],
        ),
      ),
    );
  }

  double _heightOf(int index) {
    final base = _barHeights[index];
    final amplitude = _amplitude.value;
    if (amplitude == 0) return base;
    final phase = Curves.easeInOut.transform(
      (_wave.value + _barPhases[index]) % 1.0,
    );
    final ducked = lerpDouble(base, base * _duck, phase)!;
    return lerpDouble(base, ducked, amplitude)!;
  }

  static Widget _bar(double height, double opacity) => Container(
    width: _barWidth,
    height: height,
    decoration: BoxDecoration(
      color: SpecColors.ink.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

/// The waveform as the Hero flight draws it: static, and never ticking.
///
/// The live widget owns two controllers; a second copy of it in the flight
/// overlay would animate independently of the one it is standing in for.
class StaticWaveform extends StatelessWidget {
  const StaticWaveform({super.key, this.opacity = _activeOpacity});

  final double opacity;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _boxHeight,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _barHeights.length; i++) ...[
          if (i > 0) const SizedBox(width: _barGap),
          _SearchWaveformState._bar(_barHeights[i], opacity),
        ],
      ],
    ),
  );
}
