import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:spec/home/home_card.dart';
import 'package:spec/home/home_glass.dart';
import 'package:spec/object/object_icons.dart';
import 'package:spec/object/object_tokens.dart';
import 'package:spec/theme/spec_tokens.dart';

const _circleBlur = 10.0;
const _chipBlur = 8.0;
const _dotSize = 3.0;
const _metaPadding = 13.0;

/// A 40pt glass circle with a 44pt touch target around it.
class GlassCircle extends StatelessWidget {
  const GlassCircle({
    super.key,
    required this.onTap,
    required this.label,
    required this.child,
  });

  /// The back chevron.
  const GlassCircle.back({super.key, required this.onTap})
    : label = 'Back',
      child = const BackChevron(color: SpecColors.ink75);

  /// Three 3pt dots, 3 apart.
  const GlassCircle.more({super.key, required this.onTap})
    : label = 'More options',
      child = const HomeDots(
        dotSize: _dotSize,
        gap: _dotSize,
        color: SpecColors.ink75,
      );

  final VoidCallback onTap;

  /// What a screen reader says: the glyph alone says nothing.
  final String label;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: ObjectMetrics.minHitBox,
          child: Center(
            child: GlassSurface(
              borderRadius: BorderRadius.circular(999),
              blur: _circleBlur,
              fill: ObjectColors.circleFill,
              borderColor: ObjectColors.circleBorder,
              child: SizedBox.square(
                dimension: ObjectMetrics.circle,
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `CEILING`, on glass beside the lime zone chip.
class SubZoneChip extends StatelessWidget {
  const SubZoneChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(999),
      blur: _chipBlur,
      fill: ObjectColors.chipFill,
      borderColor: ObjectColors.chipBorder,
      padding: ObjectMetrics.chipPadding,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ObjectText.subZoneChip,
      ),
    );
  }
}

/// One metadata row: a mono label left, a mono value right, sharing a baseline
/// under a hairline.
class MetaRow extends StatelessWidget {
  const MetaRow({
    super.key,
    required this.label,
    required this.value,
    this.labelFlash,
    this.bottomPadding = _metaPadding,
  });

  final String label;
  final Widget value;

  /// 0 → 1 → 0 as the label flashes lime.
  final Animation<double>? labelFlash;

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final flash = labelFlash;
    final labelText = flash == null
        ? Text(label, style: ObjectText.metaLabel)
        : AnimatedBuilder(
            animation: flash,
            builder: (context, _) => Text(
              label,
              style: TextStyle.lerp(
                ObjectText.metaLabel,
                ObjectText.metaLabelAccent,
                flash.value,
              ),
            ),
          );

    return Container(
      padding: EdgeInsets.only(top: _metaPadding, bottom: bottomPadding),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ObjectColors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          labelText,
          const SizedBox(width: 16),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }
}

/// The spec's resting style: [base] if it fits, otherwise shrunk until it
/// does — but never below 56pt. A long spec shrinks; it does not wrap or clip.
TextStyle fitSpecStyle({
  required String text,
  required TextStyle base,
  required double maxWidth,
  required TextScaler textScaler,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: base),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();
  final width = painter.width;
  painter.dispose();

  final size = base.fontSize ?? ObjectText.spec.fontSize!;
  if (width <= maxWidth || width == 0) return base;

  final scale = math.max(maxWidth / width, ObjectMetrics.specFloor / size);
  return base.copyWith(
    fontSize: size * scale,
    letterSpacing: (base.letterSpacing ?? 0) * scale,
  );
}
