import 'dart:convert';

/// The same schema subset is enforced by the manager before proposing a call.
void validateCopilotSchema(Map schema, Object? value, {int depth = 0}) {
  void invalid() => throw const FormatException('Invalid tool arguments');
  if (depth > 12) invalid();
  if (schema['enum'] is List &&
      !(schema['enum'] as List).any(
        (v) => jsonEncode(v) == jsonEncode(value),
      )) {
    invalid();
  }
  switch (schema['type']) {
    case null:
      // Unconstrained JSON values, such as variable values and block payloads.
      if (value is Map) {
        for (final v in value.values) {
          validateCopilotSchema(const {}, v, depth: depth + 1);
        }
      } else if (value is List) {
        for (final v in value) {
          validateCopilotSchema(const {}, v, depth: depth + 1);
        }
      }
    case 'object':
      if (value is! Map) invalid();
      final object = value as Map;
      final properties = schema['properties'] as Map? ?? const {};
      for (final key in schema['required'] as List? ?? const []) {
        if (!object.containsKey(key)) invalid();
      }
      for (final e in object.entries) {
        final property = properties[e.key];
        if (property is Map) {
          validateCopilotSchema(property, e.value, depth: depth + 1);
        } else if (schema['additionalProperties'] == false) {
          invalid();
        } else {
          validateCopilotSchema(const {}, e.value, depth: depth + 1);
        }
      }
    case 'array':
      if (value is! List) invalid();
      final list = value as List;
      if (list.length < (schema['minItems'] as int? ?? 0) ||
          list.length > (schema['maxItems'] as int? ?? 100000)) {
        invalid();
      }
      for (final item in list) {
        validateCopilotSchema(
          schema['items'] as Map? ?? const {},
          item,
          depth: depth + 1,
        );
      }
    case 'string':
      if (value is! String) invalid();
      final string = value as String;
      if (string.trim().runes.length < (schema['minLength'] as int? ?? 0) ||
          string.runes.length > (schema['maxLength'] as int? ?? 100000)) {
        invalid();
      }
    case 'integer':
    case 'number':
      if (value is! num ||
          !value.isFinite ||
          (schema['type'] == 'integer' && value != value.truncateToDouble())) {
        invalid();
      }
      final number = value as num;
      if (schema['minimum'] is num && number < (schema['minimum'] as num) ||
          schema['maximum'] is num && number > (schema['maximum'] as num)) {
        invalid();
      }
    case 'boolean':
      if (value is! bool) invalid();
    default:
      invalid();
  }
}
