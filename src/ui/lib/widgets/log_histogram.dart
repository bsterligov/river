import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../theme/app_theme.dart';
import '../pages/logs/logs_controller.dart';

class LogHistogram extends StatelessWidget {
  const LogHistogram({super.key, required this.controller});

  final LogsController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _LogHistogramTile(controller: controller),
    );
  }
}

class _LogHistogramTile extends StatefulWidget {
  const _LogHistogramTile({required this.controller});

  final LogsController controller;

  @override
  State<_LogHistogramTile> createState() => _LogHistogramTileState();
}

class _LogHistogramTileState extends State<_LogHistogramTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('log_histogram_tile'),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppLayout.radius),
      ),
      child: ExpansionTile(
        key: const Key('log_histogram_expansion'),
        title: const Text('Log distribution', style: AppText.label),
        initiallyExpanded: true,
        tilePadding: AppLayout.tilePadding,
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        children: [_buildContent()],
      ),
    );
  }

  Widget _buildContent() {
    if (!_expanded) return const SizedBox.shrink();
    final controller = widget.controller;
    if (controller.loading) {
      return const _HistogramPlaceholder();
    }
    if (controller.histogram.isEmpty) {
      return const SizedBox.shrink();
    }
    return _HistogramChart(
      buckets: controller.histogram,
      onTap: (from, to) => controller.rangeController.setRange(from, to),
    );
  }
}

class _HistogramPlaceholder extends StatelessWidget {
  const _HistogramPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('histogram_placeholder'),
      height: 80,
      margin: const EdgeInsets.symmetric(
        horizontal: AppLayout.cellPaddingH,
        vertical: AppLayout.gapM,
      ),
      decoration: BoxDecoration(
        color: AppColors.shimmer,
        borderRadius: BorderRadius.circular(AppLayout.radius),
      ),
    );
  }
}

// ClickHouse returns bucket timestamps as "YYYY-MM-DD HH:MM:SS" with no
// timezone suffix, but the values are UTC. Appending Z makes Dart parse them
// as UTC so subsequent .toLocal() conversions are correct.
DateTime? _parseBucketUtc(String bucket) {
  final normalized = bucket.contains('Z') ? bucket : '${bucket}Z';
  return DateTime.tryParse(normalized);
}

class _HistogramChart extends StatelessWidget {
  const _HistogramChart({required this.buckets, required this.onTap});

  final List<HistogramBucket> buckets;
  final void Function(DateTime from, DateTime to) onTap;

  @override
  Widget build(BuildContext context) {
    final step = _inferStep(buckets);
    return SizedBox(
      key: const Key('histogram_chart'),
      height: 96,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.cellPaddingH,
          vertical: AppLayout.gapM,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxCount = buckets.isEmpty
                ? 0
                : buckets.map((b) => b.count).reduce((a, b) => a > b ? a : b);
            return _HistogramCanvas(
              buckets: buckets,
              step: step,
              onTap: onTap,
              width: constraints.maxWidth,
              maxCount: maxCount,
            );
          },
        ),
      ),
    );
  }

  static Duration _inferStep(List<HistogramBucket> buckets) {
    if (buckets.length < 2) return const Duration(minutes: 1);
    final t0 = _parseBucketUtc(buckets[0].bucket);
    final t1 = _parseBucketUtc(buckets[1].bucket);
    if (t0 == null || t1 == null) return const Duration(minutes: 1);
    return t1.difference(t0);
  }
}

class _HistogramCanvas extends StatelessWidget {
  const _HistogramCanvas({
    required this.buckets,
    required this.step,
    required this.onTap,
    required this.width,
    required this.maxCount,
  });

  final List<HistogramBucket> buckets;
  final Duration step;
  final void Function(DateTime from, DateTime to) onTap;
  final double width;
  final int maxCount;

  static const _yAxisWidth = 36.0;

  @override
  Widget build(BuildContext context) {
    final n = buckets.length;
    if (n == 0) return const SizedBox.shrink();

    final chartWidth = (width - _yAxisWidth).clamp(1.0, double.infinity);
    final barWidth = chartWidth / n;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final dx = details.localPosition.dx - _yAxisWidth;
        if (dx < 0) return;
        final idx = (dx / barWidth).floor();
        if (idx < 0 || idx >= n) return;
        final from = _parseBucketUtc(buckets[idx].bucket);
        if (from == null) return;
        onTap(from, from.add(step));
      },
      child: CustomPaint(
        painter: _BarPainter(buckets: buckets, maxCount: maxCount, yAxisWidth: _yAxisWidth),
        child: _XAxisLabels(buckets: buckets, barWidth: barWidth, yAxisWidth: _yAxisWidth, step: step),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.buckets,
    required this.maxCount,
    required this.yAxisWidth,
  });

  final List<HistogramBucket> buckets;
  final int maxCount;
  final double yAxisWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 14.0;
    final barAreaHeight = size.height - labelHeight;
    final barAreaWidth = size.width - yAxisWidth;

    _drawYAxis(canvas, barAreaHeight);

    if (buckets.isEmpty || maxCount == 0) return;

    final barWidth = barAreaWidth / buckets.length;
    const gap = 1.0;
    final paint = Paint()..color = AppColors.primary.withValues(alpha: 0.7);

    for (var i = 0; i < buckets.length; i++) {
      final barH = (buckets[i].count / maxCount) * barAreaHeight;
      final left = yAxisWidth + i * barWidth + gap;
      final right = yAxisWidth + (i + 1) * barWidth - gap;
      final top = barAreaHeight - barH;
      canvas.drawRRect(
        RRect.fromLTRBR(left, top, right, barAreaHeight, const Radius.circular(2)),
        paint,
      );
    }
  }

  void _drawYAxis(Canvas canvas, double barAreaHeight) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final style = AppText.micro.copyWith(color: Colors.black45);

    void drawLabel(String text, double y) {
      tp.text = TextSpan(text: text, style: style);
      tp.layout(maxWidth: yAxisWidth - 2);
      tp.paint(canvas, Offset(yAxisWidth - tp.width - 2, y));
    }

    drawLabel(_compact(maxCount), 0);
    drawLabel('0', barAreaHeight - 10);
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.buckets != buckets || old.maxCount != maxCount;
}

class _XAxisLabels extends StatelessWidget {
  const _XAxisLabels({
    required this.buckets,
    required this.barWidth,
    required this.yAxisWidth,
    required this.step,
  });

  final List<HistogramBucket> buckets;
  final double barWidth;
  final double yAxisWidth;
  final Duration step;

  @override
  Widget build(BuildContext context) {
    const labelHeight = 14.0;
    final n = buckets.length;

    // For multi-hour ranges label every local-date boundary (day changes).
    // For sub-hour granularity keep evenly-spaced HH:MM labels.
    final List<({int index, String label})> labels;
    if (step >= const Duration(hours: 1)) {
      labels = _dateBoundaryLabels();
    } else {
      const maxLabels = 6;
      final labelStep = n <= maxLabels ? 1 : (n / maxLabels).ceil();
      labels = [
        for (var i = 0; i < n; i += labelStep)
          (index: i, label: _fmtTime(buckets[i].bucket)),
      ];
    }

    // 72px comfortably fits "MM/DD HH:MM" at 9px font.
    const labelWidth = 72.0;

    return Stack(
      children: [
        for (final l in labels)
          Positioned(
            left: yAxisWidth + l.index * barWidth,
            bottom: 0,
            width: labelWidth,
            height: labelHeight,
            child: Text(
              l.label,
              style: AppText.micro.copyWith(color: Colors.black54),
              overflow: TextOverflow.clip,
              maxLines: 1,
            ),
          ),
      ],
    );
  }

  // Emits a label at the first bucket and at every bucket where the local
  // calendar date changes — timezone-safe regardless of UTC offset.
  List<({int index, String label})> _dateBoundaryLabels() {
    final result = <({int index, String label})>[];
    int? lastDay;
    for (var i = 0; i < buckets.length; i++) {
      final dt = _parseBucketUtc(buckets[i].bucket)?.toLocal();
      if (dt == null) continue;
      final dayKey = dt.year * 10000 + dt.month * 100 + dt.day;
      if (lastDay == null || dayKey != lastDay) {
        lastDay = dayKey;
        final mm = dt.month.toString().padLeft(2, '0');
        final dd = dt.day.toString().padLeft(2, '0');
        // Include time when step is sub-day so the first label of each day
        // shows where in the day it starts.
        final label = '$mm/$dd ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        result.add((index: i, label: label));
      }
    }
    return result;
  }

  static String _fmtTime(String bucket) {
    final dt = _parseBucketUtc(bucket)?.toLocal();
    if (dt == null) return bucket;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
