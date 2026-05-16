/// Common column descriptor for content-aware table layout.
///
/// Both [LogColumn] and [TraceColumn] implement this interface so that
/// [computeColumnWidths] can be shared between the logs and traces tables.
abstract class ColumnDef {
  String get id;
  String get label;
  String? get fixedSample;
  bool get stretchy;
  bool get visible;
  String Function(dynamic) get getValueDynamic;
}
