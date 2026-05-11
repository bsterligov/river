//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Span {
  /// Returns a new [Span] instance.
  Span({
    required this.durationMs,
    required this.endTime,
    this.events = const [],
    this.links = const [],
    required this.operation,
    required this.parentSpanId,
    required this.service,
    required this.spanId,
    required this.startTime,
    required this.statusCode,
  });

  double durationMs;

  String endTime;

  List<SpanEvent> events;

  List<SpanLink> links;

  String operation;

  String parentSpanId;

  String service;

  String spanId;

  String startTime;

  int statusCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Span &&
    other.durationMs == durationMs &&
    other.endTime == endTime &&
    _deepEquality.equals(other.events, events) &&
    _deepEquality.equals(other.links, links) &&
    other.operation == operation &&
    other.parentSpanId == parentSpanId &&
    other.service == service &&
    other.spanId == spanId &&
    other.startTime == startTime &&
    other.statusCode == statusCode;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (durationMs.hashCode) +
    (endTime.hashCode) +
    (events.hashCode) +
    (links.hashCode) +
    (operation.hashCode) +
    (parentSpanId.hashCode) +
    (service.hashCode) +
    (spanId.hashCode) +
    (startTime.hashCode) +
    (statusCode.hashCode);

  @override
  String toString() => 'Span[durationMs=$durationMs, endTime=$endTime, events=$events, links=$links, operation=$operation, parentSpanId=$parentSpanId, service=$service, spanId=$spanId, startTime=$startTime, statusCode=$statusCode]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'duration_ms'] = this.durationMs;
      json[r'end_time'] = this.endTime;
      json[r'events'] = this.events;
      json[r'links'] = this.links;
      json[r'operation'] = this.operation;
      json[r'parent_span_id'] = this.parentSpanId;
      json[r'service'] = this.service;
      json[r'span_id'] = this.spanId;
      json[r'start_time'] = this.startTime;
      json[r'status_code'] = this.statusCode;
    return json;
  }

  /// Returns a new [Span] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Span? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'duration_ms'), 'Required key "Span[duration_ms]" is missing from JSON.');
        assert(json[r'duration_ms'] != null, 'Required key "Span[duration_ms]" has a null value in JSON.');
        assert(json.containsKey(r'end_time'), 'Required key "Span[end_time]" is missing from JSON.');
        assert(json[r'end_time'] != null, 'Required key "Span[end_time]" has a null value in JSON.');
        assert(json.containsKey(r'events'), 'Required key "Span[events]" is missing from JSON.');
        assert(json[r'events'] != null, 'Required key "Span[events]" has a null value in JSON.');
        assert(json.containsKey(r'links'), 'Required key "Span[links]" is missing from JSON.');
        assert(json[r'links'] != null, 'Required key "Span[links]" has a null value in JSON.');
        assert(json.containsKey(r'operation'), 'Required key "Span[operation]" is missing from JSON.');
        assert(json[r'operation'] != null, 'Required key "Span[operation]" has a null value in JSON.');
        assert(json.containsKey(r'parent_span_id'), 'Required key "Span[parent_span_id]" is missing from JSON.');
        assert(json[r'parent_span_id'] != null, 'Required key "Span[parent_span_id]" has a null value in JSON.');
        assert(json.containsKey(r'service'), 'Required key "Span[service]" is missing from JSON.');
        assert(json[r'service'] != null, 'Required key "Span[service]" has a null value in JSON.');
        assert(json.containsKey(r'span_id'), 'Required key "Span[span_id]" is missing from JSON.');
        assert(json[r'span_id'] != null, 'Required key "Span[span_id]" has a null value in JSON.');
        assert(json.containsKey(r'start_time'), 'Required key "Span[start_time]" is missing from JSON.');
        assert(json[r'start_time'] != null, 'Required key "Span[start_time]" has a null value in JSON.');
        assert(json.containsKey(r'status_code'), 'Required key "Span[status_code]" is missing from JSON.');
        assert(json[r'status_code'] != null, 'Required key "Span[status_code]" has a null value in JSON.');
        return true;
      }());

      return Span(
        durationMs: mapValueOfType<double>(json, r'duration_ms')!,
        endTime: mapValueOfType<String>(json, r'end_time')!,
        events: SpanEvent.listFromJson(json[r'events']),
        links: SpanLink.listFromJson(json[r'links']),
        operation: mapValueOfType<String>(json, r'operation')!,
        parentSpanId: mapValueOfType<String>(json, r'parent_span_id')!,
        service: mapValueOfType<String>(json, r'service')!,
        spanId: mapValueOfType<String>(json, r'span_id')!,
        startTime: mapValueOfType<String>(json, r'start_time')!,
        statusCode: mapValueOfType<int>(json, r'status_code')!,
      );
    }
    return null;
  }

  static List<Span> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Span>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Span.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Span> mapFromJson(dynamic json) {
    final map = <String, Span>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Span.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Span-objects as value to a dart map
  static Map<String, List<Span>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Span>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Span.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'duration_ms',
    'end_time',
    'events',
    'links',
    'operation',
    'parent_span_id',
    'service',
    'span_id',
    'start_time',
    'status_code',
  };
}

