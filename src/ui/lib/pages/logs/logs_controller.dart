import 'package:flutter/foundation.dart';
import 'package:river_api/api.dart';

import '../../controllers/time_range_controller.dart';
import '../../utils/api_error.dart';
import '../../utils/format_time.dart';
import '../shared/column_def.dart';
import '../shared/table_sort_state.dart';

class LogColumn implements ColumnDef {
  const LogColumn({
    required this.id,
    required this.label,
    required this.getValue,
    this.fixedSample,
    this.stretchy = false,
    this.visible = true,
  });

  @override
  final String id;
  @override
  final String label;
  @override
  final String? fixedSample;
  final String Function(LogRow) getValue;

  @override
  final bool stretchy;
  @override
  final bool visible;

  @override
  String Function(dynamic) get getValueDynamic => (row) => getValue(row as LogRow);

  LogColumn copyWith({bool? visible}) => LogColumn(
        id: id,
        label: label,
        fixedSample: fixedSample,
        stretchy: stretchy,
        getValue: getValue,
        visible: visible ?? this.visible,
      );
}

List<LogColumn> defaultColumns() => [
      LogColumn(
        id: 'timestamp',
        label: 'Timestamp',
        // All formatted timestamps are the same character width.
        fixedSample: 'Jan 28 23:59:59.999',
        getValue: (r) => formatTimestamp(r.timestamp),
      ),
      LogColumn(
        id: 'severity',
        label: 'Severity',
        getValue: (r) => r.severity,
      ),
      LogColumn(
        id: 'service',
        label: 'Service',
        getValue: (r) => r.service,
      ),
      LogColumn(
        id: 'message',
        label: 'Message',
        stretchy: true,
        getValue: (r) => r.body,
      ),
      LogColumn(
        id: 'traceId',
        label: 'TraceID',
        fixedSample: '0000000000000000000000000000000a',
        getValue: (r) => r.traceId,
        visible: false,
      ),
      LogColumn(
        id: 'spanId',
        label: 'SpanID',
        fixedSample: '000000000000000a',
        getValue: (r) => r.spanId,
        visible: false,
      ),
    ];

class LogsController extends ChangeNotifier {
  LogsController({required this.apiClient, required this.rangeController}) {
    rangeController.addListener(_onRangeChanged);
  }

  final DefaultApi apiClient;
  final TimeRangeController rangeController;

  String _filter = '';
  List<LogRow> _rawRows = [];
  List<HistogramBucket> _histogram = [];
  bool _loading = false;
  String? _error;
  LogRow? _selectedRow;
  // Incremented only when time range changes; facet panel uses this to skip
  // re-fetches caused by selection or loading notifications.
  int _rangeVersion = 0;
  final _sort = TableSortState<LogColumn>(defaultColumns());

  String get filter => _filter;
  DateTime get from => rangeController.from;
  DateTime get to => rangeController.to;
  List<LogRow> get rows => _sort.sortedRows(_rawRows);
  List<HistogramBucket> get histogram => _histogram;
  bool get loading => _loading;
  String? get error => _error;
  LogRow? get selectedRow => _selectedRow;
  int get rangeVersion => _rangeVersion;
  List<LogColumn> get columns => _sort.columns;
  String? get sortColumnId => _sort.sortColumnId;
  bool get sortAsc => _sort.sortAsc;

  void _onRangeChanged() {
    _rangeVersion++;
    notifyListeners();
    reload();
  }

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
      final rowsFuture = apiClient.getLogs(filter: filter, from: from, to: to);
      final histFuture = apiClient.getLogsHistogram(filter: filter, from: from, to: to);
      final rows = await rowsFuture;
      final hist = await histFuture;
      _rawRows = rows ?? [];
      _histogram = hist ?? [];
      _loading = false;
    } catch (e) {
      _error = extractApiError(e);
      _loading = false;
    }
    notifyListeners();
  }

}
