import 'package:flutter/foundation.dart';
import 'package:river_api/api.dart';

import '../../controllers/time_range_controller.dart';
import '../../utils/api_error.dart';

class MetricsController extends ChangeNotifier {
  MetricsController({required this.apiClient, required this.rangeController});

  final DefaultApi apiClient;
  final TimeRangeController rangeController;

  List<String> _names = [];
  bool _loadingNames = false;
  String? _error;

  List<String> get names => _names;
  bool get loadingNames => _loadingNames;
  String? get error => _error;

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

  Future<List<MetricPoint>> fetchSeries(String name, String from, String to) async {
    final points = await apiClient.getMetrics(filter: 'name:$name', from: from, to: to);
    return points ?? <MetricPoint>[];
  }
}
