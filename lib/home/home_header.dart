import 'package:flutter/widgets.dart';

import 'package:spec/home/home_card.dart';
import 'package:spec/home/home_glass.dart';
import 'package:spec/home/home_icons.dart';
import 'package:spec/home/home_models.dart';
import 'package:spec/home/home_tokens.dart';
import 'package:spec/search/search_pill.dart';
import 'package:spec/theme/spec_tokens.dart';

const _pillBlur = 20.0;
const _pillSaturation = 1.8;

/// `SPEC` pill on the left, a ••• circle on the right.
class HomeHeaderRow extends StatelessWidget {
  const HomeHeaderRow({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GlassSurface(
          borderRadius: BorderRadius.circular(999),
          blur: _pillBlur,
          saturation: _pillSaturation,
          fill: HomeColors.pillFill,
          borderColor: HomeColors.pillBorder,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: const Text('SPEC', style: SpecText.pill),
        ),
        GestureDetector(
          onTap: onMenu,
          behavior: HitTestBehavior.opaque,
          child: GlassSurface(
            borderRadius: BorderRadius.circular(999),
            blur: _pillBlur,
            saturation: _pillSaturation,
            fill: HomeColors.dotsFill,
            borderColor: HomeColors.dotsBorder,
            child: const SizedBox.square(
              dimension: 42,
              child: Center(
                child: HomeDots(
                  dotSize: 3.5,
                  gap: 3.5,
                  color: SpecColors.ink80,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The brutalist wordmark, with the mono column of promises beside it.
class HomeWordmark extends StatelessWidget {
  const HomeWordmark({super.key, required this.wrapLine});

  /// Lets the screen stagger the four mono lines without this widget knowing
  /// anything about the entrance timeline.
  final Widget Function(int index, Widget child) wrapLine;

  static const _lines = ['LOCAL', 'PRIVATE', 'YOURS', 'ALWAYS'];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Both sides are flexible so neither can push the other off the row.
        // `scaleDown` only ever shrinks, so the 72pt token is untouched
        // wherever it already fits.
        const Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SPEC', style: HomeText.wordmark),
                SizedBox(width: 3),
                // The trademark hangs from the cap line, not the baseline.
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('™', style: HomeText.trademark),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: 5),
                  wrapLine(
                    i,
                    Text(
                      _lines[i],
                      style: i == _lines.length - 1
                          ? HomeText.sideColumnAccent
                          : HomeText.sideColumn,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const SizedBox(
                  width: 22,
                  height: 1,
                  child: ColoredBox(color: HomeColors.sideRule),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width glass pill with a waveform standing in for dictation.
///
/// The shell is Search's, because this pill and Search's are the same element
/// — the Hero flies one into the other rather than cross-fading two of them.
class HomeSearchPill extends StatelessWidget {
  const HomeSearchPill({super.key, required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  /// The CSS number rather than its sigma, which is what screen 01 was
  /// authored against. The flight lerps to Search's 15.
  static const _blur = 30.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: searchPillHero(
        shell: SearchPillShell(
          borderColor: HomeColors.searchBorder,
          blur: _blur,
          bottomHighlight: HomeColors.searchUnderline,
          child: SearchPillContent(
            glyphColor: SpecColors.ink80,
            field: Text(hint, style: HomeText.searchHint),
            waveform: kFlightWaveform,
          ),
        ),
      ),
    );
  }
}

/// The scrolling rail of zones, ending in the circle that makes a new one.
class HomeCategoryRail extends StatelessWidget {
  const HomeCategoryRail({
    super.key,
    required this.categories,
    required this.onCategory,
    required this.onNewZone,
    required this.wrapChip,
  });

  final List<HomeCategory> categories;
  final ValueChanged<HomeCategory> onCategory;
  final VoidCallback onNewZone;
  final Widget Function(int index, Widget child) wrapChip;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // The chips are pills with no shadow, but the rail is clipped by the
      // page padding otherwise.
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            wrapChip(i, _CategoryChip(categories[i], onTap: onCategory)),
          ],
          if (categories.isNotEmpty) const SizedBox(width: 8),
          wrapChip(categories.length, _NewZoneButton(onTap: onNewZone)),
          if (categories.isEmpty) ...[
            const SizedBox(width: 12),
            wrapChip(
              categories.length + 1,
              const Text('NO ZONES YET', style: HomeText.hint),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(this.category, {required this.onTap});

  final HomeCategory category;
  final ValueChanged<HomeCategory> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(category),
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Level with the 42pt `+` circle beside it.
        height: 42,
        padding: const EdgeInsets.fromLTRB(11, 0, 14, 0),
        decoration: BoxDecoration(
          color: HomeColors.chipFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: HomeColors.chipBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icon(category.icon),
            const SizedBox(width: 9),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(category.label, style: HomeText.categoryName),
                const SizedBox(width: 6),
                Text('${category.count}', style: HomeText.categoryCount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _icon(HomeCategoryIcon icon) => switch (icon) {
    HomeCategoryIcon.house => const HomeIcon.house(
      size: 17,
      color: SpecColors.ink90,
    ),
    HomeCategoryIcon.car => const HomeIcon.car(
      size: 18,
      color: SpecColors.ink90,
    ),
    HomeCategoryIcon.monitor => const HomeIcon.monitor(
      size: 18,
      color: SpecColors.ink90,
    ),
  };
}

class _NewZoneButton extends StatelessWidget {
  const _NewZoneButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: HomeColors.chipFill,
          shape: BoxShape.circle,
          border: Border.all(color: HomeColors.chipBorder),
        ),
        child: const Center(child: Text('+', style: HomeText.plusSmall)),
      ),
    );
  }
}

/// `RECENTLY REMEMBERED` and its `SEE ALL ›`.
class HomeSectionRule extends StatelessWidget {
  const HomeSectionRule({
    super.key,
    required this.label,
    this.showSeeAll = false,
    this.onSeeAll,
  });

  final String label;

  /// Absent in the empty state, where there is nothing to see all of.
  final bool showSeeAll;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // The label yields rather than pushing SEE ALL off the row: the
        // action has to stay reachable at any text scale.
        Flexible(
          child: Text(
            label,
            style: HomeText.sectionRule,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showSeeAll)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('SEE ALL ›', style: HomeText.seeAll),
            ),
          ),
      ],
    );
  }
}
