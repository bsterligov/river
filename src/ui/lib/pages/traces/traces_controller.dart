import 'package:flutter/foundation.dart';
import 'package:river_api/api.dart';

import '../../controllers/time_range_controller.dart';
import '../../utils/api_error.dart';
import '../../utils/format_time.dart';
import '../shared/column_def.dart';

class TraceColumn implements ColumnDef {
  const TraceColumn({
    required this.id,
    required this.label,
    required this.getValue,
    this.fixedSample,
    bool stretchy = false,
    bool visible = true,
  })  : _stretchy = stretchy,
        _visible = visible;

  @override
  final String id;
  @override
  final String label;
  @override
  final String? fixedSample;
  final String Function(TraceGroup) getValue;

  final bool? _stretchy;
  final bool? _visible;

  @override
  bool get stretchy => _stretchy ?? false;
  @override
  bool get visible => _visible ?? true;

  @override
  String Function(dynamic) get getValueDynamic => (row) => getValue(row as TraceGroup);

  TraceColumn copyWith({bool? visible}) => TraceColumn(
        id: id,
        label: label,
        fixedSample: fixedSample,
        stretchy: stretchy,
        getValue: getValue,
        visible: visible ?? this.visible,
      );
}

List<TraceColumn> defaultTraceColumns() => [
      TraceColumn(
        id: 'startTime',
        label: 'Start Time',
        fixedSample: 'Jan 28 23:59:59.999',
        getValue: (g) => formatTimestamp(traceGroupStartTime(g)),
      ),
      TraceColumn(
        id: 'traceId',
        label: 'Trace ID',
        fixedSample: '0000000000000000000000000000000a',
        getValue: (g) => g.traceId,
      ),
      TraceColumn(
        id: 'rootService',
        label: 'Root Service',
        getValue: (g) => traceGroupRootService(g),
      ),
      TraceColumn(
        id: 'rootOperation',
        label: 'Root Operation',
        stretchy: true,
        getValue: (g) => traceGroupRootOperation(g),
      ),
      TraceColumn(
        id: 'durationMs',
        label: 'Duration ms',
        getValue: (g) => traceGroupDurationMs(g).toStringAsFixed(2),
      ),
      TraceColumn(
        id: 'spanCount',
        label: 'Spans',
        getValue: (g) => g.spans.length.toString(),
      ),
    ];

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
  List<TraceColumn> _columns = defaultTraceColumns();

  String get filter => _filter;
  DateTime get from => rangeController.from;
  DateTime get to => rangeController.to;
  List<TraceGroup> get rows => _sortedRows();
  bool get loading => _loading;
  String? get error => _error;
  String? get selectedTraceId => _selectedTraceId;
  String? get sortColumnId => _sortColumnId;
  bool get sortAsc => _sortAsc;
  List<TraceColumn> get columns => List.unmodifiable(_columns);

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

  void toggleColumn(String id) {
    final idx = _columns.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _columns = List.of(_columns)..[idx] = _columns[idx].copyWith(
          visible: !_columns[idx].visible,
        );
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
    final col = _columns.firstWhere(
      (c) => c.id == _sortColumnId,
      orElse: () => _columns.first,
    );
    final sorted = List.of(_rows)
      ..sort((a, b) {
        final cmp = col.getValue(a).compareTo(col.getValue(b));
        return _sortAsc ? cmp : -cmp;
      });
    return sorted;
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
      _error = extractApiError(e);
      _loading = false;
    }
    notifyListeners();
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
