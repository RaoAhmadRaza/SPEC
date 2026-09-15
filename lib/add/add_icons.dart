import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The rendered box. Every icon is authored in its own viewBox and fitted into
/// this square the way the design file's SVGs are.
const double addIconSize = 20;

/// The six object types, in reading order.
enum AddType { product, device, car, home, clothing, other }

/// A stroked type icon. Deliberately a path, never a Material glyph.
class AddTypeIcon extends StatelessWidget {
  const AddTypeIcon({
    super.key,
    required this.type,
    required this.color,
    required this.strokeWidth,
  });

  final AddType type;
  final Color color;

  /// In viewBox units, so it scales with the icon exactly as `stroke-width`
  /// does in the SVG.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(addIconSize),
      painter: _TypeIconPainter(
        type: type,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

/// The authored size of each icon's viewBox. Three of them are shorter than
/// they are wide, which `xMidYMid meet` centres vertically in the 20pt box.
const _viewBoxes = <AddType, Size>{
  AddType.product: Size(20, 20),
  AddType.device: Size(20, 20),
  AddType.car: Size(20, 18),
  AddType.home: Size(18, 18),
  AddType.clothing: Size(20, 18),
  AddType.other: Size(20, 20),
};

class _TypeIconPainter extends CustomPainter {
  const _TypeIconPainter({
    required this.type,
    required this.color,
    required this.strokeWidth,
  });

  final AddType type;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final viewBox = _viewBoxes[type]!;
    final scale = math.min(
      size.width / viewBox.width,
      size.height / viewBox.height,
    );

    canvas.save();
    // `preserveAspectRatio="xMidYMid meet"`: fit uniformly, then centre.
    canvas.translate(
      (size.width - viewBox.width * scale) / 2,
      (size.height - viewBox.height * scale) / 2,
    );
    canvas.scale(scale);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color
      ..isAntiAlias = true;

    switch (type) {
      case AddType.product:
        _paintProduct(canvas, paint);
      case AddType.device:
        _paintDevice(canvas, paint);
      case AddType.car:
        _paintPath(canvas, paint, _carPath);
      case AddType.home:
        _paintPath(canvas, paint, _homePath);
      case AddType.clothing:
        _paintPath(canvas, paint, _clothingPath);
      case AddType.other:
        _paintOther(canvas, paint);
    }

    canvas.restore();
  }

  void _paintProduct(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 5.5, 14, 10),
        const Radius.circular(1.6),
      ),
      paint,
    );
    paint.strokeCap = StrokeCap.round;
    for (final x in [7.0, 13.0]) {
      canvas.drawLine(Offset(x, 15.5), Offset(x, 16.9), paint);
    }
  }

  void _paintDevice(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 4, 12, 8.4),
        const Radius.circular(1.3),
      ),
      paint,
    );
    paint.strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(2.4, 15.4), const Offset(17.6, 15.4), paint);
  }

  void _paintOther(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(10, 10), 6.4, paint);
    paint.strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(10, 6.6), const Offset(10, 13.4), paint);
    canvas.drawLine(const Offset(6.6, 10), const Offset(13.4, 10), paint);
  }

  void _paintPath(Canvas canvas, Paint paint, Path Function() build) {
    canvas.drawPath(build(), paint..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_TypeIconPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.type != type;
}

/// `M3 11.5l1.6-4.3A2 2 0 016.5 6h7a2 2 0 011.9 1.2L17 11.5v3.2h-2.2v-1.4H5.2v1.4H3v-3.2z`
Path _carPath() => Path()
  ..moveTo(3, 11.5)
  ..relativeLineTo(1.6, -4.3)
  ..arcToPoint(const Offset(6.5, 6), radius: const Radius.circular(2))
  ..relativeLineTo(7, 0)
  ..relativeArcToPoint(const Offset(1.9, 1.2), radius: const Radius.circular(2))
  ..lineTo(17, 11.5)
  ..relativeLineTo(0, 3.2)
  ..relativeLineTo(-2.2, 0)
  ..relativeLineTo(0, -1.4)
  ..lineTo(5.2, 13.3)
  ..relativeLineTo(0, 1.4)
  ..lineTo(3, 14.7)
  ..relativeLineTo(0, -3.2)
  ..close();

/// `M2.5 8L9 2.8L15.5 8v6.6a.9.9 0 01-.9.9H3.4a.9.9 0 01-.9-.9V8z`
Path _homePath() => Path()
  ..moveTo(2.5, 8)
  ..lineTo(9, 2.8)
  ..lineTo(15.5, 8)
  ..relativeLineTo(0, 6.6)
  ..relativeArcToPoint(
    const Offset(-0.9, 0.9),
    radius: const Radius.circular(0.9),
  )
  ..lineTo(3.4, 15.5)
  ..relativeArcToPoint(
    const Offset(-0.9, -0.9),
    radius: const Radius.circular(0.9),
  )
  ..lineTo(2.5, 8)
  ..close();

/// `M10 4.6a1.5 1.5 0 111.3 1.5c-.7.1-1.3.5-1.3 1.3M3 13.6l7-4.2 7 4.2v1.2H3v-1.2z`
Path _clothingPath() => Path()
  ..moveTo(10, 4.6)
  ..relativeArcToPoint(
    const Offset(1.3, 1.5),
    radius: const Radius.circular(1.5),
    largeArc: true,
  )
  ..relativeCubicTo(-0.7, 0.1, -1.3, 0.5, -1.3, 1.3)
  ..moveTo(3, 13.6)
  ..relativeLineTo(7, -4.2)
  ..relativeLineTo(7, 4.2)
  ..relativeLineTo(0, 1.2)
  ..lineTo(3, 14.8)
  ..relativeLineTo(0, -1.2)
  ..close();
