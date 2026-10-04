import 'package:bot_creator_shared/sandbox/command_sandbox.dart';

/// Runs [script] on native-v1 in the fixture-only sandbox.
Future<Map<String, dynamic>> runScript(
  String script, {
  Map<String, dynamic> extra = const {},
  Map<String, dynamic>? variables,
  Duration timeout = const Duration(seconds: 5),
}) => testCommandInSandbox({
  'script': script,
  'variables': ?variables,
  ...extra,
}, timeout: timeout);

/// Message payloads produced by the script, in order.
List<Map<String, dynamic>> payloads(Map<String, dynamic> result) => [
  for (final r in (result['responses'] as List? ?? const []))
    Map<String, dynamic>.from((r as Map)['payload'] as Map),
];

/// Content of the single message produced by the script.
String? contentOf(Map<String, dynamic> result) {
  final list = payloads(result);
  expectOk(result);
  return list.isEmpty ? null : list.single['content']?.toString();
}

void expectOk(Map<String, dynamic> result) {
  if (result['success'] != true) {
    throw StateError('Sandbox run failed: ${result['error']}');
  }
}
