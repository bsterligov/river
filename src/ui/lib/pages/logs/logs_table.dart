import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
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
              _TableHeader(
                controller: controller,
                rows: rows,
                menuKey: _menuKey,
                menuOpen: _menuOpen,
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
                    _ColumnMenu(
                      menuKey: _menuKey,
                      controller: controller,
                      onClose: _closeMenu,
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

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.controller,
    required this.rows,
    required this.menuKey,
    required this.menuOpen,
    required this.onSettingsTap,
  });

  final LogsController controller;
  final List<LogRow> rows;
  final GlobalKey menuKey;
  final bool menuOpen;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final visibleColumns = controller.columns.where((c) => c.visible).toList();
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
                    onTap: () => controller.setSort(visibleColumns[i].id),
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
                        if (controller.sortColumnId == visibleColumns[i].id) ...[
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

class _ColumnMenu extends StatelessWidget {
  const _ColumnMenu({
    required this.menuKey,
    required this.controller,
    required this.onClose,
  });

  final GlobalKey menuKey;
  final LogsController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final iconBox = menuKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = context.findRenderObject() as RenderBox?;
    double menuTop = 36;
    double menuRight = 8;
    if (iconBox != null && stackBox != null) {
      final iconGlobal = iconBox.localToGlobal(Offset.zero);
      final stackGlobal = stackBox.localToGlobal(Offset.zero);
      menuTop = iconGlobal.dy - stackGlobal.dy + iconBox.size.height + 4;
      menuRight = stackBox.size.width -
          (iconGlobal.dx - stackGlobal.dx) -
          iconBox.size.width;
    }

    return Positioned(
      top: menuTop,
      right: menuRight,
      child: GestureDetector(
        onTap: () {},
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(AppLayout.radius),
          child: Container(
            width: 180,
            padding: const EdgeInsets.symmetric(vertical: AppLayout.gapS),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppLayout.radius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: controller.columns.map((col) {
                return CheckboxListTile(
                  key: Key('col_toggle_${col.id}'),
                  dense: true,
                  title: Text(col.label, style: AppText.label),
                  value: col.visible,
                  onChanged: (_) {
                    controller.toggleColumn(col.id);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: AppLayout.tilePadding,
                );
              }).toList(),
            ),
          ),
        ),
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
                computeColumnWidths(visibleColumns, constraints.maxWidth, allRows);
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
