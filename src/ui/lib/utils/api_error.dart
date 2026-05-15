import 'dart:convert';

import 'package:river_api/api.dart';

String extractApiError(Object e) {
  if (e is ApiException) {
    try {
      final body = jsonDecode(e.message ?? '') as Map<String, dynamic>;
      final msg = body['error'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    } catch (_) {}
  }
  return e.toString();
}
