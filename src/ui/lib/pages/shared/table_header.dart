import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../logs/column_layout.dart';
import 'column_def.dart';

/// Shared table header widget for logs and traces tables.
///
/// Renders column labels with sort arrows and a settings icon on the right.
/// Callers provide column definitions, current sort state, and callbacks.
class SharedTableHeader extends StatelessWidget {
  const SharedTableHeader({
    super.key,
    required this.columns,
    required this.rows,
    required this.sortColumnId,
    required this.sortAsc,
    required this.menuKey,
    required this.onSort,
    required this.onSettingsTap,
  });

  final List<ColumnDef> columns;
  final List<dynamic> rows;
  final String? sortColumnId;
  final bool sortAsc;
  final GlobalKey menuKey;
  final void Function(String id) onSort;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final visibleColumns = columns.where((c) => c.visible).toList();
    return Container(
      color: AppColors.tableHeader,
      padding: AppLayout.headerPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widths = computeColumnWidths(visibleColumns, constraints.maxWidth, rows);
          return Row(
            children: [
              for (int i = 0; i < visibleColumns.length; i++) ...[
                Expanded(
                  flex: (widths[i] * 1000).round(),
                  child: GestureDetector(
                    onTap: () => onSort(visibleColumns[i].id),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            visibleColumns[i].label,
                            style: AppText.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sortColumnId == visibleColumns[i].id) ...[
                          const SizedBox(width: 2),
                          Icon(
                            sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                            size: AppIcons.sizeS,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (i < visibleColumns.length - 1)
                  const SizedBox(width: AppLayout.gapM),
              ],
              GestureDetector(
                key: menuKey,
                onTap: onSettingsTap,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.gapS),
                  child: Icon(Icons.settings, size: AppIcons.sizeM),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
