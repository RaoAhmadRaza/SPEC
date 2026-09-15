import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_kinds.dart';
import 'package:spec/add/add_tokens.dart';
import 'package:spec/add/photo_drop_card.dart';
import 'package:spec/add/type_tile.dart';
import 'package:spec/theme/spec_tokens.dart';

/// 22 either side, matching the object screen rather than Home's 18. The 46 at
/// the bottom clears the home indicator.
const _sheetPadding = EdgeInsets.fromLTRB(22, 14, 22, 46);
const _blockGap = 24.0;
const _handleSize = Size(38, 5);
const _handleRadius = BorderRadius.all(Radius.circular(999));

const _gridColumns = 3;
const _gridGap = 9.0;

const _continueHeight = 56.0;
const _continueRadius = BorderRadius.all(Radius.circular(999));
const _continueShadowBlur = 34.0;
const _continueShadowOffset = Offset(0, 14);

const _enterDuration = Duration(milliseconds: 560);
const _reducedEnterDuration = Duration(milliseconds: 200);

const _riseQuestion = 16.0;
const _risePhoto = 18.0;
const _riseTile = 14.0;
const _riseButton = 14.0;
const _photoEnterScale = 0.98;
const _tileEnterScale = 0.96;
const _tileEnterStagger = 0.04;
const _tileEnterSpan = 0.34;

final _types = [
  for (final MapEntry(:key, :value) in addTypeLabels.entries) (key, value),
];

/// The default when nothing upstream knows better.
const defaultAddType = AddType.device;

/// Screen 04, the add flow's manual "what" step.
///
/// This is the sheet's content only. The glass belongs to the add flow, which
/// keeps one sheet across every step, and presentation — the blurred backdrop,
/// the rise and the drag — belongs to the route, so the step can be built
/// directly in a test with no navigator.
class AddWhatSheet extends StatefulWidget {
  const AddWhatSheet({
    super.key,
    required this.onContinue,
    this.initialType = defaultAddType,
    this.pickPhoto,
  });

  /// Pre-select from whatever the caller knows: a suggestion chip from
  /// onboarding, a zone from Collections. [defaultAddType] only when nothing
  /// does.
  final AddType initialType;

  /// Carries the step's answer forward. The photo is optional.
  final void Function(AddType type, File? photo) onContinue;

  /// Opens the camera or the picker. Null leaves the card inert, which is what
  /// a test that does not care about photos wants.
  final Future<File?> Function()? pickPhoto;

  @override
  State<AddWhatSheet> createState() => _AddWhatSheetState();
}

class _AddWhatSheetState extends State<AddWhatSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: _enterDuration,
  );

  late final Animation<double> _handle = _seg(0.00, 0.22);
  late final Animation<double> _question = _seg(0.05, 0.48);
  late final Animation<double> _photo = _seg(0.18, 0.60);
  late final Animation<double> _button = _seg(0.52, 1.00);
  late final List<Animation<double>> _tiles = [
    for (var i = 0; i < _types.length; i++)
      _seg(
        0.28 + i * _tileEnterStagger,
        0.28 + i * _tileEnterStagger + _tileEnterSpan,
      ),
  ];

  bool _isMotionReduced = false;
  bool? _appliedMotionPreference;
  late AddType _selected = widget.initialType;
  File? _picked;

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
    final isReduced = MediaQuery.disableAnimationsOf(context);
    if (isReduced == _appliedMotionPreference) return;
    _appliedMotionPreference = isReduced;
    _isMotionReduced = isReduced;
    _enter
      ..duration = isReduced ? _reducedEnterDuration : _enterDuration
      ..forward();
  }

  @override
  void dispose() {
    for (final anim in [_handle, _question, _photo, _button, ..._tiles]) {
      (anim as CurvedAnimation).dispose();
    }
    _enter.dispose();
    super.dispose();
  }

  /// Under reduced motion every element shares one plain fade.
  double _opacityOf(Animation<double> segment) =>
      _isMotionReduced ? _enter.value : segment.value;

  /// Under reduced motion nothing travels or scales; only the fade remains.
  double _travelOf(Animation<double> segment, double distance) =>
      _isMotionReduced ? 0 : distance * (1 - segment.value);

  double _scaleOf(Animation<double> segment, double from) =>
      _isMotionReduced ? 1 : from + (1 - from) * segment.value;

  Future<void> _pick() async {
    final pick = widget.pickPhoto;
    if (pick == null) return;
    final photo = await pick();
    if (photo == null || !mounted) return;
    setState(() => _picked = photo);
  }

  void _onContinue() {
    HapticFeedback.mediumImpact();
    widget.onContinue(_selected, _picked);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: SpecFonts.display,
        color: SpecColors.ink,
        decoration: TextDecoration.none,
      ),
      child: Padding(
        padding: _sheetPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            const SizedBox(height: _blockGap),
            _buildQuestion(),
            const SizedBox(height: _blockGap),
            _buildPhotoCard(),
            const SizedBox(height: _blockGap),
            _buildGrid(),
            const SizedBox(height: _blockGap),
            _buildContinue(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return _enterIn(
      _handle,
      0,
      Center(
        child: SizedBox.fromSize(
          size: _handleSize,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: AddColors.handle,
              borderRadius: _handleRadius,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return _enterIn(
      _question,
      _riseQuestion,
      const Text('What are you\nremembering?', style: AddText.question),
    );
  }

  Widget _buildPhotoCard() {
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) => Opacity(
        opacity: _opacityOf(_photo),
        child: Transform.translate(
          offset: Offset(0, _travelOf(_photo, _risePhoto)),
          child: Transform.scale(
            scale: _scaleOf(_photo, _photoEnterScale),
            child: child,
          ),
        ),
      ),
      child: PhotoDropCard(
        photo: _picked,
        onPick: () => unawaited(_pick()),
        onClear: () => setState(() => _picked = null),
        isMotionReduced: _isMotionReduced,
      ),
    );
  }

  Widget _buildGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row * _gridColumns < _types.length; row++) ...[
          if (row > 0) const SizedBox(height: _gridGap),
          Row(
            children: [
              for (var column = 0; column < _gridColumns; column++) ...[
                if (column > 0) const SizedBox(width: _gridGap),
                // `minmax(0, 1fr)`: an over-long label ellipsizes rather than
                // widening its track.
                Expanded(child: _buildTile(row * _gridColumns + column)),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTile(int index) {
    final (type, label) = _types[index];
    final entry = _tiles[index];
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) => Opacity(
        opacity: _opacityOf(entry),
        child: Transform.translate(
          offset: Offset(0, _travelOf(entry, _riseTile)),
          child: Transform.scale(
            scale: _scaleOf(entry, _tileEnterScale),
            child: child,
          ),
        ),
      ),
      // The selected tile's lime is already applied at entrance; it does not
      // animate in after the fact.
      child: TypeTile(
        type: type,
        label: label,
        isSelected: type == _selected,
        isMotionReduced: _isMotionReduced,
        onTap: () => setState(() => _selected = type),
      ),
    );
  }

  Widget _buildContinue() {
    return _enterIn(
      _button,
      _riseButton,
      GestureDetector(
        onTap: _onContinue,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: _continueHeight,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: SpecColors.accent,
            borderRadius: _continueRadius,
            boxShadow: [
              BoxShadow(
                color: AddColors.continueShadow,
                blurRadius: _continueShadowBlur,
                offset: _continueShadowOffset,
              ),
            ],
          ),
          child: const Text('CONTINUE', style: SpecText.nextButton),
        ),
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
