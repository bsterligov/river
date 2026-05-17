import 'package:flutter/foundation.dart';
import 'package:river_api/api.dart';

import '../../controllers/time_range_controller.dart';
import '../../utils/api_error.dart';

class MetricsController extends ChangeNotifier {
  MetricsController({required this.apiClient, required this.rangeController}) {
    rangeController.addListener(_onRangeChanged);
  }

  final DefaultApi apiClient;
  final TimeRangeController rangeController;

  List<String> _names = [];
  final Set<String> _selected = {};
  Map<String, List<MetricPoint>> _series = {};
  bool _loadingNames = false;
  bool _loadingSeries = false;
  String? _error;

  List<String> get names => _names;
  Set<String> get selected => Set.unmodifiable(_selected);
  Map<String, List<MetricPoint>> get series => _series;
  bool get loadingNames => _loadingNames;
  bool get loadingSeries => _loadingSeries;
  String? get error => _error;
  DateTime get from => rangeController.from;
  DateTime get to => rangeController.to;

  void toggleSelection(String name) {
    if (_selected.contains(name)) {
      _selected.remove(name);
    } else {
      _selected.add(name);
    }
    notifyListeners();
  }

  void _onRangeChanged() {
    if (_selected.isNotEmpty) loadSeries();
  }

  Future<void> loadNames() async {
    _loadingNames = true;
    _error = null;
    notifyListeners();
    try {
      _names = (await apiClient.getMetricNames()) ?? [];
      _names.sort();
    } catch (e) {
      _error = extractApiError(e);
    }
    _loadingNames = false;
    notifyListeners();
  }

  Future<void> loadSeries() async {
    if (_selected.isEmpty) return;
    _loadingSeries = true;
    _error = null;
    notifyListeners();
    try {
      final from = rangeController.from.toUtc().toIso8601String();
      final to = rangeController.to.toUtc().toIso8601String();
      final results = await Future.wait(
        _selected.map((name) async {
          final points = await apiClient.getMetrics(
            filter: 'name:$name',
            from: from,
            to: to,
          );
          return MapEntry(name, points ?? <MetricPoint>[]);
        }),
      );
      _series = Map.fromEntries(results);
    } catch (e) {
      _error = extractApiError(e);
    }
    _loadingSeries = false;
    notifyListeners();
  }

  @override
  void dispose() {
    rangeController.removeListener(_onRangeChanged);
    super.dispose();
  }
}
