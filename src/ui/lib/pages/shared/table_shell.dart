import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../logs/column_layout.dart';
import 'column_def.dart';
import 'column_menu.dart';
import 'table_header.dart';

/// Shared shell for logs and traces tables.
///
/// Owns menu open/close state and the outer LayoutBuilder that computes column
/// widths once. Callers supply [columns], [rows], sort state, and a
/// [rowBuilder] that receives pre-computed widths.
class TableShell extends StatefulWidget {
  const TableShell({
    super.key,
    required this.columns,
    required this.rows,
    required this.sortColumnId,
    required this.sortAsc,
    required this.onSort,
    required this.onToggleColumn,
    required this.emptyText,
    required this.listKey,
    required this.rowBuilder,
  });

  final List<ColumnDef> columns;
  final List<dynamic> rows;
  final String? sortColumnId;
  final bool sortAsc;
  final void Function(String id) onSort;
  final void Function(String id) onToggleColumn;
  final String emptyText;
  final Key listKey;
  final Widget Function(int index, List<double> widths) rowBuilder;

  @override
  State<TableShell> createState() => _TableShellState();
}

class _TableShellState extends State<TableShell> {
  bool _menuOpen = false;
  final _menuKey = GlobalKey();
  final _stackKey = GlobalKey();

  void _toggleMenu() => setState(() => _menuOpen = !_menuOpen);
  void _closeMenu() => setState(() => _menuOpen = false);

  @override
  Widget build(BuildContext context) {
    final columns = widget.columns;
    final rows = widget.rows;
    final visibleColumns = columns.where((c) => c.visible).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppLayout.radius),
      ),
      child: Stack(
        key: _stackKey,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final widths = computeColumnWidths(
                visibleColumns,
                constraints.maxWidth,
                rows,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SharedTableHeader(
                    columns: columns,
                    rows: rows,
                    sortColumnId: widget.sortColumnId,
                    sortAsc: widget.sortAsc,
                    menuKey: _menuKey,
                    onSort: widget.onSort,
                    onSettingsTap: _toggleMenu,
                    precomputedWidths: widths,
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: rows.isEmpty
                        ? Center(child: Text(widget.emptyText))
                        : ListView.separated(
                            key: widget.listKey,
                            itemCount: rows.length,
                            separatorBuilder: (context, i) => const Divider(
                              height: 1,
                              indent: AppLayout.cellPaddingH,
                              endIndent: AppLayout.cellPaddingH,
                            ),
                            itemBuilder: (_, i) => widget.rowBuilder(i, widths),
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
                      stackKey: _stackKey,
                      items: columns
                          .where((c) => !c.required)
                          .map((c) => ColumnMenuItem(
                                id: c.id,
                                label: c.label,
                                visible: c.visible,
                              ))
                          .toList(),
                      onToggle: widget.onToggleColumn,
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
