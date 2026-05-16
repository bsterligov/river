import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../logs/column_layout.dart';
import '../shared/column_def.dart';
import '../shared/column_menu.dart';
import '../shared/table_header.dart';
import 'traces_controller.dart';

class TracesTable extends StatefulWidget {
  const TracesTable({super.key, required this.controller});

  final TracesController controller;

  @override
  State<TracesTable> createState() => _TracesTableState();
}

class _TracesTableState extends State<TracesTable> {
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
        color: AppColors.white,
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
                    ? const Center(child: Text('No traces found.'))
                    : ListView.separated(
                        key: const Key('traces_table'),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: AppLayout.cellPaddingH,
                          endIndent: AppLayout.cellPaddingH,
                        ),
                        itemBuilder: (_, i) => ListenableBuilder(
                          listenable: controller,
                          builder: (context, _) => _TraceRowWidget(
                            group: rows[i],
                            allRows: rows,
                            columns: controller.columns,
                            selected: controller.selectedTraceId == rows[i].traceId,
                            onTap: () => controller.selectTrace(rows[i].traceId),
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

class _TraceRowWidget extends StatelessWidget {
  const _TraceRowWidget({
    required this.group,
    required this.allRows,
    required this.columns,
    required this.selected,
    required this.onTap,
  });

  final dynamic group;
  final List<dynamic> allRows;
  final List<TraceColumn> columns;
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
            final widths = computeColumnWidths(visibleColumns.cast<ColumnDef>(), constraints.maxWidth, allRows);
            return Row(
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
            );
          },
        ),
      ),
    );
  }
}
