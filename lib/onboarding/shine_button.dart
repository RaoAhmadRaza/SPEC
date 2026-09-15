import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

const _buttonHeight = 60.0;
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
      child: Container(
        height: _buttonHeight,
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
            builder: (context, constraints) => Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: shine,
                  builder: (context, _) => _buildBand(constraints.maxWidth),
                ),
                Center(child: Text(label, style: SpecText.button)),
              ],
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
