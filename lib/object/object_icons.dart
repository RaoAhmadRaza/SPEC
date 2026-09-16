import 'package:flutter/widgets.dart';

/// The back chevron, 10 × 16 on the design's 12 × 20 viewBox.
///
/// Stroked rather than a Material glyph: the icon font's chevron is a
/// different weight and a different optical size, and this screen has exactly
/// one icon on it.
class BackChevron extends StatelessWidget {
  const BackChevron({super.key, required this.color});

  final Color color;

  static const _size = Size(10, 16);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: _size,
      painter: _ChevronPainter(color),
      isComplex: false,
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  /// The viewBox the design authored `M9.5 2L2.5 10l7 8` against.
  static const _grid = Size(12, 20);
  static const _stroke = 2.2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / _grid.width, size.height / _grid.height);

    canvas.drawPath(
      Path()
        ..moveTo(9.5, 2)
        ..lineTo(2.5, 10)
        ..lineTo(9.5, 18),
      Paint()
        ..color = color
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => oldDelegate.color != color;
}

/// The tick beside the current choice in a picker sheet, 14 × 10.
class CheckMark extends StatelessWidget {
  const CheckMark({super.key, required this.color});

  final Color color;

  static const _size = Size(14, 10);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: _size,
      painter: _CheckPainter(color),
      isComplex: false,
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  static const _stroke = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(1, size.height * 0.5)
        ..lineTo(size.width * 0.36, size.height - 1)
        ..lineTo(size.width - 1, 1),
      Paint()
        ..color = color
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => oldDelegate.color != color;
}
