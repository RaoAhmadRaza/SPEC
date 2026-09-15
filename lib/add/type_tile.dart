import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/add/add_icons.dart';
import 'package:spec/add/add_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

const _tileHeight = 96.0;
const _tilePadding = EdgeInsets.all(13);
const _tileRadius = BorderRadius.all(Radius.circular(18));

/// Both widths draw inside the same box, so the 1 -> 1.5 swap cannot reflow
/// the grid.
const _borderWidth = 1.0;
const _selectedBorderWidth = 1.5;

/// The selected icon thickens with its border rather than only changing hue.
const _strokeWidth = 1.4;
const _selectedStrokeWidth = 1.5;

const _checkSize = 16.0;

/// The treatment cross-fade. Both tiles run it, in opposite directions.
const _treatmentDuration = Duration(milliseconds: 200);
const _checkInDuration = Duration(milliseconds: 180);
const _checkOutDuration = Duration(milliseconds: 120);

const _pressDownDuration = Duration(milliseconds: 90);
const _pressUpDuration = Duration(milliseconds: 130);
const _pressScale = 0.96;

const _instant = Duration.zero;

/// The label's weight cannot be interpolated, so it snaps at the midpoint
/// rather than being faked with a cross-fade of two Texts.
const _weightSnapPoint = 0.5;

const _tileShadowOffset = Offset(0, 12);
const _tileShadowBlur = 30.0;

/// One cell of screen 04's type grid.
///
/// Tiles are controls, not objects, so they keep radius 18 on all four corners
/// and never take the cut-corner treatment the photo card has.
class TypeTile extends StatefulWidget {
  const TypeTile({
    super.key,
    required this.type,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isMotionReduced = false,
  });

  final AddType type;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMotionReduced;

  @override
  State<TypeTile> createState() => _TypeTileState();
}

class _TypeTileState extends State<TypeTile> {
  bool _isPressed = false;

  void _setPressed(bool isPressed) {
    if (_isPressed == isPressed) return;
    setState(() => _isPressed = isPressed);
  }

  void _onTapDown(TapDownDetails details) {
    // Announce the change, not the touch: re-pressing the live tile selects
    // nothing, so it gets the press scale but no haptic.
    if (!widget.isSelected) HapticFeedback.selectionClick();
    _setPressed(true);
  }

  @override
  Widget build(BuildContext context) {
    // One-of-six is only legible to VoiceOver if the selection is announced.
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: widget.isSelected,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: (details) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: widget.isMotionReduced || !_isPressed ? 1 : _pressScale,
          duration: widget.isMotionReduced
              ? _instant
              : (_isPressed ? _pressDownDuration : _pressUpDuration),
          curve: _isPressed ? Curves.easeOut : Curves.easeOutBack,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: widget.isSelected ? 1 : 0),
            duration: widget.isMotionReduced ? _instant : _treatmentDuration,
            curve: Curves.easeOut,
            builder: (context, t, child) => _buildTile(t),
          ),
        ),
      ),
    );
  }

  /// [t] runs 0 (unselected) to 1 (selected) and drives every part of the
  /// treatment at once, so the two tiles read as one exchange.
  Widget _buildTile(double t) {
    return Container(
      height: _tileHeight,
      padding: _tilePadding,
      decoration: BoxDecoration(
        color: Color.lerp(AddColors.tileFill, AddColors.selectedTileFill, t),
        borderRadius: _tileRadius,
        border: Border.all(
          color: Color.lerp(AddColors.tileBorder, SpecColors.accent, t)!,
          width: _borderWidth + (_selectedBorderWidth - _borderWidth) * t,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(
              AddColors.tileShadowIdle,
              AddColors.selectedTileShadow,
              t,
            )!,
            blurRadius: _tileShadowBlur,
            offset: _tileShadowOffset,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AddTypeIcon(
                type: widget.type,
                color: Color.lerp(SpecColors.ink80, SpecColors.accent, t)!,
                strokeWidth:
                    _strokeWidth + (_selectedStrokeWidth - _strokeWidth) * t,
              ),
              _buildCheck(),
            ],
          ),
          Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (t >= _weightSnapPoint
                        ? AddText.tileLabelSelected
                        : AddText.tileLabel)
                    .copyWith(
                      color: Color.lerp(SpecColors.ink80, SpecColors.ink, t),
                    ),
          ),
        ],
      ),
    );
  }

  /// Always laid out, so the tile's geometry never depends on selection. A
  /// zero scale still occupies its 16pt slot.
  Widget _buildCheck() {
    return AnimatedScale(
      scale: widget.isSelected ? 1 : 0,
      duration: widget.isMotionReduced
          ? _instant
          : (widget.isSelected ? _checkInDuration : _checkOutDuration),
      curve: widget.isSelected ? Curves.easeOutBack : Curves.easeIn,
      child: Container(
        width: _checkSize,
        height: _checkSize,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: SpecColors.accent,
          shape: BoxShape.circle,
        ),
        // Decorative: the tile already announces its selected state.
        child: const ExcludeSemantics(child: Text('✓', style: AddText.check)),
      ),
    );
  }
}
