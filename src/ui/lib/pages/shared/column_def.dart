abstract class ColumnDef {
  String get id;
  String get label;
  String? get fixedSample;
  bool get stretchy;
  bool get visible;
  bool get required;
  String Function(dynamic) get getValueDynamic;
}
