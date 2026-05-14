//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FacetField {
  /// Returns a new [FacetField] instance.
  FacetField({
    required this.field,
    this.values = const [],
  });

  String field;

  List<FacetValue> values;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FacetField &&
    other.field == field &&
    _deepEquality.equals(other.values, values);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (field.hashCode) +
    (values.hashCode);

  @override
  String toString() => 'FacetField[field=$field, values=$values]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'field'] = this.field;
      json[r'values'] = this.values;
    return json;
  }

  /// Returns a new [FacetField] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FacetField? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'field'), 'Required key "FacetField[field]" is missing from JSON.');
        assert(json[r'field'] != null, 'Required key "FacetField[field]" has a null value in JSON.');
        assert(json.containsKey(r'values'), 'Required key "FacetField[values]" is missing from JSON.');
        assert(json[r'values'] != null, 'Required key "FacetField[values]" has a null value in JSON.');
        return true;
      }());

      return FacetField(
        field: mapValueOfType<String>(json, r'field')!,
        values: FacetValue.listFromJson(json[r'values']),
      );
    }
    return null;
  }

  static List<FacetField> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FacetField>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FacetField.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FacetField> mapFromJson(dynamic json) {
    final map = <String, FacetField>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FacetField.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FacetField-objects as value to a dart map
  static Map<String, List<FacetField>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FacetField>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FacetField.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'field',
    'values',
  };
}

