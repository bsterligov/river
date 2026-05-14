//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HistogramBucket {
  /// Returns a new [HistogramBucket] instance.
  HistogramBucket({
    required this.bucket,
    required this.count,
  });

  String bucket;

  /// Minimum value: 0
  int count;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HistogramBucket &&
    other.bucket == bucket &&
    other.count == count;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (bucket.hashCode) +
    (count.hashCode);

  @override
  String toString() => 'HistogramBucket[bucket=$bucket, count=$count]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'bucket'] = this.bucket;
      json[r'count'] = this.count;
    return json;
  }

  /// Returns a new [HistogramBucket] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HistogramBucket? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'bucket'), 'Required key "HistogramBucket[bucket]" is missing from JSON.');
        assert(json[r'bucket'] != null, 'Required key "HistogramBucket[bucket]" has a null value in JSON.');
        assert(json.containsKey(r'count'), 'Required key "HistogramBucket[count]" is missing from JSON.');
        assert(json[r'count'] != null, 'Required key "HistogramBucket[count]" has a null value in JSON.');
        return true;
      }());

      return HistogramBucket(
        bucket: mapValueOfType<String>(json, r'bucket')!,
        count: mapValueOfType<int>(json, r'count')!,
      );
    }
    return null;
  }

  static List<HistogramBucket> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HistogramBucket>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HistogramBucket.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HistogramBucket> mapFromJson(dynamic json) {
    final map = <String, HistogramBucket>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HistogramBucket.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HistogramBucket-objects as value to a dart map
  static Map<String, List<HistogramBucket>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HistogramBucket>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HistogramBucket.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'bucket',
    'count',
  };
}

