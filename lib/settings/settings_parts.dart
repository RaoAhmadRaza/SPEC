import 'package:flutter/widgets.dart';

import 'package:spec/object/object_icons.dart';
import 'package:spec/settings/settings_icons.dart';
import 'package:spec/settings/settings_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

/// Measured off the design at its 402 × 874 canvas.
const _cardRadius = BorderRadius.all(Radius.circular(12));

/// The row sits 8pt inside the card; the text column adds 5 more. Split this
/// way because the 40pt disc has to overhang the text's padding, not add to
/// it: a card with one line of detail is 56pt, not 40 + 2 × 13.
const _cardPadding = EdgeInsets.fromLTRB(17, 8, 17, 8);
const _textPadding = EdgeInsets.symmetric(vertical: 5);
const _disc = 40.0;
const _discGlyph = 20.0;
const _discGap = 23.0;
const _labelGap = 4.0;
const _valueGap = 12.0;
const _chevronGap = 10.0;

/// Pills draw 38pt tall but take taps across 44, so the extra 3pt either side
/// is the gap between neighbours rather than a smaller target.
const _pillHeight = 38.0;
const _pillHitSlop = EdgeInsets.symmetric(vertical: 3);
const _pillPadding = EdgeInsets.fromLTRB(17, 8, 15.5, 8);
const _pillBorder = 1.5;
const _pillGlyph = 18.0;
const _pillGlyphGap = 24.0;

/// The forward chevron: the back chevron, mirrored and scaled to 7.5 × 12.
const _chevronSize = Size(7.5, 12);

/// An information card: a glyph in a disc, a mono label over a line or two
/// of detail, and an optional reading centred on the right.
///
/// With no [onTap] it is plain content, and says nothing to a screen reader
/// about being a button.
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.glyph,
    required this.label,
    required this.detail,
    this.detailStyle = SettingsText.rowDetail,
    this.value,
    this.valueStyle = SettingsText.rowValue,
    this.onTap,
  });

  final SettingsGlyph glyph;
  final String label;
  final String detail;
  final TextStyle detailStyle;

  /// `12`, `2.1 MB`, `OFF`. Null shows nothing.
  final String? value;
  final TextStyle valueStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: SettingsColors.cardFill,
        borderRadius: _cardRadius,
        border: Border.all(color: SettingsColors.cardBorder),
      ),
      child: Padding(
        padding: _cardPadding,
        child: Row(
          children: [
            _Disc(glyph),
            const SizedBox(width: _discGap),
            Expanded(
              child: Padding(padding: _textPadding, child: _buildText()),
            ),
            if (value case final value?) ...[
              const SizedBox(width: _valueGap),
              Text(value, maxLines: 1, style: valueStyle),
            ],
          ],
        ),
      ),
    );

    final onTap = this.onTap;
    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      ),
    );
  }

  Widget _buildText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SettingsText.rowLabel,
        ),
        const SizedBox(height: _labelGap),
        Text(
          detail,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: detailStyle,
        ),
      ],
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc(this.glyph);

  final SettingsGlyph glyph;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _disc,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SettingsColors.discFill,
          shape: BoxShape.circle,
          border: Border.all(color: SettingsColors.discBorder),
        ),
        child: Center(
          child: SettingsIcon(glyph, size: _discGlyph, color: SpecColors.ink80),
        ),
      ),
    );
  }
}

/// The three tones an action can take. Lime is the one thing to do, red is
/// the one thing that cannot be undone, and everything else stays quiet.
enum SettingsPillTone { accent, plain, destructive }

/// A full-width outlined action with a glyph, a mono label and a chevron.
class SettingsPill extends StatelessWidget {
  const SettingsPill({
    super.key,
    required this.glyph,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final SettingsGlyph glyph;
  final String label;
  final SettingsPillTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (ink, outline, fill) = switch (tone) {
      SettingsPillTone.accent => (
        SpecColors.accent,
        SettingsColors.accentOutline,
        SettingsColors.accentFill,
      ),
      SettingsPillTone.plain => (
        SpecColors.ink70,
        SettingsColors.plainOutline,
        SettingsColors.plainFill,
      ),
      SettingsPillTone.destructive => (
        SettingsColors.destructive,
        SettingsColors.destructiveOutline,
        SettingsColors.destructiveFill,
      ),
    };

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: _pillHitSlop,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _pillHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: outline, width: _pillBorder),
              ),
              child: Padding(
                padding: _pillPadding,
                child: Row(
                  children: [
                    SettingsIcon(glyph, size: _pillGlyph, color: ink),
                    const SizedBox(width: _pillGlyphGap),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SettingsText.pill.copyWith(color: ink),
                      ),
                    ),
                    const SizedBox(width: _chevronGap),
                    SettingsChevron(color: ink),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The forward chevron at the end of every pill.
class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: true,
      child: SizedBox.fromSize(
        size: _chevronSize,
        child: FittedBox(child: BackChevron(color: color)),
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
