import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/add/add_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// Step 04's card: 132 tall, one cut corner bottom-left, the same language
/// the object tiles speak.
const addPhotoCardHeight = 132.0;
const addPhotoCardRadius = BorderRadius.only(
  topLeft: Radius.circular(20),
  topRight: Radius.circular(20),
  bottomRight: Radius.circular(20),
  bottomLeft: Radius.circular(6),
);

const _chipInset = 12.0;
const _chipPadding = EdgeInsets.symmetric(horizontal: 11, vertical: 6);
const _chipRadius = BorderRadius.all(Radius.circular(999));

/// CSS `backdrop-filter: blur(14px)` is sigma 7.
const _chipBlur = 7.0;

const _clearSize = 26.0;

const _pressDuration = Duration(milliseconds: 110);
const _pressScale = 0.985;

const _photoFadeDuration = Duration(milliseconds: 260);

/// Step 04 cross-fades the chip with the photo; 08 names a quicker 180.
const _chipFadeDuration = _photoFadeDuration;
const _photoClearDuration = Duration(milliseconds: 200);
const _clearInDuration = Duration(milliseconds: 180);

const _instant = Duration.zero;

/// The photo step is optional, so empty is a first-class state: a flat tile
/// with only the chip on it. No dashed border, no centred icon, no body label.
class PhotoDropCard extends StatefulWidget {
  const PhotoDropCard({
    super.key,
    required this.photo,
    required this.onPick,
    required this.onClear,
    this.isMotionReduced = false,
    this.height = addPhotoCardHeight,
    this.borderRadius = addPhotoCardRadius,
    this.chipFadeDuration = _chipFadeDuration,
  });

  final File? photo;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool isMotionReduced;
  final double height;
  final BorderRadius borderRadius;
  final Duration chipFadeDuration;

  @override
  State<PhotoDropCard> createState() => _PhotoDropCardState();
}

class _PhotoDropCardState extends State<PhotoDropCard> {
  bool _isPressed = false;

  bool get _hasPhoto => widget.photo != null;

  void _setPressed(bool isPressed) {
    if (_isPressed == isPressed) return;
    setState(() => _isPressed = isPressed);
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onPick();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _setPressed(true),
      onTapUp: (details) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: widget.isMotionReduced || !_isPressed ? 1 : _pressScale,
        duration: widget.isMotionReduced ? _instant : _pressDuration,
        curve: Curves.easeOut,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: SpecColors.tile,
            borderRadius: widget.borderRadius,
            border: Border.all(color: AddColors.cardBorder),
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPhoto(),
                Positioned(
                  left: _chipInset,
                  top: _chipInset,
                  child: IgnorePointer(child: _buildChip()),
                ),
                Positioned(
                  right: _chipInset,
                  top: _chipInset,
                  child: _buildClear(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Contain, on the card's own dark tile: a cover crop cuts the text off a
  /// portrait shot of a label, and the label is what the photo is for.
  Widget _buildPhoto() {
    return AnimatedSwitcher(
      duration: widget.isMotionReduced ? _instant : _photoFadeDuration,
      reverseDuration: widget.isMotionReduced ? _instant : _photoClearDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: widget.photo == null
          ? const SizedBox.shrink()
          : Image.file(
              widget.photo!,
              key: ValueKey<String>(widget.photo!.path),
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
    );
  }

  /// The chip and the clear disc share one glass recipe, which is what makes
  /// them read as a pair sitting on the photo rather than in the card.
  Widget _buildGlass({required EdgeInsets padding, required Widget child}) {
    return ClipRRect(
      borderRadius: _chipRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _chipBlur, sigmaY: _chipBlur),
        child: Container(
          padding: padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AddColors.chipFill,
            borderRadius: _chipRadius,
            border: Border.all(color: AddColors.chipBorder),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildChip() {
    return _buildGlass(
      padding: _chipPadding,
      child: AnimatedSwitcher(
        duration: widget.isMotionReduced ? _instant : widget.chipFadeDuration,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeOut,
        child: Text(
          _hasPhoto ? 'RETAKE' : '+ PHOTO',
          key: ValueKey<bool>(_hasPhoto),
          style: AddText.photoChip,
        ),
      ),
    );
  }

  Widget _buildClear() {
    return AnimatedScale(
      scale: _hasPhoto ? 1 : 0,
      duration: widget.isMotionReduced ? _instant : _clearInDuration,
      // easeOutBack only on the way in: run toward zero it overshoots past
      // it, and a negative scale flashes the disc mirrored.
      curve: _hasPhoto ? Curves.easeOutBack : Curves.easeIn,
      child: Semantics(
        button: true,
        label: 'Remove photo',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: _hasPhoto ? widget.onClear : null,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: _clearSize,
            height: _clearSize,
            child: _buildGlass(
              padding: EdgeInsets.zero,
              child: const Text('×', style: AddText.photoChip),
            ),
          ),
        ),
      ),
    );
  }
}
