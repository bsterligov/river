import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import '../../utils/format_time.dart';
import 'traces_controller.dart';

class TracesTable extends StatelessWidget {
  const TracesTable({super.key, required this.controller});

  final TracesController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.rows;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppLayout.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TracesHeader(controller: controller),
          const Divider(height: 1),
          Expanded(
            child: rows.isEmpty
                ? const Center(child: Text('No traces found.'))
                : ListView.separated(
                    key: const Key('traces_table'),
                    itemCount: rows.length,
                    separatorBuilder: (context, i) => const Divider(
                      height: 1,
                      indent: AppLayout.cellPaddingH,
                      endIndent: AppLayout.cellPaddingH,
                    ),
                    itemBuilder: (_, i) => ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => _TraceRowWidget(
                        group: rows[i],
                        selected: controller.selectedTraceId == rows[i].traceId,
                        onTap: () => controller.selectTrace(rows[i].traceId),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TracesHeader extends StatelessWidget {
  const _TracesHeader({required this.controller});

  final TracesController controller;

  static const _columns = [
    ('traceId', 'Trace ID'),
    ('rootService', 'Root Service'),
    ('rootOperation', 'Root Operation'),
    ('durationMs', 'Duration ms'),
    ('spanCount', 'Spans'),
    ('startTime', 'Start Time'),
  ];

  static const _flex = [3, 2, 3, 2, 1, 3];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tableHeader,
      padding: AppLayout.headerPadding,
      child: Row(
        children: [
          for (int i = 0; i < _columns.length; i++) ...[
            Expanded(
              flex: _flex[i],
              child: GestureDetector(
                onTap: () => controller.setSort(_columns[i].$1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _columns[i].$2,
                        style: AppText.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (controller.sortColumnId == _columns[i].$1) ...[
                      const SizedBox(width: 2),
                      Icon(
                        controller.sortAsc
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: AppIcons.sizeS,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (i < _columns.length - 1) const SizedBox(width: AppLayout.gapM),
          ],
        ],
      ),
    );
  }
}

class _TraceRowWidget extends StatelessWidget {
  const _TraceRowWidget({
    required this.group,
    required this.selected,
    required this.onTap,
  });

  final TraceGroup group;
  final bool selected;
  final VoidCallback onTap;

  static const _flex = [3, 2, 3, 2, 1, 3];

  @override
  Widget build(BuildContext context) {
    final cells = _buildCells(group);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: selected ? AppColors.rowSelected : null,
        padding: AppLayout.cellPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < cells.length; i++) ...[
              Expanded(
                flex: _flex[i],
                child: Text(
                  cells[i],
                  style: AppText.mono,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
              if (i < cells.length - 1) const SizedBox(width: AppLayout.gapM),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _buildCells(TraceGroup group) {
    final root = rootSpan(group);
    final durationMs = root?.durationMs ?? 0;
    final startTime = traceGroupStartTime(group);
    final formattedStart = formatTimestamp(startTime);
    return [
      group.traceId,
      root?.service ?? '',
      root?.operation ?? '',
      durationMs.toStringAsFixed(2),
      group.spans.length.toString(),
      formattedStart,
    ];
  }
}
