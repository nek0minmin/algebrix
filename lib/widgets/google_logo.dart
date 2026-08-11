import 'package:flutter/material.dart';

/// Authentic Official Multi-Colored Google 'G' Logo Widget.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({
    super.key,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPainterWidget(size: size),
    );
  }
}

class CustomPainterWidget extends StatelessWidget {
  final double size;

  const CustomPainterWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: GoogleLogoPainter(),
    );
  }
}

/// Precise Vector Painter for Google's official brand 4-color 'G' logo.
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = w / 2;

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Red Arc (Top) - #EA4335
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        -1.3,
        1.6,
        false,
      )
      ..close();
    canvas.drawPath(redPath, paint);

    // 2. Yellow Arc (Left) - #FBBC05
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        2.35,
        1.25,
        false,
      )
      ..close();
    canvas.drawPath(yellowPath, paint);

    // 3. Green Arc (Bottom) - #34A853
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        0.3,
        2.05,
        false,
      )
      ..close();
    canvas.drawPath(greenPath, paint);

    // 4. Blue Arc & Bar (Right) - #4285F4
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        -0.5,
        0.8,
        false,
      )
      ..close();
    canvas.drawPath(bluePath, paint);

    // Center cutout circle (white)
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), radius * 0.58, paint);

    // Blue horizontal bar
    paint.color = const Color(0xFF4285F4);
    final Rect barRect = Rect.fromLTRB(
      cx - radius * 0.05,
      cy - radius * 0.22,
      cx + radius * 0.95,
      cy + radius * 0.22,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
      paint,
    );

    // Inner white mask for horizontal bar cutoff
    paint.color = Colors.white;
    final Path innerCutout = Path()
      ..moveTo(cx - radius * 0.55, cy - radius * 0.55)
      ..lineTo(cx + radius * 0.05, cy - radius * 0.55)
      ..lineTo(cx + radius * 0.05, cy + radius * 0.55)
      ..lineTo(cx - radius * 0.55, cy + radius * 0.55)
      ..close();
    canvas.drawPath(innerCutout, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
