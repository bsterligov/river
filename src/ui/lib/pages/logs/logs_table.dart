import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import '../shared/column_def.dart';
import '../shared/column_menu.dart';
import '../shared/table_header.dart';
import 'column_layout.dart';
import 'logs_controller.dart';

class LogsTable extends StatefulWidget {
  const LogsTable({super.key, required this.controller});

  final LogsController controller;

  @override
  State<LogsTable> createState() => _LogsTableState();
}

class _LogsTableState extends State<LogsTable> {
  bool _menuOpen = false;
  final _menuKey = GlobalKey();

  void _toggleMenu() => setState(() => _menuOpen = !_menuOpen);
  void _closeMenu() => setState(() => _menuOpen = false);

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final rows = controller.rows;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppLayout.radius),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SharedTableHeader(
                columns: controller.columns.cast<ColumnDef>(),
                rows: rows,
                sortColumnId: controller.sortColumnId,
                sortAsc: controller.sortAsc,
                menuKey: _menuKey,
                onSort: controller.setSort,
                onSettingsTap: _toggleMenu,
              ),
              const Divider(height: 1),
              Expanded(
                child: rows.isEmpty
                    ? const Center(child: Text('No logs found.'))
                    : ListView.separated(
                        key: const Key('logs_table'),
                        itemCount: rows.length,
                        separatorBuilder: (context, i) => const Divider(
                          height: 1,
                          indent: AppLayout.cellPaddingH,
                          endIndent: AppLayout.cellPaddingH,
                        ),
                        itemBuilder: (_, i) => ListenableBuilder(
                          listenable: controller,
                          builder: (context, _) => _LogRowWidget(
                            row: rows[i],
                            allRows: rows,
                            columns: controller.columns,
                            selected: controller.selectedRow == rows[i],
                            onTap: () => controller.selectRow(rows[i]),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          if (_menuOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeMenu,
                child: Stack(
                  children: [
                    ColumnMenu(
                      menuKey: _menuKey,
                      items: controller.columns
                          .map((c) => ColumnMenuItem(id: c.id, label: c.label, visible: c.visible))
                          .toList(),
                      onToggle: (id) {
                        controller.toggleColumn(id);
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LogRowWidget extends StatelessWidget {
  const _LogRowWidget({
    required this.row,
    required this.allRows,
    required this.columns,
    required this.selected,
    required this.onTap,
  });

  final LogRow row;
  final List<LogRow> allRows;
  final List<LogColumn> columns;
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final widths =
                computeColumnWidths(visibleColumns.cast<ColumnDef>(), constraints.maxWidth, allRows);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < visibleColumns.length; i++) ...[
                  Expanded(
                    flex: (widths[i] * 1000).round(),
                    child: _cellText(visibleColumns[i]),
                  ),
                  if (i < visibleColumns.length - 1)
                    const SizedBox(width: AppLayout.gapM),
                ],
              ],
            );
          },
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
