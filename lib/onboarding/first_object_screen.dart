import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_layout.dart';
import 'package:spec/theme/spec_tokens.dart';
import 'package:spec/widgets/tap_target.dart';

import 'capture_frame.dart';
import 'shine_button.dart';

const _ringPeriod = Duration(milliseconds: 2600);
const _shinePeriod = Duration(milliseconds: 3800);
const _enterDuration = Duration(milliseconds: 760);
const _reducedEnterDuration = Duration(milliseconds: 200);

/// How long the brackets sit at full accent after the frame is tapped.
const _flashDuration = Duration(milliseconds: 120);

/// Chip selection cross-fades rather than resizing.
const _selectDuration = Duration(milliseconds: 180);

const _suggestions = ['BULB', 'TYRE', 'CARTRIDGE', 'FILTER'];

/// Half of each chip's bob period, since the controllers yo-yo.
const _bobHalfPeriodsMs = [2500, 2800, 3100, 2600];
const _bobPhases = [0.00, 0.25, 0.42, 0.65];
const _bobDistance = 9.0;

/// Scrim over the background photograph. It keeps the lens and leaves legible
/// up top, then grounds the headline, chips and button below.
const _scrimStops = [0.0, 0.30, 0.62, 1.0];
const _scrimAlphas = [0.28, 0.42, 0.72, 0.88];

const _contentSide = 18.0;
const _contentTop = 56.0;
const _blockGap = 18.0;
const _headlineOffset = 4.0;

/// The body copy is pulled toward the headline rather than pushed away.
const _bodyPull = -8.0;
const _framePush = 2.0;
const _bodyMaxWidth = 310.0;

const _chipSpacing = 8.0;
const _chipPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 9);

const _bottomInset = 24.0;

/// 96 above the bottom inset clears the action button and its caption, so the
/// last suggestion chip scrolls out from under them rather than hiding there.
/// It tracks the text scale because the caption and the button's label both
/// grow with it; without that the chips overlap the button again at 1.5.
const _bottomBlockReserve = 96.0;
const _bottomSideInset = 16.0;
const _bottomGap = 12.0;

const _enterRiseHeadline = 22.0;
const _enterRiseBody = 14.0;
const _enterRiseChip = 10.0;
const _enterRiseActions = 12.0;
const _frameEnterScaleFrom = 0.96;
const _chipEnterStagger = 0.05;
const _chipEnterSpan = 0.35;

final _scrim = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    for (final alpha in _scrimAlphas) SpecColors.bg.withValues(alpha: alpha),
  ],
  stops: _scrimStops,
);

/// Onboarding 03, the first-object screen.
class FirstObjectScreen extends StatefulWidget {
  const FirstObjectScreen({
    super.key,
    required this.onAdd,
    required this.onLater,
    this.onCapture,
    this.preview,
  });

  /// ADD MY FIRST OBJECT, carrying the selected suggestion forward.
  final ValueChanged<String> onAdd;

  /// LATER, which completes onboarding and goes to Home.
  final VoidCallback onLater;

  /// Tapping the capture frame, which opens the camera.
  final VoidCallback? onCapture;

  /// The photo the user has taken, if they have taken one. Passed straight
  /// through to the frame, which already knows both states.
  final Widget? preview;

  @override
  State<FirstObjectScreen> createState() => _FirstObjectScreenState();
}

class _FirstObjectScreenState extends State<FirstObjectScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rings = AnimationController(
    vsync: this,
    duration: _ringPeriod,
  );
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: _shinePeriod,
  );
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _enterDuration,
  );
  late final List<AnimationController> _bobs = [
    for (final ms in _bobHalfPeriodsMs)
      AnimationController(
        vsync: this,
        duration: Duration(milliseconds: ms),
      ),
  ];

  late final Animation<double> _header = _seg(0.00, 0.28);
  late final Animation<double> _headline = _seg(0.08, 0.55);
  late final Animation<double> _body = _seg(0.20, 0.62);
  late final Animation<double> _frame = _seg(0.30, 0.80);
  late final Animation<double> _actions = _seg(0.60, 1.00);
  late final List<Animation<double>> _chipEntries = [
    for (var i = 0; i < _suggestions.length; i++)
      _seg(
        0.45 + i * _chipEnterStagger,
        0.45 + i * _chipEnterStagger + _chipEnterSpan,
      ),
  ];

  bool _isMotionReduced = false;
  bool? _appliedMotionPreference;
  bool _isFlashing = false;
  int _selected = 0;

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
      _rings.stop();
      _shine
        ..stop()
        ..value = 0;
      for (final controller in _bobs) {
        controller
          ..stop()
          ..value = 0;
      }
      _enter
        ..duration = _reducedEnterDuration
        ..forward();
      return;
    }

    _enter
      ..duration = _enterDuration
      ..forward();
    _rings.repeat();
    _shine.repeat();
    for (var i = 0; i < _bobs.length; i++) {
      _bobs[i]
        ..value = _bobPhases[i]
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final anim in [
      _header,
      _headline,
      _body,
      _frame,
      _actions,
      ..._chipEntries,
    ]) {
      (anim as CurvedAnimation).dispose();
    }
    for (final controller in [..._bobs, _rings, _shine, _enter]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Under reduced motion every element shares one plain fade.
  double _opacityOf(Animation<double> segment) =>
      _isMotionReduced ? _enter.value : segment.value;

  /// Under reduced motion nothing travels; only the fade remains.
  double _travelOf(Animation<double> segment, double distance) =>
      _isMotionReduced ? 0 : distance * (1 - segment.value);

  double _bobOf(int index) => _isMotionReduced
      ? 0
      : -_bobDistance * Curves.easeInOut.transform(_bobs[index].value);

  Future<void> _onFrameTap() async {
    setState(() => _isFlashing = true);
    widget.onCapture?.call();
    await Future<void>.delayed(_flashDuration);
    if (!mounted) return;
    setState(() => _isFlashing = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: SpecFonts.display,
        color: SpecColors.ink,
        decoration: TextDecoration.none,
      ),
      child: Builder(
        builder: (context) {
          final isExpanded = SpecLayout.isExpanded(context);
          final bottomInset = SpecLayout.bottomInset(
            context,
            design: _bottomInset,
          );
          final reserve = MediaQuery.textScalerOf(context)
              .scale(_bottomBlockReserve)
              .clamp(
                _bottomBlockReserve,
                _bottomBlockReserve * SpecLayout.maxTextScale,
              );
          return Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: SpecColors.bg),
              Image.asset(
                'assets/images/first_object_bg.png',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              DecoratedBox(
                decoration: BoxDecoration(gradient: _scrim),
                child: const SizedBox.expand(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _contentSide,
                  SpecLayout.topInset(context, design: _contentTop),
                  _contentSide,
                  0,
                ),
                child: _buildContent(isExpanded, bottomInset + reserve),
              ),
              Positioned(
                left: _bottomSideInset,
                right: _bottomSideInset,
                bottom: bottomInset,
                child: _buildBottomBlock(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The page content, in a scroll view whose bottom padding reserves the
  /// band the action button sits in.
  ///
  /// Without it the column simply runs past the viewport: it sits in a
  /// `Padding` inside an expanded `Stack`, which reports no overflow, so the
  /// button silently covers the last chips instead of anything failing.
  ///
  /// No `Spacer` or `Expanded` goes in here — the scroll view hands its child
  /// an unbounded height, and a flex child under that is a hard crash.
  Widget _buildContent(bool isExpanded, double bottomReserve) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = isExpanded
            ? math.min(constraints.maxWidth, SpecLayout.maxContentWidth)
            : constraints.maxWidth;
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomReserve),
          child: Center(
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: _blockGap + _headlineOffset),
                  _buildHeadline(),
                  const SizedBox(height: _blockGap + _bodyPull),
                  _buildBody(isExpanded),
                  const SizedBox(height: _blockGap + _framePush),
                  _buildFrame(),
                  const SizedBox(height: _blockGap),
                  _buildSuggestions(),
                ],
              ),
            ),
          ),
        );
      },
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
                child: const Text('03 / 03', style: SpecText.pill),
              ),
            ),
          ),
          TapTarget(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onLater();
            },
            child: const Text('LATER', style: SpecText.skip),
          ),
        ],
      ),
    );
  }

  /// [BoxFit.scaleDown] only ever shrinks, so the 46pt token survives intact
  /// at the reference canvas and a narrow phone or a raised text scale shrinks
  /// the headline instead of clipping it.
  Widget _buildHeadline() {
    return _enterIn(
      _headline,
      _enterRiseHeadline,
      const Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'REMEMBER\nONE THING.',
            style: SpecText.firstObjectHeadline,
            maxLines: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isExpanded) {
    return _enterIn(
      _body,
      _enterRiseBody,
      Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isExpanded ? SpecLayout.maxContentWidth : _bodyMaxWidth,
          ),
          child: const Text(
            "Pick something within arm's reach. "
            'The bulb above you is a good start.',
            style: SpecText.bodyCopy,
          ),
        ),
      ),
    );
  }

  Widget _buildFrame() {
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final entry = _opacityOf(_frame);
        return Opacity(
          opacity: entry,
          child: Transform.scale(
            scale: _isMotionReduced
                ? 1
                : _frameEnterScaleFrom + (1 - _frameEnterScaleFrom) * entry,
            child: child,
          ),
        );
      },
      child: CaptureFrame(
        rings: _rings,
        onTap: _onFrameTap,
        isMotionReduced: _isMotionReduced,
        isFlashing: _isFlashing,
        preview: widget.preview,
      ),
    );
  }

  Widget _buildSuggestions() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: _chipSpacing,
        runSpacing: _chipSpacing,
        children: [for (var i = 0; i < _suggestions.length; i++) _buildChip(i)],
      ),
    );
  }

  Widget _buildChip(int index) {
    final isSelected = index == _selected;
    return AnimatedBuilder(
      animation: Listenable.merge([_bobs[index], _enter]),
      builder: (context, child) {
        final entry = _chipEntries[index];
        return Opacity(
          opacity: _opacityOf(entry),
          child: Transform.translate(
            offset: Offset(0, _bobOf(index) + _travelOf(entry, _enterRiseChip)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selected = index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: _selectDuration,
          curve: Curves.easeOut,
          padding: _chipPadding,
          decoration: BoxDecoration(
            color: isSelected ? SpecColors.accent : SpecColors.suggestionFill,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            // The selected chip keeps a transparent border so swapping styles
            // never changes its size and the row cannot reflow.
            border: Border.all(
              color: isSelected
                  ? const Color(0x00000000)
                  : SpecColors.suggestionBorder,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: _selectDuration,
            curve: Curves.easeOut,
            style: isSelected
                ? SpecText.suggestionSelected
                : SpecText.suggestion,
            child: Text(_suggestions[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBlock() {
    return _enterIn(
      _actions,
      _enterRiseActions,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShineButton(
            label: 'ADD MY FIRST OBJECT',
            shine: _shine,
            bandPeak: SpecColors.shinePeakSoft,
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.onAdd(_suggestions[_selected]);
            },
          ),
          const SizedBox(height: _bottomGap),
          const Text(
            'CAMERA IS USED ON DEVICE ONLY',
            style: SpecText.frameCaption,
            textAlign: TextAlign.center,
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
