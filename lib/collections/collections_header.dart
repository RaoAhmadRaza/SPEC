import 'package:flutter/widgets.dart';

import 'package:spec/collections/collections_models.dart';
import 'package:spec/collections/collections_tokens.dart';
import 'package:spec/home/home_glass.dart';
import 'package:spec/theme/spec_tokens.dart';
import 'package:spec/widgets/tap_target.dart';

/// The CSS numbers screen 01's pill was authored against, kept identical so
/// the two tab roots' `SPEC` pills are the same glass.
const _pillBlur = 20.0;
const _pillSaturation = 1.8;

const _pillPadding = EdgeInsets.symmetric(horizontal: 15, vertical: 8);
const _editFade = Duration(milliseconds: 180);
const _titleGap = 12.0;

/// `SPEC` on the left; `EDIT`, or `DONE` while editing, on the right.
class CollectionsHeaderRow extends StatelessWidget {
  const CollectionsHeaderRow({super.key, required this.isEditing, this.onEdit});

  final bool isEditing;

  /// Null removes the pill: the empty state has nothing to edit.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _editFade;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GlassSurface(
          borderRadius: BorderRadius.circular(999),
          blur: _pillBlur,
          saturation: _pillSaturation,
          fill: CollectionsColors.specPillFill,
          borderColor: CollectionsColors.specPillBorder,
          padding: _pillPadding,
          child: const Text('SPEC', style: SpecText.pill),
        ),
        if (onEdit case final VoidCallback onTap)
          TapTarget(
            onTap: onTap,
            child: AnimatedContainer(
              duration: duration,
              padding: _pillPadding,
              decoration: BoxDecoration(
                color: CollectionsColors.editPillFill,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isEditing
                      ? CollectionsColors.limeOutline
                      : CollectionsColors.editPillBorder,
                ),
              ),
              child: AnimatedSwitcher(
                duration: duration,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.center,
                  children: [...previous, ?current],
                ),
                child: Text(
                  isEditing ? 'DONE' : 'EDIT',
                  key: ValueKey(isEditing),
                  style: isEditing
                      ? CollectionsText.editPill.copyWith(
                          color: SpecColors.accent,
                        )
                      : CollectionsText.editPill,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// `MY / STUFF` with the right-aligned totals column beside it.
class CollectionsTitle extends StatelessWidget {
  const CollectionsTitle({
    super.key,
    required this.objects,
    required this.photos,
    required this.wrapTitle,
    required this.wrapTotal,
  });

  final int objects;
  final int photos;

  final Widget Function(Widget child) wrapTitle;

  /// Lets the screen stagger the total lines without this widget knowing the
  /// entrance timeline.
  final Widget Function(int index, Widget child) wrapTotal;

  @override
  Widget build(BuildContext context) {
    // An empty archive drops the photo count rather than showing a zero.
    final lines = [
      Text(countLabel(objects, 'OBJECT'), style: CollectionsText.totals),
      if (objects > 0)
        Text(countLabel(photos, 'PHOTO'), style: CollectionsText.totals),
      Text(
        'ON DEVICE',
        style: CollectionsText.totals.copyWith(color: SpecColors.accent),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        wrapTitle(const Text('MY\nSTUFF', style: CollectionsText.title)),
        const SizedBox(width: _titleGap),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < lines.length; i++) wrapTotal(i, lines[i]),
          ],
        ),
      ],
    );
  }
}

/// What replaces the rows before anything is saved.
class CollectionsEmptyBlock extends StatelessWidget {
  const CollectionsEmptyBlock({super.key});

  static const _padding = 22.0;
  static const _gap = 10.0;
  static const _bodyWidth = 300.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('NO ZONES\nYET.', style: CollectionsText.emptyTitle),
          const SizedBox(height: _gap),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _bodyWidth),
            child: const Text(
              'Zones appear as you save things. Add your first object and '
              'it lands in one.',
              style: CollectionsText.emptyBody,
            ),
          ),
        ],
      ),
    );
  }
}
