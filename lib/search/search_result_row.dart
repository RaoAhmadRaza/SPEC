import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/search/search_models.dart';
import 'package:spec/search/search_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// 54pt thumb, 14pt of padding either side of it, and the 1pt divider under.
///
/// The reference height, which [searchRowHeight] returns at scale 1.0.
///
/// The list positions its rows rather than laying them out in a column — a
/// row that survives a re-query travels to its new index — so the height has
/// to be known up front rather than discovered from the content.
const kSearchRowHeight = 83.0;

const _thumbSize = 54.0;
const _rowPadding = EdgeInsets.symmetric(vertical: 14);
const _rowGap = 14.0;
const _specGap = 16.0;
const _nameToZone = 5.0;

const _hairline = 1.0;

const _pressDuration = Duration(milliseconds: 110);

/// A row's height at the current text scale, measured from the two styles it
/// draws — the same technique `libraryCellHeight` uses for its grid.
///
/// Never below [kSearchRowHeight], so the reference canvas is untouched: at
/// scale 1.0 the 54pt thumb is taller than the text and sets the height
/// anyway. Above it, the text wins and the rows grow instead of overlapping,
/// which is what index-positioned rows do when the height lies.
double searchRowHeight(BuildContext context) {
  final scaler = MediaQuery.textScalerOf(context);
  double lineOf(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: 'Hg', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  final text = lineOf(SearchText.name) + _nameToZone + lineOf(SearchText.zone);
  return math.max(
    kSearchRowHeight,
    _rowPadding.vertical + math.max(_thumbSize, text) + _hairline,
  );
}

/// The lime moves with the best match rather than cutting to it.
const _bestMatchDuration = Duration(milliseconds: 200);

/// The thumb cuts its bottom-left corner; the other three are 16. Public so
/// screen 03's photo can fly from exactly this shape.
const kSearchThumbRadius = BorderRadius.only(
  topLeft: Radius.circular(16),
  topRight: Radius.circular(16),
  bottomRight: Radius.circular(16),
  bottomLeft: Radius.circular(5),
);

/// One result: thumb, name, zone line, and the spec set large and right.
class SearchResultRow extends StatefulWidget {
  const SearchResultRow({
    super.key,
    required this.result,
    required this.isBest,
    this.onTap,
  });

  final SearchResult result;

  /// Marks the best match, not a selection. Never true for more than one row.
  final bool isBest;

  final VoidCallback? onTap;

  @override
  State<SearchResultRow> createState() => _SearchResultRowState();
}

class _SearchResultRowState extends State<SearchResultRow> {
  bool _isPressed = false;

  void _setPressed(bool isPressed) {
    if (isPressed == _isPressed) return;
    setState(() => _isPressed = isPressed);
  }

  void _onTap() {
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isMotionReduced = MediaQuery.disableAnimationsOf(context);

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: isMotionReduced ? Duration.zero : _pressDuration,
        curve: Curves.easeOut,
        height: searchRowHeight(context),
        padding: _rowPadding,
        decoration: BoxDecoration(
          color: _isPressed ? SearchColors.rowPress : null,
          border: const Border(
            bottom: BorderSide(color: SearchColors.hairline),
          ),
        ),
        child: Row(
          children: [
            _Thumb(result: result),
            const SizedBox(width: _rowGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.name,
                    style: SearchText.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: _nameToZone),
                  Text(
                    result.zoneLine,
                    style: SearchText.zone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: _specGap),
            // Flexible so a long spec yields instead of squeezing the name
            // column to nothing and then overflowing the row.
            Flexible(
              child: _Spec(
                id: result.id,
                spec: result.spec,
                isBest: widget.isBest,
                isMotionReduced: isMotionReduced,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.result});

  final SearchResult result;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'obj-${result.id}-photo',
      child: Container(
        width: _thumbSize,
        height: _thumbSize,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // A missing photo is a flat tile: no icon, no label.
          color: SpecColors.tile,
          borderRadius: kSearchThumbRadius,
          border: Border.all(color: SearchColors.thumbBorder),
        ),
        child: switch (result.photo) {
          final ImageProvider photo => Image(image: photo, fit: BoxFit.cover),
          null => null,
        },
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec({
    required this.id,
    required this.spec,
    required this.isBest,
    required this.isMotionReduced,
  });

  final int id;
  final String spec;
  final bool isBest;
  final bool isMotionReduced;

  @override
  Widget build(BuildContext context) {
    final target = isBest ? SpecColors.accent : SpecColors.ink;
    return Hero(
      tag: 'obj-$id-spec',
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: target),
        duration: isMotionReduced ? Duration.zero : _bestMatchDuration,
        curve: Curves.easeOut,
        builder: (context, color, _) => Text(
          spec,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SearchText.spec.copyWith(color: color ?? target),
        ),
      ),
    );
  }
}
