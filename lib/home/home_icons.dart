import 'package:flutter/widgets.dart';

/// Stroked outline icons for screen 01, authored on the same viewBoxes the
/// design file's SVGs use and scaled to the rendered box.
///
/// Deliberately not Material glyphs, and deliberately separate from
/// `SpecIcon`: none of these shapes overlap with onboarding's, and this set
/// needs a size, a colour and a fill variant that the other does not.
class HomeIcon extends StatelessWidget {
  const HomeIcon.house({
    super.key,
    required this.size,
    required this.color,
    this.isFilled = false,
  }) : _shape = _Shape.house;

  const HomeIcon.car({super.key, required this.size, required this.color})
    : isFilled = false,
      _shape = _Shape.car;

  const HomeIcon.monitor({super.key, required this.size, required this.color})
    : isFilled = false,
      _shape = _Shape.monitor;

  const HomeIcon.folder({
    super.key,
    required this.size,
    required this.color,
    this.isFilled = false,
  }) : _shape = _Shape.folder;

  const HomeIcon.search({super.key, required this.size, required this.color})
    : isFilled = false,
      _shape = _Shape.search;

  const HomeIcon.arrow({super.key, required this.size, required this.color})
    : isFilled = false,
      _shape = _Shape.arrow;

  final double size;
  final Color color;

  /// The active tab's icon is solid; every other icon is stroked.
  final bool isFilled;

  final _Shape _shape;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(shape: _shape, color: color, isFilled: isFilled),
      isComplex: false,
    );
  }
}

enum _Shape {
  house(grid: 18, stroke: 1.4),
  car(grid: 20, stroke: 1.4),
  monitor(grid: 20, stroke: 1.4),
  folder(grid: 18, stroke: 1.4),
  search(grid: 16, stroke: 1.5),
  arrow(grid: 12, stroke: 1.4);

  const _Shape({required this.grid, required this.stroke});

  /// The viewBox the design authored this path against.
  final double grid;
  final double stroke;
}

class _IconPainter extends CustomPainter {
  const _IconPainter({
    required this.shape,
    required this.color,
    required this.isFilled,
  });

  final _Shape shape;
  final Color color;
  final bool isFilled;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / shape.grid;
    canvas.save();
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = shape.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    switch (shape) {
      case _Shape.house:
        canvas.drawPath(_house(), paint);
      case _Shape.car:
        canvas.drawPath(_car(), paint);
      case _Shape.monitor:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 4, 12, 8.2),
            const Radius.circular(1.2),
          ),
          paint,
        );
        canvas.drawLine(
          const Offset(2.4, 14.6),
          const Offset(17.6, 14.6),
          paint,
        );
      case _Shape.folder:
        canvas.drawPath(_folder(), paint);
      case _Shape.search:
        canvas.drawCircle(const Offset(7, 7), 5.2, paint);
        canvas.drawLine(const Offset(11, 11), const Offset(14.6, 14.6), paint);
      case _Shape.arrow:
        canvas.drawPath(_arrow(), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.color != color ||
      oldDelegate.isFilled != isFilled;
}

/// `M2.5 8L9 2.8L15.5 8v6.6a.9.9 0 01-.9.9H3.4a.9.9 0 01-.9-.9V8z`
Path _house() => Path()
  ..moveTo(2.5, 8)
  ..lineTo(9, 2.8)
  ..lineTo(15.5, 8)
  ..lineTo(15.5, 14.6)
  ..arcToPoint(const Offset(14.6, 15.5), radius: const Radius.circular(0.9))
  ..lineTo(3.4, 15.5)
  ..arcToPoint(const Offset(2.5, 14.6), radius: const Radius.circular(0.9))
  ..close();

/// `M3 11.5l1.6-4.3A2 2 0 016.5 6h7a2 2 0 011.9 1.2L17 11.5v3.2h-2.2v-1.4H5.2v1.4H3v-3.2z`
Path _car() => Path()
  ..moveTo(3, 11.5)
  ..lineTo(4.6, 7.2)
  ..arcToPoint(const Offset(6.5, 6), radius: const Radius.circular(2))
  ..lineTo(13.5, 6)
  ..arcToPoint(const Offset(15.4, 7.2), radius: const Radius.circular(2))
  ..lineTo(17, 11.5)
  ..lineTo(17, 14.7)
  ..lineTo(14.8, 14.7)
  ..lineTo(14.8, 13.3)
  ..lineTo(5.2, 13.3)
  ..lineTo(5.2, 14.7)
  ..lineTo(3, 14.7)
  ..close();

/// `M2.4 5.4a1 1 0 011-1h3.3l1.4 1.7h6.5a1 1 0 011 1v6.5a1 1 0 01-1 1h-11.2a1 1 0 01-1-1V5.4z`
Path _folder() => Path()
  ..moveTo(2.4, 5.4)
  ..arcToPoint(const Offset(3.4, 4.4), radius: const Radius.circular(1))
  ..lineTo(6.7, 4.4)
  ..lineTo(8.1, 6.1)
  ..lineTo(14.6, 6.1)
  ..arcToPoint(const Offset(15.6, 7.1), radius: const Radius.circular(1))
  ..lineTo(15.6, 13.6)
  ..arcToPoint(const Offset(14.6, 14.6), radius: const Radius.circular(1))
  ..lineTo(3.4, 14.6)
  ..arcToPoint(const Offset(2.4, 13.6), radius: const Radius.circular(1))
  ..close();

/// `M2 6h8m0 0L6.5 2.5M10 6l-3.5 3.5`
Path _arrow() => Path()
  ..moveTo(2, 6)
  ..lineTo(10, 6)
  ..moveTo(10, 6)
  ..lineTo(6.5, 2.5)
  ..moveTo(10, 6)
  ..lineTo(6.5, 9.5);
