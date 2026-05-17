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

class _GraphTab extends StatefulWidget {
  const _GraphTab({required this.controller});

  final MetricsController controller;

  @override
  State<_GraphTab> createState() => _GraphTabState();
}

class _GraphTabState extends State<_GraphTab> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _onSelected(String name) {
    widget.controller.toggleSelection(name);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Padding(
      padding: const EdgeInsets.all(AppLayout.gapXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _MetricAutocomplete(
                  names: controller.names,
                  selected: controller.selected,
                  textController: _inputController,
                  onSelected: _onSelected,
                ),
              ),
              const SizedBox(width: AppLayout.gapM),
              FilledButton(
                onPressed: controller.loadingSeries || controller.selected.isEmpty
                    ? null
                    : controller.loadSeries,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Refresh'),
              ),
            ],
          ),
          if (controller.selected.isNotEmpty) ...[
            const SizedBox(height: AppLayout.gapM),
            _SelectedChips(
              selected: controller.selected,
              onRemove: controller.toggleSelection,
            ),
          ],
          const SizedBox(height: AppLayout.gapL),
          Expanded(
            child: controller.loadingSeries
                ? const Center(child: CircularProgressIndicator())
                : controller.error != null && controller.series.isEmpty
                    ? Center(
                        child: Text(controller.error!,
                            style: const TextStyle(color: AppColors.error)))
                    : controller.selected.isEmpty
                        ? const Center(
                            child: Text('Add a metric above to render a graph.'))
                        : MetricsChart(series: controller.series),
          ),
        ],
      ),
    );
  }
}

class _MetricAutocomplete extends StatelessWidget {
  const _MetricAutocomplete({
    required this.names,
    required this.selected,
    required this.textController,
    required this.onSelected,
  });

  final List<String> names;
  final Set<String> selected;
  final TextEditingController textController;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return names;
        return names.where((n) => n.toLowerCase().contains(q));
      },
      displayStringForOption: (n) => n,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        // Keep external controller in sync so we can clear it.
        controller.text = textController.text;
        controller.addListener(() => textController.text = controller.text);
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            hintText: 'Add metric…',
            isDense: true,
          ),
          style: AppText.mono,
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(AppLayout.radius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemExtent: 36,
              itemBuilder: (context, index) {
                final name = options.elementAt(index);
                final alreadySelected = selected.contains(name);
                return InkWell(
                  onTap: () => onSelected(name),
                  child: Container(
                    color: alreadySelected ? AppColors.rowSelected : null,
                    padding: AppLayout.cellPadding,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      name,
                      style: AppText.mono.copyWith(
                        color: alreadySelected ? AppColors.primary : AppColors.textBody,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      onSelected: onSelected,
    );
  }
}

class _SelectedChips extends StatelessWidget {
  const _SelectedChips({required this.selected, required this.onRemove});

  final Set<String> selected;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppLayout.gapM,
      runSpacing: AppLayout.gapS,
      children: selected.map((name) {
        return Chip(
          label: Text(name, style: AppText.mono.copyWith(fontSize: 11)),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: () => onRemove(name),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: AppLayout.gapS),
          backgroundColor: AppColors.rowSelected,
          side: const BorderSide(color: AppColors.primary, width: 0.5),
          labelStyle: AppText.mono.copyWith(color: AppColors.primary, fontSize: 11),
        );
      }).toList(),
    );
  }
}
