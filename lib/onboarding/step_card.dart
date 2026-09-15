import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

const _cardPadding = EdgeInsets.all(18);
const _cardBlurSigma = 13.0;
const _leadingSize = 64.0;
const _leadingRadius = 18.0;
const _rowGap = 14.0;
const _textGap = 6.0;

/// One of the three "how it works" cards.
///
/// The lime variant is the same shell with a tinted fill, a heavier border and
/// a lime shadow instead of a black one.
class StepCard extends StatelessWidget {
  const StepCard({
    super.key,
    required this.radius,
    required this.leading,
    required this.label,
    required this.title,
    required this.body,
    this.isLime = false,
  });

  final BorderRadius radius;
  final Widget leading;
  final String label;
  final String title;
  final String body;
  final bool isLime;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _cardBlurSigma,
          sigmaY: _cardBlurSigma,
        ),
        child: Container(
          padding: _cardPadding,
          decoration: BoxDecoration(
            color: isLime ? SpecColors.limeCardFill : SpecColors.cardFill,
            borderRadius: radius,
            border: Border.all(
              color: isLime ? SpecColors.limeCardBorder : SpecColors.cardBorder,
              width: isLime ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isLime
                    ? SpecColors.limeCardShadow
                    : SpecColors.cardShadow,
                blurRadius: isLime ? 50 : 44,
                offset: Offset(0, isLime ? 22 : 20),
              ),
            ],
          ),
          child: Row(
            children: [
              _LeadingSquare(isLime: isLime, child: leading),
              const SizedBox(width: _rowGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: SpecText.stepLabel),
                    const SizedBox(height: _textGap),
                    Text(title, style: SpecText.cardTitle),
                    const SizedBox(height: _textGap),
                    Text(
                      body,
                      style: isLime
                          ? SpecText.cardBodyBright
                          : SpecText.cardBody,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingSquare extends StatelessWidget {
  const _LeadingSquare({required this.isLime, required this.child});

  final bool isLime;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _leadingSize,
      height: _leadingSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isLime ? SpecColors.limeLeadingFill : SpecColors.leadingFill,
        borderRadius: BorderRadius.circular(_leadingRadius),
        border: Border.all(
          color: isLime
              ? SpecColors.limeLeadingBorder
              : SpecColors.leadingBorder,
        ),
      ),
      child: child,
    );
  }
}
