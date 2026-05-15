import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'logs_controller.dart';

// Horizontal padding added to each measured column width.
const double _colPad = 16.0;
// Settings icon + its symmetric padding, reserved on the right of the header row.
// Add 32px buffer for hit-test padding and sub-pixel measurement variance.
const double _settingsReserved = AppIcons.sizeM + AppLayout.gapS * 2 + 32.0;
// Maximum rows sampled for content-width measurement (keeps layout fast).
const int _sampleLimit = 50;

double _measureText(String text, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return tp.width;
}

double _naturalWidth(LogColumn col, List<dynamic> sample) {
  final labelW = _measureText(col.label, AppText.label);
  final dataW = col.fixedSample != null
      ? _measureText(col.fixedSample!, AppText.mono)
      : sample.fold(0.0, (max, row) {
          final w = _measureText(col.getValue(row), AppText.mono);
          return w > max ? w : max;
        });
  return (labelW > dataW ? labelW : dataW) + _colPad;
}

List<double> _scaleToFit(List<LogColumn> columns, List<double> natural, double usable) {
  final scale = usable / natural.fold(0.0, (s, w) => s + w);
  return [
    for (int i = 0; i < columns.length; i++)
      columns[i].stretchy == true ? 0.0 : (natural[i] * scale).floorToDouble(),
  ];
}

List<double> _distributeStretch(
  List<LogColumn> columns,
  List<double> natural,
  double usable,
  int stretchCount,
  double fixedTotal,
) {
  final stretchWidth =
      ((usable - fixedTotal) / stretchCount).clamp(60.0, double.infinity);
  final result = [
    for (int i = 0; i < columns.length; i++)
      columns[i].stretchy == true ? stretchWidth : natural[i],
  ];
  // Guard: sub-pixel drift — shave excess from stretchy columns.
  final total = result.fold(0.0, (s, w) => s + w);
  if (total <= usable) return result;
  final adjusted = (stretchWidth - (total - usable) / stretchCount).clamp(60.0, double.infinity);
  return [
    for (int i = 0; i < columns.length; i++)
      columns[i].stretchy == true ? adjusted : natural[i],
  ];
}

/// Computes pixel widths for [columns] given [available] width and current [rows].
///
/// - Columns with [LogColumn.fixedSample]: width = max(label, fixedSample) + padding.
/// - Columns without fixedSample and not stretchy: width = max(label, widest cell value
///   across up to [_sampleLimit] rows) + padding.
/// - Stretchy columns ([LogColumn.stretchy]): share remaining space; minimum 60px.
/// - If fixed columns overflow usable space they are scaled down proportionally.
List<double> computeColumnWidths(
  List<LogColumn> columns,
  double available,
  List<dynamic> rows,
) {
  if (available <= 0 || columns.isEmpty) {
    return List.filled(columns.length, 0);
  }
  final usable = (available - _settingsReserved - (columns.length - 1) * AppLayout.gapM)
      .clamp(0.0, double.infinity);
  final sample = rows.length > _sampleLimit ? rows.sublist(0, _sampleLimit) : rows;

  double fixedTotal = 0;
  int stretchCount = 0;
  final natural = <double>[];

  for (final col in columns) {
    if (col.stretchy == true) {
      natural.add(0);
      stretchCount++;
    } else {
      final w = _naturalWidth(col, sample);
      natural.add(w);
      fixedTotal += w;
    }
  }

  if (fixedTotal >= usable) return _scaleToFit(columns, natural, usable);
  if (stretchCount > 0) return _distributeStretch(columns, natural, usable, stretchCount, fixedTotal);
  return natural;
}

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
                        separatorBuilder: (_, __) => const Divider(
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
  final List<dynamic> rows;
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
      menuRight = stackBox.size.width - (iconGlobal.dx - stackGlobal.dx) - iconBox.size.width;
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

  final dynamic row;
  final List<dynamic> allRows;
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
            final widths = computeColumnWidths(visibleColumns, constraints.maxWidth, allRows);
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
      return Text(text, style: AppText.body, overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1);
    }
    return Text(text, style: AppText.mono, overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1);
  }

  Color _severityColor(String severity) {
    return switch (severity.toUpperCase()) {
      'ERROR' || 'FATAL' => AppColors.error,
      'WARN' || 'WARNING' => Colors.orange,
      _ => Colors.black87,
    };
  }
}
