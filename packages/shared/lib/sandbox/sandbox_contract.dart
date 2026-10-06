/// Contract evaluation of a sandbox result (expected response + JSON pointers).
///
/// Deliberately dependency-free (no `dart:io`, no engine): the Studio web UI
/// imports this file by path to judge results returned by the runner, while the
/// engine-side function suite re-exports it.
library;

/// Shared by the audit, mobile laboratory and Copilot's catalog contracts.
Map<String, dynamic> evaluateSandboxContract(
  Map<String, dynamic> result, {
  String? expectedContent,
  Map<String, dynamic> expectedValues = const {},
}) {
  final actual = (result['responses'] as List? ?? [])
      .map((response) => response['payload']['content'] ?? '')
      .join('\n');
  final checks = <Map<String, dynamic>>[];
  if (expectedContent != null) {
    checks.add({
      'path': 'response content',
      'expected': expectedContent,
      'actual': actual,
      'passed': actual == expectedContent,
    });
  }
  for (final entry in expectedValues.entries) {
    // A JSON pointer starts with '/'. Models often drop it: accept both instead of failing silently.
    final path = entry.key.startsWith('/') ? entry.key : '/${entry.key}';
    dynamic value = result;
    var found = true;
    String? hint;
    final walked = StringBuffer();
    for (final token in path.split('/').skip(1)) {
      final key = token.replaceAll('~1', '/').replaceAll('~0', '~');
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else if (value is List) {
        final index = int.tryParse(key);
        if (index == null || index < 0 || index >= value.length) {
          found = false;
          hint =
              "'$key' is not an index of the list at "
              "${walked.isEmpty ? '/' : walked} (length ${value.length})";
          break;
        }
        value = value[index];
      } else {
        found = false;
        hint = value is Map
            ? "no '$key' under ${walked.isEmpty ? '/' : walked}; "
                  'available: ${_availableKeys(value)}'
            : "'$key' cannot be read: ${walked.isEmpty ? '/' : walked} "
                  'is not an object or a list';
        break;
      }
      walked.write('/$token');
    }
    checks.add({
      'path': path,
      'expected': entry.value,
      'actual': found ? value : null,
      'found': found,
      'passed': found && _sameJsonValue(value, entry.value),
      'hint': ?hint,
    });
  }
  return {
    'actual': actual,
    'checks': checks,
    'passed':
        (result['success'] == true ||
            (expectedValues['/success'] == false &&
                expectedValues.containsKey('/error'))) &&
        checks.isNotEmpty &&
        checks.every((check) => check['passed'] == true),
  };
}

String _availableKeys(Map value) {
  final keys = value.keys.map((key) => key.toString()).toList()..sort();
  return keys.length <= 12
      ? keys.join(', ')
      : '${keys.take(12).join(', ')}, … (${keys.length} keys)';
}

bool _sameJsonValue(dynamic left, dynamic right) {
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.keys.every(
          (key) =>
              right.containsKey(key) && _sameJsonValue(left[key], right[key]),
        );
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        List.generate(
          left.length,
          (index) => index,
        ).every((index) => _sameJsonValue(left[index], right[index]));
  }
  if (right == sandboxIsoTimestampMatcher && left is String) {
    return DateTime.tryParse(left)?.isUtc == true;
  }
  // Embed colors are reported as '#RRGGBB' but models often assert the integer form (or vice versa).
  final leftColor = _hexColorValue(left), rightColor = _hexColorValue(right);
  if (leftColor != null &&
      rightColor != null &&
      (left is String) != (right is String)) {
    return leftColor == rightColor;
  }
  return left == right;
}

int? _hexColorValue(dynamic value) {
  if (value is int) return value >= 0 && value <= 0xFFFFFF ? value : null;
  if (value is String && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
    return int.parse(value.substring(1), radix: 16);
  }
  return null;
}

/// Expected value matching any UTC ISO-8601 timestamp, for clock-dependent
/// output the sandbox cannot pin to a fixed instant.
const sandboxIsoTimestampMatcher = '<utc iso-8601 timestamp>';
