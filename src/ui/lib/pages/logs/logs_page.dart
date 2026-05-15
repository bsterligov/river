import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import '../../controllers/time_range_controller.dart';
import '../../widgets/facet_panel.dart';
import '../../widgets/log_detail_panel.dart';
import '../../widgets/log_histogram.dart';
import 'log_search_bar.dart';
import 'logs_controller.dart';
import 'logs_table.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key, required this.apiClient, required this.rangeController});

  final DefaultApi apiClient;
  final TimeRangeController rangeController;

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
    _controller = LogsController(apiClient: widget.apiClient, rangeController: widget.rangeController);
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
          LogHistogram(controller: _controller),
          const SizedBox(height: AppLayout.gapL),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                child!,
                const SizedBox(width: AppLayout.gapL),
                Expanded(child: _buildTable()),
              ],
            ),
          ),
        ],
      ),
      child: facetPanel,
    );
  }

  Widget _buildTable() {
    return Stack(
      children: [
        _controller.loading
            ? const Center(child: CircularProgressIndicator())
            : LogsTable(controller: _controller),
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
    return LogSearchBar(
      controller: searchController,
      onSubmit: onSubmit,
      errorText: controller.error,
    );
  }
}

