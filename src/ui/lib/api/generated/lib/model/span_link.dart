//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SpanLink {
  /// Returns a new [SpanLink] instance.
  SpanLink({
    required this.attributes,
    required this.spanId,
    required this.traceId,
  });

  Object? attributes;

  String spanId;

  String traceId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SpanLink &&
    other.attributes == attributes &&
    other.spanId == spanId &&
    other.traceId == traceId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (attributes == null ? 0 : attributes!.hashCode) +
    (spanId.hashCode) +
    (traceId.hashCode);

  @override
  String toString() => 'SpanLink[attributes=$attributes, spanId=$spanId, traceId=$traceId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.attributes != null) {
      json[r'attributes'] = this.attributes;
    } else {
      json[r'attributes'] = null;
    }
      json[r'span_id'] = this.spanId;
      json[r'trace_id'] = this.traceId;
    return json;
  }

  /// Returns a new [SpanLink] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SpanLink? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'attributes'), 'Required key "SpanLink[attributes]" is missing from JSON.');
        assert(json.containsKey(r'span_id'), 'Required key "SpanLink[span_id]" is missing from JSON.');
        assert(json[r'span_id'] != null, 'Required key "SpanLink[span_id]" has a null value in JSON.');
        assert(json.containsKey(r'trace_id'), 'Required key "SpanLink[trace_id]" is missing from JSON.');
        assert(json[r'trace_id'] != null, 'Required key "SpanLink[trace_id]" has a null value in JSON.');
        return true;
      }());

      return SpanLink(
        attributes: mapValueOfType<Object>(json, r'attributes'),
        spanId: mapValueOfType<String>(json, r'span_id')!,
        traceId: mapValueOfType<String>(json, r'trace_id')!,
      );
    }
    return null;
  }

  static List<SpanLink> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SpanLink>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SpanLink.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SpanLink> mapFromJson(dynamic json) {
    final map = <String, SpanLink>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SpanLink.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SpanLink-objects as value to a dart map
  static Map<String, List<SpanLink>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SpanLink>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SpanLink.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'attributes',
    'span_id',
    'trace_id',
  };
}

