import 'dart:math';
import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';

// Palette cycles through these colours for multiple series.
const _kSeriesColors = [
  AppColors.primary,
  Color(0xFFE05252),
  Color(0xFF52A352),
  Color(0xFFE0A020),
  Color(0xFF9B59B6),
  Color(0xFF1ABC9C),
];

class MetricsChart extends StatelessWidget {
  const MetricsChart({super.key, required this.series});

  final Map<String, List<MetricPoint>> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty || series.values.every((pts) => pts.isEmpty)) {
      return const Center(
        child: Text('No data for selected metrics in this time range.'),
      );
    }
    return CustomPaint(
      painter: _ChartPainter(series: series),
      child: const SizedBox.expand(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.series});

  final Map<String, List<MetricPoint>> series;

  static const _paddingLeft = 56.0;
  static const _paddingBottom = 32.0;
  static const _paddingTop = 12.0;
  static const _paddingRight = 12.0;
  static const _labelStyle = TextStyle(fontSize: 10, color: AppColors.textMuted);

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _paddingLeft - _paddingRight;
    final chartH = size.height - _paddingTop - _paddingBottom;
    if (chartW <= 0 || chartH <= 0) return;

    final allPoints = series.values.expand((pts) => pts).toList();
    if (allPoints.isEmpty) return;

    final minTs = allPoints
        .map((p) => DateTime.parse(p.timestamp).millisecondsSinceEpoch)
        .reduce(min)
        .toDouble();
    final maxTs = allPoints
        .map((p) => DateTime.parse(p.timestamp).millisecondsSinceEpoch)
        .reduce(max)
        .toDouble();
    final minVal = allPoints.map((p) => p.value).reduce(min);
    final maxVal = allPoints.map((p) => p.value).reduce(max);

    final tsRange = (maxTs - minTs).clamp(1.0, double.infinity);
    final valRange = (maxVal - minVal).clamp(1e-9, double.infinity);

    _drawGrid(canvas, size, chartW, chartH, minVal, maxVal, valRange);

    final colorKeys = series.keys.toList();
    for (var i = 0; i < colorKeys.length; i++) {
      final name = colorKeys[i];
      final points = series[name]!;
      if (points.isEmpty) continue;
      final color = _kSeriesColors[i % _kSeriesColors.length];
      _drawSeries(canvas, points, color, chartW, chartH, minTs, tsRange, minVal, valRange);
    }

    _drawLegend(canvas, size, colorKeys);
  }

  void _drawGrid(Canvas canvas, Size size, double chartW, double chartH,
      double minVal, double maxVal, double valRange) {
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;
    final axisPaint = Paint()
      ..color = AppColors.textMuted
      ..strokeWidth = 1;

    const steps = 4;
    for (var i = 0; i <= steps; i++) {
      final y = _paddingTop + chartH * (1 - i / steps);
      canvas.drawLine(
        Offset(_paddingLeft, y),
        Offset(_paddingLeft + chartW, y),
        i == 0 ? axisPaint : gridPaint,
      );
      final label = (minVal + valRange * i / steps).toStringAsFixed(2);
      _drawText(canvas, label, Offset(0, y - 6), _paddingLeft - 4, TextAlign.right);
    }

    canvas.drawLine(
      Offset(_paddingLeft, _paddingTop),
      Offset(_paddingLeft, _paddingTop + chartH),
      axisPaint,
    );
  }

  void _drawSeries(
    Canvas canvas,
    List<MetricPoint> points,
    Color color,
    double chartW,
    double chartH,
    double minTs,
    double tsRange,
    double minVal,
    double valRange,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final sorted = [...points]
      ..sort((a, b) => DateTime.parse(a.timestamp).compareTo(DateTime.parse(b.timestamp)));

    final path = Path();
    for (var i = 0; i < sorted.length; i++) {
      final ts = DateTime.parse(sorted[i].timestamp).millisecondsSinceEpoch.toDouble();
      final x = _paddingLeft + chartW * (ts - minTs) / tsRange;
      final y = _paddingTop + chartH * (1 - (sorted[i].value - minVal) / valRange);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawLegend(Canvas canvas, Size size, List<String> names) {
    var x = _paddingLeft;
    final y = size.height - 14;
    for (var i = 0; i < names.length; i++) {
      final color = _kSeriesColors[i % _kSeriesColors.length];
      canvas.drawRect(Rect.fromLTWH(x, y - 6, 10, 8),
          Paint()..color = color);
      x += 14;
      _drawText(canvas, names[i], Offset(x, y - 7), 120, TextAlign.left,
          color: AppColors.textMuted);
      x += 128;
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, double maxWidth,
      TextAlign align, {Color color = AppColors.textMuted}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _labelStyle.copyWith(color: color)),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    final dx = align == TextAlign.right ? offset.dx - tp.width : offset.dx;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.series != series;
}
