import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/search/search_models.dart';
import 'package:spec/search/search_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// 54pt thumb, 14pt of padding either side of it, and the 1pt divider under.
///
/// Fixed, because the list positions its rows rather than laying them out in
/// a column: a row that survives a re-query has to travel to its new index.
const kSearchRowHeight = 83.0;

const _thumbSize = 54.0;
const _rowPadding = EdgeInsets.symmetric(vertical: 14);
const _rowGap = 14.0;
const _specGap = 16.0;
const _nameToZone = 5.0;

const _pressDuration = Duration(milliseconds: 110);

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
        height: kSearchRowHeight,
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
            _Spec(
              id: result.id,
              spec: result.spec,
              isBest: widget.isBest,
              isMotionReduced: isMotionReduced,
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
          style: SearchText.spec.copyWith(color: color ?? target),
        ),
      ),
    );
  }
}
