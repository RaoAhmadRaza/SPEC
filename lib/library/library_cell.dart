import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/library/library_models.dart';
import 'package:spec/library/library_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

const kLibraryThumbHeight = 84.0;
const _thumbToName = 7.0;

/// The column gap is 7, and the spec line pulls itself up by 4 of it.
const _nameToSpec = 3.0;

const _pressDuration = Duration(milliseconds: 100);
const _pressScale = 0.96;

/// The example spec clears in place when its cell is picked.
const _specFadeDuration = Duration(milliseconds: 140);

const _big = Radius.circular(16);
const _cut = Radius.circular(5);

/// The cut corner walks around the thumb in reading order: bottom-left,
/// bottom-right, top-right, top-left.
const kLibraryCuts = [
  BorderRadius.only(
    topLeft: _big,
    topRight: _big,
    bottomRight: _big,
    bottomLeft: _cut,
  ),
  BorderRadius.only(
    topLeft: _big,
    topRight: _big,
    bottomRight: _cut,
    bottomLeft: _big,
  ),
  BorderRadius.only(
    topLeft: _big,
    topRight: _cut,
    bottomRight: _big,
    bottomLeft: _big,
  ),
  BorderRadius.only(
    topLeft: _cut,
    topRight: _big,
    bottomRight: _big,
    bottomLeft: _big,
  ),
];

BorderRadius libraryCutFor(int index) => kLibraryCuts[index % 4];

/// A cell's height, measured from the two text styles it draws.
///
/// The grid positions cells rather than laying them out, so it needs the
/// height up front; measuring the real styles keeps that honest at any text
/// scale.
double libraryCellHeight(BuildContext context) {
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

  return kLibraryThumbHeight +
      _thumbToName +
      lineOf(LibraryText.itemName) +
      _nameToSpec +
      lineOf(LibraryText.itemSpec);
}

/// One library object: a cut-corner thumb, the name, an example spec.
class LibraryCell extends StatefulWidget {
  const LibraryCell({
    super.key,
    required this.item,
    required this.index,
    this.isPicked = false,
    this.onTap,
  });

  final LibraryItem item;

  /// The cell's place in the grid, which decides its cut corner.
  final int index;

  /// Picked cells clear their example spec: it was never the user's value.
  final bool isPicked;

  final VoidCallback? onTap;

  @override
  State<LibraryCell> createState() => _LibraryCellState();
}

class _LibraryCellState extends State<LibraryCell> {
  bool _isPressed = false;

  void _setPressed(bool isPressed) {
    if (isPressed != _isPressed) setState(() => _isPressed = isPressed);
  }

  void _onTap() {
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isMotionReduced = MediaQuery.disableAnimationsOf(context);

    return GestureDetector(
      onTap: _onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed && !isMotionReduced ? _pressScale : 1,
        duration: _pressDuration,
        curve: Curves.easeOut,
        // Reduce Motion picks with a cross-fade and no flight.
        child: HeroMode(
          enabled: !isMotionReduced,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'lib-${item.id}-photo',
                child: _Thumb(item: item, radius: libraryCutFor(widget.index)),
              ),
              const SizedBox(height: _thumbToName),
              Hero(
                tag: 'lib-${item.id}-name',
                child: Text(
                  item.name,
                  style: LibraryText.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: _nameToSpec),
              // Never a Hero: the example spec stays behind and fades, so it
              // visibly does not become the user's value.
              AnimatedOpacity(
                opacity: widget.isPicked ? 0 : 1,
                duration: isMotionReduced ? Duration.zero : _specFadeDuration,
                child: Text(
                  item.exampleSpec,
                  style: LibraryText.itemSpec,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item, required this.radius});

  final LibraryItem item;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kLibraryThumbHeight,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SpecColors.tile,
        borderRadius: radius,
        border: Border.all(color: LibraryColors.thumbBorder),
      ),
      // A missing or undecodable image leaves the flat tile: no icon, no
      // label, no broken-image glyph.
      child: switch (item.asset) {
        final String asset => Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        null => null,
      },
    );
  }
}
