import 'dart:convert';

/// Runtime lists are emitted as JSON arrays or comma-separated context values.
/// Membership checks must compare whole items rather than substrings.
List<String> runtimeAccessItems(String source) {
  final text = source.trim();
  if (text.isEmpty) return const [];
  if (text.startsWith('[')) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }
    } on FormatException {
      // Fall through for older comma-separated context values.
    }
  }
  return text.split(',').map((item) => item.trim()).toList();
}

bool runtimeContainsItem(String source, String item) =>
    item.isNotEmpty && runtimeAccessItems(source).contains(item);

bool runtimeHasPermission(String source, String permission) {
  String normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  final required = normalize(permission);
  if (required.isEmpty) return false;
  final items = runtimeAccessItems(source).map(normalize).toSet();
  return items.contains('administrator') || items.contains(required);
}
