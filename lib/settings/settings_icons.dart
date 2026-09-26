import 'package:flutter/widgets.dart';

/// Every Settings glyph is authored on this square viewBox.
const _grid = 24.0;
const _stroke = 1.5;

/// The glyphs Settings draws, in the order the page shows them.
enum SettingsGlyph { cloud, phone, photo, storage, share, trash, info }

/// A stroked Settings icon. Deliberately paths, never Material glyphs, like
/// `HomeIcon` and `AddTypeIcon`: none of these shapes exist elsewhere.
class SettingsIcon extends StatelessWidget {
  const SettingsIcon(
    this.glyph, {
    super.key,
    required this.size,
    required this.color,
  });

  final SettingsGlyph glyph;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SettingsIconPainter(glyph: glyph, color: color),
      isComplex: false,
    );
  }
}

class _SettingsIconPainter extends CustomPainter {
  const _SettingsIconPainter({required this.glyph, required this.color});

  final SettingsGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / _grid);

    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      // Divided back out so the line stays 1.5pt at any rendered size.
      ..strokeWidth = _stroke * _grid / size.width
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    for (final path in _paths(glyph)) {
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SettingsIconPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}

/// A zero-length segment: with a round cap it draws as a dot.
Path _dot(double x, double y) => Path()
  ..moveTo(x, y)
  ..lineTo(x + 0.01, y);

Path _line(double x1, double y1, double x2, double y2) => Path()
  ..moveTo(x1, y1)
  ..lineTo(x2, y2);

List<Path> _paths(SettingsGlyph glyph) => switch (glyph) {
  // `M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z`
  SettingsGlyph.cloud => [
    Path()
      ..moveTo(17.5, 19)
      ..lineTo(9, 19)
      ..arcToPoint(
        const Offset(15.71, 10),
        radius: const Radius.circular(7),
        largeArc: true,
      )
      ..lineTo(17.5, 10)
      ..arcToPoint(
        const Offset(17.5, 19),
        radius: const Radius.circular(4.5),
        largeArc: true,
      )
      ..close(),
  ],
  SettingsGlyph.phone => [
    Path()
      ..addRRect(RRect.fromLTRBR(6, 2.5, 18, 21.5, const Radius.circular(2.5))),
    _line(11, 18, 13, 18),
  ],
  SettingsGlyph.photo => [
    Path()..addRRect(RRect.fromLTRBR(3, 3, 21, 21, const Radius.circular(2.5))),
    Path()..addOval(Rect.fromCircle(center: const Offset(9, 9), radius: 2)),
    // `m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21`
    Path()
      ..moveTo(21, 15)
      ..lineTo(17.914, 11.914)
      ..arcToPoint(
        const Offset(15.086, 11.914),
        radius: const Radius.circular(2),
        clockwise: false,
      )
      ..lineTo(6, 21),
  ],
  // Three stacked discs: `ellipse 12 5 9 3`, then the lower rims.
  SettingsGlyph.storage => [
    Path()..addOval(
      Rect.fromCenter(center: const Offset(12, 5), width: 18, height: 6),
    ),
    Path()
      ..moveTo(3, 5)
      ..lineTo(3, 19)
      ..arcToPoint(
        const Offset(21, 19),
        radius: const Radius.elliptical(9, 3),
        clockwise: false,
      )
      ..lineTo(21, 5),
    Path()
      ..moveTo(3, 12)
      ..arcToPoint(
        const Offset(21, 12),
        radius: const Radius.elliptical(9, 3),
        clockwise: false,
      ),
  ],
  // An open tray with an arrow leaving it.
  SettingsGlyph.share => [
    Path()
      ..moveTo(4, 12)
      ..lineTo(4, 20)
      ..cubicTo(4, 21.1, 4.9, 22, 6, 22)
      ..lineTo(18, 22)
      ..cubicTo(19.1, 22, 20, 21.1, 20, 20)
      ..lineTo(20, 12),
    Path()
      ..moveTo(16, 6)
      ..lineTo(12, 2)
      ..lineTo(8, 6),
    _line(12, 2, 12, 15),
  ],
  SettingsGlyph.trash => [
    _line(3, 6, 21, 6),
    Path()
      ..moveTo(19, 6)
      ..lineTo(19, 20)
      ..cubicTo(19, 21, 18, 22, 17, 22)
      ..lineTo(7, 22)
      ..cubicTo(6, 22, 5, 21, 5, 20)
      ..lineTo(5, 6),
    Path()
      ..moveTo(8, 6)
      ..lineTo(8, 4)
      ..cubicTo(8, 3, 9, 2, 10, 2)
      ..lineTo(14, 2)
      ..cubicTo(15, 2, 16, 3, 16, 4)
      ..lineTo(16, 6),
    _line(10, 11, 10, 17),
    _line(14, 11, 14, 17),
  ],
  SettingsGlyph.info => [
    Path()..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 10)),
    _line(12, 16, 12, 11.5),
    _dot(12, 8),
  ],
};
