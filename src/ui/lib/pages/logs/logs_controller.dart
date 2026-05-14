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
  bool _loading = false;
  String? _error;
  String get filter => _filter;
  DateTime get from => _from;
  DateTime get to => _to;
  List<LogRow> get rows => _rows;
  bool get loading => _loading;
  String? get error => _error;
  void setFilter(String value) {
    _filter = value;
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
    notifyListeners();
    reload();
  }

  Future<void> reload() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await apiClient.getLogs(
        filter: _filter.isEmpty ? null : _filter,
        from: _from.toIso8601String(),
        to: _to.toIso8601String(),
      );
      _rows = results ?? [];
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
