import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import 'span_waterfall.dart';
import 'traces_controller.dart';

/// Maximum number of spans displayed in the waterfall.
const _kMaxSpans = 200;

/// 560 px-wide side panel that appears when a trace row is selected.
/// Overlays the table (Stack + Positioned), animates open/closed via
/// [AnimatedSize] matching the [LogDetailPanel] pattern.
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
                  width: AppLayout.traceDetailPanelWidth,
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

  Span? get _selectedSpan {
    if (selectedSpanId == null) return null;
    try {
      return nodes.firstWhere((n) => n.span.spanId == selectedSpanId).span;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedSpan;
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
          if (selected != null) ...[
            const Divider(height: 1),
            _SpanAttributesSection(span: selected),
          ],
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

class _SpanAttributesSection extends StatelessWidget {
  const _SpanAttributesSection({required this.span});

  final Span span;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.gapM),
        shrinkWrap: true,
        children: [
          ExpansionTile(
            key: const Key('span_attrs_info'),
            initiallyExpanded: true,
            tilePadding: AppLayout.tilePadding,
            title: const Text('Span Info', style: AppText.label),
            children: [
              _KvRow(k: 'span_id', v: span.spanId),
              _KvRow(k: 'service', v: span.service),
              _KvRow(k: 'operation', v: span.operation),
              _KvRow(k: 'status_code', v: '${span.statusCode}'),
              _KvRow(k: 'duration_ms', v: span.durationMs.toStringAsFixed(3)),
              _KvRow(k: 'start_time', v: span.startTime),
              _KvRow(k: 'end_time', v: span.endTime),
            ],
          ),
          ExpansionTile(
            key: const Key('span_attrs_events'),
            initiallyExpanded: false,
            tilePadding: AppLayout.tilePadding,
            title: Text('Events (${span.events.length})', style: AppText.label),
            children: span.events.isEmpty
                ? [_emptyRow('No events')]
                : span.events.map((e) => _EventRow(event: e)).toList(),
          ),
          ExpansionTile(
            key: const Key('span_attrs_links'),
            initiallyExpanded: false,
            tilePadding: AppLayout.tilePadding,
            title: Text('Links (${span.links.length})', style: AppText.label),
            children: span.links.isEmpty
                ? [_emptyRow('No links')]
                : span.links.map((l) => _LinkRow(link: l)).toList(),
          ),
        ],
      ),
    );
  }

  static Widget _emptyRow(String text) => Padding(
        padding: AppLayout.sectionPadding,
        child: Text(text, style: AppText.body),
      );
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final SpanEvent event;

  @override
  Widget build(BuildContext context) {
    final attrs = _parseAttrs(event.attributes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KvRow(k: 'name', v: event.name),
        _KvRow(k: 'timestamp', v: event.timestamp),
        ...attrs.map((p) => _KvRow(k: '  ${p.$1}', v: p.$2)),
        const Divider(height: 1, indent: AppLayout.cellPaddingH),
      ],
    );
  }

  static List<(String, String)> _parseAttrs(Object? raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is Map<String, dynamic>) {
        return decoded.entries.map((e) => (e.key, '${e.value}')).toList();
      }
    } catch (_) {}
    return [];
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.link});

  final SpanLink link;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KvRow(k: 'trace_id', v: link.traceId),
        _KvRow(k: 'span_id', v: link.spanId),
        const Divider(height: 1, indent: AppLayout.cellPaddingH),
      ],
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.k, required this.v});

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppLayout.sectionPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppLayout.detailLabelWidth,
            child: Text(k, style: AppText.label),
          ),
          Expanded(child: SelectableText(v, style: AppText.mono)),
        ],
      ),
    );
  }
}
