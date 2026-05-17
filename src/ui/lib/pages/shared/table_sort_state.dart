import 'column_def.dart';

/// Manages column visibility and sort state for a table controller.
///
/// Controllers compose this rather than duplicate toggleColumn/setSort/_sortedRows.
class TableSortState<C extends ColumnDef> {
  TableSortState(List<C> columns) : _columns = columns;

  List<C> _columns;
  String? _sortColumnId;
  bool _sortAsc = true;

  String? get sortColumnId => _sortColumnId;
  bool get sortAsc => _sortAsc;
  List<C> get columns => List.unmodifiable(_columns);

  /// Returns true if state changed (caller should call notifyListeners).
  /// Required columns cannot be hidden and are silently ignored.
  bool toggleColumn(String id, C Function(C col, bool visible) copyWith) {
    final idx = _columns.indexWhere((c) => c.id == id);
    if (idx == -1) return false;
    if (_columns[idx].required) return false;
    _columns = List.of(_columns)..[idx] = copyWith(_columns[idx], !_columns[idx].visible);
    return true;
  }

  /// Returns true if state changed (caller should call notifyListeners).
  bool setSort(String columnId) {
    if (_sortColumnId == columnId) {
      _sortAsc = !_sortAsc;
    } else {
      _sortColumnId = columnId;
      _sortAsc = true;
    }
    return true;
  }

  List<T> sortedRows<T>(List<T> rows) {
    if (_sortColumnId == null) return List.unmodifiable(rows);
    final col = _columns.firstWhere(
      (c) => c.id == _sortColumnId,
      orElse: () => _columns.first,
    );
    final sorted = List.of(rows)
      ..sort((a, b) {
        final cmp = col.getValueDynamic(a).compareTo(col.getValueDynamic(b));
        return _sortAsc ? cmp : -cmp;
      });
    return sorted;
  }
}
