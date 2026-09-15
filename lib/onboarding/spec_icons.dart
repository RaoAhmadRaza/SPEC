import 'package:flutter/widgets.dart';

import 'package:spec/theme/spec_tokens.dart';

/// Icons are authored on a 24 x 24 grid and scaled to the rendered box, the
/// same way the design file's SVGs are.
const _grid = 24.0;
const _strokeWidth = 1.5;
const _iconSize = 26.0;

/// A stroked outline icon. Deliberately not a Material glyph.
class SpecIcon extends StatelessWidget {
  const SpecIcon.camera({super.key}) : _painter = const _CameraPainter();
  const SpecIcon.search({super.key}) : _painter = const _SearchPainter();

  final CustomPainter _painter;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size.square(_iconSize), painter: _painter);
  }
}

Paint _strokePaint(double scale) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = _strokeWidth
  ..color = SpecColors.ink
  ..isAntiAlias = true;

class _CameraPainter extends CustomPainter {
  const _CameraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _grid;
    canvas.save();
    canvas.scale(scale);

    final paint = _strokePaint(scale);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 6.5, 18, 13),
        const Radius.circular(2.4),
      ),
      paint,
    );
    canvas.drawCircle(const Offset(12, 13), 3.6, paint);

    // The hump over the lens, joined rather than capped.
    final hump = Path()
      ..moveTo(8.6, 6.5)
      ..relativeLineTo(1.2, -2)
      ..relativeLineTo(4.4, 0)
      ..relativeLineTo(1.2, 2);
    canvas.drawPath(hump, paint..strokeJoin = StrokeJoin.round);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CameraPainter oldDelegate) => false;
}

class _SearchPainter extends CustomPainter {
  const _SearchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _grid;
    canvas.save();
    canvas.scale(scale);

    final paint = _strokePaint(scale);
    canvas.drawCircle(const Offset(10.5, 10.5), 6.4, paint);
    canvas.drawLine(
      const Offset(15.4, 15.4),
      const Offset(20, 20),
      paint..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SearchPainter oldDelegate) => false;
}
