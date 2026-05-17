import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../controllers/time_range_controller.dart';
import '../../theme/app_theme.dart';
import 'metrics_chart.dart';
import 'metrics_controller.dart';

class MetricsPage extends StatefulWidget {
  const MetricsPage({
    super.key,
    required this.apiClient,
    required this.rangeController,
    required this.tabController,
  });

  final DefaultApi apiClient;
  final TimeRangeController rangeController;
  final TabController tabController;

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  late final MetricsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MetricsController(
      apiClient: widget.apiClient,
      rangeController: widget.rangeController,
    );
    _controller.loadNames();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => TabBarView(
        controller: widget.tabController,
        children: [
          _AllMetricsTab(controller: _controller),
          _GraphTab(controller: _controller),
        ],
      ),
    );
  }
}

class _AllMetricsTab extends StatelessWidget {
  const _AllMetricsTab({required this.controller});

  final MetricsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.loadingNames) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null && controller.names.isEmpty) {
      return Center(
        child: Text(controller.error!, style: const TextStyle(color: AppColors.error)),
      );
    }
    if (controller.names.isEmpty) {
      return const Center(child: Text('No metrics found.'));
    }
    return ListView.builder(
      itemCount: controller.names.length,
      itemExtent: 40,
      itemBuilder: (context, index) {
        final name = controller.names[index];
        final selected = controller.selected.contains(name);
        return GestureDetector(
          onTap: () => controller.toggleSelection(name),
          child: Container(
            color: selected ? AppColors.rowSelected : Colors.transparent,
            padding: AppLayout.cellPadding,
            alignment: Alignment.centerLeft,
            child: Text(
              name,
              style: AppText.mono.copyWith(
                color: selected ? AppColors.primary : AppColors.textBody,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

class _GraphTab extends StatelessWidget {
  const _GraphTab({required this.controller});

  final MetricsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.selected.isEmpty) {
      return const Center(
        child: Text('Select one or more metrics in the "All Metrics" tab.'),
      );
    }
    if (controller.loadingSeries) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null && controller.series.isEmpty) {
      return Center(
        child: Text(controller.error!, style: const TextStyle(color: AppColors.error)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppLayout.gapXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              FilledButton(
                onPressed: controller.loadingSeries ? null : controller.loadSeries,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.gapL),
          Expanded(
            child: MetricsChart(series: controller.series),
          ),
        ],
      ),
    );
  }
}
