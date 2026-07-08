import 'package:flutter/material.dart';
import '../theme.dart';

/// Recreates the source design's inline SVG attendance line/area chart
/// (viewBox 320x130, straight-segment line, 3 gridlines, gradient fill,
/// circle markers) via [CustomPainter], scaled to fill the available box.
class AttendanceChart extends StatelessWidget {
  final List<int> values;
  final Color accentColor;
  const AttendanceChart({super.key, required this.values, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: CustomPaint(painter: _ChartPainter(values, accentColor)),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<int> values;
  final Color accentColor;
  _ChartPainter(this.values, this.accentColor);

  static const _chartW = 320.0;
  static const _chartH = 130.0;
  static const _padTop = 10.0;
  static const _padBottom = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final usableH = _chartH - _padTop - _padBottom;
    final scaleX = size.width / _chartW;
    final scaleY = size.height / _chartH;

    final gridPaint = Paint()
      ..color = AdminColors.chartGridline
      ..strokeWidth = 1;
    for (final y in const [20.0, 55.0, 90.0]) {
      canvas.drawLine(Offset(0, y * scaleY), Offset(size.width, y * scaleY), gridPaint);
    }

    if (values.isEmpty) return;
    final stepX = _chartW / (values.length - 1);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          i * stepX * scaleX,
          (_padTop + usableH - (values[i] / 100) * usableH) * scaleY,
        ),
    ];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    final baselineY = (_chartH - _padBottom) * scaleY;
    final areaPath = Path.from(linePath)
      ..lineTo(size.width, baselineY)
      ..lineTo(0, baselineY)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accentColor.withValues(alpha: 0.28), accentColor.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotFill = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotFill);
      canvas.drawCircle(p, 3.5, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.accentColor != accentColor;
}
