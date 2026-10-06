import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/features/copilot/logic/copilot_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

// Contract with the documentation MCP served by vitrine (/api/mcp) and relayed
// by the manager (internal/services/ai_documentation.go): the Copilot docs_*
// tools declared here must be handled by CopilotMcp and stay identical to the
// manager's copy.
void main() {
  final tools =
      (jsonDecode(File('assets/copilot/tools.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
  final docs = tools.where((t) => (t['name'] as String).startsWith('docs_'));

  test('every docs_* tool is read-only and handled by CopilotMcp', () {
    final source = File(
      'lib/features/copilot/logic/copilot_mcp.dart',
    ).readAsStringSync();
    expect(
      docs.map((t) => t['name']),
      containsAll([
        'docs_search',
        'docs_get',
        'docs_manifest',
        'docs_actions',
        'docs_validate_actions',
      ]),
    );
    for (final tool in docs) {
      expect(
        tool['mutating'],
        false,
        reason: '${tool['name']} must not mutate',
      );
      expect(source, contains("case '${tool['name']}':"));
    }
  });

  test('every tool is compatible with the manager copilot_tools.json', () {
    // The manager lives next to this repository's bot-creator folder; a checkout without it skips.
    final manager = File(
      '../../../bot-creator-manager/internal/services/copilot_tools.json',
    );
    if (!manager.existsSync()) return;
    final server = {
      for (final t in jsonDecode(manager.readAsStringSync()) as List)
        (t as Map)['name'] as String: t,
    };
    // The app negotiates per tool (copilotToolCompatible): a tool it ships must be understood by the
    // manager with the same name, approval flag and schema, or it is silently dropped at runtime.
    for (final tool in tools) {
      final remote = server[tool['name']];
      expect(
        remote,
        isNotNull,
        reason: '${tool['name']} is missing on the manager',
      );
      expect(
        copilotToolCompatible(tool, remote as Map),
        isTrue,
        reason: '${tool['name']} would be dropped by the negotiation',
      );
    }
    for (final name in const [
      'library_search',
      'library_get',
      'local_create_command_from_library',
      'local_patch_command_execution',
    ]) {
      expect(
        server.containsKey(name),
        isTrue,
        reason: '$name missing on the manager',
      );
      expect(
        tools.any((t) => t['name'] == name),
        isTrue,
        reason: '$name missing in the app',
      );
    }
  });
}
