import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import '../shared/column_def.dart';
import '../shared/table_shell.dart';
import 'logs_controller.dart';

class LogsTable extends StatelessWidget {
  const LogsTable({super.key, required this.controller});

  final LogsController controller;

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
      emptyText: 'No logs found.',
      listKey: const Key('logs_table'),
      rowBuilder: (i, widths) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _LogRowWidget(
          row: rows[i],
          columns: controller.columns,
          widths: widths,
          selected: controller.selectedRow == rows[i],
          onTap: () => controller.selectRow(rows[i]),
        ),
      ),
    );
  }
}

class _LogRowWidget extends StatelessWidget {
  const _LogRowWidget({
    required this.row,
    required this.columns,
    required this.widths,
    required this.selected,
    required this.onTap,
  });

  final LogRow row;
  final List<LogColumn> columns;
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
                key: ValueKey(visibleColumns[i].id),
                flex: (widths[i] * 1000).round(),
                child: _cellText(visibleColumns[i]),
              ),
              if (i < visibleColumns.length - 1)
                SizedBox(key: ValueKey('gap_${visibleColumns[i].id}'), width: AppLayout.gapM),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cellText(LogColumn col) {
    final text = col.getValue(row);
    if (col.id == 'severity') {
      return Text(
        text,
        style: AppText.label.copyWith(color: _severityColor(text)),
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        maxLines: 1,
      );
    }
    if (col.id == 'message') {
      return Text(
          text, style: AppText.body, overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1);
    }
    return Text(
        text, style: AppText.mono, overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1);
  }

  Color _severityColor(String severity) {
    return switch (severity.toUpperCase()) {
      'ERROR' || 'FATAL' => AppColors.error,
      'WARN' || 'WARNING' => AppColors.warning,
      _ => AppColors.textBody,
    };
  }
}
