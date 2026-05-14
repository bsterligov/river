//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FacetValue {
  /// Returns a new [FacetValue] instance.
  FacetValue({
    required this.count,
    required this.value,
  });

  /// Minimum value: 0
  int count;

  String value;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FacetValue &&
    other.count == count &&
    other.value == value;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (count.hashCode) +
    (value.hashCode);

  @override
  String toString() => 'FacetValue[count=$count, value=$value]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'count'] = this.count;
      json[r'value'] = this.value;
    return json;
  }

  /// Returns a new [FacetValue] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FacetValue? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'count'), 'Required key "FacetValue[count]" is missing from JSON.');
        assert(json[r'count'] != null, 'Required key "FacetValue[count]" has a null value in JSON.');
        assert(json.containsKey(r'value'), 'Required key "FacetValue[value]" is missing from JSON.');
        assert(json[r'value'] != null, 'Required key "FacetValue[value]" has a null value in JSON.');
        return true;
      }());

      return FacetValue(
        count: mapValueOfType<int>(json, r'count')!,
        value: mapValueOfType<String>(json, r'value')!,
      );
    }
    return null;
  }

  static List<FacetValue> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FacetValue>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FacetValue.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FacetValue> mapFromJson(dynamic json) {
    final map = <String, FacetValue>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FacetValue.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FacetValue-objects as value to a dart map
  static Map<String, List<FacetValue>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FacetValue>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FacetValue.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'count',
    'value',
  };
}

