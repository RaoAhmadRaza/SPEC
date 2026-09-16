import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:spec/home/home_glass.dart';
import 'package:spec/object/object_icons.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

const _riseDuration = Duration(milliseconds: 320);

/// A damped settle rather than a bounce: fast out, then the last few points
/// arrive slowly. `easeOutBack` would overshoot, which a sheet should not do.
const _settle = Cubic(0.16, 1, 0.3, 1);

/// The page behind is blurred 4px at 30% opacity, so the sheet reads as lifted
/// off it rather than pasted on top.
const _backdropSigma = 2.0;
const _backdropOpacity = 0.30;

const _sheetRadius = BorderRadius.vertical(top: Radius.circular(30));
const _sheetBlur = 15.0;
const _sheetSaturation = 2.0;

const _itemHeight = ObjectMetrics.minHitBox + 12;
const _sheetPadding = EdgeInsets.fromLTRB(22, 10, 22, 34);
const _handleSize = Size(38, 5);

/// One row of a sheet.
@immutable
class SheetItem {
  const SheetItem({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.needsConfirmation = false,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onTap;

  /// The only non-lime accent in the app, used nowhere else.
  final bool isDestructive;

  /// Asks inside the sheet rather than stacking a dialog on top of it.
  final bool needsConfirmation;

  /// The current choice in a picker: a zone, a reminder interval.
  final bool isSelected;
}

/// Shows a glass sheet rising from the bottom over a blurred page.
Future<void> showObjectSheet(
  BuildContext context, {
  required List<SheetItem> items,
}) {
  final isMotionReduced = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: const Color(0x00000000),
      transitionDuration: isMotionReduced ? Duration.zero : _riseDuration,
      reverseTransitionDuration: isMotionReduced
          ? Duration.zero
          : _riseDuration,
      pageBuilder: (context, animation, _) =>
          _ObjectSheet(items: items, animation: animation),
    ),
  );
}

class _ObjectSheet extends StatefulWidget {
  const _ObjectSheet({required this.items, required this.animation});

  final List<SheetItem> items;
  final Animation<double> animation;

  @override
  State<_ObjectSheet> createState() => _ObjectSheetState();
}

class _ObjectSheetState extends State<_ObjectSheet> {
  /// The item awaiting a yes, asked inside the sheet.
  SheetItem? _confirming;

  late final CurvedAnimation _rise = CurvedAnimation(
    parent: widget.animation,
    curve: _settle,
  );

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  void _onItem(SheetItem item) {
    if (item.needsConfirmation && _confirming != item) {
      setState(() => _confirming = item);
      return;
    }
    Navigator.of(context).pop();
    item.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The scrim and the blur belong to the sheet, so they arrive with it.
        Positioned.fill(
          child: FadeTransition(
            opacity: widget.animation,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: _backdropSigma,
                  sigmaY: _backdropSigma,
                ),
                child: ColoredBox(
                  color: SpecColors.bg.withValues(alpha: _backdropOpacity),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_rise),
            child: _buildSheet(),
          ),
        ),
      ],
    );
  }

  Widget _buildSheet() {
    final confirming = _confirming;

    // A long zone list scrolls inside the sheet rather than running off the
    // top of the screen.
    final maxHeight =
        MediaQuery.sizeOf(context).height - ObjectMetrics.page.top;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: GlassSurface(
        borderRadius: _sheetRadius,
        blur: _sheetBlur,
        saturation: _sheetSaturation,
        fill: ObjectColors.barFill,
        borderColor: ObjectColors.barBorder,
        topHighlight: ObjectColors.barHighlight,
        padding: _sheetPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(child: _Handle()),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in widget.items)
                      _Row(
                        label: confirming == item
                            ? 'Yes, ${item.label.toLowerCase()}'
                            : item.label,
                        isDestructive: item.isDestructive || confirming == item,
                        isSelected: item.isSelected,
                        onTap: () => _onItem(item),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: _handleSize,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: ObjectColors.barHighlight,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.isDestructive,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isDestructive;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: _itemHeight,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isDestructive
                      ? ObjectText.menuItemDestructive
                      : ObjectText.menuItem,
                ),
              ),
              if (isSelected) const CheckMark(color: SpecColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
