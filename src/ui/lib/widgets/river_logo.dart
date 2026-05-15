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
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Rounded square background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.22),
      ),
      fillPaint,
    );

    // Left bracket [
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.23, h * 0.24)
        ..lineTo(w * 0.15, h * 0.24)
        ..lineTo(w * 0.15, h * 0.76)
        ..lineTo(w * 0.23, h * 0.76),
      strokePaint,
    );

    // Right bracket ]
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.77, h * 0.24)
        ..lineTo(w * 0.85, h * 0.24)
        ..lineTo(w * 0.85, h * 0.76)
        ..lineTo(w * 0.77, h * 0.76),
      strokePaint,
    );

    // Wave arch: starts low-left, peaks at centre-top, ends low-right
    final x0   = w * 0.27;
    final x4   = w * 0.73;
    final yLo  = h * 0.58;
    final yHi  = h * 0.34;
    final xMid = (x0 + x4) / 2;
    final pull = (x4 - x0) * 0.28;

    canvas.drawPath(
      Path()
        ..moveTo(x0, yLo)
        ..cubicTo(x0 + pull, yLo, xMid - pull, yHi, xMid, yHi)
        ..cubicTo(xMid + pull, yHi, x4 - pull, yLo, x4, yLo),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}
