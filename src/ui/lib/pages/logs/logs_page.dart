import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import 'log_search_bar.dart';
import 'logs_controller.dart';
import 'time_range_picker.dart';

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
    _controller.setFilter(value);
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Toolbar(
            controller: _controller,
            searchController: _searchController,
            onSubmit: _onSubmit,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FacetPlaceholder(),
                const SizedBox(width: 12),
                Expanded(child: _buildMain()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMain() {
    if (_controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SelectionArea(child: _LogsTable(rows: _controller.rows));
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
        const SizedBox(width: 12),
        TimeRangePicker(
          onRange: controller.setRange,
        ),
      ],
    );
  }
}

class _FacetPlaceholder extends StatelessWidget {
  const _FacetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _LogsTable extends StatelessWidget {
  const _LogsTable({required this.rows});

  final List<LogRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
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
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (_, i) => _LogRow(row: rows[i]),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
  const _LogRow({required this.row});

  final LogRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
