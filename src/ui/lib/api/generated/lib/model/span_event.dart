//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SpanEvent {
  /// Returns a new [SpanEvent] instance.
  SpanEvent({
    required this.attributes,
    required this.name,
    required this.timestamp,
  });

  Object? attributes;

  String name;

  String timestamp;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SpanEvent &&
    other.attributes == attributes &&
    other.name == name &&
    other.timestamp == timestamp;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (attributes == null ? 0 : attributes!.hashCode) +
    (name.hashCode) +
    (timestamp.hashCode);

  @override
  String toString() => 'SpanEvent[attributes=$attributes, name=$name, timestamp=$timestamp]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.attributes != null) {
      json[r'attributes'] = this.attributes;
    } else {
      json[r'attributes'] = null;
    }
      json[r'name'] = this.name;
      json[r'timestamp'] = this.timestamp;
    return json;
  }

  /// Returns a new [SpanEvent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SpanEvent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'attributes'), 'Required key "SpanEvent[attributes]" is missing from JSON.');
        assert(json.containsKey(r'name'), 'Required key "SpanEvent[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "SpanEvent[name]" has a null value in JSON.');
        assert(json.containsKey(r'timestamp'), 'Required key "SpanEvent[timestamp]" is missing from JSON.');
        assert(json[r'timestamp'] != null, 'Required key "SpanEvent[timestamp]" has a null value in JSON.');
        return true;
      }());

      return SpanEvent(
        attributes: mapValueOfType<Object>(json, r'attributes'),
        name: mapValueOfType<String>(json, r'name')!,
        timestamp: mapValueOfType<String>(json, r'timestamp')!,
      );
    }
    return null;
  }

  static List<SpanEvent> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SpanEvent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SpanEvent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SpanEvent> mapFromJson(dynamic json) {
    final map = <String, SpanEvent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SpanEvent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SpanEvent-objects as value to a dart map
  static Map<String, List<SpanEvent>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SpanEvent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SpanEvent.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'attributes',
    'name',
    'timestamp',
  };
}

