import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';

/// A single node in the depth-first span tree.
class SpanNode {
  SpanNode({required this.span, required this.depth});

  final Span span;
  final int depth;
}

/// Builds a flat, depth-first ordered list of [SpanNode]s from [spans].
///
/// Spans whose [Span.parentSpanId] is empty or not present in the span set
/// are treated as root-level entries (depth 0). Orphan spans never cause
/// an exception or silent drop.
List<SpanNode> buildSpanTree(List<Span> spans) {
  if (spans.isEmpty) return [];

  final byId = <String, Span>{for (final s in spans) s.spanId: s};
  final childrenOf = <String, List<Span>>{};
  final roots = <Span>[];

  for (final s in spans) {
    final parentId = s.parentSpanId;
    if (parentId.isEmpty || !byId.containsKey(parentId)) {
      roots.add(s);
    } else {
      childrenOf.putIfAbsent(parentId, () => []).add(s);
    }
  }

  final result = <SpanNode>[];
  _dfs(roots, childrenOf, 0, result);
  return result;
}

void _dfs(
  List<Span> nodes,
  Map<String, List<Span>> childrenOf,
  int depth,
  List<SpanNode> out,
) {
  for (final s in nodes) {
    out.add(SpanNode(span: s, depth: depth));
    final children = childrenOf[s.spanId];
    if (children != null) {
      _dfs(children, childrenOf, depth + 1, out);
    }
  }
}

/// Returns the millisecond offset of [span] relative to [traceStartMs].
double spanOffsetMs(Span span, double traceStartMs) {
  final dt = DateTime.tryParse(span.startTime);
  if (dt == null) return 0;
  return dt.millisecondsSinceEpoch.toDouble() - traceStartMs;
}

const double spanRowHeight = 28.0;
const double _barHeight = 14.0;
const double _indentPx = 12.0;
const double _minBarWidth = 2.0;

/// Paints a single row of the waterfall: label on the left, proportional bar
/// on the right.
class SpanRowPainter extends CustomPainter {
  SpanRowPainter({
    required this.node,
    required this.traceStartMs,
    required this.traceDurationMs,
    required this.labelColumnWidth,
    required this.isSelected,
  });

  final SpanNode node;
  final double traceStartMs;
  final double traceDurationMs;
  final double labelColumnWidth;
  final bool isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    final span = node.span;

    // Background highlight for selected span.
    if (isSelected) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, spanRowHeight),
        Paint()..color = AppColors.rowSelected,
      );
    }

    // Label: indented by depth.
    final indent = node.depth * _indentPx;
    final label = '${span.service}  ${span.operation}';
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: AppText.spanLabel,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: labelColumnWidth - indent - 4);

    labelPainter.paint(
      canvas,
      Offset(indent, (spanRowHeight - labelPainter.height) / 2),
    );

    // Bar.
    final barAreaLeft = labelColumnWidth;
    final barAreaWidth = size.width - barAreaLeft;
    if (traceDurationMs <= 0 || barAreaWidth <= 0) return;

    final offsetMs = spanOffsetMs(span, traceStartMs);
    final barLeft = barAreaLeft + (offsetMs / traceDurationMs) * barAreaWidth;
    final barWidth = ((span.durationMs / traceDurationMs) * barAreaWidth)
        .clamp(_minBarWidth, barAreaWidth - (barLeft - barAreaLeft));

    final barColor = _barColor(span.statusCode);
    canvas.drawRect(
      Rect.fromLTWH(
        barLeft,
        (spanRowHeight - _barHeight) / 2,
        barWidth,
        _barHeight,
      ),
      Paint()..color = barColor,
    );
  }

  Color _barColor(int statusCode) {
    // OTel status codes: 0=unset, 1=ok, 2=error.
    return switch (statusCode) {
      1 => AppColors.primary,
      2 => AppColors.error,
      _ => AppColors.spanUnset,
    };
  }

  @override
  bool shouldRepaint(SpanRowPainter old) =>
      old.node != node ||
      old.traceStartMs != traceStartMs ||
      old.traceDurationMs != traceDurationMs ||
      old.isSelected != isSelected;
}

/// The widget that wraps a row with tap handling and the [SpanRowPainter].
class SpanWaterfallRow extends StatelessWidget {
  const SpanWaterfallRow({
    super.key,
    required this.node,
    required this.traceStartMs,
    required this.traceDurationMs,
    required this.labelColumnWidth,
    required this.isSelected,
    required this.onTap,
  });

  final SpanNode node;
  final double traceStartMs;
  final double traceDurationMs;
  final double labelColumnWidth;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: spanRowHeight,
        child: CustomPaint(
          painter: SpanRowPainter(
            node: node,
            traceStartMs: traceStartMs,
            traceDurationMs: traceDurationMs,
            labelColumnWidth: labelColumnWidth,
            isSelected: isSelected,
          ),
        ),
      ),
    );
  }
}
