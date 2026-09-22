import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// The designed height, now a floor rather than a ceiling: a label that
/// needs more room at a raised text scale grows the button instead of
/// spilling out of it.
const _minButtonHeight = 60.0;

/// Air around the label. Kept small enough that a one-line label at the app's
/// 1.5 scale ceiling still fits inside [_minButtonHeight].
const _labelPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
const _bandWidth = 70.0;

/// The sweep occupies the first 60% of the cycle; the rest is a dwell with the
/// band parked off screen.
const _sweepEnd = 0.6;

/// The primary lime button, with a highlight band sweeping across it.
///
/// [shine] drives the band and is expected to repeat without reversing. The
/// band is clipped to the button, so a stopped controller parks it out of view.
class ShineButton extends StatelessWidget {
  const ShineButton({
    super.key,
    required this.label,
    required this.shine,
    required this.onPressed,
    this.bandPeak = SpecColors.shinePeak,
  });

  final String label;
  final Animation<double> shine;
  final VoidCallback onPressed;

  /// Brightest point of the sweeping band.
  final Color bandPeak;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minButtonHeight),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: SpecColors.accent,
            borderRadius: BorderRadius.all(Radius.circular(999)),
            boxShadow: [
              BoxShadow(
                color: SpecColors.buttonShadow,
                blurRadius: 44,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            child: LayoutBuilder(
              // The label sizes the Stack, so the band has to be told to fill
              // it rather than the other way round.
              builder: (context, constraints) => Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: shine,
                      builder: (context, _) => _buildBand(constraints.maxWidth),
                    ),
                  ),
                  Padding(
                    padding: _labelPadding,
                    child: Text(
                      label,
                      style: SpecText.button,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBand(double buttonWidth) {
    final progress = Curves.easeInOut.transform(
      (shine.value / _sweepEnd).clamp(0.0, 1.0),
    );
    final x = -_bandWidth + (buttonWidth + 2 * _bandWidth) * progress;
    return Transform.translate(
      offset: Offset(x, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: _bandWidth,
          height: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SpecColors.shineEdge, bandPeak, SpecColors.shineEdge],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
