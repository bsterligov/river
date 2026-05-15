import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:river_api/api.dart';

import '../../time_range_controller.dart';

class LogColumn {
  const LogColumn({
    required this.id,
    required this.label,
    required this.getValue,
    this.fixedSample,
    bool stretchy = false,
    bool visible = true,
  })  : _stretchy = stretchy,
        _visible = visible;

  final String id;
  final String label;
  final String? fixedSample;
  final String Function(LogRow) getValue;

  // Stored as nullable so dart2 interop cannot make the getter throw.
  final bool? _stretchy;
  final bool? _visible;

  bool get stretchy => _stretchy ?? false;
  bool get visible => _visible ?? true;

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
        getValue: (r) {
          final dt = DateTime.tryParse(r.timestamp);
          if (dt == null) return r.timestamp;
          final local = dt.toLocal();
          final mon = const [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
          ][local.month - 1];
          final ms = local.millisecond.toString().padLeft(3, '0');
          return '$mon ${local.day.toString().padLeft(2)} '
              '${local.hour.toString().padLeft(2, '0')}:'
              '${local.minute.toString().padLeft(2, '0')}:'
              '${local.second.toString().padLeft(2, '0')}.$ms';
        },
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
  List<LogColumn> _columns = defaultColumns();
  String? _sortColumnId;
  bool _sortAsc = true;

  String get filter => _filter;
  DateTime get from => rangeController.from;
  DateTime get to => rangeController.to;
  List<LogRow> get rows => _sortedRows();
  List<HistogramBucket> get histogram => _histogram;
  bool get loading => _loading;
  String? get error => _error;
  LogRow? get selectedRow => _selectedRow;
  int get rangeVersion => _rangeVersion;
  List<LogColumn> get columns => List.unmodifiable(_columns);
  String? get sortColumnId => _sortColumnId;
  bool get sortAsc => _sortAsc;

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

  List<LogRow> _sortedRows() {
    if (_sortColumnId == null) return List.unmodifiable(_rawRows);
    final col = _columns.firstWhere(
      (c) => c.id == _sortColumnId,
      orElse: () => _columns.first,
    );
    final sorted = List.of(_rawRows)
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
      final rowsFuture = apiClient.getLogs(filter: filter, from: from, to: to);
      final histFuture = apiClient.getLogsHistogram(filter: filter, from: from, to: to);
      final rows = await rowsFuture;
      final hist = await histFuture;
      _rawRows = rows ?? [];
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
