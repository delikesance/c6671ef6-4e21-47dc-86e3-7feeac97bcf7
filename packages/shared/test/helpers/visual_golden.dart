import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:test_api/src/backend/invoker.dart';
import 'package:test/test.dart';

import 'visual_message_gateway.dart';
import 'visual_parity_harness.dart';

/// Whether the parity helpers of the messaging / components families still run
/// the historical engine next to the native one. The golden expectations below
/// are checked either way, so when the historical engine is deleted this flag
/// goes to `false` (or the comparison is dropped) and the tests keep their
/// meaning.
const bool parityWithHistorical = true;

/// Explicit expectations of the native path alone: for every parity call the
/// native outcome (effects, results, variables, error text, host response
/// state...) is compared with the value stored in `test/golden/<file>.json`,
/// keyed by the full test name and the call index within the test. Reviewed
/// and committed like any other expected value. Regenerate on purpose with
/// `UPDATE_GOLDEN=1 dart test test/<file>`.
class GoldenFile {
  GoldenFile(this.name);
  final String name;
  final _counters = <String, int>{};
  Map<String, dynamic>? _data;

  File get _file => File('test/golden/$name.json');

  Map<String, dynamic> get _stored => _data ??= _file.existsSync()
      ? (jsonDecode(_file.readAsStringSync()) as Map).cast<String, dynamic>()
      : <String, dynamic>{};

  static final _timestamp = RegExp(r'^\d{4}-\d\d-\d\dT[\d:.]+Z?$');

  static Object? _stable(Object? value) {
    if (value is String) {
      return _timestamp.hasMatch(value) ? '<timestamp>' : value;
    }
    if (value is List) return [for (final item in value) _stable(item)];
    if (value is Map) {
      return {for (final e in value.entries) e.key: _stable(e.value)};
    }
    return value;
  }

  /// JSON form of a snapshot; wall-clock timestamps are masked.
  static Object? normalize(Object? value) => _stable(
    jsonDecode(jsonEncode(value, toEncodable: (object) => object.toString())),
  );

  void expectSnapshot(Object? snapshot) {
    final test = Invoker.current!.liveTest.test.name;
    final index = _counters.update(test, (n) => n + 1, ifAbsent: () => 0);
    final key = '$test #$index';
    final actual = normalize(snapshot);
    if (Platform.environment['UPDATE_GOLDEN'] == '1') {
      _stored[key] = actual;
      final sorted = Map.fromEntries(
        _stored.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      _file.writeAsStringSync(
        '${const JsonEncoder.withIndent(' ').convert(sorted)}\n',
      );
      return;
    }
    expect(
      _stored.containsKey(key),
      isTrue,
      reason: 'no golden for "$key" (run with UPDATE_GOLDEN=1)',
    );
    expect(actual, _stored[key], reason: 'native outcome of "$key"');
  }

  /// A native outcome of the message gateway family.
  void expectMessage(MessageOutcome outcome) => expectSnapshot({
    'writes': outcome.writes,
    'interaction': outcome.interaction?.calls,
    'host': [
      outcome.context.response.acknowledged,
      outcome.context.response.originalResponseCompleted,
    ],
    'results': outcome.results,
    'variables': outcome.variables,
    'error': outcome.errorText,
  });

  /// A native outcome of the generic harness.
  void expectOutcome(Outcome outcome) => expectSnapshot({
    'effects': outcome.effects,
    'results': outcome.results,
    'variables': outcome.variables,
    'error': outcome.errorText,
  });
}
