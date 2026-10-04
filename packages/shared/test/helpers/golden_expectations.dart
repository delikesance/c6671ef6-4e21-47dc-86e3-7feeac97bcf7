import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Explicit expected values of the native path, stored as JSON next to the
/// tests (`test/golden/<suite>.json`), so a parity test keeps its meaning once
/// the historical path it was compared against is gone.
///
/// Every scenario snapshot (effects, results, final variables, error text) is
/// compared with the stored value; regenerate with
/// `UPDATE_GOLDEN=1 dart test <file>` and review the diff. Strings over 160 characters (rendered PNGs) are
/// stored as `<len>:<fnv1a64 hex>` digests.

late String _suite;
Map<String, dynamic> _stored = {};
final Map<String, dynamic> _recorded = {};
final Map<String, int> _seenNames = {};
String _scenario = '';
int _counter = 0;

bool get _update => Platform.environment['UPDATE_GOLDEN'] == '1';

File get _file => File('test/golden/$_suite.json');

/// Call at the top of `main`.
void useGolden(String suite) {
  _suite = suite;
  _stored = _file.existsSync()
      ? Map<String, dynamic>.from(jsonDecode(_file.readAsStringSync()) as Map)
      : {};
  _recorded.clear();
  _seenNames.clear();
  tearDownAll(() {
    if (_update) {
      _file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(_recorded)}\n',
      );
    }
  });
}

/// `test` that scopes the golden keys of its body.
void gtest(String name, dynamic Function() body, {dynamic skip}) {
  final occurrence = _seenNames.update(name, (n) => n + 1, ifAbsent: () => 0);
  final scenario = occurrence == 0 ? name : '$name@$occurrence';
  test(name, () async {
    _scenario = scenario;
    _counter = 0;
    await body();
  }, skip: skip);
}

String _digest(String value) {
  var hash = 0xcbf29ce484222325;
  for (final unit in utf8.encode(value)) {
    hash = ((hash ^ unit) * 0x100000001b3) & 0x7fffffffffffffff;
  }
  return '${value.length}:${hash.toRadixString(16)}';
}

Object? _normalize(Object? value) {
  if (value is String)
    return value.length > 160 ? 'digest:${_digest(value)}' : value;
  if (value is Map) {
    return {for (final e in value.entries) '${e.key}': _normalize(e.value)};
  }
  if (value is Iterable) return [for (final e in value) _normalize(e)];
  if (value == null || value is num || value is bool) return value;
  return _normalize(value.toString());
}

/// Compares [snapshot] with the stored expectation of the current scenario
/// step (or records it under `UPDATE_GOLDEN=1`).
void expectGolden(
  Map<String, Object?> snapshot, {
  Map<String, String> mask = const {},
}) {
  final key = '$_scenario#${_counter++}';
  var encoded = jsonEncode(_normalize(snapshot));
  for (final entry in mask.entries) {
    encoded = encoded.replaceAll(entry.key, entry.value);
  }
  final actual = jsonDecode(encoded);
  if (_update) {
    _recorded[key] = actual;
    return;
  }
  expect(_stored.containsKey(key), isTrue, reason: 'no golden for $key');
  expect(actual, _stored[key], reason: 'golden $key');
}
