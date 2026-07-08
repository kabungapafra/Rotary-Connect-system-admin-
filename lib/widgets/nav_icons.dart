import 'package:flutter/material.dart';

/// Sidebar icons redrawn to match the source SVG geometry exactly (viewBox
/// 18x18, same rects/circles/opacities), scaled to a 16x16 box.
class NavIcon extends StatelessWidget {
  final NavIconShape shape;
  final Color color;
  const NavIcon(this.shape, {super.key, required this.color});

  const NavIcon.dashboard({Key? key, required Color color})
      : this(NavIconShape.dashboard, key: key, color: color);
  const NavIcon.analytics({Key? key, required Color color})
      : this(NavIconShape.analytics, key: key, color: color);
  const NavIcon.clubs({Key? key, required Color color})
      : this(NavIconShape.clubs, key: key, color: color);
  const NavIcon.members({Key? key, required Color color})
      : this(NavIconShape.members, key: key, color: color);
  const NavIcon.billing({Key? key, required Color color})
      : this(NavIconShape.billing, key: key, color: color);
  const NavIcon.sms({Key? key, required Color color})
      : this(NavIconShape.sms, key: key, color: color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CustomPaint(painter: _NavIconPainter(shape, color)),
    );
  }
}

enum NavIconShape { dashboard, analytics, clubs, members, billing, sms }

class _NavIconPainter extends CustomPainter {
  final NavIconShape shape;
  final Color color;
  _NavIconPainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 18.0;
    canvas.save();
    canvas.scale(scale, scale);
    final paint = Paint()..style = PaintingStyle.fill;

    void rrect(double x, double y, double w, double h, double r, double opacity) {
      paint.color = color.withValues(alpha: opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
        paint,
      );
    }

    void circle(double cx, double cy, double r, double opacity) {
      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    switch (shape) {
      case NavIconShape.dashboard:
        rrect(1, 1, 7, 7, 1.5, 1);
        rrect(10, 1, 7, 7, 1.5, 0.5);
        rrect(1, 10, 7, 7, 1.5, 0.5);
        rrect(10, 10, 7, 7, 1.5, 1);
        break;
      case NavIconShape.analytics:
        rrect(1.5, 9, 3.4, 7.5, 1, 0.5);
        rrect(7.3, 4, 3.4, 12.5, 1, 1);
        rrect(13.1, 7, 3.4, 9.5, 1, 0.75);
        break;
      case NavIconShape.clubs:
        rrect(2, 7, 14, 9, 1, 0.5);
        final path = Path()
          ..moveTo(9, 1)
          ..lineTo(16, 7)
          ..lineTo(2, 7)
          ..close();
        paint.color = color.withValues(alpha: 1);
        canvas.drawPath(path, paint);
        break;
      case NavIconShape.members:
        circle(6.5, 6.5, 4, 1);
        circle(12.5, 8, 4, 0.5);
        break;
      case NavIconShape.billing:
        rrect(1, 3, 16, 12, 2, 0.5);
        rrect(1, 6, 16, 2.5, 0, 1);
        break;
      case NavIconShape.sms:
        final path = Path()
          ..moveTo(2, 3)
          ..lineTo(16, 3)
          ..arcToPoint(const Offset(17, 4), radius: const Radius.circular(1))
          ..lineTo(17, 12)
          ..arcToPoint(const Offset(16, 13), radius: const Radius.circular(1))
          ..lineTo(7, 13)
          ..lineTo(3, 16)
          ..lineTo(3, 13)
          ..lineTo(2, 13)
          ..arcToPoint(const Offset(1, 12), radius: const Radius.circular(1))
          ..lineTo(1, 4)
          ..arcToPoint(const Offset(2, 3), radius: const Radius.circular(1))
          ..close();
        paint.color = color.withValues(alpha: 0.5);
        canvas.drawPath(path, paint);
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}

/// The bullseye logo mark in the sidebar header (circle outline + center dot).
class TargetLogoIcon extends StatelessWidget {
  final double size;
  final Color color;
  const TargetLogoIcon({super.key, this.size = 14, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TargetPainter(color)),
    );
  }
}

class _TargetPainter extends CustomPainter {
  final Color color;
  _TargetPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 16.0;
    final center = Offset(8 * scale, 8 * scale);
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 * scale;
    canvas.drawCircle(center, 6.6 * scale, ring);
    final dot = Paint()..color = color;
    canvas.drawCircle(center, 2.3 * scale, dot);
  }

  @override
  bool shouldRepaint(covariant _TargetPainter oldDelegate) => oldDelegate.color != color;
}
