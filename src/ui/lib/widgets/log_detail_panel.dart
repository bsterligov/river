import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../theme/app_theme.dart';
import '../pages/logs/logs_controller.dart';

class LogDetailPanel extends StatelessWidget {
  const LogDetailPanel({super.key, required this.controller});

  final LogsController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final row = controller.selectedRow;
        if (row == null) return const SizedBox.shrink();
        return SizedBox(
          key: const Key('log_detail_panel'),
          width: AppLayout.detailPanelWidth,
          child: _PanelContent(row: row, controller: controller),
        );
      },
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({required this.row, required this.controller});

  final LogRow row;
  final LogsController controller;

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
          _PanelHeader(controller: controller),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppLayout.gapM),
              children: [
                _TagsSection(row: row),
                _MessageSection(body: row.body),
                _AttributesSection(attributes: row.attributes),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.controller});

  final LogsController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppLayout.cellPadding,
      child: Row(
        children: [
          Expanded(child: const Text('Log Detail', style: AppText.label)),
          IconButton(
            key: const Key('detail_close'),
            icon: const Icon(Icons.close, size: AppIcons.sizeM),
            onPressed: controller.clearSelection,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.row});

  final LogRow row;

  @override
  Widget build(BuildContext context) {
    final pairs = [
      ('timestamp', row.timestamp),
      ('service_name', row.service),
      ('severity_text', row.severity),
      ('severity_number', '${row.severityNumber}'),
      ('trace_id', row.traceId),
      ('span_id', row.spanId),
    ];
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: AppLayout.tilePadding,
      title: const Text('Log Tags & Infra Info', style: AppText.label),
      children: pairs.map((p) => _KvRow(k: p.$1, v: p.$2)).toList(),
    );
  }
}

class _MessageSection extends StatelessWidget {
  const _MessageSection({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: AppLayout.tilePadding,
      title: const Text('Log Message', style: AppText.label),
      children: [
        Padding(
          padding: AppLayout.sectionPadding,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(body, style: AppText.mono),
          ),
        ),
      ],
    );
  }
}

class _AttributesSection extends StatelessWidget {
  const _AttributesSection({required this.attributes});

  final Object? attributes;

  @override
  Widget build(BuildContext context) {
    final pairs = _parseAttributes(attributes);
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: AppLayout.tilePadding,
      title: const Text('Log Attributes', style: AppText.label),
      children: pairs.isEmpty
          ? [
              const Padding(
                padding: AppLayout.sectionPadding,
                child: Text('No attributes', style: AppText.body),
              ),
            ]
          : pairs.map((p) => _KvRow(k: p.$1, v: p.$2)).toList(),
    );
  }

  static List<(String, String)> _parseAttributes(Object? raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is Map<String, dynamic>) {
        return decoded.entries.map((e) => (e.key, '${e.value}')).toList();
      }
    } catch (_) {}
    return [];
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
          Expanded(child: Text(v, style: AppText.mono)),
        ],
      ),
    );
  }
}
