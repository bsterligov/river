import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RiverLogo extends StatelessWidget {
  const RiverLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;

    // Rounded square background
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.22));
    canvas.drawRRect(rRect, fillPaint);

    final w = size.width;
    final h = size.height;

    // Stylized "R": vertical stem + arch top + diagonal leg
    final stemPath = Path()
      ..moveTo(w * 0.28, h * 0.22)
      ..lineTo(w * 0.28, h * 0.78);

    // Top arch of R
    final archPath = Path()
      ..moveTo(w * 0.28, h * 0.22)
      ..lineTo(w * 0.58, h * 0.22)
      ..cubicTo(w * 0.80, h * 0.22, w * 0.80, h * 0.52, w * 0.58, h * 0.52)
      ..lineTo(w * 0.28, h * 0.52);

    // Diagonal leg of R
    final legPath = Path()
      ..moveTo(w * 0.52, h * 0.52)
      ..lineTo(w * 0.76, h * 0.78);

    canvas.drawPath(stemPath, strokePaint);
    canvas.drawPath(archPath, strokePaint);
    canvas.drawPath(legPath, strokePaint);
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}
