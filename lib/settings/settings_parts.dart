import 'package:flutter/widgets.dart';

import 'package:spec/collections/collections_tokens.dart';
import 'package:spec/settings/settings_tokens.dart';
import 'package:spec/widgets/tap_target.dart';

const _chipPadding = EdgeInsets.symmetric(horizontal: 13, vertical: 8);

/// The three tones an action can take. Lime is the one thing to do, red is
/// the one thing that cannot be undone, and everything else stays quiet.
enum SettingsChipTone { accent, plain, destructive }

/// A pill-shaped mono action, drawn like Collections' `EXPORT` chip and grown
/// to a 44pt touch target without changing its size on screen.
class SettingsChip extends StatelessWidget {
  const SettingsChip({
    super.key,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final SettingsChipTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (style, fill, border) = switch (tone) {
      SettingsChipTone.accent => (
        SettingsText.chipAccent,
        CollectionsColors.limeFill,
        CollectionsColors.limeOutline,
      ),
      SettingsChipTone.plain => (
        SettingsText.chip,
        CollectionsColors.chipFill,
        CollectionsColors.chipBorder,
      ),
      SettingsChipTone.destructive => (
        SettingsText.chipDestructive,
        SettingsColors.destructiveFill,
        SettingsColors.destructiveOutline,
      ),
    };

    return Semantics(
      button: true,
      child: TapTarget(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Padding(
            padding: _chipPadding,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width one-point rule.
class SettingsRule extends StatelessWidget {
  const SettingsRule({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: ColoredBox(color: color),
    );
  }
}
