import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:river_api/api.dart';

import '../../controllers/time_range_controller.dart';

class TracesController extends ChangeNotifier {
  TracesController({required this.apiClient, required this.rangeController}) {
    rangeController.addListener(_onRangeChanged);
  }

  final DefaultApi apiClient;
  final TimeRangeController rangeController;

  String _filter = '';
  List<TraceGroup> _rows = [];
  bool _loading = false;
  String? _error;
  String? _selectedTraceId;
  String? _sortColumnId;
  bool _sortAsc = true;

  String get filter => _filter;
  DateTime get from => rangeController.from;
  DateTime get to => rangeController.to;
  List<TraceGroup> get rows => _sortedRows();
  bool get loading => _loading;
  String? get error => _error;
  String? get selectedTraceId => _selectedTraceId;
  String? get sortColumnId => _sortColumnId;
  bool get sortAsc => _sortAsc;

  void _onRangeChanged() {
    notifyListeners();
    reload();
  }

  void setFilter(String value) {
    _filter = value;
    _selectedTraceId = null;
    notifyListeners();
  }

  void selectTrace(String traceId) {
    _selectedTraceId = traceId;
    notifyListeners();
  }

  void clearSelection() {
    _selectedTraceId = null;
    notifyListeners();
  }

  void setSort(String columnId) {
    if (_sortColumnId == columnId) {
      _sortAsc = !_sortAsc;
    } else {
      _sortColumnId = columnId;
      _sortAsc = true;
    }
    notifyListeners();
  }

  List<TraceGroup> _sortedRows() {
    if (_sortColumnId == null) return List.unmodifiable(_rows);
    final sorted = List.of(_rows)
      ..sort((a, b) {
        final cmp = _valueForSort(a).compareTo(_valueForSort(b));
        return _sortAsc ? cmp : -cmp;
      });
    return sorted;
  }

  String _valueForSort(TraceGroup group) {
    return switch (_sortColumnId) {
      'traceId' => group.traceId,
      'rootService' => _rootService(group),
      'rootOperation' => _rootOperation(group),
      'durationMs' => _totalDurationMs(group).toStringAsFixed(2).padLeft(20, '0'),
      'spanCount' => group.spans.length.toString().padLeft(10, '0'),
      'startTime' => _earliestStartTime(group),
      _ => '',
    };
  }

  @override
  void dispose() {
    rangeController.removeListener(_onRangeChanged);
    super.dispose();
  }

  Future<void> reload() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final filter = _filter.isEmpty ? null : _filter;
      final from = rangeController.from.toIso8601String();
      final to = rangeController.to.toIso8601String();
      final result = await apiClient.getTraces(
        filter: filter,
        from: from,
        to: to,
        limit: 200,
      );
      _rows = result ?? [];
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

/// Returns the root span (the one with an empty parentSpanId), or the
/// first span if no root is found.
Span? rootSpan(TraceGroup group) {
  if (group.spans.isEmpty) return null;
  try {
    return group.spans.firstWhere((s) => s.parentSpanId.isEmpty);
  } catch (_) {
    return group.spans.first;
  }
}

String _rootService(TraceGroup group) => rootSpan(group)?.service ?? '';

String _rootOperation(TraceGroup group) => rootSpan(group)?.operation ?? '';

double _totalDurationMs(TraceGroup group) {
  if (group.spans.isEmpty) return 0;
  final root = rootSpan(group);
  return root?.durationMs ?? 0;
}

String _earliestStartTime(TraceGroup group) {
  if (group.spans.isEmpty) return '';
  return group.spans
      .map((s) => s.startTime)
      .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
}

String traceGroupRootService(TraceGroup group) => _rootService(group);
String traceGroupRootOperation(TraceGroup group) => _rootOperation(group);
double traceGroupDurationMs(TraceGroup group) => _totalDurationMs(group);
String traceGroupStartTime(TraceGroup group) => _earliestStartTime(group);
