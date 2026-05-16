import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../controllers/time_range_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/river_search_bar.dart';
import 'trace_detail_panel.dart';
import 'traces_controller.dart';
import 'traces_table.dart';

class TracesPage extends StatefulWidget {
  const TracesPage({
    super.key,
    required this.apiClient,
    required this.rangeController,
  });

  final DefaultApi apiClient;
  final TimeRangeController rangeController;

  @override
  State<TracesPage> createState() => _TracesPageState();
}

class _TracesPageState extends State<TracesPage> {
  late final TracesController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TracesController(
      apiClient: widget.apiClient,
      rangeController: widget.rangeController,
    );
    _controller.reload();
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
          RiverSearchBar(
            fieldKey: const Key('traces_search'),
            controller: _searchController,
            onSubmit: _onSubmit,
            hintText: 'Filter (e.g. service:myapp AND operation:GET)',
            errorText: _controller.error,
          ),
          const SizedBox(height: AppLayout.gapL),
          Expanded(
            child: Stack(
              children: [
                _controller.loading
                    ? const Center(child: CircularProgressIndicator())
                    : TracesTable(controller: _controller),
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: TraceDetailPanel(controller: _controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
