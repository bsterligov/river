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
    return TabBarView(
      controller: widget.tabController,
      children: [
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _AllMetricsTab(controller: _controller),
        ),
        _GraphTab(controller: _controller),
      ],
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
        return Container(
          padding: AppLayout.cellPadding,
          alignment: Alignment.centerLeft,
          child: Text(
            name,
            style: AppText.mono.copyWith(color: AppColors.textBody),
            overflow: TextOverflow.ellipsis,
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
  final Set<String> _selected = {};
  Map<String, List<MetricPoint>> _series = {};
  bool _loadingSeries = false;
  String? _seriesError;

  @override
  void initState() {
    super.initState();
    widget.controller.rangeController.addListener(_onRangeChanged);
    widget.controller.addListener(_onNamesChanged);
  }

  @override
  void dispose() {
    widget.controller.rangeController.removeListener(_onRangeChanged);
    widget.controller.removeListener(_onNamesChanged);
    _inputController.dispose();
    super.dispose();
  }

  void _onNamesChanged() => setState(() {});

  void _onRangeChanged() {
    if (_selected.isNotEmpty) _loadSeries();
  }

  void _onSelected(String name) {
    if (_selected.contains(name)) return;
    setState(() => _selected.add(name));
    _inputController.clear();
    _loadSeries();
  }

  void _removeMetric(String name) {
    setState(() {
      _selected.remove(name);
      _series.remove(name);
    });
    if (_selected.isNotEmpty) _loadSeries();
  }

  Future<void> _loadSeries() async {
    if (_selected.isEmpty) return;
    setState(() {
      _loadingSeries = true;
      _seriesError = null;
    });
    try {
      final from = widget.controller.rangeController.from.toUtc().toIso8601String();
      final to = widget.controller.rangeController.to.toUtc().toIso8601String();
      final results = await Future.wait(
        _selected.map((name) async {
          final points = await widget.controller.fetchSeries(name, from, to);
          return MapEntry(name, points);
        }),
      );
      if (mounted) setState(() => _series = Map.fromEntries(results));
    } catch (e) {
      if (mounted) setState(() => _seriesError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingSeries = false);
    }
  }

  Widget _buildChartArea() {
    if (_loadingSeries) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_seriesError != null && _series.isEmpty) {
      return Center(
        child: Text(_seriesError!, style: const TextStyle(color: AppColors.error)),
      );
    }
    if (_selected.isEmpty) {
      return const Center(child: Text('Add a metric above to render a graph.'));
    }
    return MetricsChart(series: _series);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppLayout.gapXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricAutocomplete(
            names: widget.controller.names,
            selected: _selected,
            textController: _inputController,
            onSelected: _onSelected,
          ),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: AppLayout.gapM),
            _SelectedChips(
              selected: _selected,
              onRemove: _removeMetric,
            ),
          ],
          const SizedBox(height: AppLayout.gapL),
          Expanded(child: _buildChartArea()),
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
