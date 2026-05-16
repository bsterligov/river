import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import '../../utils/parse_attributes.dart';
import '../../widgets/kv_row.dart';

class SpanAttributesSection extends StatelessWidget {
  const SpanAttributesSection({
    super.key,
    required this.span,
    this.onClear,
  });

  final Span span;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final attrPairs = parseAttributes(span.attributes);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SpanAttrHeader(onClear: onClear),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExpansionTile(
                    key: const Key('span_attrs_attributes'),
                    initiallyExpanded: true,
                    tilePadding: AppLayout.tilePadding,
                    title: const Text('Attributes', style: AppText.label),
                    children: attrPairs.isEmpty
                        ? [_emptyRow('No attributes')]
                        : attrPairs.map((p) => KvRow(k: p.$1, v: p.$2)).toList(),
                  ),
                  ExpansionTile(
                    key: const Key('span_attrs_info'),
                    initiallyExpanded: true,
                    tilePadding: AppLayout.tilePadding,
                    title: const Text('Span Info', style: AppText.label),
                    children: [
                      KvRow(k: 'span_id', v: span.spanId),
                      KvRow(k: 'service', v: span.service),
                      KvRow(k: 'operation', v: span.operation),
                      KvRow(k: 'status_code', v: '${span.statusCode}'),
                      KvRow(
                          k: 'duration_ms',
                          v: span.durationMs.toStringAsFixed(3)),
                      KvRow(k: 'start_time', v: span.startTime),
                      KvRow(k: 'end_time', v: span.endTime),
                    ],
                  ),
                  ExpansionTile(
                    key: const Key('span_attrs_events'),
                    initiallyExpanded: false,
                    tilePadding: AppLayout.tilePadding,
                    title: Text('Events (${span.events.length})',
                        style: AppText.label),
                    children: span.events.isEmpty
                        ? [_emptyRow('No events')]
                        : span.events.map((e) => EventRow(event: e)).toList(),
                  ),
                  ExpansionTile(
                    key: const Key('span_attrs_links'),
                    initiallyExpanded: false,
                    tilePadding: AppLayout.tilePadding,
                    title: Text('Links (${span.links.length})',
                        style: AppText.label),
                    children: span.links.isEmpty
                        ? [_emptyRow('No links')]
                        : span.links.map((l) => LinkRow(link: l)).toList(),
                  ),
                ],
              ),
            ),
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

class _SpanAttrHeader extends StatelessWidget {
  const _SpanAttrHeader({this.onClear});

  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppLayout.cellPadding,
      child: Row(
        children: [
          const Expanded(
            child: Text('Span Details', style: AppText.label),
          ),
          if (onClear != null)
            IconButton(
              key: const Key('span_attrs_close'),
              icon: const Icon(Icons.close, size: AppIcons.sizeM),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class EventRow extends StatelessWidget {
  const EventRow({super.key, required this.event});

  final SpanEvent event;

  @override
  Widget build(BuildContext context) {
    final attrs = parseAttributes(event.attributes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KvRow(k: 'name', v: event.name),
        KvRow(k: 'timestamp', v: event.timestamp),
        ...attrs.map((p) => KvRow(k: '  ${p.$1}', v: p.$2)),
        const Divider(height: 1, indent: AppLayout.cellPaddingH),
      ],
    );
  }
}

class LinkRow extends StatelessWidget {
  const LinkRow({super.key, required this.link});

  final SpanLink link;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KvRow(k: 'trace_id', v: link.traceId),
        KvRow(k: 'span_id', v: link.spanId),
        const Divider(height: 1, indent: AppLayout.cellPaddingH),
      ],
    );
  }
}
