//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TraceGroup {
  /// Returns a new [TraceGroup] instance.
  TraceGroup({
    this.spans = const [],
    required this.traceId,
  });

  List<Span> spans;

  String traceId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TraceGroup &&
    _deepEquality.equals(other.spans, spans) &&
    other.traceId == traceId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (spans.hashCode) +
    (traceId.hashCode);

  @override
  String toString() => 'TraceGroup[spans=$spans, traceId=$traceId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'spans'] = this.spans;
      json[r'trace_id'] = this.traceId;
    return json;
  }

  /// Returns a new [TraceGroup] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TraceGroup? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'spans'), 'Required key "TraceGroup[spans]" is missing from JSON.');
        assert(json[r'spans'] != null, 'Required key "TraceGroup[spans]" has a null value in JSON.');
        assert(json.containsKey(r'trace_id'), 'Required key "TraceGroup[trace_id]" is missing from JSON.');
        assert(json[r'trace_id'] != null, 'Required key "TraceGroup[trace_id]" has a null value in JSON.');
        return true;
      }());

      return TraceGroup(
        spans: Span.listFromJson(json[r'spans']),
        traceId: mapValueOfType<String>(json, r'trace_id')!,
      );
    }
    return null;
  }

  static List<TraceGroup> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TraceGroup>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TraceGroup.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TraceGroup> mapFromJson(dynamic json) {
    final map = <String, TraceGroup>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TraceGroup.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TraceGroup-objects as value to a dart map
  static Map<String, List<TraceGroup>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TraceGroup>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TraceGroup.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'spans',
    'trace_id',
  };
}

