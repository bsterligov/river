import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import '../../controllers/time_range_controller.dart';
import '../../widgets/facet_panel.dart';
import '../../widgets/log_detail_panel.dart';
import '../../widgets/log_histogram.dart';
import '../../widgets/river_search_bar.dart';
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
  bool _facetExpanded = true;

  @override
  void initState() {
    super.initState();
    _controller = LogsController(apiClient: widget.apiClient, rangeController: widget.rangeController);
    _controller.reload().onError((e, _) => debugPrint('LogsPage: initial reload failed: $e'));
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
      expanded: _facetExpanded,
      onToggle: () => setState(() => _facetExpanded = !_facetExpanded),
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
                _CollapsibleFacetPanel(
                  expanded: _facetExpanded,
                  child: child!,
                ),
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

class _CollapsibleFacetPanel extends StatelessWidget {
  const _CollapsibleFacetPanel({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  static const _collapsedWidth = AppLayout.collapsedFacetPanelWidth;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppLayout.radius);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: expanded ? AppLayout.facetPanelWidth : _collapsedWidth,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: AppLayout.facetPanelWidth,
          maxWidth: AppLayout.facetPanelWidth,
          child: child,
        ),
      ),
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
    return FilterBar(
      fieldKey: const Key('logs_search'),
      controller: searchController,
      onSubmit: onSubmit,
      hintText: 'Filter (e.g. service:myapp AND severity:ERROR)',
      errorText: controller.error,
    );
  }
}

