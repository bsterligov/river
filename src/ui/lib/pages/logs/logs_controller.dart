import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:river_api/api.dart';

class LogsController extends ChangeNotifier {
  LogsController({required this.apiClient}) {
    final now = DateTime.now().toUtc();
    _from = now.subtract(const Duration(hours: 1));
    _to = now;
  }

  final DefaultApi apiClient;

  String _filter = '';
  late DateTime _from;
  late DateTime _to;
  List<LogRow> _rows = [];
  List<HistogramBucket> _histogram = [];
  bool _loading = false;
  String? _error;
  LogRow? _selectedRow;
  // Incremented only when time range changes; facet panel uses this to skip
  // re-fetches caused by selection or loading notifications.
  int _rangeVersion = 0;
  String get filter => _filter;
  DateTime get from => _from;
  DateTime get to => _to;
  List<LogRow> get rows => _rows;
  List<HistogramBucket> get histogram => _histogram;
  bool get loading => _loading;
  String? get error => _error;
  LogRow? get selectedRow => _selectedRow;
  int get rangeVersion => _rangeVersion;

  void selectRow(LogRow row) {
    _selectedRow = row;
    notifyListeners();
  }

  void clearSelection() {
    _selectedRow = null;
    notifyListeners();
  }
  void setFilter(String value) {
    _filter = value;
    _selectedRow = null;
    notifyListeners();
  }

  void appendFilter(String token) {
    _filter = _filter.isEmpty ? token : '$_filter AND $token';
    notifyListeners();
    reload();
  }

  void setRange(DateTime from, DateTime to) {
    _from = from;
    _to = to;
    _rangeVersion++;
    notifyListeners();
    reload();
  }

  Future<void> reload() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = _filter.isEmpty ? null : _filter;
      final from = _from.toIso8601String();
      final to = _to.toIso8601String();
      final rowsFuture = apiClient.getLogs(filter: filter, from: from, to: to);
      final histFuture = apiClient.getLogsHistogram(filter: filter, from: from, to: to);
      final rows = await rowsFuture;
      final hist = await histFuture;
      _rows = rows ?? [];
      _histogram = hist ?? [];
      _loading = false;
    } catch (e) {
      _error = _extractError(e);
      _loading = false;
    }
    notifyListeners();
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
}
