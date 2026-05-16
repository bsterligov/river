import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../shared/column_def.dart';
import '../shared/table_shell.dart';
import 'traces_controller.dart';

class TracesTable extends StatelessWidget {
  const TracesTable({super.key, required this.controller});

  final TracesController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.rows;
    final columns = controller.columns.cast<ColumnDef>();

    return TableShell(
      columns: columns,
      rows: rows,
      sortColumnId: controller.sortColumnId,
      sortAsc: controller.sortAsc,
      onSort: controller.setSort,
      onToggleColumn: controller.toggleColumn,
      emptyText: 'No traces found.',
      listKey: const Key('traces_table'),
      rowBuilder: (i, widths) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _TraceRowWidget(
          group: rows[i],
          columns: controller.columns,
          widths: widths,
          selected: controller.selectedTraceId == rows[i].traceId,
          onTap: () => controller.selectTrace(rows[i].traceId),
        ),
      ),
    );
  }
}

class _TraceRowWidget extends StatelessWidget {
  const _TraceRowWidget({
    required this.group,
    required this.columns,
    required this.widths,
    required this.selected,
    required this.onTap,
  });

  final dynamic group;
  final List<TraceColumn> columns;
  final List<double> widths;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visibleColumns = columns.where((c) => c.visible).toList();
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: selected ? AppColors.rowSelected : null,
        padding: AppLayout.cellPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < visibleColumns.length; i++) ...[
              Expanded(
                flex: (widths[i] * 1000).round(),
                child: Text(
                  visibleColumns[i].getValue(group),
                  style: AppText.mono,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
              if (i < visibleColumns.length - 1)
                const SizedBox(width: AppLayout.gapM),
            ],
          ],
        ),
      ),
    );
  }
}
