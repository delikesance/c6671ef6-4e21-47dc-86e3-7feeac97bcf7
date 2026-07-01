import 'dart:convert';

const _sensitiveKeyFragments = <String>[
  'token',
  'secret',
  'password',
  'authorization',
  'receipt',
  'purchase',
  'credential',
  'apikey',
  'api_key',
];

/// Returns true when [key] looks like it holds sensitive data.
bool isSensitiveLogKey(String key) {
  final normalized = key.trim().toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }
  if (normalized == 'auth') {
    return true;
  }
  for (final fragment in _sensitiveKeyFragments) {
    if (normalized.contains(fragment)) {
      return true;
    }
  }
  return false;
}

/// Redacts sensitive values inside a JSON-like structure for safe logging.
dynamic redactSensitiveValue(dynamic value) {
  if (value is Map) {
    final out = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      if (isSensitiveLogKey(key)) {
        out[key] = '[REDACTED]';
      } else {
        out[key] = redactSensitiveValue(entry.value);
      }
    }
    return out;
  }
  if (value is List) {
    return value.map(redactSensitiveValue).toList(growable: false);
  }
  return value;
}

/// Redacts sensitive keys in a JSON string; falls back to a generic marker on parse failure.
String redactSensitiveJson(String raw) {
  if (raw.trim().isEmpty) {
    return raw;
  }
  try {
    final decoded = jsonDecode(raw);
    return jsonEncode(redactSensitiveValue(decoded));
  } catch (_) {
    return '[REDACTED_PAYLOAD]';
  }
}

/// Redacts common sensitive query parameters from a URI string.
String redactUriForLog(String uri) {
  final parsed = Uri.tryParse(uri);
  if (parsed == null) {
    return uri;
  }
  if (parsed.queryParameters.isEmpty) {
    return uri;
  }

  final redactedQuery = <String, String>{};
  for (final entry in parsed.queryParameters.entries) {
    redactedQuery[entry.key] =
        isSensitiveLogKey(entry.key) ? '[REDACTED]' : entry.value;
  }

  return parsed.replace(queryParameters: redactedQuery).toString();
}
