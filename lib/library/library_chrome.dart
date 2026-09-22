import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:spec/home/home_glass.dart';
import 'package:spec/library/library_tokens.dart';
import 'package:spec/theme/spec_layout.dart';
import 'package:spec/theme/spec_tokens.dart';

const _chipGap = 7.0;
const _chipPadding = EdgeInsets.symmetric(horizontal: 13, vertical: 8);
const _chipDuration = Duration(milliseconds: 200);
const _chipScrollDuration = Duration(milliseconds: 240);

const _countFadeDuration = Duration(milliseconds: 160);

/// The bar's designed height. [libraryBarHeight] is what anything laying out
/// against it should read.
const kLibraryBarHeight = 64.0;

/// The bar's height at the current text scale. The bar and the page's bottom
/// reserve both read this, so a bar that grows cannot end up covering the
/// last grid row. Exactly 64 at scale 1.0.
double libraryBarHeight(BuildContext context) =>
    MediaQuery.textScalerOf(context)
        .scale(kLibraryBarHeight)
        .clamp(kLibraryBarHeight, kLibraryBarHeight * SpecLayout.maxTextScale);
const _barBlur = 15.0;
const _squeezeDown = Duration(milliseconds: 100);
const _squeezeUp = Duration(milliseconds: 140);
const _squeezeScale = 0.96;

/// The category row. Exactly one chip is selected at all times.
class LibraryFilterChips extends StatelessWidget {
  const LibraryFilterChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.wrapChip,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  /// Lets the screen stagger the chips without this row knowing the timeline.
  final Widget Function(int index, Widget child) wrapChip;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (index, category) in categories.indexed) ...[
            if (index > 0) const SizedBox(width: _chipGap),
            wrapChip(
              index,
              _FilterChip(
                label: category,
                isSelected: category == selected,
                onTap: () => onSelect(category),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  void _onTap(BuildContext context) {
    unawaited(HapticFeedback.selectionClick());
    // A chip half off the edge brings itself fully into view.
    unawaited(
      Scrollable.ensureVisible(
        context,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : _chipScrollDuration,
        curve: Curves.easeOutCubic,
      ),
    );
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: isSelected ? 1 : 0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : _chipDuration,
        curve: Curves.easeOut,
        builder: (context, t, _) => Container(
          padding: _chipPadding,
          decoration: BoxDecoration(
            color: Color.lerp(LibraryColors.chipFill, SpecColors.accent, t),
            borderRadius: BorderRadius.circular(999),
            // The border never goes away, only its colour, so both states
            // have identical geometry and the row never reflows.
            border: Border.all(
              color: Color.lerp(
                LibraryColors.chipBorder,
                LibraryColors.chipBorderSelected,
                t,
              )!,
            ),
          ),
          child: Text(
            label,
            style: TextStyle.lerp(
              LibraryText.chip,
              LibraryText.chipSelected,
              t,
            ),
          ),
        ),
      ),
    );
  }
}

/// `LIBRARY · 100 OBJECTS` on the left, `OFFLINE` on the right.
class LibraryRuleRow extends StatelessWidget {
  const LibraryRuleRow({super.key, required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: LibraryColors.ruleStrong)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // The count is the long one, so it yields first and OFFLINE keeps
          // its place. Neither was flexible before, so the row overflowed.
          Flexible(
            flex: 3,
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : _countFadeDuration,
              child: Text(
                count,
                key: ValueKey(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LibraryText.ruleCount,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // A statement of fact: the library ships inside the binary.
          const Flexible(
            child: Text(
              'OFFLINE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LibraryText.offline,
            ),
          ),
        ],
      ),
    );
  }
}

/// The floating escape hatch: `Not in the list?` and `ADD YOUR OWN`.
class LibraryBottomBar extends StatelessWidget {
  const LibraryBottomBar({super.key, this.onAddOwn});

  final VoidCallback? onAddOwn;

  @override
  Widget build(BuildContext context) {
    // A tight height, not a `minHeight`: `GlassSurface` lays its child out in
    // a Stack, so a loose height paints the bar at full size while the row
    // keeps its natural height and pins to the top edge. The height still
    // tracks the text scale, which is what a `minHeight` was reaching for.
    return SizedBox(
      height: libraryBarHeight(context),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(999),
        blur: _barBlur,
        saturation: 2,
        fill: LibraryColors.barFill,
        borderColor: LibraryColors.barBorder,
        topHighlight: LibraryColors.barHighlight,
        shadows: const [
          BoxShadow(
            color: LibraryColors.barShadow,
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
        padding: const EdgeInsets.only(left: 22, right: 8),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Not in the list?',
                  style: LibraryText.barPrompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Squeeze(
                  onTap: onAddOwn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: SpecColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'ADD YOUR OWN',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LibraryText.addOwn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A medium thump and a squeeze, then the action.
///
/// The action waits for the squeeze to come back, so the press reads as the
/// cause of what happens next rather than racing it.
class Squeeze extends StatefulWidget {
  const Squeeze({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Squeeze> createState() => _SqueezeState();
}

class _SqueezeState extends State<Squeeze> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: _squeezeDown,
    reverseDuration: _squeezeUp,
  );

  Future<void> _onTap() async {
    unawaited(HapticFeedback.mediumImpact());
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _press.forward().orCancel.catchError((_) {});
      await _press.reverse().orCancel.catchError((_) {});
    }
    if (mounted) widget.onTap?.call();
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap == null ? null : () => unawaited(_onTap()),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _press,
        child: widget.child,
        builder: (context, child) {
          final isReturning = _press.status == AnimationStatus.reverse;
          final t = isReturning
              ? Curves.easeOutBack.flipped.transform(_press.value)
              : Curves.easeOut.transform(_press.value);
          return Transform.scale(
            scale: 1 - (1 - _squeezeScale) * t,
            child: child,
          );
        },
      ),
    );
  }
}
