import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

const _frameHeight = 236.0;
const _bracketSize = 26.0;
const _bracketInset = 16.0;
const _bracketStroke = 2.0;

/// Radius of the turn on a bracket's outer corner.
const _bracketTurn = 6.0;

const _ringSize = 76.0;
const _ringStroke = 1.5;
const _ringScaleFrom = 0.82;
const _ringScaleTo = 1.5;
const _ringOpacity = 0.75;

/// A ring sits at rest under reduced motion rather than pulsing.
const _ringRestOpacity = 0.35;

const _corners = [
  Alignment.topLeft,
  Alignment.topRight,
  Alignment.bottomLeft,
  Alignment.bottomRight,
];

/// One cut corner, bottom-left, matching the step cards' language.
const _frameRadius = BorderRadius.only(
  topLeft: Radius.circular(24),
  topRight: Radius.circular(24),
  bottomRight: Radius.circular(24),
  bottomLeft: Radius.circular(8),
);

/// The camera-style capture target.
///
/// Empty it is a flat tile: no placeholder icon, no label. The only motion is
/// the pair of rings pulsing out of its centre.
class CaptureFrame extends StatelessWidget {
  const CaptureFrame({
    super.key,
    required this.rings,
    required this.onTap,
    this.isMotionReduced = false,
    this.isFlashing = false,
    this.preview,
  });

  /// Drives both rings. Expected to repeat without reversing.
  final Animation<double> rings;
  final VoidCallback onTap;
  final bool isMotionReduced;

  /// Brackets go to full accent while a capture is being opened.
  final bool isFlashing;

  /// The live camera preview or the picked photo, if there is one.
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: _frameHeight,
        decoration: BoxDecoration(
          color: SpecColors.tile,
          borderRadius: _frameRadius,
          border: Border.all(color: SpecColors.frameBorder),
        ),
        child: ClipRRect(
          borderRadius: _frameRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ?preview,
              IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    for (final corner in _corners)
                      _Bracket(corner: corner, isFlashing: isFlashing),
                    Center(child: _buildRings()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRings() {
    if (isMotionReduced) {
      return const Opacity(opacity: _ringRestOpacity, child: _RingOutline());
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        for (final phase in [0.0, 0.5]) _buildRing(phase),
      ],
    );
  }

  /// Two rings share one controller half a cycle apart, so a new one starts as
  /// the previous reaches full scale and zero opacity.
  Widget _buildRing(double phase) {
    return AnimatedBuilder(
      animation: rings,
      builder: (context, child) {
        final t = Curves.easeOut.transform((rings.value + phase) % 1.0);
        return Opacity(
          opacity: _ringOpacity * (1 - t),
          child: Transform.scale(
            scale: _ringScaleFrom + (_ringScaleTo - _ringScaleFrom) * t,
            child: child,
          ),
        );
      },
      child: const _RingOutline(),
    );
  }
}

class _RingOutline extends StatelessWidget {
  const _RingOutline();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ringSize,
      height: _ringSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: SpecColors.ring, width: _ringStroke),
      ),
    );
  }
}

class _Bracket extends StatelessWidget {
  const _Bracket({required this.corner, required this.isFlashing});

  final Alignment corner;
  final bool isFlashing;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: corner,
      child: Padding(
        padding: const EdgeInsets.all(_bracketInset),
        child: CustomPaint(
          size: const Size.square(_bracketSize),
          painter: _BracketPainter(
            corner: corner,
            color: isFlashing ? SpecColors.accent : SpecColors.bracket,
          ),
        ),
      ),
    );
  }
}

/// Strokes the two outer edges of one corner. The shape is authored for the
/// top-left corner and mirrored onto the other three.
class _BracketPainter extends CustomPainter {
  const _BracketPainter({required this.corner, required this.color});

  final Alignment corner;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(corner.x < 0 ? 1 : -1, corner.y < 0 ? 1 : -1);
    canvas.translate(-size.width / 2, -size.height / 2);

    const edge = _bracketStroke / 2;
    final path = Path()
      ..moveTo(edge, size.height)
      ..lineTo(edge, edge + _bracketTurn)
      ..arcToPoint(
        Offset(edge + _bracketTurn, edge),
        radius: const Radius.circular(_bracketTurn),
      )
      ..lineTo(size.width, edge);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _bracketStroke
        ..strokeCap = StrokeCap.round
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BracketPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.corner != corner;
}
