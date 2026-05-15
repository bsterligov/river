//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LogRow {
  /// Returns a new [LogRow] instance.
  LogRow({
    required this.attributes,
    required this.body,
    required this.service,
    required this.severity,
    required this.severityNumber,
    required this.spanId,
    required this.timestamp,
    required this.traceId,
  });

  Object? attributes;

  String body;

  String service;

  String severity;

  int severityNumber;

  String spanId;

  String timestamp;

  String traceId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LogRow &&
    other.attributes == attributes &&
    other.body == body &&
    other.service == service &&
    other.severity == severity &&
    other.severityNumber == severityNumber &&
    other.spanId == spanId &&
    other.timestamp == timestamp &&
    other.traceId == traceId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (attributes == null ? 0 : attributes!.hashCode) +
    (body.hashCode) +
    (service.hashCode) +
    (severity.hashCode) +
    (severityNumber.hashCode) +
    (spanId.hashCode) +
    (timestamp.hashCode) +
    (traceId.hashCode);

  @override
  String toString() => 'LogRow[attributes=$attributes, body=$body, service=$service, severity=$severity, severityNumber=$severityNumber, spanId=$spanId, timestamp=$timestamp, traceId=$traceId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.attributes != null) {
      json[r'attributes'] = this.attributes;
    } else {
      json[r'attributes'] = null;
    }
      json[r'body'] = this.body;
      json[r'service'] = this.service;
      json[r'severity'] = this.severity;
      json[r'severity_number'] = this.severityNumber;
      json[r'span_id'] = this.spanId;
      json[r'timestamp'] = this.timestamp;
      json[r'trace_id'] = this.traceId;
    return json;
  }

  /// Returns a new [LogRow] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LogRow? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'attributes'), 'Required key "LogRow[attributes]" is missing from JSON.');
        assert(json.containsKey(r'body'), 'Required key "LogRow[body]" is missing from JSON.');
        assert(json[r'body'] != null, 'Required key "LogRow[body]" has a null value in JSON.');
        assert(json.containsKey(r'service'), 'Required key "LogRow[service]" is missing from JSON.');
        assert(json[r'service'] != null, 'Required key "LogRow[service]" has a null value in JSON.');
        assert(json.containsKey(r'severity'), 'Required key "LogRow[severity]" is missing from JSON.');
        assert(json[r'severity'] != null, 'Required key "LogRow[severity]" has a null value in JSON.');
        assert(json.containsKey(r'severity_number'), 'Required key "LogRow[severity_number]" is missing from JSON.');
        assert(json[r'severity_number'] != null, 'Required key "LogRow[severity_number]" has a null value in JSON.');
        assert(json.containsKey(r'span_id'), 'Required key "LogRow[span_id]" is missing from JSON.');
        assert(json[r'span_id'] != null, 'Required key "LogRow[span_id]" has a null value in JSON.');
        assert(json.containsKey(r'timestamp'), 'Required key "LogRow[timestamp]" is missing from JSON.');
        assert(json[r'timestamp'] != null, 'Required key "LogRow[timestamp]" has a null value in JSON.');
        assert(json.containsKey(r'trace_id'), 'Required key "LogRow[trace_id]" is missing from JSON.');
        assert(json[r'trace_id'] != null, 'Required key "LogRow[trace_id]" has a null value in JSON.');
        return true;
      }());

      return LogRow(
        attributes: mapValueOfType<Object>(json, r'attributes'),
        body: mapValueOfType<String>(json, r'body')!,
        service: mapValueOfType<String>(json, r'service')!,
        severity: mapValueOfType<String>(json, r'severity')!,
        severityNumber: mapValueOfType<int>(json, r'severity_number')!,
        spanId: mapValueOfType<String>(json, r'span_id')!,
        timestamp: mapValueOfType<String>(json, r'timestamp')!,
        traceId: mapValueOfType<String>(json, r'trace_id')!,
      );
    }
    return null;
  }

  static List<LogRow> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LogRow>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LogRow.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LogRow> mapFromJson(dynamic json) {
    final map = <String, LogRow>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LogRow.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LogRow-objects as value to a dart map
  static Map<String, List<LogRow>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LogRow>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LogRow.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'attributes',
    'body',
    'service',
    'severity',
    'severity_number',
    'span_id',
    'timestamp',
    'trace_id',
  };
}

