import 'dart:convert';

List<(String, String)> parseAttributes(Object? raw) {
  try {
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is Map<String, dynamic>) {
      return decoded.entries.map((e) => (e.key, '${e.value}')).toList();
    }
  } catch (_) {}
  return [];
}
