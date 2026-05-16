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
    final columns = controller.columns;
    final visibleColumns = columns.where((c) => c.visible).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppLayout.radius),
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final widths = computeColumnWidths(
                visibleColumns.cast<ColumnDef>(),
                constraints.maxWidth,
                rows,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SharedTableHeader(
                    columns: columns.cast<ColumnDef>(),
                    rows: rows,
                    sortColumnId: controller.sortColumnId,
                    sortAsc: controller.sortAsc,
                    menuKey: _menuKey,
                    onSort: controller.setSort,
                    onSettingsTap: _toggleMenu,
                    precomputedWidths: widths,
                  ),
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
                                columns: visibleColumns,
                                widths: widths,
                                selected: controller.selectedTraceId == rows[i].traceId,
                                onTap: () => controller.selectTrace(rows[i].traceId),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
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
                      items: columns
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: selected ? AppColors.rowSelected : null,
        padding: AppLayout.cellPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < columns.length; i++) ...[
              Expanded(
                flex: (widths[i] * 1000).round(),
                child: Text(
                  columns[i].getValue(group),
                  style: AppText.mono,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
              if (i < columns.length - 1)
                const SizedBox(width: AppLayout.gapM),
            ],
          ],
        ),
      ),
    );
  }
}
