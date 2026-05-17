import 'package:flutter/foundation.dart';
import 'package:river_api/api.dart';

import '../../controllers/time_range_controller.dart';
import '../../utils/api_error.dart';
import '../../utils/format_time.dart';
import '../shared/column_def.dart';
import '../shared/table_sort_state.dart';

class TraceColumn implements ColumnDef {
  const TraceColumn({
    required this.id,
    required this.label,
    required this.getValue,
    this.fixedSample,
    this.stretchy = false,
    this.visible = true,
    this.required = false,
  });

  @override
  final String id;
  @override
  final String label;
  @override
  final String? fixedSample;
  final String Function(TraceGroup) getValue;

  @override
  final bool stretchy;
  @override
  final bool visible;
  @override
  final bool required;

  @override
  String Function(dynamic) get getValueDynamic => (row) => getValue(row as TraceGroup);

  TraceColumn copyWith({bool? visible}) => TraceColumn(
        id: id,
        label: label,
        fixedSample: fixedSample,
        stretchy: stretchy,
        getValue: getValue,
        visible: visible ?? this.visible,
        required: required,
      );
}

List<TraceColumn> defaultTraceColumns() => [
      TraceColumn(
        id: 'startTime',
        label: 'Start Time',
        fixedSample: 'Jan 28 23:59:59.999',
        getValue: (g) => formatTimestamp(traceGroupStartTime(g)),
        required: true,
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
  final _sort = TableSortState<TraceColumn>(defaultTraceColumns());

  String get filter => _filter;
  DateTime get from => rangeController.from;
  DateTime get to => rangeController.to;
  List<TraceGroup> get rows => _sort.sortedRows(_rows).cast<TraceGroup>();
  bool get loading => _loading;
  String? get error => _error;
  String? get selectedTraceId => _selectedTraceId;
  String? get sortColumnId => _sort.sortColumnId;
  bool get sortAsc => _sort.sortAsc;
  List<TraceColumn> get columns => _sort.columns;

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
    if (_sort.toggleColumn(id, (c, v) => c.copyWith(visible: v))) notifyListeners();
  }

  void setSort(String columnId) {
    if (_sort.setSort(columnId)) notifyListeners();
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
