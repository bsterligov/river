import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import 'span_waterfall.dart';
import 'traces_controller.dart';

/// Maximum number of spans displayed in the waterfall.
const _kMaxSpans = 200;

/// 420 px-wide side panel that appears when a trace row is selected.
/// Animates open/closed via [AnimatedSize] matching the [LogDetailPanel]
/// pattern.
class TraceDetailPanel extends StatefulWidget {
  const TraceDetailPanel({super.key, required this.controller});

  final TracesController controller;

  @override
  State<TraceDetailPanel> createState() => _TraceDetailPanelState();
}

class _TraceDetailPanelState extends State<TraceDetailPanel> {
  String? _loadedTraceId;
  List<SpanNode> _nodes = [];
  bool _loading = false;
  String? _selectedSpanId;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _syncSelection();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    _syncSelection();
  }

  void _syncSelection() {
    final traceId = widget.controller.selectedTraceId;
    if (traceId == null) {
      // Panel closing — reset state.
      if (_loadedTraceId != null) {
        setState(() {
          _loadedTraceId = null;
          _nodes = [];
          _selectedSpanId = null;
        });
      }
      return;
    }
    if (traceId != _loadedTraceId) {
      _fetchTrace(traceId);
    }
  }

  Future<void> _fetchTrace(String traceId) async {
    setState(() {
      _loading = true;
      _loadedTraceId = traceId;
      _nodes = [];
      _selectedSpanId = null;
    });

    try {
      final spans =
          await widget.controller.apiClient.getTrace(traceId) ?? [];
      final capped = spans.length > _kMaxSpans
          ? spans.sublist(0, _kMaxSpans)
          : spans;
      final nodes = buildSpanTree(capped);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _nodes = nodes;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _selectSpan(String spanId) {
    setState(() => _selectedSpanId = spanId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isOpen = widget.controller.selectedTraceId != null;
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topRight,
          child: isOpen
              ? SizedBox(
                  key: const Key('trace_detail_panel'),
                  width: AppLayout.detailPanelWidth,
                  child: _PanelContent(
                    nodes: _nodes,
                    loading: _loading,
                    controller: widget.controller,
                    selectedSpanId: _selectedSpanId,
                    onSelectSpan: _selectSpan,
                    spansCapped: _nodes.length >= _kMaxSpans,
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.nodes,
    required this.loading,
    required this.controller,
    required this.selectedSpanId,
    required this.onSelectSpan,
    required this.spansCapped,
  });

  final List<SpanNode> nodes;
  final bool loading;
  final TracesController controller;
  final String? selectedSpanId;
  final void Function(String) onSelectSpan;
  final bool spansCapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppLayout.radius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(controller: controller, nodes: nodes),
          const Divider(height: 1),
          if (spansCapped)
            const _CappedNotice(count: _kMaxSpans),
          Expanded(child: _PanelBody(
            nodes: nodes,
            loading: loading,
            selectedSpanId: selectedSpanId,
            onSelectSpan: onSelectSpan,
          )),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.controller, required this.nodes});

  final TracesController controller;
  final List<SpanNode> nodes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppLayout.cellPadding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _headerLabel(nodes),
              style: AppText.label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            key: const Key('trace_detail_close'),
            icon: const Icon(Icons.close, size: AppIcons.sizeM),
            onPressed: controller.clearSelection,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _headerLabel(List<SpanNode> nodes) {
    if (nodes.isEmpty) return 'Trace Detail';
    final allSpans = nodes.map((n) => n.span).toList();
    final durationMs = _traceDurationMs(allSpans);
    return 'Trace Detail — ${durationMs.toStringAsFixed(2)} ms';
  }

  double _traceDurationMs(List<Span> spans) {
    if (spans.isEmpty) return 0;
    DateTime? minStart;
    DateTime? maxEnd;
    for (final s in spans) {
      minStart = _earlier(minStart, DateTime.tryParse(s.startTime));
      maxEnd = _later(maxEnd, DateTime.tryParse(s.endTime));
    }
    if (minStart == null || maxEnd == null) return 0;
    return maxEnd.difference(minStart).inMicroseconds / 1000.0;
  }

  static DateTime? _earlier(DateTime? a, DateTime? b) {
    if (b == null) return a;
    if (a == null) return b;
    return b.isBefore(a) ? b : a;
  }

  static DateTime? _later(DateTime? a, DateTime? b) {
    if (b == null) return a;
    if (a == null) return b;
    return b.isAfter(a) ? b : a;
  }
}

class _CappedNotice extends StatelessWidget {
  const _CappedNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('spans_capped_notice'),
      color: AppColors.tableHeader,
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.cellPaddingH,
        vertical: AppLayout.gapS,
      ),
      child: Text(
        'Showing top $count spans',
        style: AppText.micro.copyWith(color: Colors.black54),
      ),
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.nodes,
    required this.loading,
    required this.selectedSpanId,
    required this.onSelectSpan,
  });

  final List<SpanNode> nodes;
  final bool loading;
  final String? selectedSpanId;
  final void Function(String) onSelectSpan;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (nodes.isEmpty) {
      return const Center(child: Text('No spans found.', style: AppText.body));
    }

    final traceBounds = _computeTraceBounds(nodes);
    final traceStartMs = traceBounds.$1;
    final traceDurationMs = traceBounds.$2;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Label column is 40% of available width (min 120, max 200).
        final labelWidth =
            (constraints.maxWidth * 0.40).clamp(120.0, 200.0);
        return ListView.separated(
          key: const Key('span_waterfall'),
          itemCount: nodes.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => SpanWaterfallRow(
            key: ValueKey(nodes[i].span.spanId),
            node: nodes[i],
            traceStartMs: traceStartMs,
            traceDurationMs: traceDurationMs,
            labelColumnWidth: labelWidth,
            isSelected: nodes[i].span.spanId == selectedSpanId,
            onTap: () => onSelectSpan(nodes[i].span.spanId),
          ),
        );
      },
    );
  }

  (double, double) _computeTraceBounds(List<SpanNode> nodes) {
    DateTime? minStart;
    DateTime? maxEnd;
    for (final n in nodes) {
      final start = DateTime.tryParse(n.span.startTime);
      final end = DateTime.tryParse(n.span.endTime);
      if (start != null) {
        if (minStart == null || start.isBefore(minStart)) minStart = start;
      }
      if (end != null) {
        if (maxEnd == null || end.isAfter(maxEnd)) maxEnd = end;
      }
    }
    if (minStart == null || maxEnd == null) return (0, 0);
    final startMs = minStart.millisecondsSinceEpoch.toDouble();
    final durationMs =
        maxEnd.difference(minStart).inMicroseconds / 1000.0;
    return (startMs, durationMs.clamp(0.001, double.infinity));
  }
}
