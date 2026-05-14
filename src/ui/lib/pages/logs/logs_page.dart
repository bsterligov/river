import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import 'facet_panel.dart';
import 'log_detail_panel.dart';
import 'log_search_bar.dart';
import 'logs_controller.dart';
import 'time_range_picker.dart';

export 'facet_panel.dart';
export 'log_detail_panel.dart';
export 'log_search_bar.dart';
export 'logs_controller.dart';
export 'time_range_picker.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key, required this.apiClient});

  final DefaultApi apiClient;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  late final LogsController _controller;
  final _searchController = TextEditingController();
  String _manualFilter = '';

  @override
  void initState() {
    super.initState();
    _controller = LogsController(apiClient: widget.apiClient);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSubmit(String value) {
    setState(() => _manualFilter = value);
    _controller.setFilter(value);
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final facetPanel = FacetPanel(
      controller: _controller,
      searchController: _searchController,
      manualFilter: _manualFilter,
    );
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Toolbar(
            controller: _controller,
            searchController: _searchController,
            onSubmit: _onSubmit,
          ),
          const SizedBox(height: AppLayout.gapL),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                child!,
                const SizedBox(width: AppLayout.gapL),
                Expanded(child: _buildMain()),
              ],
            ),
          ),
        ],
      ),
      child: facetPanel,
    );
  }

  Widget _buildMain() {
    if (_controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        _LogsTable(
          rows: _controller.rows,
          controller: _controller,
        ),
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          child: LogDetailPanel(controller: _controller),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.searchController,
    required this.onSubmit,
  });

  final LogsController controller;
  final TextEditingController searchController;
  final void Function(String) onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LogSearchBar(
            controller: searchController,
            onSubmit: onSubmit,
            errorText: controller.error,
          ),
        ),
        const SizedBox(width: AppLayout.gapL),
        TimeRangePicker(
          onRange: controller.setRange,
        ),
      ],
    );
  }
}

class _LogsTable extends StatelessWidget {
  const _LogsTable({required this.rows, required this.controller});

  final List<LogRow> rows;
  final LogsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppLayout.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TableHeader(),
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
                      builder: (context, _) => _LogRow(
                        row: rows[i],
                        selected: controller.selectedRow == rows[i],
                        onTap: () => controller.selectRow(rows[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tableHeader,
      padding: AppLayout.headerPadding,
      child: const Row(
        children: [
          _HeaderCell('Timestamp', flex: 3),
          _HeaderCell('Severity', flex: 1),
          _HeaderCell('Service', flex: 2),
          _HeaderCell('Message', flex: 5),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label, style: AppText.label),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.row, required this.selected, required this.onTap});

  final LogRow row;
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
            Expanded(flex: 3, child: Text(_fmtTs(row.timestamp), style: AppText.mono)),
            Expanded(
              flex: 1,
              child: Text(
                row.severity,
                style: AppText.label.copyWith(
                  color: _severityColor(row.severity),
                ),
              ),
            ),
            Expanded(flex: 2, child: Text(row.service, style: AppText.mono)),
            Expanded(flex: 5, child: Text(row.body, style: AppText.body)),
          ],
        ),
      ),
    );
  }

  static String _fmtTs(String ts) {
    final dt = DateTime.tryParse(ts);
    if (dt == null) return ts;
    final local = dt.toLocal();
    final mon = const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][local.month - 1];
    final ms = (local.millisecond).toString().padLeft(3, '0');
    return '$mon ${local.day.toString().padLeft(2)} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}.$ms';
  }

  Color _severityColor(String severity) {
    return switch (severity.toUpperCase()) {
      'ERROR' || 'FATAL' => AppColors.error,
      'WARN' || 'WARNING' => Colors.orange,
      _ => Colors.black87,
    };
  }
}
