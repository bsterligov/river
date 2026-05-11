import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../theme/app_theme.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key, required this.apiClient});

  final DefaultApi apiClient;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final _searchController = TextEditingController();
  List<LogRow> _rows = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String filter) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.apiClient.getLogs(
        filter: filter.isEmpty ? null : filter,
      );
      setState(() {
        _rows = results ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = _extractError(e);
        _loading = false;
      });
    }
  }

  String _extractError(Object e) {
    if (e is ApiException) {
      try {
        final body = jsonDecode(e.message ?? '') as Map<String, dynamic>;
        final msg = body['error'] as String?;
        if (msg != null && msg.isNotEmpty) return msg;
      } catch (_) {}
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchBar(
          controller: _searchController,
          onSearch: _search,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildTable(),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AppColors.error)),
      );
    }
    return SelectionArea(child: _LogsTable(rows: _rows));
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final void Function(String) onSearch;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('logs_search'),
      controller: controller,
      decoration: const InputDecoration(
        hintText: 'Filter logs (e.g. service:myapp AND level:error)',
        prefixIcon: Icon(Icons.search, size: 18),
      ),
      onSubmitted: onSearch,
      style: AppText.mono,
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
                    separatorBuilder: (context, index) =>
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
          Expanded(flex: 3, child: Text(row.timestamp, style: AppText.mono)),
          Expanded(
            flex: 1,
            child: Text(
              row.severity,
              style: AppText.label.copyWith(color: _severityColor(row.severity)),
            ),
          ),
          Expanded(flex: 2, child: Text(row.service, style: AppText.mono)),
          Expanded(flex: 5, child: Text(row.body, style: AppText.body)),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    return switch (severity.toUpperCase()) {
      'ERROR' || 'FATAL' => AppColors.error,
      'WARN' || 'WARNING' => Colors.orange,
      _ => Colors.black87,
    };
  }
}
